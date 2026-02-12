import 'package:just_audio/just_audio.dart';
import 'dart:typed_data';

/// Audio player for TTS output
/// Converts Float32 PCM samples to WAV format and plays using just_audio
class TtsPlayer {
  final AudioPlayer _player = AudioPlayer();

  /// Play PCM audio samples
  Future<void> speak(Float32List samples, int sampleRate) async {
    // Convert float32 to int16 PCM
    final pcm = _convertToInt16(samples);

    // Create WAV file
    final wav = _createWav(pcm, sampleRate);

    // Load and play
    await _player.setAudioSource(
      AudioSource.uri(Uri.dataFromBytes(wav, mimeType: 'audio/wav')),
    );
    await _player.play();

    // Wait for playback to complete
    await _player.playerStateStream.firstWhere(
      (state) => state.processingState == ProcessingState.completed,
    );
  }

  /// Convert Float32 samples to Int16 PCM
  Uint8List _convertToInt16(Float32List samples) {
    final bytes = Uint8List(samples.length * 2);
    for (int i = 0; i < samples.length; i++) {
      int value = (samples[i] * 32767).clamp(-32768, 32767).toInt();
      bytes[i * 2] = value & 0xFF;
      bytes[i * 2 + 1] = (value >> 8) & 0xFF;
    }
    return bytes;
  }

  /// Create WAV header and combine with PCM data
  Uint8List _createWav(Uint8List pcm, int sampleRate) {
    final header = BytesBuilder();

    // RIFF header
    header.add([0x52, 0x49, 0x46, 0x46]); // "RIFF"
    header.add(_int32(36 + pcm.length)); // File size - 8
    header.add([0x57, 0x41, 0x56, 0x45]); // "WAVE"

    // fmt chunk
    header.add([0x66, 0x6D, 0x74, 0x20]); // "fmt "
    header.add(_int32(16)); // fmt chunk size
    header.add(_int16(1)); // PCM format
    header.add(_int16(1)); // Mono
    header.add(_int32(sampleRate)); // Sample rate
    header.add(_int32(sampleRate * 2)); // Byte rate
    header.add(_int16(2)); // Block align
    header.add(_int16(16)); // Bits per sample

    // data chunk
    header.add([0x64, 0x61, 0x74, 0x61]); // "data"
    header.add(_int32(pcm.length));
    header.add(pcm);

    return header.toBytes();
  }

  Uint8List _int32(int n) => Uint8List(4)
    ..[0] = n & 0xFF
    ..[1] = (n >> 8) & 0xFF
    ..[2] = (n >> 16) & 0xFF
    ..[3] = (n >> 24) & 0xFF;

  Uint8List _int16(int n) => Uint8List(2)
    ..[0] = n & 0xFF
    ..[1] = (n >> 8) & 0xFF;

  /// Clean up resources
  void dispose() {
    _player.dispose();
  }
}
