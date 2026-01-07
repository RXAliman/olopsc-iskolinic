#include "sherpa-onnx/c-api/c-api.h"
#include <vector>
#include <string.h>
#include <stdio.h>

extern "C" {

    // --- Keyword Spotter ---
    const SherpaOnnxKeywordSpotter* CreateKeywordSpotter(
        const char* tokens,
        const char* encoder,
        const char* decoder,
        const char* joiner,
        const char* keywords_file,
        const char* keywords_score_file) {
        
        SherpaOnnxKeywordSpotterConfig config;
        memset(&config, 0, sizeof(config));
        
        config.feat_config.sample_rate = 16000;
        config.feat_config.feature_dim = 80;
        
        config.model_config.transducer.encoder = encoder;
        config.model_config.transducer.decoder = decoder;
        config.model_config.transducer.joiner = joiner;
        config.model_config.tokens = tokens;
        config.model_config.num_threads = 1;
        config.model_config.debug = 0;
        
        config.keywords_file = keywords_file;
        config.keywords_score_file = keywords_score_file;

        return SherpaOnnxCreateKeywordSpotter(&config);
    }

    void DestroyKeywordSpotter(const SherpaOnnxKeywordSpotter* kws) {
        SherpaOnnxDestroyKeywordSpotter(kws);
    }

    const SherpaOnnxKeywordStream* CreateKeywordStream(const SherpaOnnxKeywordSpotter* kws) {
        return SherpaOnnxCreateKeywordStream(kws);
    }

    void DestroyKeywordStream(const SherpaOnnxKeywordStream* stream) {
        SherpaOnnxDestroyKeywordStream(stream);
    }

    void AcceptWaveformKWS(const SherpaOnnxKeywordStream* stream, int32_t sample_rate, const float* samples, int32_t n) {
        SherpaOnnxKeywordStreamAcceptWaveform(stream, sample_rate, samples, n);
    }

    int32_t IsKeywordDetected(const SherpaOnnxKeywordStream* stream) {
        return SherpaOnnxIsKeywordStreamReady(stream);
    }

    void ResetKeywordStream(const SherpaOnnxKeywordStream* stream) {
         // Sherpa-ONNX streams might not have explicit reset, usually we create a new one or just keep running.
         // For KWS, it's continuous.
    }

    // --- Offline Recognizer ---
    const SherpaOnnxOfflineRecognizer* CreateOfflineRecognizer(
        const char* tokens,
        const char* encoder, 
        const char* decoder,
        const char* joiner) {
        
        SherpaOnnxOfflineRecognizerConfig config;
        memset(&config, 0, sizeof(config));
        
        config.feat_config.sample_rate = 16000;
        config.feat_config.feature_dim = 80;
        
        config.model_config.transducer.encoder = encoder;
        config.model_config.transducer.decoder = decoder;
        config.model_config.transducer.joiner = joiner;
        config.model_config.tokens = tokens;
        config.model_config.num_threads = 1;
        config.model_config.debug = 0;
        
        // zipformer
        config.model_config.transducer.encoder = encoder; // re-assign just to be safe, logic depends on model type
        
        // Decoding method greedy_search
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
    
    const char* GetOfflineStreamResult(const SherpaOnnxOfflineStream* stream) {
        const SherpaOnnxOfflineRecognizerResult* result = SherpaOnnxGetOfflineStreamResult(stream);
        return result->text;
    }
    
    void DestroyOfflineStreamResult(const SherpaOnnxOfflineRecognizerResult* result) {
        SherpaOnnxDestroyOfflineRecognizerResult(result);
    }
}
