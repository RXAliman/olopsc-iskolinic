PLEASE DOWNLOAD THE MODELS AND PLACE THEM HERE:

Expected Files:
1. `tokens.txt` (from the model directory)
2. `keywords.txt` (Create this file: lines containing keywords e.g. "vvella", "blood pressure", etc. - Check sherpa docs for format, usually `kw_ID kw_TEXT score` or just text for some spotters)
   - Actually for standard KWS, user needs to create it.
   - Example content for `keywords.txt`: 
     vvella/5.0
     
3. Streaming Model (Used for KWS):
   - `encoder-streaming.onnx`
   - `decoder-streaming.onnx`
   - `joiner-streaming.onnx`
   (Rename the files from the downloaded model, e.g. `encoder-epoch-99-avg-1.onnx` -> `encoder-streaming.onnx`)

4. Offline Model (Used for ASR):
   - `encoder-offline.onnx`
   - `decoder-offline.onnx`
   - `joiner-offline.onnx`
   (Rename accordingly)

Recommended Models:
- Streaming: `sherpa-onnx-streaming-zipformer-en-2023-02-21` from https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-streaming-zipformer-en-2023-06-26.tar.bz2
- Offline: `sherpa-onnx-zipformer-en-2023-06-26` from https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-zipformer-en-2023-06-26.tar.bz2

https://github.com/k2-fsa/sherpa-onnx/releases
