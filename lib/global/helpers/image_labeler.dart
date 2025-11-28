// lib/feature/image_labeling/image_labeling_service.dart

import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class ImageLabelingService {
  ImageLabeler? _labeler;

  /// Initialize with optional custom confidence threshold
  void initialize({double confidenceThreshold = 0.5}) {
    final options = ImageLabelerOptions(confidenceThreshold: confidenceThreshold);
    _labeler = ImageLabeler(options: options);
  }

  /// Get labels for an image file
  Future<List<ImageLabelResult>> getLabels(String imagePath) async {
    if (_labeler == null) {
      initialize();
    }

    final inputImage = InputImage.fromFilePath(imagePath);
    final labels = await _labeler!.processImage(inputImage);

    return labels
        .map((label) => ImageLabelResult(text: label.label, confidence: label.confidence, index: label.index))
        .toList();
  }

  /// Convenience: get labels as joined string for embedding
  Future<String?> getLabelsAsText(String imagePath, {int maxLabels = 5}) async {
    final labels = await getLabels(imagePath);

    if (labels.isEmpty) return null;

    // Take top N labels, sorted by confidence (already sorted by ML Kit)
    final topLabels = labels.take(maxLabels).map((l) => l.text).toList();

    return topLabels.join(' ');
  }

  /// Dispose the labeler
  Future<void> dispose() async {
    await _labeler?.close();
    _labeler = null;
  }
}

/// Simple result class
class ImageLabelResult {
  final String text;
  final double confidence;
  final int index;

  ImageLabelResult({required this.text, required this.confidence, required this.index});

  @override
  String toString() => '$text (${(confidence * 100).toStringAsFixed(1)}%)';
}
