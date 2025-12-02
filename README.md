[![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=fff)](#) [![ONNX](https://img.shields.io/badge/ONNX-005CED?logo=ONNX&logoColor=white)](#) [![iOS](https://img.shields.io/badge/iOS-000000?&logo=apple&logoColor=white)](#) [![Android](https://img.shields.io/badge/Android-3DDC84?logo=android&logoColor=white)](#) [![Rust](https://img.shields.io/badge/Rust-%23000000.svg?e&logo=rust&logoColor=white)](#)

## Chuck'it (v1.0.16+17)

Chuck your data into baskets and worry less about sorting it!

### Features

Chuck'it is all about being able to bookmark items in the most convenient way possible and is built upon four foundations:
- Bookmark without breaking the flow of your current app
- Auto-tag shared items while still providing manual tagging
- Fully offline, the data you share is yours and no one elses
- Good search capabilities to easily find items shared in the past

### Getting Started

Platforms Supported:
- iOS
- Android

If you are looking to try the app out you can download it from the following links:
- [iOS](https://testflight.apple.com/join/EZ7BMmKW) (TestFlight): Email address is required to join the beta testing.
- [Android](https://drive.google.com/drive/folders/1EWhWk3mepMPJ372suxfbAbhTRLgwhlJl?usp=drive_link) or download the latest release from the repository (APK): Direct APK download, no email required.

If you want to set up the project locally, follow the instructions below

### Prerequisites

Install Flutter SDK from [flutter.dev](https://flutter.dev/docs/get-started/install). This project is built and tested on Flutter version:

``` 
Flutter 3.35.5 • channel stable • https://github.com/flutter/flutter.git
Framework • revision ac4e799d23 (9 weeks ago) • 2025-09-26 12:05:09 -0700
Engine • hash 0274ead41f6265309f36e9d74bc8c559becd5345 (revision
d3d45dcf25) (2 months ago) • 2025-09-26 16:45:18.000Z
Tools • Dart 3.9.2 • DevTools 2.48.0
```

**Download Embedding Models**
- Download Text Embedding Model: [nomic-embed-text-v1.5](https://huggingface.co/nomic-ai/nomic-embed-text-v1.5/blob/main/onnx/model_int8.onnx)
  - File name should be `model_int8.onnx`
- Download Vision Embedding Model: [nomic-embed-vision-v1.5](https://huggingface.co/nomic-ai/nomic-embed-vision-v1.5/blob/main/onnx/model_fp16.onnx)
  - File name should be `model_fp16.onnx`

### Setup

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
```

### Running/Building the App
```bash
# To run on Andriod device/emulator on DEBUG mode
flutter run --no-enable-impeller 

# To run on Andriod device/emulator on RELEASE mode
flutter run --release --no-enable-impeller

# To build apk for Andriod
flutter build apk --release

# To run on iOS device/simulator on DEBUG mode
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