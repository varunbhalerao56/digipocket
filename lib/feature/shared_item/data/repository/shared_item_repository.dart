import 'dart:math';

import 'package:digipocket/feature/fonnex/fonnex.dart';
import 'package:digipocket/feature/shared_item/data/isolates/shared_item_isolate.dart';
import 'package:digipocket/feature/shared_item/shared_item.dart';
import 'package:digipocket/feature/user_topic/user_topic.dart';
import 'package:digipocket/global/helpers/link_extracter.dart';
import 'package:digipocket/global/helpers/tagger.dart';

class SharedItemRepository {
  final SharedItemDb database;
  final EmbeddingIsolateManager embeddingIsolateManager;
  final UserTopicRepository userTopicRepository;
  final ShareQueueDataSource shareQueueDataSource;

  SharedItemRepository({
    required this.database,
    required this.userTopicRepository,
    required this.embeddingIsolateManager,
    required this.shareQueueDataSource,
  });

  Future<List<SharedItem>> getQueuedItems() async {
    final queuedItems = await shareQueueDataSource.readQueuedItems();
    final items = <SharedItem>[];

    for (var data in queuedItems) {
      try {
        final item = SharedItem(
          contentType: _mapContentType(data['type'] as String?),
          createdAt: data['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
          sourceApp: data['source_app'] as String?,
          text: data['text'] as String?,
          url: data['url'] as String?,
          imagePath: data['image_path'] as String?,
        );
        items.add(item);
      } catch (e) {
        print('Error reading queued item: $e');
      }
    }

    return items;
  }

  /// Save a processed item to the database
  Future<void> saveProcessedItem(SharedItem item) async {
    try {
      insertSharedItem(item);
    } catch (e) {
      print('Error saving processed item: $e');
      rethrow;
    }
  }

  Future<int> getQueuedItemCount() async {
    return await shareQueueDataSource.getQueuedItemCount();
  }

  /// Process queued items: read from file system and save to database
  Future<int> processQueuedItems() async {
    final queuedItems = await shareQueueDataSource.readQueuedItems();
    final linkExtractor = LinkExtractor();
    int processedCount = 0;

    // Get all active user topics for matching
    final activeTopics = await userTopicRepository.getAllActiveUserTopics();

    for (var data in queuedItems) {
      try {
        final text = data['text'] as String?;

        // Map queue data to SharedItem
        final item = SharedItem(
          contentType: _mapContentType(data['type'] as String?),
          createdAt: data['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
          sourceApp: data['source_app'] as String?,
          text: text?.trim(),
          url: data['url'] as String?,
          imagePath: data['image_path'] as String?,
        );

        // 1. Generate embedding based on content type
        List<double>? embedding;

        print('Processing shared item of type: ${item.contentType}');

        switch (item.contentType) {
          case SharedItemType.text:
            if (item.text != null && item.text!.isNotEmpty) {
              embedding = await embeddingIsolateManager.generateTextEmbedding(
                item.text!,
                task: NomicTask.searchDocument,
              );
            }
            break;

          case SharedItemType.image:
            if (item.imagePath != null) {
              embedding = await embeddingIsolateManager.generateImageEmbedding(item.imagePath!);
            }
            break;

          case SharedItemType.url:
            if (item.url != null) {
              LinkMetadata? linkData;

              try {
                linkData = await linkExtractor.extractMetadata(item.url!);
              } catch (e) {
                print('Error extracting link metadata: $e');
              }

              embedding = await embeddingIsolateManager.generateTextEmbedding(
                linkData?.combinedText ?? item.url!,
                task: NomicTask.searchDocument,
              );

              if (linkData != null && linkData.hasTitle) {
                item.urlTitle = linkData.title;
              }
              if (linkData != null && linkData.hasDescription) {
                item.urlDescription = linkData.description;
              }
            }
            break;
        }

        // Store the embedding
        if (embedding != null) {
          item.vectorEmbedding = embedding;

          item.userTags = await matchTopics(embedding, activeTopics, item.contentType);
        }

        insertSharedItem(item);
        processedCount++;
      } catch (e) {
        print('Error processing shared item: $e');
      }
    }

    // Clear queue after processing
    if (processedCount > 0) {
      await shareQueueDataSource.clearAllQueueFiles();
    }

    return processedCount;
  }

  Future<int> reprocessExistingItem(SharedItem item) async {
    try {
      // 1. Generate embedding based on content type
      List<double>? embedding;
      final linkExtractor = LinkExtractor();

      switch (item.contentType) {
        case SharedItemType.text:
          if (item.text != null && item.text!.isNotEmpty) {
            embedding = await embeddingIsolateManager.generateTextEmbedding(item.text!, task: NomicTask.searchDocument);
          }
          break;

        case SharedItemType.image:
          if (item.imagePath != null) {
            embedding = await embeddingIsolateManager.generateImageEmbedding(item.imagePath!);
          }
          break;

        case SharedItemType.url:
          if (item.url != null) {
            LinkMetadata? linkData;

            try {
              linkData = await linkExtractor.extractMetadata(item.url!);
            } catch (e) {
              print('Error extracting link metadata: $e');
            }

            embedding = await embeddingIsolateManager.generateTextEmbedding(
              linkData?.combinedText ?? item.url!,
              task: NomicTask.searchDocument,
            );

            if (linkData != null && linkData.hasTitle) {
              item.urlTitle = linkData.title;
            }
            if (linkData != null && linkData.hasDescription) {
              item.urlDescription = linkData.description;
            }
          }
          break;
      }

      // Store the embedding
      if (embedding != null) {
        item.vectorEmbedding = embedding;
      }

      if (item.userCaption != null && item.userCaption!.isNotEmpty) {
        final captionEmbedding = await embeddingIsolateManager.generateTextEmbedding(
          item.userCaption!,
          task: NomicTask.searchDocument,
        );
        item.userCaptionEmbedding = captionEmbedding;
      }

      return insertSharedItem(item);
    } catch (e) {
      rethrow;
    }
  }

  int insertSharedItem(SharedItem item) {
    return database.insertSharedItem(item);
  }

  /// Get all shared items from database
  Future<List<SharedItem>> getAllSharedItems() async {
    return database.getAllSharedItems();
  }

  // Get all shared items by type
  Future<List<SharedItem>> getSharedItemsByType(SharedItemType type) async {
    return database.getSharedItemsByType(type);
  }

  Future<List<SharedItem>> searchItems({
    List<double>? queryEmbedding,
    String? searchQuery,
    SharedItemType? typeFilter,
    String? userTopic,
  }) async {
    return await database.searchItems(
      queryEmbedding: queryEmbedding,
      keyword: searchQuery,
      itemType: typeFilter,
      userTopic: userTopic,
    );
  }

  /// Delete a shared item
  Future<bool> deleteSharedItem(int id) async {
    return database.deleteSharedItem(id);
  }

  /// Clear all items from database
  Future<int> clearAllItems() async {
    return database.clearAllItems();
  }

  Future<List<String>> matchTopics(
    List<double> itemEmbedding,
    List<UserTopic> activeTopics,
    SharedItemType itemType,
  ) async {
    final matcher = TopicMatcher();

    final result = await matcher.matchTopics(itemEmbedding, activeTopics, itemType);

    return result.autoTags;
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
