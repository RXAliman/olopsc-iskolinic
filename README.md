# VVella - Offline Voice Assistant for Health Logging

VVella is a **fully offline**, voice-activated health assistant designed for busy middle-aged users. It uses on-device speech recognition powered by Sherpa-ONNX to log health metrics like blood pressure, heart rate, weight, and sleep duration—all without requiring an internet connection.

---

## 🎯 Key Features

- **100% Offline Operation**: All voice processing happens on-device using Sherpa-ONNX
- **Wake Word Detection (KWS)**: Continuously listens for the wake word "VVella"
- **Automatic Speech Recognition (ASR)**: Converts spoken commands to text
- **Natural Language Understanding (NLU)**: Extracts structured health data from speech
- **Local Encrypted Storage**: Health records stored securely using Hive
- **User-Friendly UI**: Large text, clear visual feedback, and simple interactions

---

## 🏗️ Technical Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                      Flutter UI Layer                        │
│                (lib/ui/vvella_screen.dart)                   │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────┐
│                      State Management                        │
│              (lib/logic/vvella_provider.dart)                │
│                                                              │
│       ┌──────────┐    ┌───────────┐    ┌────────────┐        │
│       │   KWS    │ →  │    ASR    │ →  │    NLU     │        │
│       │  (Idle)  │    │(Listening)│    │(Processing)│        │
│       └──────────┘    └───────────┘    └────────────┘        │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────┐
│                      Audio Pipeline                          │
│                (lib/logic/audio_pipeline.dart)               │
│           flutter_voice_processor (16kHz, 16-bit)            │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────┐
│                      FFI Bridge (Dart)                       │
│                 (lib/native/ffi_bridge.dart)                 │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────┐
│                    C++ Wrapper Layer                         │
│          (android/app/src/main/cpp/sherpa-wrapper.cc)        │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────┐
│              Sherpa-ONNX Native Libraries                    │
│       libsherpa-onnx-c-api.so  +  libonnxruntime.so          │
└──────────────────────────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
vvella/
├── android/
│   └── app/src/main/cpp/
│       ├── CMakeLists.txt           # Native build configuration
│       ├── sherpa-wrapper.cc        # C++ wrapper for Sherpa-ONNX
│       ├── includes/                # Sherpa-ONNX headers
│       │   └── sherpa-onnx/c-api/c-api.h
│       └── libs/
│           └── arm64-v8a/           # Native .so libraries
│               ├── libsherpa-onnx-c-api.so
│               └── libonnxruntime.so
├── assets/
│   └── models/                      # ONNX models (NOT bundled in APK)
│       ├── encoder-streaming.onnx   # KWS encoder
│       ├── decoder-streaming.onnx   # KWS decoder
│       ├── joiner-streaming.onnx    # KWS joiner
│       ├── encoder-offline.onnx     # ASR encoder
│       ├── decoder-offline.onnx     # ASR decoder
│       ├── joiner-offline.onnx      # ASR joiner
│       ├── tokens.txt               # BPE vocabulary
│       └── keywords.txt             # Wake word definitions
├── lib/
│   ├── main.dart                    # App entry point
│   ├── native/
│   │   └── ffi_bridge.dart          # Dart FFI bindings
│   ├── logic/
│   │   ├── vvella_provider.dart     # State machine & business logic
│   │   ├── audio_pipeline.dart      # Microphone audio capture
│   │   └── nlu_processor.dart       # Intent extraction
│   ├── data/
│   │   └── health_repository.dart   # Hive local storage
│   └── ui/
│       └── vvella_screen.dart       # Main UI screen
└── pubspec.yaml
```

---

## 🛠️ Prerequisites

### Required Software
- **Flutter SDK**: 3.x or later
- **Android SDK**: API 24+ (Android 7.0+)
- **Android NDK**: 27.x (bundled with Flutter)
- **ADB**: For pushing model files to device

### Required Hardware
- **Android device** with ARM64 processor (arm64-v8a)
- **Microphone** access

---

## 📥 Setup Instructions

### Step 1: Clone the Repository
```bash
git clone <repository-url>
cd vvella
flutter pub get
```

### Step 2: Download Sherpa-ONNX Native Libraries

Download the Android build from [Sherpa-ONNX Releases](https://github.com/k2-fsa/sherpa-onnx/releases):

```bash
# Download (example for v1.12.13)
wget https://github.com/k2-fsa/sherpa-onnx/releases/download/v1.12.13/sherpa-onnx-v1.12.13-android.tar.bz2

# Extract
tar -xjf sherpa-onnx-v1.12.13-android.tar.bz2
```

Copy the libraries to your project:
```bash
# Create directory
mkdir -p android/app/src/main/cpp/libs/arm64-v8a

# Copy .so files
cp sherpa-onnx-v1.12.13-android/jniLibs/arm64-v8a/libsherpa-onnx-c-api.so android/app/src/main/cpp/libs/arm64-v8a/
cp sherpa-onnx-v1.12.13-android/jniLibs/arm64-v8a/libonnxruntime.so android/app/src/main/cpp/libs/arm64-v8a/
```

### Step 3: Download Sherpa-ONNX C API Header

```bash
# Create directory
mkdir -p android/app/src/main/cpp/includes/sherpa-onnx/c-api

# Download header
curl -o android/app/src/main/cpp/includes/sherpa-onnx/c-api/c-api.h \
  https://raw.githubusercontent.com/k2-fsa/sherpa-onnx/master/sherpa-onnx/c-api/c-api.h
```

### Step 4: Download ONNX Models

#### For Keyword Spotting (Recommended - Small & Fast)
```bash
wget https://github.com/k2-fsa/sherpa-onnx/releases/download/kws-models/sherpa-onnx-kws-zipformer-gigaspeech-3.3M-2024-01-01.tar.bz2
tar -xjf sherpa-onnx-kws-zipformer-gigaspeech-3.3M-2024-01-01.tar.bz2
```

#### For Offline ASR
```bash
wget https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-zipformer-en-2023-06-26.tar.bz2
tar -xjf sherpa-onnx-zipformer-en-2023-06-26.tar.bz2
```

Copy and rename model files to `assets/models/`:
```
assets/models/
├── encoder-streaming.onnx    (from KWS model)
├── decoder-streaming.onnx    (from KWS model)
├── joiner-streaming.onnx     (from KWS model)
├── encoder-offline.onnx      (from ASR model, renamed)
├── decoder-offline.onnx      (from ASR model, renamed)
├── joiner-offline.onnx       (from ASR model, renamed)
├── tokens.txt                (from model)
└── keywords.txt              (create manually - see below)
```

### Step 5: Create keywords.txt

Create `assets/models/keywords.txt` with your wake word:
```
▁HE LL O ▁VI VE ▁LA
▁HE LL O ▁VI VE LA
▁HE LL O ▁VI VE ▁NA
▁HE LL O ▁VI VE
▁VI VE ▁LA
▁VI VE LA
▁VI VE ▁NA
▁VI VE
```

> **Note**: Use the `sherpa-onnx-cli text2token` tool to convert words to BPE tokens.

---

## 🚀 Running the Application

### Build & Install (First Time)
```bash
flutter clean
flutter pub get
flutter run
```

### Push Models to Device
**IMPORTANT**: Models are NOT bundled in the APK (too large). Push them manually:

```bash
# Create directory on device
adb shell mkdir -p /sdcard/Android/data/com.example.vvella/files/models/

# Push all model files
adb push assets/models/. /sdcard/Android/data/com.example.vvella/files/models/
```

### Verify Models on Device
```bash
adb shell ls -la /sdcard/Android/data/com.example.vvella/files/models/
```

---

## 🐛 Debugging

### View Native Logs
```bash
adb logcat -s VVellaNative
```

This shows:
- KWS initialization status
- Keyword matches (`KWS MATCHED: '...'`)
- ASR results

### View Flutter Logs
```bash
adb logcat -s flutter
```

### Common Issues

#### 1. "Native library not found"
**Cause**: Missing `.so` files in `android/app/src/main/cpp/libs/arm64-v8a/`

**Fix**: Download and copy the correct Sherpa-ONNX Android libraries.

#### 2. "Missing model files"
**Cause**: Models not pushed to device after install.

**Fix**: Run `adb push assets/models/. /sdcard/Android/data/com.example.vvella/files/models/`

#### 3. "Keyword is empty" spam in logs
**Cause**: Normal behavior - the KWS processes audio continuously.

**Fix**: This is expected. Only `KWS MATCHED: '...'` indicates actual detection.

#### 4. Wake word never triggers
**Causes**:
- Wrong `keywords.txt` format
- Wrong model type (using ASR model instead of KWS model)
- Threshold too high

**Fix**:
1. Use the dedicated KWS model: `sherpa-onnx-kws-zipformer-gigaspeech-3.3M-2024-01-01`
2. Ensure `keywords.txt` uses BPE tokens (see Step 5)
3. Lower threshold in `sherpa-wrapper.cc`: `config.keywords_threshold = 0.1;`

#### 5. APK too large (500MB+)
**Cause**: Model files accidentally bundled in assets.

**Fix**: Ensure `pubspec.yaml` does NOT include `assets/models/` in the assets section.

---

## 📝 Supported Voice Commands

| Command Type | Example Phrase | Extracted Data |
|--------------|----------------|----------------|
| Blood Pressure | "Log blood pressure 120 over 80" | `{sys: 120, dia: 80}` |
| Heart Rate | "Heart rate 75 BPM" | `{bpm: 75}` |
| Weight | "Weight 70 kilos" | `{kg: 70}` |
| Sleep | "Slept 7 hours" | `{hours: 7}` |

---

## 🔧 Configuration

### Adjust KWS Sensitivity
Edit `android/app/src/main/cpp/sherpa-wrapper.cc`:
```cpp
config.keywords_threshold = 0.25;  // Lower = more sensitive, Higher = fewer false positives
```

### Change Wake Word
Edit `assets/models/keywords.txt` and push to device:
```bash
adb push assets/models/keywords.txt /sdcard/Android/data/com.example.vvella/files/models/
```

Use `sherpa-onnx-cli text2token` to convert your custom wake word to BPE tokens.

---

## 🙏 Acknowledgments

- [Sherpa-ONNX](https://github.com/k2-fsa/sherpa-onnx) - On-device speech recognition
- [flutter_voice_processor](https://pub.dev/packages/flutter_voice_processor) - Audio capture
- [Hive](https://pub.dev/packages/hive) - Local storage
