import 'dart:ffi';
import 'package:flutter_voice_processor/flutter_voice_processor.dart';
import 'package:ffi/ffi.dart';

class AudioPipeline {
  VoiceProcessor? _voiceProcessor;
  final void Function(Pointer<Float>, int, bool) _onAudio;
  final bool Function() _isKwsMode;

  // Frame length for 16kHz audio (e.g., 512 samples = 32ms)
  static const int _frameLength = 512;

  AudioPipeline({
    required void Function(Pointer<Float>, int, bool) onAudio,
    required bool Function() isKwsMode,
  }) : _onAudio = onAudio,
       _isKwsMode = isKwsMode;

  Future<void> start() async {
    try {
      _voiceProcessor = VoiceProcessor.instance;

      // Add frame listener - receives List<int> (16-bit samples)
      _voiceProcessor!.addFrameListener(_onFrame);

      // Add error listener
      _voiceProcessor!.addErrorListener(_onError);

      // Start recording at 16kHz with specified frame length
      await _voiceProcessor!.start(_frameLength, 16000);

      print("AudioPipeline started successfully");
    } catch (e) {
      print("AudioPipeline start error: $e");
      rethrow;
    }
  }

  void _onFrame(List<int> frame) {
    // frame contains 16-bit signed PCM samples as int values
    int numSamples = frame.length;

    if (numSamples == 0) return;

    // Allocate native float array
    final ptr = calloc<Float>(numSamples);

    // Convert INT16 to Float (-1.0 to 1.0)
    for (int i = 0; i < numSamples; i++) {
      ptr[i] = frame[i] / 32768.0;
    }

    // Send to C++
    _onAudio(ptr, numSamples, _isKwsMode());

    // Free memory
    calloc.free(ptr);
  }

  void _onError(VoiceProcessorException error) {
    print("VoiceProcessor error: ${error.message}");
  }

  Future<void> stop() async {
    try {
      if (_voiceProcessor != null) {
        _voiceProcessor!.removeFrameListener(_onFrame);
        _voiceProcessor!.removeErrorListener(_onError);
        await _voiceProcessor!.stop();
      }
    } catch (e) {
      print("AudioPipeline stop error: $e");
    }
  }
}
