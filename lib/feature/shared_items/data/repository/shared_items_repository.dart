import 'package:digipocket/feature/shared_items/shared_items.dart';

class SharedItemsRepository {
  final AppDatabase database;
  final ShareQueueDataSource shareQueueDataSource;

  SharedItemsRepository({
    required this.database,
    required this.shareQueueDataSource,
  });

  /// Process queued items: read from file system and save to database
  Future<int> processQueuedItems() async {
    final queuedItems = await shareQueueDataSource.readQueuedItems();
    int processedCount = 0;

    // Get all active user topics for matching
    final activeTopics = database.getActiveUserTopics();

    for (var data in queuedItems) {
      try {
        // Map queue data to DigipocketItem
        final item = DigipocketItem(
          contentType: _mapContentType(data['type'] as String?),
          createdAt:
              data['timestamp'] as int? ??
              DateTime.now().millisecondsSinceEpoch,
          sourceApp: data['source_app'] as String?,
          text: data['text'] as String?,
          url: data['url'] as String?,
          imagePath: data['image_path'] as String?,
        );

        // TODO: Process item
        // 1. Generate embedding for item
        // 2. Match against activeTopics embeddings (semantic)
        // 3. Use LLM for classification if needed
        // 4. Generate tags & summary
        // 5. Set item.userTags, item.generatedTags, item.summary, item.vectorEmbedding

        database.insertSharedItem(item);
        processedCount++;
      } catch (e) {
        print('Error inserting shared item: $e');
      }
    }

    // Clear queue files after successful processing
    if (processedCount > 0) {
      await shareQueueDataSource.clearAllQueueFiles();
    }

    return processedCount;
  }

  /// Get all shared items from database
  Future<List<DigipocketItem>> getAllSharedItems() async {
    return database.getAllSharedItems();
  }

  /// Delete a shared item
  Future<bool> deleteSharedItem(int id) async {
    return database.deleteSharedItem(id);
  }

  /// Clear all items from database
  Future<int> clearAllItems() async {
    return database.clearAllItems();
  }

  /// Helper: Map string type to enum
  DigipocketItemType _mapContentType(String? type) {
    switch (type?.toLowerCase()) {
      case 'text':
        return DigipocketItemType.text;
      case 'url':
        return DigipocketItemType.url;
      case 'image':
        return DigipocketItemType.image;
      default:
        return DigipocketItemType.text; // default fallback
    }
  }
}
