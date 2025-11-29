// lib/core/isolates/embedding_isolate.dart

import 'dart:async';

import 'package:digipocket/generated/tokenizer_bridge/frb_generated.dart';
import 'package:flutter/services.dart';
import "package:typed_isolate/typed_isolate.dart";
import 'package:digipocket/feature/fonnex/fonnex.dart';

// ========== Messages ==========

/// Request to initialize the embedding models
class InitializeModelsRequest {
  const InitializeModelsRequest();
}

/// Request to generate text embedding
class GenerateTextEmbeddingRequest {
  final String text;
  final NomicTask task;

  const GenerateTextEmbeddingRequest({required this.text, this.task = NomicTask.searchDocument});
}

/// Request to generate image embedding
class GenerateImageEmbeddingRequest {
  final String imagePath;

  const GenerateImageEmbeddingRequest({required this.imagePath});
}

/// Base class for all requests
abstract class EmbeddingRequest {}

class InitRequest extends EmbeddingRequest {
  final Map<String, Uint8List> modelAssets; // ✅ Pass pre-loaded assets

  InitRequest({required this.modelAssets});
}

class TextEmbeddingRequest extends EmbeddingRequest {
  final String text;
  final NomicTask task;

  TextEmbeddingRequest({required this.text, this.task = NomicTask.searchDocument});
}

class ImageEmbeddingRequest extends EmbeddingRequest {
  final String imagePath;

  ImageEmbeddingRequest({required this.imagePath});
}

// ========== Responses ==========

/// Base class for all responses
abstract class EmbeddingResponse {}

class InitProgressResponse extends EmbeddingResponse {
  final String message;

  InitProgressResponse(this.message);
}

class InitCompleteResponse extends EmbeddingResponse {
  InitCompleteResponse();
}

class EmbeddingResultResponse extends EmbeddingResponse {
  final List<double> embedding;

  EmbeddingResultResponse(this.embedding);
}

class ErrorResponse extends EmbeddingResponse {
  final String error;

  ErrorResponse(this.error);
}

// ========== Isolate Child ==========

class EmbeddingIsolateChild extends IsolateChild<EmbeddingResponse, EmbeddingRequest> {
  FonnexEmbeddingRepository? _embeddingRepository;

  EmbeddingIsolateChild() : super(id: "embedding-worker");

  @override
  Future<void> onSpawn() async {
    print("🔄 Embedding isolate spawning...");

    // ✅ Initialize Rust FFI in the isolate
    try {
      await RustLib.init();
      print("✅ RustLib initialized in isolate");
    } catch (e) {
      print("⚠️ RustLib init warning: $e");
      // Continue anyway - might already be initialized
    }

    sendToParent(InitProgressResponse("Initializing embedding models..."));
  }

  @override
  void onData(EmbeddingRequest request) async {
    try {
      if (request is InitRequest) {
        await _initializeModels(request.modelAssets);
      } else if (request is TextEmbeddingRequest) {
        await _generateTextEmbedding(request);
      } else if (request is ImageEmbeddingRequest) {
        await _generateImageEmbedding(request);
      }
    } catch (e, stackTrace) {
      print("❌ Error in isolate: $e");
      print("Stack trace: $stackTrace");
      sendToParent(ErrorResponse(e.toString()));
    }
  }

  Future<void> _initializeModels(Map<String, Uint8List> modelAssets) async {
    try {
      sendToParent(InitProgressResponse("Loading Nomic embedding models..."));

      _embeddingRepository = FonnexEmbeddingRepository.nomic(preloadedAssets: modelAssets);

      sendToParent(InitProgressResponse("Initializing text model..."));
      await _embeddingRepository!.initializeText();

      sendToParent(InitProgressResponse("Initializing vision model..."));
      await _embeddingRepository!.initializeVision();

      sendToParent(InitCompleteResponse());
      print("✅ Embedding models initialized in isolate");
    } catch (e, stackTrace) {
      print("❌ Full init error: $e");
      print("Stack trace: $stackTrace");
      sendToParent(ErrorResponse("Failed to initialize models: $e"));
    }
  }

  Future<void> _generateTextEmbedding(TextEmbeddingRequest request) async {
    if (_embeddingRepository == null) {
      sendToParent(ErrorResponse("Models not initialized"));
      return;
    }

    try {
      final embedding = await _embeddingRepository!.generateTextEmbedding(request.text, task: request.task);
      sendToParent(EmbeddingResultResponse(embedding));
    } catch (e) {
      sendToParent(ErrorResponse("Text embedding failed: $e"));
    }
  }

  Future<void> _generateImageEmbedding(ImageEmbeddingRequest request) async {
    if (_embeddingRepository == null) {
      sendToParent(ErrorResponse("Models not initialized"));
      return;
    }

    try {
      final embedding = await _embeddingRepository!.generateImageEmbedding(request.imagePath);
      sendToParent(EmbeddingResultResponse(embedding));
    } catch (e) {
      sendToParent(ErrorResponse("Image embedding failed: $e"));
    }
  }
}

class EmbeddingIsolateManager {
  IsolateParent<EmbeddingRequest, EmbeddingResponse>? _parent;
  bool _isInitialized = false;
  final _responseController = StreamController<EmbeddingResponse>.broadcast();

  Stream<EmbeddingResponse> get responseStream => _responseController.stream;

  /// Initialize the isolate and spawn the worker
  Future<void> initialize() async {
    if (_isInitialized) return;

    // ✅ Pre-load all assets in main isolate
    print("📦 Pre-loading model assets...");
    final modelAssets = await _preloadAssets();
    print("✅ Assets loaded: ${modelAssets.keys.length} files");

    _parent = IsolateParent<EmbeddingRequest, EmbeddingResponse>();
    _parent!.init();

    _parent!.stream.listen((response) {
      _responseController.add(response);
    });

    await _parent!.spawn(EmbeddingIsolateChild());

    // ✅ Send pre-loaded assets
    _parent!.sendToChild(
      data: InitRequest(modelAssets: modelAssets),
      id: "embedding-worker",
    );

    await for (final response in responseStream) {
      if (response is InitProgressResponse) {
        print("📦 ${response.message}");
      } else if (response is InitCompleteResponse) {
        _isInitialized = true;
        print("✅ Embedding isolate ready");
        print("----------------------------------------");
        break;
      } else if (response is ErrorResponse) {
        throw Exception("Initialization failed: ${response.error}");
      }
    }
  }

  // ✅ Pre-load all required assets using the actual config paths
  Future<Map<String, Uint8List>> _preloadAssets() async {
    final assets = <String, Uint8List>{};

    // Get the actual config
    final textConfig = EmbeddingModelConfig.nomicEmbedText;
    final visionConfig = EmbeddingModelConfig.nomicEmbedVision;

    // Collect all asset paths
    final allPaths = [
      textConfig.modelPath,
      textConfig.tokenizerPath,
      textConfig.preprocessorPath,
      visionConfig.modelPath,
      visionConfig.preprocessorPath,
    ];

    for (final path in allPaths) {
      try {
        final byteData = await rootBundle.load(path);
        assets[path] = byteData.buffer.asUint8List();
        print("  ✓ Loaded: $path (${assets[path]!.length ~/ (1024 * 1024)} MB)");
      } catch (e) {
        print("  ✗ Failed to load: $path - $e");
        rethrow; // ✅ Don't continue if assets fail to load
      }
    }

    return assets;
  }

  /// Generate text embedding in background
  Future<List<double>> generateTextEmbedding(String text, {NomicTask task = NomicTask.searchDocument}) async {
    if (!_isInitialized || _parent == null) {
      throw Exception("Isolate not initialized");
    }

    final completer = Completer<List<double>>();

    // Listen for response
    final subscription = responseStream.listen((response) {
      if (response is EmbeddingResultResponse) {
        completer.complete(response.embedding);
      } else if (response is ErrorResponse) {
        completer.completeError(Exception(response.error));
      }
    });

    // Send request
    _parent!.sendToChild(
      data: TextEmbeddingRequest(text: text, task: task),
      id: "embedding-worker",
    );

    final result = await completer.future;
    await subscription.cancel();
    return result;
  }

  /// Generate image embedding in background
  Future<List<double>> generateImageEmbedding(String imagePath) async {
    if (!_isInitialized || _parent == null) {
      throw Exception("Isolate not initialized");
    }

    final completer = Completer<List<double>>();

    final subscription = responseStream.listen((response) {
      if (response is EmbeddingResultResponse) {
        completer.complete(response.embedding);
      } else if (response is ErrorResponse) {
        completer.completeError(Exception(response.error));
      }
    });

    _parent!.sendToChild(
      data: ImageEmbeddingRequest(imagePath: imagePath),
      id: "embedding-worker",
    );

    final result = await completer.future;
    await subscription.cancel();
    return result;
  }

  /// Dispose the isolate
  Future<void> dispose() async {
    await _responseController.close();
    await _parent?.dispose();
    _isInitialized = false;
    print("🗑️ Embedding isolate disposed");
  }
}
