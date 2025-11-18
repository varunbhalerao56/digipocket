import 'dart:math';

import 'package:digipocket/feature/fonnex/fonnex.dart';
import 'package:digipocket/feature/shared_item/shared_item.dart';
import 'package:digipocket/feature/user_topic/user_topic.dart';

class SharedItemRepository {
  final SharedItemDb database;
  final FonnexEmbeddingRepository embeddingRepository;
  final UserTopicRepository userTopicRepository;
  final ShareQueueDataSource shareQueueDataSource;

  SharedItemRepository({
    required this.database,
    required this.userTopicRepository,
    required this.embeddingRepository,
    required this.shareQueueDataSource,
  });

  /// Process queued items: read from file system and save to database
  Future<int> processQueuedItems() async {
    final queuedItems = await shareQueueDataSource.readQueuedItems();
    int processedCount = 0;

    // Get all active user topics for matching
    final activeTopics = userTopicRepository.getAllUserTopics();

    for (var data in queuedItems) {
      try {
        // Map queue data to SharedItem
        final item = SharedItem(
          contentType: _mapContentType(data['type'] as String?),
          createdAt: data['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
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

        insertSharedItem(item);
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

  int insertSharedItem(SharedItem item) {
    return database.insertSharedItem(item);
  }

  /// Get all shared items from database
  Future<List<SharedItem>> getAllSharedItems() async {
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

  Future<List<String>> matchTopics(List<double> itemEmbedding, List<UserTopic> activeTopics) async {
    final matchedTopics = <String>[];
    final threshold = 0.7; // adjust based on testing

    for (var topic in activeTopics) {
      final similarity = cosineSimilarity(itemEmbedding, topic.embedding ?? []);

      if (similarity >= threshold) {
        matchedTopics.add(topic.name);
      }
    }

    return matchedTopics;
  }

  double cosineSimilarity(List<double> a, List<double> b) {
    double dotProduct = 0;
    double normA = 0;
    double normB = 0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  /// Helper: Map string type to enum
  SharedItemType _mapContentType(String? type) {
    switch (type?.toLowerCase()) {
      case 'text':
        return SharedItemType.text;
      case 'url':
        return SharedItemType.url;
      case 'image':
        return SharedItemType.image;
      default:
        return SharedItemType.text; // default fallback
    }
  }
}
