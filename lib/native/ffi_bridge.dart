import 'dart:ffi';
import 'package:ffi/ffi.dart';

// --- Typedefs ---
typedef CreateKeywordSpotterC =
    Pointer<Void> Function(
      Pointer<Utf8>,
      Pointer<Utf8>,
      Pointer<Utf8>,
      Pointer<Utf8>,
      Pointer<Utf8>,
      Pointer<Utf8>,
    );
typedef CreateKeywordSpotterDart =
    Pointer<Void> Function(
      Pointer<Utf8>,
      Pointer<Utf8>,
      Pointer<Utf8>,
      Pointer<Utf8>,
      Pointer<Utf8>,
      Pointer<Utf8>,
    );

typedef CreateKeywordStreamC = Pointer<Void> Function(Pointer<Void> kws);
typedef CreateKeywordStreamDart = Pointer<Void> Function(Pointer<Void> kws);

typedef DestroyKeywordStreamC = Void Function(Pointer<Void> stream);
typedef DestroyKeywordStreamDart = void Function(Pointer<Void> stream);

typedef AcceptWaveformKWSC =
    Void Function(
      Pointer<Void> stream,
      Int32 sampleRate,
      Pointer<Float> samples,
      Int32 n,
    );
typedef AcceptWaveformKWSDart =
    void Function(
      Pointer<Void> stream,
      int sampleRate,
      Pointer<Float> samples,
      int n,
    );

typedef IsKeywordReadyC =
    Int32 Function(Pointer<Void> kws, Pointer<Void> stream);
typedef IsKeywordReadyDart =
    int Function(Pointer<Void> kws, Pointer<Void> stream);

typedef DecodeKeywordC = Void Function(Pointer<Void> kws, Pointer<Void> stream);
typedef DecodeKeywordDart =
    void Function(Pointer<Void> kws, Pointer<Void> stream);

typedef GetKeywordResultC =
    Int32 Function(
      Pointer<Void> kws,
      Pointer<Void> stream,
      Pointer<Utf8> outText,
      Int32 maxLen,
    );
typedef GetKeywordResultDart =
    int Function(
      Pointer<Void> kws,
      Pointer<Void> stream,
      Pointer<Utf8> outText,
      int maxLen,
    );

typedef CreateOfflineRecognizerC =
    Pointer<Void> Function(
      Pointer<Utf8>,
      Pointer<Utf8>,
      Pointer<Utf8>,
      Pointer<Utf8>,
    );
typedef CreateOfflineRecognizerDart =
    Pointer<Void> Function(
      Pointer<Utf8>,
      Pointer<Utf8>,
      Pointer<Utf8>,
      Pointer<Utf8>,
    );

typedef CreateOfflineStreamC = Pointer<Void> Function(Pointer<Void> recognizer);
typedef CreateOfflineStreamDart =
    Pointer<Void> Function(Pointer<Void> recognizer);

typedef AcceptWaveformASRC =
    Void Function(
      Pointer<Void> stream,
      Int32 sampleRate,
      Pointer<Float> samples,
      Int32 n,
    );
typedef AcceptWaveformASRDart =
    void Function(
      Pointer<Void> stream,
      int sampleRate,
      Pointer<Float> samples,
      int n,
    );

typedef DecodeOfflineStreamC =
    Void Function(Pointer<Void> recognizer, Pointer<Void> stream);
typedef DecodeOfflineStreamDart =
    void Function(Pointer<Void> recognizer, Pointer<Void> stream);

typedef GetOfflineResultC =
    Int32 Function(Pointer<Void> stream, Pointer<Utf8> outText, Int32 maxLen);
typedef GetOfflineResultDart =
    int Function(Pointer<Void> stream, Pointer<Utf8> outText, int maxLen);

class SherpaService {
  late DynamicLibrary _lib;
  late CreateKeywordSpotterDart _createKeywordSpotter;
  late CreateKeywordStreamDart _createKeywordStream;
  late DestroyKeywordStreamDart _destroyKeywordStream;
  late AcceptWaveformKWSDart _acceptWaveformKWS;
  late IsKeywordReadyDart _isKeywordReady;
  late DecodeKeywordDart _decodeKeyword;
  late GetKeywordResultDart _getKeywordResult;

  late CreateOfflineRecognizerDart _createOfflineRecognizer;
  late CreateOfflineStreamDart _createOfflineStream;
  late AcceptWaveformASRDart _acceptWaveformASR;
  late DecodeOfflineStreamDart _decodeOfflineStream;
  late GetOfflineResultDart _getOfflineResult;

  Pointer<Void>? _kws;
  Pointer<Void>? _kwsStream;
  Pointer<Void>? _asr;
  Pointer<Void>? _asrStream;

  SherpaService() {
    _lib = DynamicLibrary.open('libvvella_native.so');
    _loadFunctions();
  }

  void _loadFunctions() {
    _createKeywordSpotter = _lib
        .lookupFunction<CreateKeywordSpotterC, CreateKeywordSpotterDart>(
          'CreateKeywordSpotter',
        );
    _createKeywordStream = _lib
        .lookupFunction<CreateKeywordStreamC, CreateKeywordStreamDart>(
          'CreateKeywordStream',
        );
    _destroyKeywordStream = _lib
        .lookupFunction<DestroyKeywordStreamC, DestroyKeywordStreamDart>(
          'DestroyKeywordStream',
        );
    _acceptWaveformKWS = _lib
        .lookupFunction<AcceptWaveformKWSC, AcceptWaveformKWSDart>(
          'AcceptWaveformKWS',
        );
    _isKeywordReady = _lib.lookupFunction<IsKeywordReadyC, IsKeywordReadyDart>(
      'IsKeywordReady',
    );
    _decodeKeyword = _lib.lookupFunction<DecodeKeywordC, DecodeKeywordDart>(
      'DecodeKeyword',
    );
    _getKeywordResult = _lib
        .lookupFunction<GetKeywordResultC, GetKeywordResultDart>(
          'GetKeywordResult',
        );

    _createOfflineRecognizer = _lib
        .lookupFunction<CreateOfflineRecognizerC, CreateOfflineRecognizerDart>(
          'CreateOfflineRecognizer',
        );
    _createOfflineStream = _lib
        .lookupFunction<CreateOfflineStreamC, CreateOfflineStreamDart>(
          'CreateOfflineStream',
        );
    _acceptWaveformASR = _lib
        .lookupFunction<AcceptWaveformASRC, AcceptWaveformASRDart>(
          'AcceptWaveformASR',
        );
    _decodeOfflineStream = _lib
        .lookupFunction<DecodeOfflineStreamC, DecodeOfflineStreamDart>(
          'DecodeOfflineStream',
        );
    _getOfflineResult = _lib
        .lookupFunction<GetOfflineResultC, GetOfflineResultDart>(
          'GetOfflineResult',
        );
  }

  void initKeywordSpotter(
    String tokens,
    String encoder,
    String decoder,
    String joiner,
    String kwFile,
    String kwScoreFile,
  ) {
    final t = tokens.toNativeUtf8();
    final e = encoder.toNativeUtf8();
    final d = decoder.toNativeUtf8();
    final j = joiner.toNativeUtf8();
    final k = kwFile.toNativeUtf8();
    final s = kwScoreFile.toNativeUtf8();
    _kws = _createKeywordSpotter(t, e, d, j, k, s);
    _kwsStream = _createKeywordStream(_kws!);
    calloc.free(t);
    calloc.free(e);
    calloc.free(d);
    calloc.free(j);
    calloc.free(k);
    calloc.free(s);
  }

  void initOfflineRecognizer(
    String tokens,
    String encoder,
    String decoder,
    String joiner,
  ) {
    final t = tokens.toNativeUtf8();
    final e = encoder.toNativeUtf8();
    final d = decoder.toNativeUtf8();
    final j = joiner.toNativeUtf8();
    _asr = _createOfflineRecognizer(t, e, d, j);
    calloc.free(t);
    calloc.free(e);
    calloc.free(d);
    calloc.free(j);
  }

  void startASRStream() {
    if (_asr != null) _asrStream = _createOfflineStream(_asr!);
  }

  void acceptWaveform(Pointer<Float> samples, int n, bool isKwsMode) {
    if (isKwsMode && _kwsStream != null) {
      _acceptWaveformKWS(_kwsStream!, 16000, samples, n);
    } else if (!isKwsMode && _asrStream != null) {
      _acceptWaveformASR(_asrStream!, 16000, samples, n);
    }
  }

  bool checkKeyword() {
    if (_kws == null || _kwsStream == null) return false;

    if (_isKeywordReady(_kws!, _kwsStream!) == 1) {
      _decodeKeyword(_kws!, _kwsStream!);

      final buffer = calloc<Int8>(512).cast<Utf8>();
      int found = _getKeywordResult(_kws!, _kwsStream!, buffer, 512);
      String resultText = "";
      if (found == 1) {
        resultText = buffer.toDartString();
      }
      calloc.free(buffer);

      // Only reset stream if we got a VALID match
      // If empty, keep accumulating audio for context
      if (resultText.isNotEmpty) {
        print("KWS MATCH FOUND: '$resultText'");
        _destroyKeywordStream(_kwsStream!);
        _kwsStream = _createKeywordStream(_kws!);
        return true;
      }
      // Empty result = keep listening, don't reset
    }
    return false;
  }

  String decodeASR() {
    if (_asrStream == null || _asr == null) return "";
    _decodeOfflineStream(_asr!, _asrStream!);
    final buffer = calloc<Int8>(1024).cast<Utf8>();
    int found = _getOfflineResult(_asrStream!, buffer, 1024);
    String result = "";
    if (found == 1) result = buffer.toDartString();
    calloc.free(buffer);
    return result;
  }
}
