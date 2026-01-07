PLEASE DOWNLOAD THE FOLLOWING LIBRARIES:

1. `libsherpa-onnx-c-api.so`
2. `libonnxruntime.so`

Place them IN THIS FOLDER:
`android/app/src/main/cpp/libs/arm64-v8a/`

You can find them in the `sherpa-onnx` releases or build them:
https://github.com/k2-fsa/sherpa-onnx/releases

Ensure they are for the `arm64-v8a` architecture (standard Android).
If you need `armeabi-v7a`, create that folder and put the 32-bit libs there too.
