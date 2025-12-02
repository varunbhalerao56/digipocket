class ExportResult {
  final bool success;
  final String? message;
  final int itemCount;
  final int topicCount;
  final int imageCount;
  final String? filePath;

  ExportResult({
    required this.success,
    this.message,
    required this.itemCount,
    required this.topicCount,
    required this.imageCount,
    this.filePath,
  });
}

class ImportResult {
  final bool success;
  final String? message;
  final int itemsAdded;
  final int itemsUpdated;
  final int itemsSkipped;
  final int topicsAdded;

  ImportResult({
    required this.success,
    this.message,
    required this.itemsAdded,
    required this.itemsUpdated,
    required this.itemsSkipped,
    required this.topicsAdded,
  });
}
