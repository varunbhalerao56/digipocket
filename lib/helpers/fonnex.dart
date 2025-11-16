import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart';
import 'dart:convert';

class EmbeddingService {
  static const String modelPath = 'assets/onnx/jina-clip-v2/model_q4f16.onnx';
  static const String configPath = 'assets/onnx/jina-clip-v2/config.json';
  static const String tokenizerPath = 'assets/onnx/jina-clip-v2/tokenizer.json';
  static const String tokenizerConfigPath = 'assets/onnx/jina-clip-v2/tokenizer_config.json';
  static const String preprocessorPath = 'assets/onnx/jina-clip-v2/preprocessor_config.json';

  static const int embeddingDimensions = 1024; // Jina CLIP v2 full dimensions
  static const int truncateDim = 768; // Can truncate to 768 for compatibility

  OrtSession? _session;
  Map<String, dynamic>? _tokenizerConfig;
  Map<String, dynamic>? _preprocessorConfig;
  bool isInitialized = false;

  Future<void> initialize() async {
    try {
      print('🔄 Loading Jina CLIP v2 model...');

      // Load model
      final modelBytes = await rootBundle.load(modelPath);
      final modelData = modelBytes.buffer.asUint8List(modelBytes.offsetInBytes, modelBytes.lengthInBytes);
      print('📦 Model loaded: ${modelData.length ~/ (1024 * 1024)} MB');

      // Load configs
      _tokenizerConfig = json.decode(await rootBundle.loadString(tokenizerConfigPath));
      _preprocessorConfig = json.decode(await rootBundle.loadString(preprocessorPath));

      // Create ONNX session
      final sessionOptions = OrtSessionOptions();
      _session = OrtSession.fromBuffer(modelData, sessionOptions);

      isInitialized = true;
      print('✅ Jina CLIP v2 initialized!');
      print('📊 Inputs: ${_session?.inputNames}');
      print('📊 Outputs: ${_session?.outputNames}');
    } catch (e, stackTrace) {
      print('❌ Error loading model: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Generate text embedding (for text, URLs, OCR results)
  Future<List<double>> generateTextEmbedding(String text) async {
    if (!isInitialized) await initialize();
    if (_session == null) throw Exception('Model not initialized');

    try {
      print('🔄 Generating text embedding for: "${text.substring(0, text.length > 50 ? 50 : text.length)}..."');

      // Tokenize text (simplified - you'll need proper tokenizer)
      final tokens = _tokenizeText(text);

      // Create input tensor [batch_size, sequence_length]
      final inputIds = OrtValueTensor.createTensorWithDataList([tokens], [1, tokens.length]);

      // Run inference
      final inputs = {'input_ids': inputIds};
      final outputs = await _session!.runAsync(OrtRunOptions(), inputs);

      // Extract embedding
      final embedding = _extractEmbedding(outputs);

      // Cleanup
      inputIds.release();
      outputs?.forEach((value) => value?.release());

      print('✅ Generated ${embedding.length}D text embedding');
      return _truncateEmbedding(embedding, truncateDim);
    } catch (e) {
      print('❌ Error generating text embedding: $e');
      rethrow;
    }
  }

  /// Generate image embedding
  Future<List<double>> generateImageEmbedding(String imagePath) async {
    if (!isInitialized) await initialize();
    if (_session == null) throw Exception('Model not initialized');

    try {
      print('🔄 Generating image embedding from: $imagePath');

      // Load and preprocess image
      final imageBytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) throw Exception('Failed to decode image');

      // Get image size from preprocessor config (default 512x512 for Jina CLIP v2)
      final imageSize = _preprocessorConfig?['size']?['height'] ?? 512;

      // Resize image
      final resized = img.copyResize(image, width: imageSize, height: imageSize);

      // Convert to normalized float array
      final pixels = _preprocessImage(resized);

      // Create input tensor [batch, channels, height, width]
      final pixelValues = OrtValueTensor.createTensorWithDataList(pixels, [1, 3, imageSize, imageSize]);

      // Run inference
      final inputs = {'pixel_values': pixelValues};
      final outputs = await _session!.runAsync(OrtRunOptions(), inputs);

      // Extract embedding
      final embedding = _extractEmbedding(outputs);

      // Cleanup
      pixelValues.release();
      outputs?.forEach((value) => value?.release());

      print('✅ Generated ${embedding.length}D image embedding');
      return _truncateEmbedding(embedding, truncateDim);
    } catch (e) {
      print('❌ Error generating image embedding: $e');
      rethrow;
    }
  }

  /// Generate embedding for URL content
  Future<List<double>> generateUrlEmbedding(String url, String? extractedText) async {
    final textToEmbed = extractedText ?? url;
    return generateTextEmbedding(textToEmbed);
  }

  // ========== Helper Methods ==========

  /// Simple tokenization (PLACEHOLDER - needs proper implementation)
  List<int> _tokenizeText(String text) {
    // TODO: Implement proper tokenization using tokenizer.json
    // This is a placeholder that will NOT work correctly
    // You need to implement BPE tokenization or use a tokenizer package

    final maxLength = _tokenizerConfig?['model_max_length'] ?? 512;
    final words = text.toLowerCase().split(RegExp(r'\s+'));

    // Very crude approximation - replace with proper tokenizer
    return words.take(maxLength).map((w) => w.hashCode % 30000).toList();
  }

  /// Preprocess image to normalized float array
  List<double> _preprocessImage(img.Image image) {
    final pixels = <double>[];

    // Get normalization values from preprocessor config
    final mean = _preprocessorConfig?['image_mean'] ?? [0.48145466, 0.4578275, 0.40821073];
    final std = _preprocessorConfig?['image_std'] ?? [0.26862954, 0.26130258, 0.27577711];

    // Convert to CHW format (channels, height, width)
    for (var c = 0; c < 3; c++) {
      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          double value;

          if (c == 0)
            value = pixel.r / 255.0; // Red
          else if (c == 1)
            value = pixel.g / 255.0; // Green
          else
            value = pixel.b / 255.0; // Blue

          // Normalize
          pixels.add((value - mean[c]) / std[c]);
        }
      }
    }

    return pixels;
  }

  /// Extract embedding from model output
  List<double> _extractEmbedding(List<OrtValue?>? outputs) {
    if (outputs == null || outputs.isEmpty) {
      throw Exception('No outputs from model');
    }

    // Get output (Jina CLIP returns 'last_hidden_state' or 'embeddings')
    final output = outputs.first;

    if (output == null) throw Exception('Output is null');

    // Extract data
    final tensor = output as OrtValueTensor;
    final data = tensor.value;

    // Handle different output formats
    if (data is List<List<double>>) {
      return data[0]; // Return first batch
    } else if (data is List<double>) {
      return data;
    } else {
      throw Exception('Unexpected output format: ${data.runtimeType}');
    }
  }

  /// Truncate embedding to specified dimensions (Matryoshka)
  List<double> _truncateEmbedding(List<double> embedding, int? targetDim) {
    if (targetDim == null || targetDim >= embedding.length) {
      return embedding;
    }
    return embedding.sublist(0, targetDim);
  }

  void dispose() {
    _session?.release();
    _session = null;
    isInitialized = false;
    print('🗑️ Model disposed');
  }
}
