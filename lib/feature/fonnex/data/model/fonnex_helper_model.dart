// ========== EMBEDDING CONFIGS ==========

class EmbeddingModelConfig {
  final String name;
  final String modelPath;
  final String tokenizerPath;
  final String tokenizerConfigPath;
  final String preprocessorPath;
  final int embeddingDimensions;
  final int maxTokenLength;
  final int truncateDim;
  final bool requiresTaskPrefix;
  final bool requiresPixelValues;
  final bool requiresTokenTypeIds;
  final bool requiresAttentionMask;

  const EmbeddingModelConfig({
    required this.name,
    required this.modelPath,
    required this.tokenizerPath,
    required this.tokenizerConfigPath,
    required this.preprocessorPath,
    required this.embeddingDimensions,
    required this.maxTokenLength,
    required this.truncateDim,
    this.requiresTaskPrefix = false,
    this.requiresPixelValues = false,
    this.requiresTokenTypeIds = false,
    this.requiresAttentionMask = false,
  });

  static const jinaClipV2 = EmbeddingModelConfig(
    name: 'jina-clip-v2',
    modelPath: 'assets/onnx/jina-clip-v2/model_q4f16.onnx',
    tokenizerPath: 'assets/onnx/jina-clip-v2/tokenizer.json',
    tokenizerConfigPath: 'assets/onnx/jina-clip-v2/tokenizer_config.json',
    preprocessorPath: 'assets/onnx/jina-clip-v2/preprocessor_config.json',
    embeddingDimensions: 1024,
    maxTokenLength: 77,
    truncateDim: 768,
    requiresPixelValues: true,
    requiresAttentionMask: false,
  );

  static const nomicEmbedText = EmbeddingModelConfig(
    name: 'nomic-embed-text-v1.5',
    modelPath: 'assets/onnx/nomic-embed-text-v1.5/model_int8.onnx',
    tokenizerPath: 'assets/onnx/nomic-embed-text-v1.5/tokenizer.json',
    tokenizerConfigPath: 'assets/onnx/nomic-embed-text-v1.5/tokenizer_config.json',
    preprocessorPath: 'assets/onnx/nomic-embed-text-v1.5/preprocessor_config.json',
    embeddingDimensions: 768,
    maxTokenLength: 512,
    truncateDim: 768,
    requiresTaskPrefix: true,
    requiresTokenTypeIds: true,
    requiresAttentionMask: true,
  );

  static const nomicEmbedVision = EmbeddingModelConfig(
    name: 'nomic-embed-vision-v1.5',
    modelPath: 'assets/onnx/nomic-vision-v1.5/model_fp16.onnx',
    tokenizerPath: '',
    tokenizerConfigPath: '',
    preprocessorPath: 'assets/onnx/nomic-vision-v1.5/preprocessor_config.json',
    embeddingDimensions: 768,
    maxTokenLength: 0,
    truncateDim: 768,
    requiresTaskPrefix: false,
    requiresPixelValues: true,
    requiresTokenTypeIds: false,
    requiresAttentionMask: false,
  );
}

// ========== TASK PREFIXES FOR NOMIC ==========

enum NomicTask {
  searchDocument('search_document'),
  searchQuery('search_query'),
  clustering('clustering'),
  classification('classification');

  final String prefix;
  const NomicTask(this.prefix);
}
