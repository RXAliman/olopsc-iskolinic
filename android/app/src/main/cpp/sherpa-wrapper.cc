#include "sherpa-onnx/c-api/c-api.h"
#include <string.h>
#include <stdio.h>
#include <android/log.h>

#define TAG "VVellaNative"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)

extern "C" {

    const SherpaOnnxKeywordSpotter* CreateKeywordSpotter(
        const char* tokens,
        const char* encoder,
        const char* decoder,
        const char* joiner,
        const char* keywords_file,
        const char* keywords_score_file) { 
        
        LOGI("Creating KWS with keywords: %s", keywords_file);
        
        SherpaOnnxKeywordSpotterConfig config;
        memset(&config, 0, sizeof(config));
        
        config.feat_config.sample_rate = 16000;
        config.feat_config.feature_dim = 80;
        
        config.model_config.transducer.encoder = encoder;
        config.model_config.transducer.decoder = decoder;
        config.model_config.transducer.joiner = joiner;
        config.model_config.tokens = tokens;
        config.model_config.num_threads = 2;
        config.model_config.debug = 0;
        config.keywords_file = keywords_file;
        
        // Balanced threshold - not too sensitive, not too strict
        config.keywords_threshold = 0.1; 

        const SherpaOnnxKeywordSpotter* kws = SherpaOnnxCreateKeywordSpotter(&config);
        if (kws) {
            LOGI("KWS created successfully");
        } else {
            LOGE("Failed to create KWS!");
        }
        return kws;
    }

    void DestroyKeywordSpotter(const SherpaOnnxKeywordSpotter* kws) {
        SherpaOnnxDestroyKeywordSpotter(kws);
    }

    const SherpaOnnxOnlineStream* CreateKeywordStream(const SherpaOnnxKeywordSpotter* kws) {
        return SherpaOnnxCreateKeywordStream(kws);
    }

    void DestroyKeywordStream(const SherpaOnnxOnlineStream* stream) {
        SherpaOnnxDestroyOnlineStream(stream);
    }

    void AcceptWaveformKWS(const SherpaOnnxOnlineStream* stream, int32_t sample_rate, const float* samples, int32_t n) {
        SherpaOnnxOnlineStreamAcceptWaveform(stream, sample_rate, samples, n);
    }

    // Simple check - just returns if the engine thinks it's ready
    int32_t IsKeywordReady(const SherpaOnnxKeywordSpotter* kws, const SherpaOnnxOnlineStream* stream) {
        return SherpaOnnxIsKeywordStreamReady(kws, stream) ? 1 : 0;
    }
    
    // MUST be called after IsKeywordReady returns 1
    void DecodeKeyword(const SherpaOnnxKeywordSpotter* kws, const SherpaOnnxOnlineStream* stream) {
        SherpaOnnxDecodeKeywordStream(kws, stream);
    }
    
    // MUST be called after DecodeKeyword
    int32_t GetKeywordResult(const SherpaOnnxKeywordSpotter* kws, const SherpaOnnxOnlineStream* stream, char* out_text, int max_len) {
        const SherpaOnnxKeywordResult* result = SherpaOnnxGetKeywordResult(kws, stream);
        if (result == nullptr) {
            LOGI("GetKeywordResult: result is null");
            return 0;
        }
        
        if (result->keyword && strlen(result->keyword) > 0) {
            LOGI("KWS MATCHED: '%s'", result->keyword);
            strncpy(out_text, result->keyword, max_len - 1);
            out_text[max_len - 1] = '\0';
            SherpaOnnxDestroyKeywordResult(result);
            return 1;
        }
        
        LOGI("GetKeywordResult: keyword is empty");
        SherpaOnnxDestroyKeywordResult(result);
        return 0;
    }

    // --- Offline Recognizer ---
    const SherpaOnnxOfflineRecognizer* CreateOfflineRecognizer(
        const char* tokens, const char* encoder, const char* decoder, const char* joiner) {
        SherpaOnnxOfflineRecognizerConfig config;
        memset(&config, 0, sizeof(config));
        config.feat_config.sample_rate = 16000;
        config.feat_config.feature_dim = 80;
        config.model_config.transducer.encoder = encoder;
        config.model_config.transducer.decoder = decoder;
        config.model_config.transducer.joiner = joiner;
        config.model_config.tokens = tokens;
        config.model_config.num_threads = 2;
        config.decoding_method = "greedy_search";
        return SherpaOnnxCreateOfflineRecognizer(&config);
    }
    
    void DestroyOfflineRecognizer(const SherpaOnnxOfflineRecognizer* recognizer) {
        SherpaOnnxDestroyOfflineRecognizer(recognizer);
    }

    const SherpaOnnxOfflineStream* CreateOfflineStream(const SherpaOnnxOfflineRecognizer* recognizer) {
        return SherpaOnnxCreateOfflineStream(recognizer);
    }

    void DestroyOfflineStream(const SherpaOnnxOfflineStream* stream) {
        SherpaOnnxDestroyOfflineStream(stream);
    }

    void AcceptWaveformASR(const SherpaOnnxOfflineStream* stream, int32_t sample_rate, const float* samples, int32_t n) {
        SherpaOnnxAcceptWaveformOffline(stream, sample_rate, samples, n);
    }
    
    void DecodeOfflineStream(const SherpaOnnxOfflineRecognizer* recognizer, const SherpaOnnxOfflineStream* stream) {
        SherpaOnnxDecodeOfflineStream(recognizer, stream);
    }
    
    int32_t GetOfflineResult(const SherpaOnnxOfflineStream* stream, char* out_text, int max_len) {
        const SherpaOnnxOfflineRecognizerResult* result = SherpaOnnxGetOfflineStreamResult(stream);
        if (result == nullptr) return 0;
        if (result->text && strlen(result->text) > 0) {
            strncpy(out_text, result->text, max_len - 1);
            out_text[max_len - 1] = '\0';
            SherpaOnnxDestroyOfflineRecognizerResult(result);
            return 1;
        }
        SherpaOnnxDestroyOfflineRecognizerResult(result);
        return 0;
    }

    // ==================== TTS Functions ====================
    


const SherpaOnnxOfflineTts* CreateTts(
        const char* model,
        const char* voices,
        const char* tokens,
        const char* data_dir,
        int32_t num_threads
    ) {
        LOGI("Creating TTS: model=%s", model);
        LOGI("TTS voices: %s", voices);
        LOGI("TTS tokens: %s", tokens);
        LOGI("TTS data_dir: %s", data_dir);
        
        SherpaOnnxOfflineTtsConfig config;
        memset(&config, 0, sizeof(config));
        
        // Kokoro model config
        config.model.kokoro.model = model;
        config.model.kokoro.voices = voices;
        config.model.kokoro.tokens = tokens;
        config.model.kokoro.data_dir = data_dir;
        config.model.num_threads = num_threads;
        config.model.debug = 1; // Enable debug for troubleshooting
        
        const SherpaOnnxOfflineTts* tts = SherpaOnnxCreateOfflineTts(&config);
        
        if (tts) {
            LOGI("TTS created successfully");
        } else {
            LOGE("TTS creation failed!");
        }
        return tts;
    }

    void DestroyTts(const SherpaOnnxOfflineTts* tts) {
        SherpaOnnxDestroyOfflineTts(tts);
    }

    const SherpaOnnxGeneratedAudio* GenerateSpeech(
        const SherpaOnnxOfflineTts* tts,
        const char* text,
        int32_t speaker_id,
        float speed
    ) {
        LOGI("Generating TTS for: %s", text);
        return SherpaOnnxOfflineTtsGenerate(tts, text, speaker_id, speed);
    }

    int32_t GetNumSamples(const SherpaOnnxGeneratedAudio* audio) {
        return audio->n;
    }

    int32_t GetSampleRate(const SherpaOnnxGeneratedAudio* audio) {
        return audio->sample_rate;
    }

    void CopyAudioSamples(
        const SherpaOnnxGeneratedAudio* audio,
        float* buffer,
        int32_t buffer_size
    ) {
        int32_t n = audio->n < buffer_size ? audio->n : buffer_size;
        memcpy(buffer, audio->samples, n * sizeof(float));
        LOGI("Copied %d audio samples", n);
    }

    void DestroyGeneratedAudio(const SherpaOnnxGeneratedAudio* audio) {
        SherpaOnnxDestroyOfflineTtsGeneratedAudio(audio);
    }
}
