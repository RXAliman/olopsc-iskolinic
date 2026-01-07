import 'dart:async';
import 'dart:ffi'; // For Struct/Pointer checks if needed, but mainly for the buffer conversions
import 'dart:typed_data';
import 'package:mic_stream/mic_stream.dart'; // Make sure this is in pubspec
import 'package:ffi/ffi.dart';

class AudioPipeline {
  StreamSubscription<Uint8List>? _micSubscription;
  final void Function(Pointer<Float>, int, bool) _onAudio;
  final bool Function() _isKwsMode;
  
  // Buffer to holding converted floats
  // Reusing memory to avoid GC pressure
  // However, FFI expects a Pointer<Float>. We need to allocate native memory.
  // Pushing data to C++ ideally should use `calloc` or similar, pass it, then free it?
  // OR, better, Pass a typed data list and use `allocator` inside but that's slow per chunk.
  // Best: Allocate a large native buffer once? No, sample size varies.
  // We will allocate per chunk for simplicity now, or better use Arena.
  
  AudioPipeline({
    required void Function(Pointer<Float>, int, bool) onAudio,
    required bool Function() isKwsMode,
  }) : _onAudio = onAudio, _isKwsMode = isKwsMode;

  Future<void> start() async {
    Stream<Uint8List>? stream = await MicStream.microphone(
        audioSource: AudioSource.VOICE_RECOGNITION,
        sampleRate: 16000,
        channelConfig: ChannelConfig.CHANNEL_IN_MONO,
        audioFormat: AudioFormat.ENCODING_PCM_16BIT,
    );

    if (stream == null) {
        print("Mic stream null");
        return;
    }

    _micSubscription = stream.listen((Uint8List samples) {
      // samples is int16 bytes (little endian).
      // 2 bytes per sample.
      int numSamples = samples.length ~/ 2;
      
      // Allocate native float array
      final ptr = calloc<Float>(numSamples);
      
      // Convert INT16 to Float (-1.0 to 1.0)
      ByteData byteData = ByteData.sublistView(samples);
      for (int i = 0; i < numSamples; i++) {
        int val = byteData.getInt16(i * 2, Endian.little);
        ptr[i] = val / 32768.0;
      }
      
      // Send to C++
      _onAudio(ptr, numSamples, _isKwsMode());
      
      // Free memory
      calloc.free(ptr);
    });
  }

  Future<void> stop() async {
    await _micSubscription?.cancel();
    _micSubscription = null;
  }
}
