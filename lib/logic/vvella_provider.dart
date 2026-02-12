import 'dart:io';
import 'dart:async';
import 'dart:ffi';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/scheduler.dart';

import '../native/ffi_bridge.dart';
import 'audio_pipeline.dart';
import 'nlu_processor.dart';
import 'tts_player.dart';
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

  String _statusMessage = "Starting up...";
  String get statusMessage => _statusMessage;

  double _loadingProgress = 0.0;
  double get loadingProgress => _loadingProgress;

  // Chat history
  final List<Map<String, String>> _chatHistory = [];
  List<Map<String, String>> get chatHistory => _chatHistory;

  // Typing animation state
  bool _isVvellaTyping = false;
  bool get isVvellaTyping => _isVvellaTyping;

  String _currentTypingText = "";
  String get currentTypingText => _currentTypingText;

  SherpaService? _sherpa;
  final NLUProcessor _nlu = NLUProcessor();
  final HealthRepository _repo = HealthRepository();
  AudioPipeline? _audioPipeline;
  TtsPlayer? _ttsPlayer;

  // Model paths
  late String _localModelDir;

  VvellaProvider() {
    // Delay initialization to allow splash screen to render first
    SchedulerBinding.instance.addPostFrameCallback((_) {
      // Additional small delay to ensure smooth transition
      Future.delayed(const Duration(milliseconds: 100), () {
        _init();
      });
    });
  }

  Future<void> _init() async {
    try {
      // Stage 1: Permissions (15%)
      _statusMessage = "Requesting permissions...";
      _loadingProgress = 0.0;
      notifyListeners();

      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        _statusMessage = "Microphone permission denied";
        notifyListeners();
        return;
      }

      _loadingProgress = 0.15;
      notifyListeners();

      // Stage 2: Health Repository (25%)
      _statusMessage = "Setting up storage...";
      _loadingProgress = 0.2;
      notifyListeners();

      await _repo.init();

      _loadingProgress = 0.25;
      notifyListeners();

      // Stage 3: Copy/Verify Assets (40%)
      _statusMessage = "Verifying AI models...";
      _loadingProgress = 0.3;
      notifyListeners();

      await _copyAssets();

      _loadingProgress = 0.4;
      notifyListeners();

      // Stage 4: Load Native Library (55%)
      _statusMessage = "Loading native libraries...";
      _loadingProgress = 0.45;
      notifyListeners();

      try {
        _sherpa = SherpaService();
      } catch (e) {
        _statusMessage = "Native library not found: $e";
        print("Failed to load native library: $e");
        notifyListeners();
        return;
      }

      _loadingProgress = 0.55;
      notifyListeners();

      // Stage 5: Init Keyword Spotter (70%)
      _statusMessage = "Initializing wake word detection...";
      _loadingProgress = 0.6;
      notifyListeners();

      _sherpa!.initKeywordSpotter(
        "$_localModelDir/tokens.txt",
        "$_localModelDir/encoder-streaming.onnx",
        "$_localModelDir/decoder-streaming.onnx",
        "$_localModelDir/joiner-streaming.onnx",
        "$_localModelDir/keywords.txt",
        "",
      );

      _loadingProgress = 0.7;
      notifyListeners();

      // Stage 6: Init Speech Recognizer (85%)
      _statusMessage = "Initializing speech recognizer...";
      _loadingProgress = 0.75;
      notifyListeners();

      _sherpa!.initOfflineRecognizer(
        "$_localModelDir/tokens.txt",
        "$_localModelDir/encoder-offline.onnx",
        "$_localModelDir/decoder-offline.onnx",
        "$_localModelDir/joiner-offline.onnx",
      );

      _loadingProgress = 0.85;
      notifyListeners();

      // Stage 7: Audio Pipeline (90%)
      _statusMessage = "Starting audio pipeline...";
      _loadingProgress = 0.85;
      notifyListeners();

      _audioPipeline = AudioPipeline(
        onAudio: _handleAudio,
        isKwsMode: () => _state == VoiceState.idle,
      );
      await _audioPipeline!.start();

      _loadingProgress = 0.9;
      notifyListeners();

      // Stage 8: TTS (100%)
      _statusMessage = "Initializing text-to-speech...";
      _loadingProgress = 0.95;
      notifyListeners();

      _sherpa!.initTts("$_localModelDir/tts/kokoro-en-v0_19");
      _ttsPlayer = TtsPlayer();

      // Complete
      _loadingProgress = 1.0;
      _statusMessage = "Ready!";
      notifyListeners();

      // Small delay to show completion
      await Future.delayed(const Duration(milliseconds: 300));

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

    // Add user message to chat
    if (text.isNotEmpty) {
      _chatHistory.add({'actor': 'user', 'content': text});
      notifyListeners();
    }

    // NLU - Process command
    final intent = _nlu.process(text);

    String vvellaResponse;
    if (intent != null) {
      await _repo.saveRecord(intent);
      vvellaResponse = "Okay, I've logged that for you.";
      _statusMessage = "Saved: ${intent.toString()}";
    } else if (text.isEmpty) {
      vvellaResponse = "I didn't catch that. Please try again.";
      _statusMessage = "No speech detected";
    } else {
      vvellaResponse =
          "I'm not sure how to help with that. Try saying 'log blood pressure 120 over 80'.";
      _statusMessage = "No command recognized from: $text";
    }

    // Add VVella response with TTS
    await _addVvellaResponse(vvellaResponse);

    // Back to idle after animation completes
    if (_state == VoiceState.processing) {
      _state = VoiceState.idle;
      _statusMessage = "Listening for 'VVella'...";
      notifyListeners();
    }
  }

  // TTS-based response (replaces typewriter animation)
  Future<void> _addVvellaResponse(String message) async {
    // Add message to chat instantly
    _chatHistory.add({'actor': 'vvella', 'content': message});
    notifyListeners();

    // Generate and play speech
    // Note: TTS generation may cause brief UI pause - this is expected
    // for on-device neural TTS. Could be improved with native threading.
    try {
      final samples = _sherpa!.speak(message, speakerId: 0, speed: 1.0);
      if (samples.isNotEmpty) {
        final sampleRate = _sherpa!.lastSampleRate;
        await _ttsPlayer!.speak(samples, sampleRate);
      }
    } catch (e) {
      print("TTS error: $e");
    }
  }

  // Public methods for manual control

  /// Manually start listening without wake word
  void startListeningManually() {
    if (_state == VoiceState.idle && _sherpa != null) {
      _transitionToListening();
    }
  }

  /// Stop listening and return to idle
  void stopListening() {
    if (_state == VoiceState.listening) {
      _silenceTimer?.cancel();
      _state = VoiceState.idle;
      _statusMessage = "Listening for 'VVella'...";
      _lastRecognizedText = "";
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
