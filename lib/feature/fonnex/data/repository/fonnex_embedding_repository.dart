import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:digipocket/feature/fonnex/fonnex.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart';
import 'dart:convert';
import 'package:digipocket/generated/tokenizer_bridge/api.dart';

// ========== EMBEDDING SERVICE ==========

class FonnexEmbeddingRepository {
  final EmbeddingModelConfig textConfig;
  final EmbeddingModelConfig? visionConfig;

  OrtSession? _textSession;
  OrtSession? _visionSession;
  TokenizerHandle? _tokenizerHandle;
  Map<String, dynamic>? _visionPreprocessorConfig;
  bool _isTextInitialized = false;
  bool _isVisionInitialized = false;

  FonnexEmbeddingRepository({required this.textConfig, this.visionConfig});

  // Factory constructors for easy switching
  factory FonnexEmbeddingRepository.jina() => FonnexEmbeddingRepository(
    textConfig: EmbeddingModelConfig.jinaClipV2,
    visionConfig: null, // Same model for both text and vision
  );

  factory FonnexEmbeddingRepository.nomic() => FonnexEmbeddingRepository(
    textConfig: EmbeddingModelConfig.nomicEmbedText,
    visionConfig: EmbeddingModelConfig.nomicEmbedVision,
  );

  Future<void> initializeText() async {
    if (_isTextInitialized) return;

    try {
      print('🔄 Loading ${textConfig.name} model...');

      // Load ONNX model
      final modelBytes = await rootBundle.load(textConfig.modelPath);
      final modelData = modelBytes.buffer.asUint8List(modelBytes.offsetInBytes, modelBytes.lengthInBytes);
      print('📦 Model loaded: ${modelData.length ~/ (1024 * 1024)} MB');

      // Create ONNX session
      final sessionOptions = OrtSessionOptions();
      _textSession = OrtSession.fromBuffer(modelData, sessionOptions);

      // Initialize Rust tokenizer
      await _initializeTokenizer();

      _isTextInitialized = true;
      print('✅ ${textConfig.name} initialized!');
      print('📊 Inputs: ${_textSession?.inputNames}');
      print('📊 Outputs: ${_textSession?.outputNames}');
    } catch (e, stackTrace) {
      print('❌ Error loading text model: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> initializeVision() async {
    if (_isVisionInitialized) return;

    try {
      final config = visionConfig ?? textConfig; // Use text config if same model
      print('🔄 Loading ${config.name} vision model...');

      // Load ONNX model
      final modelBytes = await rootBundle.load(config.modelPath);
      final modelData = modelBytes.buffer.asUint8List(modelBytes.offsetInBytes, modelBytes.lengthInBytes);
      print('📦 Vision model loaded: ${modelData.length ~/ (1024 * 1024)} MB');

      // Create ONNX session (reuse text session if same model)
      if (visionConfig == null) {
        _visionSession = _textSession;
      } else {
        final sessionOptions = OrtSessionOptions();
        _visionSession = OrtSession.fromBuffer(modelData, sessionOptions);
      }

      // Load preprocessor config
      _visionPreprocessorConfig = json.decode(await rootBundle.loadString(config.preprocessorPath));

      _isVisionInitialized = true;
      print('✅ Vision model initialized!');
      print('📊 Vision Inputs: ${_visionSession?.inputNames}');
      print('📊 Vision Outputs: ${_visionSession?.outputNames}');
    } catch (e, stackTrace) {
      print('❌ Error loading vision model: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> _initializeTokenizer() async {
    try {
      final tokenizerFile = await _getAssetFile(textConfig.tokenizerPath);
      _tokenizerHandle = await loadTokenizer(
        path: tokenizerFile.path,
        maxLength: BigInt.from(textConfig.maxTokenLength),
      );
      print('✅ Tokenizer initialized (max_length: ${textConfig.maxTokenLength})');
    } catch (e) {
      print('❌ Error initializing tokenizer: $e');
      rethrow;
    }
  }

  Future<File> _getAssetFile(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/${assetPath.split('/').last}');
    await tempFile.writeAsBytes(byteData.buffer.asUint8List());
    return tempFile;
  }

  /// Generate text embedding with optional task prefix for Nomic
  Future<List<double>> generateTextEmbedding(String text, {NomicTask task = NomicTask.searchDocument}) async {
    if (!_isTextInitialized) await initializeText();
    if (_textSession == null || _tokenizerHandle == null) {
      throw Exception('Text model not initialized');
    }

    try {
      // Add task prefix if required (Nomic models)
      String processedText = text;
      if (textConfig.requiresTaskPrefix) {
        processedText = '${task.prefix}: $text';
      }

      print(
        '🔄 Generating text embedding for: "${processedText.substring(0, processedText.length > 50 ? 50 : processedText.length)}..."',
      );

      // Tokenize
      final tokenData = await tokenize(handle: _tokenizerHandle!, text: processedText);
      final inputIdsInt64 = Int64List.fromList(tokenData.inputIds.map((e) => e.toInt()).toList());
      final attentionMaskInt64 = Int64List.fromList(tokenData.attentionMask.map((e) => e.toInt()).toList());

      // Build inputs based on model requirements
      final inputs = <String, OrtValueTensor>{};

      // Always add input_ids
      inputs['input_ids'] = OrtValueTensor.createTensorWithDataList(inputIdsInt64, [1, textConfig.maxTokenLength]);

      // Add attention_mask if required (Nomic)
      if (textConfig.requiresAttentionMask) {
        inputs['attention_mask'] = OrtValueTensor.createTensorWithDataList(attentionMaskInt64, [
          1,
          textConfig.maxTokenLength,
        ]);
      }

      // Add token_type_ids if required (Nomic - all zeros)
      if (textConfig.requiresTokenTypeIds) {
        final tokenTypeIds = Int64List(textConfig.maxTokenLength);
        inputs['token_type_ids'] = OrtValueTensor.createTensorWithDataList(tokenTypeIds, [
          1,
          textConfig.maxTokenLength,
        ]);
      }

      // Add dummy pixel_values if required (Jina CLIP)
      if (textConfig.requiresPixelValues) {
        // Need to initialize vision config for image size
        if (_visionPreprocessorConfig == null) {
          _visionPreprocessorConfig = json.decode(await rootBundle.loadString(textConfig.preprocessorPath));
        }

        final imageSize = _visionPreprocessorConfig?['size']?['height'] as int? ?? 512;
        final dummyPixels = List<double>.filled(3 * imageSize * imageSize, 0.0);
        inputs['pixel_values'] = OrtValueTensor.createTensorWithDataList(dummyPixels, [1, 3, imageSize, imageSize]);
      }

      // Run inference
      final outputs = await _textSession!.runAsync(OrtRunOptions(), inputs);

      // Extract embedding with attention mask for proper pooling
      final attentionMaskList = tokenData.attentionMask.map((e) => e.toInt()).toList();
      final embedding = _extractEmbedding(outputs, attentionMask: attentionMaskList);

      // Cleanup
      inputs.values.forEach((tensor) => tensor.release());
      outputs?.forEach((value) => value?.release());

      print('✅ Generated ${embedding.length}D text embedding');
      return _truncateEmbedding(embedding, textConfig.truncateDim);
    } catch (e) {
      print('❌ Error generating text embedding: $e');
      rethrow;
    }
  }

  /// Generate image embedding
  Future<List<double>> generateImageEmbedding(String imagePath) async {
    if (!_isVisionInitialized) await initializeVision();
    if (_visionSession == null) throw Exception('Vision model not initialized');

    try {
      print('🔄 Generating image embedding from: $imagePath');

      // Check if it's an asset or file path
      Uint8List imageBytes;
      if (imagePath.startsWith('assets/')) {
        // Load from assets
        final byteData = await rootBundle.load(imagePath);
        imageBytes = byteData.buffer.asUint8List();
      } else {
        // Load from file system
        imageBytes = await File(imagePath).readAsBytes();
      }

      final image = img.decodeImage(imageBytes);
      if (image == null) throw Exception('Failed to decode image');

      // Get image size from config (Nomic vision uses 224x224, Jina uses 512x512)
      final imageSize = _visionPreprocessorConfig?['size']?['height'] ?? 224;
      final resized = img.copyResize(image, width: imageSize, height: imageSize);
      final pixels = _preprocessImage(resized);

      final pixelValues = OrtValueTensor.createTensorWithDataList(pixels, [1, 3, imageSize, imageSize]);

      final inputs = {'pixel_values': pixelValues};
      final outputs = await _visionSession!.runAsync(OrtRunOptions(), inputs);

      // Extract embedding without attention mask for vision
      final embedding = _extractEmbedding(outputs);

      pixelValues.release();
      outputs?.forEach((value) => value?.release());

      print('✅ Generated ${embedding.length}D image embedding');

      // For vision config, don't truncate (already correct size)
      if (visionConfig != null) {
        return embedding;
      }
      return _truncateEmbedding(embedding, textConfig.truncateDim);
    } catch (e) {
      print('❌ Error generating image embedding: $e');
      rethrow;
    }
  }

  // ========== Helper Methods ==========

  Float32List _preprocessImage(img.Image image) {
    final pixels = <double>[];
    final mean = _visionPreprocessorConfig?['image_mean'] ?? [0.48145466, 0.4578275, 0.40821073];
    final std = _visionPreprocessorConfig?['image_std'] ?? [0.26862954, 0.26130258, 0.27577711];

    for (var c = 0; c < 3; c++) {
      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          double value;
          if (c == 0)
            value = pixel.r / 255.0;
          else if (c == 1)
            value = pixel.g / 255.0;
          else
            value = pixel.b / 255.0;
          pixels.add((value - mean[c]) / std[c]);
        }
      }
    }

    // Convert to Float32List
    return Float32List.fromList(pixels);
  }

  /// Extract embedding from model output with optional masked mean pooling
  List<double> _extractEmbedding(List<OrtValue?>? outputs, {List<int>? attentionMask}) {
    if (outputs == null || outputs.isEmpty) {
      throw Exception('No outputs from model');
    }

    final output = outputs.first;
    if (output == null) throw Exception('Output is null');

    final tensor = output as OrtValueTensor;
    final data = tensor.value;

    if (data is List<List<List<double>>>) {
      // Nomic format: [batch_size, sequence_length, embedding_dim]
      final batchData = data[0]; // Get first batch
      final embeddingDim = batchData[0].length;
      final sequenceLength = batchData.length;

      // Use masked mean pooling if attention mask is provided
      if (attentionMask != null && attentionMask.isNotEmpty) {
        final sumVector = List<double>.filled(embeddingDim, 0.0);
        int validTokenCount = 0;

        // Only average over actual tokens (mask == 1), not padding (mask == 0)
        for (var i = 0; i < sequenceLength && i < attentionMask.length; i++) {
          if (attentionMask[i] == 1) {
            for (var d = 0; d < embeddingDim; d++) {
              sumVector[d] += batchData[i][d];
            }
            validTokenCount++;
          }
        }

        if (validTokenCount == 0) {
          throw Exception('No valid tokens found in attention mask');
        }

        // Compute mean
        final meanEmbedding = sumVector.map((val) => val / validTokenCount).toList();

        // L2 normalize (critical for Nomic embeddings!)
        return _normalizeEmbedding(meanEmbedding);
      }

      // Fallback: simple mean pooling over all tokens (for vision or when mask not provided)
      final meanEmbedding = List<double>.filled(embeddingDim, 0.0);
      for (var token in batchData) {
        for (var i = 0; i < embeddingDim; i++) {
          meanEmbedding[i] += token[i];
        }
      }
      for (var i = 0; i < embeddingDim; i++) {
        meanEmbedding[i] /= sequenceLength;
      }

      // L2 normalize
      return _normalizeEmbedding(meanEmbedding);
    } else if (data is List<List<double>>) {
      // Jina format: [batch_size, embedding_dim]
      // Already normalized by the model
      return data[0];
    } else if (data is List<double>) {
      return data;
    } else {
      throw Exception('Unexpected output format: ${data.runtimeType}');
    }
  }

  /// L2 normalize embedding vector
  List<double> _normalizeEmbedding(List<double> embedding) {
    // Calculate L2 norm (Euclidean length)
    final norm = math.sqrt(embedding.fold<double>(0.0, (sum, val) => sum + val * val));

    // Avoid division by zero
    if (norm == 0 || norm.isNaN) {
      print('⚠️ Warning: Zero or NaN norm detected, returning unnormalized embedding');
      return embedding;
    }

    // Normalize: divide each component by the norm
    return embedding.map((val) => val / norm).toList();
  }

  List<double> _truncateEmbedding(List<double> embedding, int? targetDim) {
    if (targetDim == null || targetDim >= embedding.length) {
      return embedding;
    }
    return embedding.sublist(0, targetDim);
  }

  void dispose() {
    _textSession?.release();
    _textSession = null;

    // Only release vision session if it's a separate model
    if (visionConfig != null) {
      _visionSession?.release();
    }
    _visionSession = null;

    _tokenizerHandle = null;
    _isTextInitialized = false;
    _isVisionInitialized = false;
    print('🗑️ Models disposed');
  }
}
