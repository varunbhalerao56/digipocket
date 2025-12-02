// lib/feature/ocr/ocr_service.dart

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  TextRecognizer? _recognizer;

  /// Initialize the text recognizer
  void initialize() {
    _recognizer = TextRecognizer();
  }

  /// Extract text from an image file
  Future<String?> extractText(String imagePath) async {
    if (_recognizer == null) {
      initialize();
    }

    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _recognizer!.processImage(inputImage);

    if (recognizedText.text.isEmpty) return null;

    return recognizedText.text;
  }

  /// Dispose the recognizer
  Future<void> dispose() async {
    await _recognizer?.close();
    _recognizer = null;
  }
}
