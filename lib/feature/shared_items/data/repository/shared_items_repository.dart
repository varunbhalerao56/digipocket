import 'package:digipocket/feature/shared_items/shared_items.dart';
import 'package:drift/drift.dart' as drift;

class SharedItemsRepository {
  final AppDatabase database;
  final ShareQueueDataSource shareQueueDataSource;

  SharedItemsRepository({required this.database, required this.shareQueueDataSource});

  /// Process queued items: read from file system and save to database
  Future<int> processQueuedItems() async {
    final queuedItems = await shareQueueDataSource.readQueuedItems();
    int processedCount = 0;

    for (var data in queuedItems) {
      try {
        await database.insertSharedItem(
          SharedItemsCompanion(
            type: drift.Value(data['type'] as String? ?? 'unknown'),
            content: drift.Value(data['text'] as String?), // Map 'text' from JSON to 'content' in DB
            url: drift.Value(data['url'] as String?),
            imagePath: drift.Value(data['image_path'] as String?),
            sourceApp: drift.Value(data['source_app'] as String? ?? 'unknown'),
            timestamp: drift.Value(data['timestamp'] as int),
          ),
        );
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
  Future<List<SharedItem>> getAllSharedItems() {
    return database.getAllSharedItems();
  }

  /// Delete a shared item
  Future<void> deleteSharedItem(int id) {
    return database.deleteSharedItem(id);
  }

  /// Clear all items from database
  Future<void> clearAllItems() {
    return database.clearAllItems();
  }
}
