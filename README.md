[![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=fff)](#) [![ONNX](https://img.shields.io/badge/ONNX-005CED?logo=ONNX&logoColor=white)](#) [![iOS](https://img.shields.io/badge/iOS-000000?&logo=apple&logoColor=white)](#) [![Android](https://img.shields.io/badge/Android-3DDC84?logo=android&logoColor=white)](#) [![Rust](https://img.shields.io/badge/Rust-%23000000.svg?e&logo=rust&logoColor=white)](#)

## Chuck'it (v1.0.18+19)

Chuck your data into baskets and worry less about sorting it!

### Features

Chuck'it is all about being able to bookmark items in the most convenient way possible and is built upon four foundations:
- Bookmark without breaking the flow of your current app
- Auto-tag shared items while still providing manual tagging
- Fully offline, the data you share is yours and no one elses
- Good search capabilities to easily find items shared in the past

### Getting Started

Platforms Supported: iOS & Android.

> Testing available on iOS 16.0+, and for Android it is recommended to use Android 12.0+ for the best performance.

If you are looking to try the app out you can download it from the following links:
- [iOS](https://testflight.apple.com/join/EZ7BMmKW) (TestFlight) to test on iOS.
- [Android](https://drive.google.com/drive/folders/1EWhWk3mepMPJ372suxfbAbhTRLgwhlJl?usp=drive_link) or download the latest release from the repository (APK): Direct APK download, no email required.


If you want to set up the project locally, follow the instructions below:

### Prerequisites & Setup

<details>
<summary>Step 1: Flutter SDK</summary>

Install Flutter SDK from [flutter.dev](https://flutter.dev/docs/get-started/install)

<details>
<summary>Flutter / Xcode / Android Toolchain Versions</summary>

``` 
Flutter (Channel stable, 3.35.5, on macOS 15.6.1 24G90
    darwin-arm64, locale en-SG) [608ms]
    • Flutter version 3.35.5 on channel stable at
      /Users/skywar56/Documents/Flutter/flutter
    • Upstream repository https://github.com/flutter/flutter.git
    • Framework revision ac4e799d23 (10 weeks ago), 2025-09-26
      12:05:09 -0700
    • Engine revision d3d45dcf25
    • Dart version 3.9.2
    • DevTools version 2.48.0
    • Feature flags: enable-web, enable-linux-desktop,
      enable-macos-desktop, enable-windows-desktop,
      enable-android, enable-ios, cli-animations,
      enable-lldb-debugging

[✓] Android toolchain - develop for Android devices (Android SDK
    version 36.1.0) [1,983ms]
    • Android SDK at /Users/skywar56/Library/Android/sdk
    • Emulator version 33.1.24.0 (build_id 11237101) (CL:N/A)
    • Platform android-36, build-tools 36.1.0
    • Java binary at:
      /Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home/
      bin/java
      This JDK is specified in your Flutter configuration.
      To change the current JDK, run: `flutter config
      --jdk-dir="path/to/jdk"`.
    • Java version OpenJDK Runtime Environment Zulu17.52+17-CA
      (build 17.0.12+7-LTS)
    • All Android licenses accepted.

[✓] Xcode - develop for iOS and macOS (Xcode 26.1.1) [1,192ms]
    • Xcode at /Applications/Xcode.app/Contents/Developer
    • Build 17B100
    • CocoaPods version 1.16.2
```
</details>


Once Flutter is installed, change Flutter channel to stable and change Flutter version to `3.35.5` using the following commands:

```bash
flutter channel stable
flutter version 3.35.5
```

> NOTE: Make sure you set your flutter version to `3.35.5` to avoid any compatibility issues.

---

</details>


<details>
<summary>Step 2: ONNX Embedding Models</summary>


**Download Embedding Models**
- Download Text Embedding Model: [nomic-embed-text-v1.5](https://huggingface.co/nomic-ai/nomic-embed-text-v1.5/blob/main/onnx/model_int8.onnx)
  - File name should be `model_int8.onnx`
- Download Vision Embedding Model: [nomic-embed-vision-v1.5](https://huggingface.co/nomic-ai/nomic-embed-vision-v1.5/blob/main/onnx/model_fp16.onnx)
  - File name should be `model_fp16.onnx`

---
</details>

<details>
<summary>Step 3: Local Project Setup</summary>
Clone this repository on your local machine using:

```bash
git clone https://github.com/varunbhalerao56/digipocket.git
```

Open the project in your preferred IDE (e.g., VSCode, Android Studio).
- Copy the `model_int8.onnx` into `assets/onnx/nomic-embed-text-v1.5` directory.
- Copy the `model_fp16.onnx` into `assets/onnx/nomic-vision-v1.5` directory.

```bash
# Install dependencies
flutter clean && flutter pub get

# iOS specific setup
cd ios && pod install && cd ..
```

---
</details>

### Running/Building the App
```bash
# To run on Andriod device/emulator on DEBUG mode
flutter run --no-enable-impeller 

# To run on Andriod device/emulator on RELEASE mode
flutter run --release --no-enable-impeller

# To build apk for Android
flutter build apk --release

# To run on iOS device/simulator on DEBUG mode (Make sure to run pod install before running for iOS)
flutter run
```

### Citation

This project uses [Nomic Embed](https://arxiv.org/abs/2402.01613).
```bibtex
@misc{nussbaum2024nomic,
      title={Nomic Embed: Training a Reproducible Long Context Text Embedder}, 
      author={Zach Nussbaum and John X. Morris and Brandon Duderstadt and Andriy Mulyar},
      year={2024},
      eprint={2402.01613},
      archivePrefix={arXiv},
      primaryClass={cs.CL}
}
```