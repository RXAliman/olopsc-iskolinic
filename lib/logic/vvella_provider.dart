import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ffi';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../native/ffi_bridge.dart';
import 'audio_pipeline.dart';
import 'nlu_processor.dart';
import '../data/health_repository.dart';

enum VoiceState {
  initializing,
  idle,       // KWS Monitor
  listening,  // ASR Active
  processing, // NLU
}

class VvellaProvider extends ChangeNotifier {
  VoiceState _state = VoiceState.initializing;
  VoiceState get state => _state;

  String _lastRecognizedText = "";
  String get lastRecognizedText => _lastRecognizedText;
  
  String _statusMessage = "Initializing...";
  String get statusMessage => _statusMessage;

  final SherpaService _sherpa = SherpaService();
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
      await Permission.microphone.request();
      
      // 2. Health Repo
      await _repo.init();
      
      // 3. Copy Assets
      await _copyAssets();
      
      // 4. Init Sherpa KWS
      // paths assume standard sherpa zipformer structure
      _sherpa.initKeywordSpotter(
        "$_localModelDir/tokens.txt",
        "$_localModelDir/encoder-epoch-99-avg-1.onnx", // KWS usually uses smaller model or same as ASR?
        // Actually for this demo we'll use the SAME model for both if possible, or distinct.
        // The user request specified Zipformer-small.
        // We will assume a single Streaming Zipformer or Offline Zipformer.
        // Wait, User said "OfflineRecognizer (for command processing)" and "Wake Word Detection".
        // KWS usually needs a specific KWS model or we can use the Streaming ASR in KWS mode?
        // Simpler for "Zero Cloud" strict offline: Use a dedicated KWS model (like sherpa-onnx-kws-zipformer-gigaspeech-3.0M-2023-11-08)
        // And a dedicated ASR model (sherpa-onnx-zipformer-en-2023-06-26).
        // I will document the filenames I expect.
        "$_localModelDir/decoder-epoch-99-avg-1.onnx",
        "$_localModelDir/joiner-epoch-99-avg-1.onnx",
        "$_localModelDir/keywords.txt",
        "" // no score file for simple kws
      );
      
      // 5. Init Sherpa ASR (Offline)
      // Assuming a different model or re-using? 
      // For simplicity/size, we can reuse if it's the same architecture, but usually KWS is streaming and ASR is offline/zipformer.
      // I will assume ASR uses the SAME model files for this MVP to reduce asset size, 
      // OR I will assume different filenames if they need to be distinct.
      // Let's assume distinct for robustness if the user downloads them.
      // KWS: encoder_kws.onnx ...
      // ASR: encoder_asr.onnx ...
      // But to make it EASIER for the user, I'll use ONE set of variables, but allow them to be same.
      // Actually, for "OfflineRecognizer", it MUST be a non-streaming model (Zipformer).
      // KWS MUST be a streaming model (Zipformer-streaming or LSTM).
      // So they ARE different.
      
      // KWS Files
      // encoder-streaming.onnx, decoder-streaming.onnx, joiner-streaming.onnx
      
      // ASR Files
      // encoder-offline.onnx, decoder-offline.onnx, joiner-offline.onnx
      
      _sherpa.initKeywordSpotter(
         "$_localModelDir/tokens.txt",
         "$_localModelDir/encoder-streaming.onnx",
         "$_localModelDir/decoder-streaming.onnx",
         "$_localModelDir/joiner-streaming.onnx",
         "$_localModelDir/keywords.txt",
         "" 
      );
      
      _sherpa.initOfflineRecognizer(
         "$_localModelDir/tokens.txt",
         "$_localModelDir/encoder-offline.onnx", 
         "$_localModelDir/decoder-offline.onnx", 
         "$_localModelDir/joiner-offline.onnx"
      );
      
      // 6. Audio Pipeline
      _audioPipeline = AudioPipeline(
        onAudio: _handleAudio,
        isKwsMode: () => _state == VoiceState.idle,
      );
      await _audioPipeline!.start();
      
      _state = VoiceState.idle;
      _statusMessage = "Listening for 'VVella'...";
      notifyListeners();
      
    } catch (e) {
      _statusMessage = "Error: $e";
      print("Init Error: $e");
      notifyListeners();
    }
  }
  
  Future<void> _copyAssets() async {
    final dir = await getApplicationDocumentsDirectory();
    _localModelDir = "${dir.path}/models";
    final modelDir = Directory(_localModelDir);
    if (!modelDir.existsSync()) {
      modelDir.createSync(recursive: true);
    }
    
    // List of assets to copy
    // We expect these to be in assets/models/ in the pubspec
    final assets = [
      "tokens.txt",
      "keywords.txt",
      "encoder-streaming.onnx",
      "decoder-streaming.onnx",
      "joiner-streaming.onnx",
      "encoder-offline.onnx",
      "decoder-offline.onnx",
      "joiner-offline.onnx",
    ];
    
    for (final name in assets) {
       try {
         final data = await rootBundle.load("assets/models/$name");
         final bytes = data.buffer.asUint8List();
         File("$_localModelDir/$name").writeAsBytesSync(bytes);
       } catch (e) {
         print("Warning: Failed to copy $name. Make sure it exists in assets/models/");
       }
    }
  }

  // Called from AudioPipeline (maybe background isolate if mic_stream ran there, but here it runs on main isolate via stream)
  // AudioPipeline uses simple stream listener, so it's on main isolate.
  // Pointers are valid.
  void _handleAudio(Pointer<Float> samples, int n, bool isKwsMode) {
      if (_state == VoiceState.idle) {
         _sherpa.acceptWaveform(samples, n, true);
         if (_sherpa.checkKeyword()) {
             _transitionToListening();
         }
      } else if (_state == VoiceState.listening) {
         _sherpa.acceptWaveform(samples, n, false);
         // Silence detection logic would go here.
         // For this MVP, we'll implement a simple timeout or user-stop.
         // Or we can check RMS of samples.
         // Let's implement a simple "Silence Timeout" in Dart for simplicity.
         _detectSilence(samples, n);
      }
  }
  
  Timer? _silenceTimer;
  double _energyThreshold = 0.01;
  
  void _transitionToListening() {
      print("Keyword Detected!");
      _state = VoiceState.listening;
      _statusMessage = "Listening for command...";
      _lastRecognizedText = "";
      notifyListeners();
      
      _sherpa.startASRStream(); // Start new utterance
      _resetSilenceTimer();
  }
  
  void _detectSilence(Pointer<Float> samples, int n) {
      // Calculate RMS
      double sum = 0;
      for (int i=0; i<n; i++) {
          sum += samples[i] * samples[i];
      }
      double rms = (sum / n); // squared mean
      
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
      final text = _sherpa.decodeASR();
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
      if (_state == VoiceState.processing) { // check if not changed
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
