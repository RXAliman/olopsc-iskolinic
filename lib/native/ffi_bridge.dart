import 'dart:ffi';
import 'dart:typed_data';
import 'dart:io';
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

// TTS Typedefs
typedef CreateTtsC =
    Pointer<Void> Function(
      Pointer<Utf8>,
      Pointer<Utf8>,
      Pointer<Utf8>,
      Pointer<Utf8>,
      Int32,
    );
typedef CreateTtsDart =
    Pointer<Void> Function(
      Pointer<Utf8>,
      Pointer<Utf8>,
      Pointer<Utf8>,
      Pointer<Utf8>,
      int,
    );

typedef DestroyTtsC = Void Function(Pointer<Void>);
typedef DestroyTtsDart = void Function(Pointer<Void>);

typedef GenerateSpeechC =
    Pointer<Void> Function(Pointer<Void>, Pointer<Utf8>, Int32, Float);
typedef GenerateSpeechDart =
    Pointer<Void> Function(Pointer<Void>, Pointer<Utf8>, int, double);

typedef GetNumSamplesC = Int32 Function(Pointer<Void>);
typedef GetNumSamplesDart = int Function(Pointer<Void>);

typedef GetSampleRateC = Int32 Function(Pointer<Void>);
typedef GetSampleRateDart = int Function(Pointer<Void>);

typedef CopyAudioSamplesC = Void Function(Pointer<Void>, Pointer<Float>, Int32);
typedef CopyAudioSamplesDart =
    void Function(Pointer<Void>, Pointer<Float>, int);

typedef DestroyGeneratedAudioC = Void Function(Pointer<Void>);
typedef DestroyGeneratedAudioDart = void Function(Pointer<Void>);

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

  // TTS function pointers
  late CreateTtsDart _createTts;
  late DestroyTtsDart _destroyTts;
  late GenerateSpeechDart _generateSpeech;
  late GetNumSamplesDart _getNumSamples;
  late GetSampleRateDart _getSampleRate;
  late CopyAudioSamplesDart _copyAudioSamples;
  late DestroyGeneratedAudioDart _destroyGeneratedAudio;

  Pointer<Void>? _kws;
  Pointer<Void>? _kwsStream;
  Pointer<Void>? _asr;
  Pointer<Void>? _asrStream;
  Pointer<Void>? _tts; // TTS instance
  int _lastSampleRate = 16000; // Cache last generated audio's sample rate

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

    // TTS function lookups
    _createTts = _lib.lookupFunction<CreateTtsC, CreateTtsDart>('CreateTts');
    _destroyTts = _lib.lookupFunction<DestroyTtsC, DestroyTtsDart>(
      'DestroyTts',
    );
    _generateSpeech = _lib.lookupFunction<GenerateSpeechC, GenerateSpeechDart>(
      'GenerateSpeech',
    );
    _getNumSamples = _lib.lookupFunction<GetNumSamplesC, GetNumSamplesDart>(
      'GetNumSamples',
    );
    _getSampleRate = _lib.lookupFunction<GetSampleRateC, GetSampleRateDart>(
      'GetSampleRate',
    );
    _copyAudioSamples = _lib
        .lookupFunction<CopyAudioSamplesC, CopyAudioSamplesDart>(
          'CopyAudioSamples',
        );
    _destroyGeneratedAudio = _lib
        .lookupFunction<DestroyGeneratedAudioC, DestroyGeneratedAudioDart>(
          'DestroyGeneratedAudio',
        );
  }

  void initKeywordSpotter(
    String tokens,
    String encoder,
    String decoder,
    String joiner,
    String keywordsFile,
    String keywordsScoreFile,
  ) {
    final tokensUtf8 = tokens.toNativeUtf8();
    final encoderUtf8 = encoder.toNativeUtf8();
    final decoderUtf8 = decoder.toNativeUtf8();
    final joinerUtf8 = joiner.toNativeUtf8();
    final keywordsUtf8 = keywordsFile.toNativeUtf8();
    final scoresUtf8 = keywordsScoreFile.toNativeUtf8();

    _kws = _createKeywordSpotter(
      tokensUtf8,
      encoderUtf8,
      decoderUtf8,
      joinerUtf8,
      keywordsUtf8,
      scoresUtf8,
    );
    _kwsStream = _createKeywordStream(_kws!);

    calloc.free(tokensUtf8);
    calloc.free(encoderUtf8);
    calloc.free(decoderUtf8);
    calloc.free(joinerUtf8);
    calloc.free(keywordsUtf8);
    calloc.free(scoresUtf8);
  }

  void initOfflineRecognizer(
    String tokens,
    String encoder,
    String decoder,
    String joiner,
  ) {
    final tokensUtf8 = tokens.toNativeUtf8();
    final encoderUtf8 = encoder.toNativeUtf8();
    final decoderUtf8 = decoder.toNativeUtf8();
    final joinerUtf8 = joiner.toNativeUtf8();

    _asr = _createOfflineRecognizer(
      tokensUtf8,
      encoderUtf8,
      decoderUtf8,
      joinerUtf8,
    );

    calloc.free(tokensUtf8);
    calloc.free(encoderUtf8);
    calloc.free(decoderUtf8);
    calloc.free(joinerUtf8);
  }

  void startASRStream() {
    if (_asrStream != null) {
      // Destroy old stream if exists
      _asrStream = null;
    }
    _asrStream = _createOfflineStream(_asr!);
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

    final ready = _isKeywordReady(_kws!, _kwsStream!);
    if (ready == 1) {
      // Decode result first
      _decodeKeyword(_kws!, _kwsStream!);

      // Get result text
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

  // TTS Methods
  void initTts(String modelDir) {
    // Validate model files exist
    final modelFile = "$modelDir/model.onnx";
    final voicesFile = "$modelDir/voices.bin";
    final tokensFile = "$modelDir/tokens.txt";
    final dataDir = "$modelDir/espeak-ng-data";

    if (!File(modelFile).existsSync()) {
      throw Exception("TTS model file not found: $modelFile");
    }
    if (!File(voicesFile).existsSync()) {
      throw Exception("TTS voices file not found: $voicesFile");
    }
    if (!File(tokensFile).existsSync()) {
      throw Exception("TTS tokens file not found: $tokensFile");
    }
    if (!Directory(dataDir).existsSync()) {
      throw Exception("TTS espeak-ng-data directory not found: $dataDir");
    }

    print("TTS: Initializing with model: $modelFile");
    print("TTS: Voices: $voicesFile");
    print("TTS: Tokens: $tokensFile");
    print("TTS: Data dir: $dataDir");

    final model = modelFile.toNativeUtf8();
    final voices = voicesFile.toNativeUtf8();
    final tokens = tokensFile.toNativeUtf8();
    final data = dataDir.toNativeUtf8();

    _tts = _createTts(model, voices, tokens, data, 2);

    calloc.free(model);
    calloc.free(voices);
    calloc.free(tokens);
    calloc.free(data);

    if (_tts == null || _tts == nullptr) {
      throw Exception(
        "Failed to initialize TTS - model creation returned null",
      );
    }

    print("TTS: Initialized successfully");
  }

  Float32List speak(String text, {int speakerId = 0, double speed = 1.0}) {
    if (_tts == null) return Float32List(0);

    final textUtf8 = text.toNativeUtf8();
    final audio = _generateSpeech(_tts!, textUtf8, speakerId, speed);
    calloc.free(textUtf8);

    if (audio == nullptr) return Float32List(0);

    final numSamples = _getNumSamples(audio);
    _lastSampleRate = _getSampleRate(audio); // Store for later use

    // Allocate buffer and copy samples
    final buffer = calloc<Float>(numSamples);
    _copyAudioSamples(audio, buffer, numSamples);

    // Convert to Dart list
    final samples = Float32List(numSamples);
    for (int i = 0; i < numSamples; i++) {
      samples[i] = buffer[i];
    }

    calloc.free(buffer);
    _destroyGeneratedAudio(audio);

    return samples;
  }

  // Get sample rate of last generated speech
  int get lastSampleRate => _lastSampleRate;

  // Cleanup TTS resources (call on app exit if needed)
  void disposeTts() {
    if (_tts != null) {
      _destroyTts(_tts!);
      _tts = null;
    }
  }
}
