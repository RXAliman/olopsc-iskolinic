import 'dart:io';
import 'dart:async';
import 'dart:ffi';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../native/ffi_bridge.dart';
import 'audio_pipeline.dart';
import 'nlu_processor.dart';
import '../data/health_repository.dart';

enum VoiceState {
  initializing,
  idle, // KWS Monitor
  listening, // ASR Active
  processing, // NLU
}

class VvellaProvider extends ChangeNotifier {
  VoiceState _state = VoiceState.initializing;
  VoiceState get state => _state;

  String _lastRecognizedText = "";
  String get lastRecognizedText => _lastRecognizedText;

  String _statusMessage = "Initializing...";
  String get statusMessage => _statusMessage;

  SherpaService? _sherpa;
  final NLUProcessor _nlu = NLUProcessor();
  final HealthRepository _repo = HealthRepository();
  AudioPipeline? _audioPipeline;

  // Model paths
  late String _localModelDir;

  VvellaProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      // 1. Permissions
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        _statusMessage = "Microphone permission denied";
        notifyListeners();
        return;
      }

      // 2. Health Repo
      await _repo.init();

      // 3. Copy Assets
      await _copyAssets();

      // 4. Init Sherpa Service (loads native library)
      try {
        _sherpa = SherpaService();
      } catch (e) {
        _statusMessage = "Native library not found: $e";
        print("Failed to load native library: $e");
        notifyListeners();
        return;
      }

      // 5. Init Sherpa KWS (Streaming model for keyword spotting)
      _sherpa!.initKeywordSpotter(
        "$_localModelDir/tokens.txt",
        "$_localModelDir/encoder-streaming.onnx",
        "$_localModelDir/decoder-streaming.onnx",
        "$_localModelDir/joiner-streaming.onnx",
        "$_localModelDir/keywords.txt",
        "",
      );

      // 6. Init Sherpa ASR (Offline model for command recognition)
      _sherpa!.initOfflineRecognizer(
        "$_localModelDir/tokens.txt",
        "$_localModelDir/encoder-offline.onnx",
        "$_localModelDir/decoder-offline.onnx",
        "$_localModelDir/joiner-offline.onnx",
      );

      // 7. Audio Pipeline
      _audioPipeline = AudioPipeline(
        onAudio: _handleAudio,
        isKwsMode: () => _state == VoiceState.idle,
      );
      await _audioPipeline!.start();

      _state = VoiceState.idle;
      _statusMessage = "Listening for 'VVella'...";
      notifyListeners();
    } catch (e, stackTrace) {
      _statusMessage = "Error: $e";
      print("Init Error: $e");
      print("Stack: $stackTrace");
      notifyListeners();
    }
  }

  Future<void> _copyAssets() async {
    // Models are NOT bundled in APK (too large, 400MB+)
    // They must be pushed manually via:
    // adb push assets/models/ /sdcard/Android/data/com.example.vvella/files/models/

    final dir = await getExternalStorageDirectory();
    if (dir == null) {
      throw Exception("External storage not available");
    }
    _localModelDir = "${dir.path}/models";
    final modelDir = Directory(_localModelDir);

    if (!modelDir.existsSync()) {
      modelDir.createSync(recursive: true);
      _statusMessage = "Models folder created. Please push models via adb.";
      notifyListeners();
    }

    // Required model files
    final requiredFiles = [
      "tokens.txt",
      "keywords.txt",
      "encoder-streaming.onnx",
      "decoder-streaming.onnx",
      "joiner-streaming.onnx",
      "encoder-offline.onnx",
      "decoder-offline.onnx",
      "joiner-offline.onnx",
    ];

    // Check if all required files exist
    List<String> missingFiles = [];
    for (final name in requiredFiles) {
      final file = File("$_localModelDir/$name");
      if (!file.existsSync()) {
        missingFiles.add(name);
      }
    }

    if (missingFiles.isNotEmpty) {
      _statusMessage =
          "Missing models: ${missingFiles.join(', ')}\n\nPush via:\nadb push assets/models/ ${dir.path}/models/";
      print("Missing model files: $missingFiles");
      print("Model directory: $_localModelDir");
      notifyListeners();
      throw Exception("Missing model files: $missingFiles");
    }

    print("All model files found in: $_localModelDir");
  }

  void _handleAudio(Pointer<Float> samples, int n, bool isKwsMode) {
    if (_sherpa == null) return;

    if (_state == VoiceState.idle) {
      _sherpa!.acceptWaveform(samples, n, true);
      if (_sherpa!.checkKeyword()) {
        _transitionToListening();
      }
    } else if (_state == VoiceState.listening) {
      _sherpa!.acceptWaveform(samples, n, false);
      _detectSilence(samples, n);
    }
  }

  Timer? _silenceTimer;
  final double _energyThreshold = 0.01;

  void _transitionToListening() {
    print("Keyword Detected!");
    _state = VoiceState.listening;
    _statusMessage = "Listening for command...";
    _lastRecognizedText = "";
    notifyListeners();

    _sherpa?.startASRStream(); // Start new utterance
    _resetSilenceTimer();
  }

  void _detectSilence(Pointer<Float> samples, int n) {
    // Calculate RMS energy
    double sum = 0;
    for (int i = 0; i < n; i++) {
      sum += samples[i] * samples[i];
    }
    double rms = (sum / n);

    if (rms > _energyThreshold) {
      _resetSilenceTimer();
    }
  }

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(seconds: 2), () {
      // Silence detected for 2 seconds
      _finalizeASR();
    });
  }

  Future<void> _finalizeASR() async {
    _silenceTimer?.cancel();
    if (_state != VoiceState.listening) return;

    _state = VoiceState.processing;
    _statusMessage = "Processing...";
    notifyListeners();

    // Decode
    final text = _sherpa?.decodeASR() ?? "";
    _lastRecognizedText = text;
    print("Recognized: $text");

    // NLU
    final intent = _nlu.process(text);

    if (intent != null) {
      await _repo.saveRecord(intent);
      _statusMessage = "Saved: ${intent.toString()}";
    } else {
      _statusMessage = "No command recognized from: $text";
    }

    notifyListeners();

    // Back to idle after delay
    await Future.delayed(const Duration(seconds: 3));
    if (_state == VoiceState.processing) {
      _state = VoiceState.idle;
      _statusMessage = "Listening for 'VVella'...";
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _audioPipeline?.stop();
    _silenceTimer?.cancel();
    super.dispose();
  }
}
