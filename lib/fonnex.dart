import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';

class EmbeddingService {
  // Correct asset path matching your pubspec.yaml
  static const String assetModelPath = 'assets/onnx/model_q4.onnx';

  OrtSession? _session;
  bool isInitialized = false;

  Future<void> initialize() async {
    try {
      print('🔄 Loading ONNX model from assets (no copy)...');

      // Load model directly from assets as bytes
      final modelBytes = await rootBundle.load(assetModelPath);
      final modelData = modelBytes.buffer.asUint8List(modelBytes.offsetInBytes, modelBytes.lengthInBytes);

      print('📦 Model loaded into memory: ${modelData.length ~/ (1024 * 1024)} MB');

      // Create session from bytes (no file needed!)
      final sessionOptions = OrtSessionOptions();
      _session = OrtSession.fromBuffer(modelData, sessionOptions);

      isInitialized = true;
      print('✅ ONNX model initialized successfully!');

      // Print model info
      print('📊 Model inputs: ${_session?.inputNames}');
      print('📊 Model outputs: ${_session?.outputNames}');
    } catch (e, stackTrace) {
      print('❌ Error loading ONNX model: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<double>> generateTextEmbedding(String text) async {
    if (!isInitialized) {
      await initialize();
    }

    if (_session == null) {
      throw Exception('Model not initialized');
    }

    try {
      print('🔄 Generating embedding for: "$text"');

      // TODO: Tokenize text and run inference
      print('⚠️ Tokenization not implemented yet');
      return [];
    } catch (e) {
      print('❌ Error generating embedding: $e');
      rethrow;
    }
  }

  void dispose() {
    _session?.release();
    _session = null;
    isInitialized = false;
    print('🗑️ Model session disposed');
  }
}
