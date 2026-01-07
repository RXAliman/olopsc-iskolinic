import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// --- Typedefs for C functions ---

// KWS
typedef CreateKeywordSpotterC = Pointer<Void> Function(
  Pointer<Utf8> tokens,
  Pointer<Utf8> encoder,
  Pointer<Utf8> decoder,
  Pointer<Utf8> joiner,
  Pointer<Utf8> keywordsFile,
  Pointer<Utf8> keywordsScoreFile,
);
typedef CreateKeywordSpotterDart = Pointer<Void> Function(
  Pointer<Utf8> tokens,
  Pointer<Utf8> encoder,
  Pointer<Utf8> decoder,
  Pointer<Utf8> joiner,
  Pointer<Utf8> keywordsFile,
  Pointer<Utf8> keywordsScoreFile,
);

typedef CreateKeywordStreamC = Pointer<Void> Function(Pointer<Void> kws);
typedef CreateKeywordStreamDart = Pointer<Void> Function(Pointer<Void> kws);

typedef AcceptWaveformKWSC = Void Function(Pointer<Void> stream, Int32 sampleRate, Pointer<Float> samples, Int32 n);
typedef AcceptWaveformKWSDart = void Function(Pointer<Void> stream, int sampleRate, Pointer<Float> samples, int n);

typedef IsKeywordDetectedC = Int32 Function(Pointer<Void> stream);
typedef IsKeywordDetectedDart = int Function(Pointer<Void> stream);

// ASR
typedef CreateOfflineRecognizerC = Pointer<Void> Function(
    Pointer<Utf8> tokens, Pointer<Utf8> encoder, Pointer<Utf8> decoder, Pointer<Utf8> joiner);
typedef CreateOfflineRecognizerDart = Pointer<Void> Function(
    Pointer<Utf8> tokens, Pointer<Utf8> encoder, Pointer<Utf8> decoder, Pointer<Utf8> joiner);

typedef CreateOfflineStreamC = Pointer<Void> Function(Pointer<Void> recognizer);
typedef CreateOfflineStreamDart = Pointer<Void> Function(Pointer<Void> recognizer);

typedef AcceptWaveformASRC = Void Function(Pointer<Void> stream, Int32 sampleRate, Pointer<Float> samples, Int32 n);
typedef AcceptWaveformASRDart = void Function(Pointer<Void> stream, int sampleRate, Pointer<Float> samples, int n);

typedef DecodeOfflineStreamC = Void Function(Pointer<Void> recognizer, Pointer<Void> stream);
typedef DecodeOfflineStreamDart = void Function(Pointer<Void> recognizer, Pointer<Void> stream);

typedef GetOfflineStreamResultC = Pointer<Utf8> Function(Pointer<Void> stream);
typedef GetOfflineStreamResultDart = Pointer<Utf8> Function(Pointer<Void> stream);

// --- SherpaService Class ---

class SherpaService {
  late DynamicLibrary _lib;
  late CreateKeywordSpotterDart _createKeywordSpotter;
  late CreateKeywordStreamDart _createKeywordStream;
  late AcceptWaveformKWSDart _acceptWaveformKWS;
  late IsKeywordDetectedDart _isKeywordDetected;
  
  late CreateOfflineRecognizerDart _createOfflineRecognizer;
  late CreateOfflineStreamDart _createOfflineStream;
  late AcceptWaveformASRDart _acceptWaveformASR;
  late DecodeOfflineStreamDart _decodeOfflineStream;
  late GetOfflineStreamResultDart _getOfflineStreamResult;

  Pointer<Void>? _kws;
  Pointer<Void>? _kwsStream;
  Pointer<Void>? _asr;
  Pointer<Void>? _asrStream;

  SherpaService() {
    if (Platform.isAndroid) {
      _lib = DynamicLibrary.open('libvvella_native.so');
    } else {
      // Fallback or error for other platforms
      throw UnsupportedError('Only Android is supported currently');
    }

    _loadFunctions();
  }

  void _loadFunctions() {
    _createKeywordSpotter = _lib
        .lookup<NativeFunction<CreateKeywordSpotterC>>('CreateKeywordSpotter')
        .asFunction();
    _createKeywordStream = _lib
        .lookup<NativeFunction<CreateKeywordStreamC>>('CreateKeywordStream')
        .asFunction();
    _acceptWaveformKWS = _lib
        .lookup<NativeFunction<AcceptWaveformKWSC>>('AcceptWaveformKWS')
        .asFunction();
    _isKeywordDetected = _lib
        .lookup<NativeFunction<IsKeywordDetectedC>>('IsKeywordDetected')
        .asFunction();
        
    _createOfflineRecognizer = _lib
        .lookup<NativeFunction<CreateOfflineRecognizerC>>('CreateOfflineRecognizer')
        .asFunction();
    _createOfflineStream = _lib
        .lookup<NativeFunction<CreateOfflineStreamC>>('CreateOfflineStream')
        .asFunction();
    _acceptWaveformASR = _lib
        .lookup<NativeFunction<AcceptWaveformASRC>>('AcceptWaveformASR')
        .asFunction();
    _decodeOfflineStream = _lib
        .lookup<NativeFunction<DecodeOfflineStreamC>>('DecodeOfflineStream')
        .asFunction();
    _getOfflineStreamResult = _lib
        .lookup<NativeFunction<GetOfflineStreamResultC>>('GetOfflineStreamResult')
        .asFunction();
  }

  void initKeywordSpotter(
      String tokens, String encoder, String decoder, String joiner, String kwFile, String kwScoreFile) {
    
    final t = tokens.toNativeUtf8();
    final e = encoder.toNativeUtf8();
    final d = decoder.toNativeUtf8();
    final j = joiner.toNativeUtf8();
    final k = kwFile.toNativeUtf8();
    final s = kwScoreFile.toNativeUtf8();

    _kws = _createKeywordSpotter(t, e, d, j, k, s);
    _kwsStream = _createKeywordStream(_kws!);

    calloc.free(t); calloc.free(e); calloc.free(d); calloc.free(j); calloc.free(k); calloc.free(s);
  }

  void initOfflineRecognizer(String tokens, String encoder, String decoder, String joiner) {
      final t = tokens.toNativeUtf8();
      final e = encoder.toNativeUtf8();
      final d = decoder.toNativeUtf8();
      final j = joiner.toNativeUtf8();
      
      _asr = _createOfflineRecognizer(t, e, d, j);
      
      calloc.free(t); calloc.free(e); calloc.free(d); calloc.free(j);
  }
  
  void startASRStream() {
      // Create a fresh stream for a new utterance
      if (_asr != null) {
          _asrStream = _createOfflineStream(_asr!);
      }
  }

  void acceptWaveform(Pointer<Float> samples, int n, bool isKwsMode) {
      if (isKwsMode && _kwsStream != null) {
          _acceptWaveformKWS(_kwsStream!, 16000, samples, n);
      } else if (!isKwsMode && _asrStream != null) {
          _acceptWaveformASR(_asrStream!, 16000, samples, n);
      }
  }
  
  bool checkKeyword() {
      if (_kwsStream == null) return false;
      return _isKeywordDetected(_kwsStream!) == 1;
  }
  
  String decodeASR() {
      if (_asrStream == null || _asr == null) return "";
      _decodeOfflineStream(_asr!, _asrStream!);
      final ptr = _getOfflineStreamResult(_asrStream!);
      return ptr.toDartString();
  }
}
