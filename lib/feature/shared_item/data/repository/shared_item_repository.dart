import 'dart:io';
import 'dart:math';

import 'package:digipocket/feature/fonnex/fonnex.dart';
import 'package:digipocket/feature/shared_item/shared_item.dart';
import 'package:digipocket/feature/user_topic/user_topic.dart';
import 'package:digipocket/global/helpers/link_extracter.dart';
import 'package:digipocket/global/helpers/tagger.dart';
import 'package:http/http.dart' as http;

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
    final linkExtractor = LinkExtractor();
    int processedCount = 0;

    // Get all active user topics for matching
    final activeTopics = await userTopicRepository.getAllActiveUserTopics();

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

        // 1. Generate embedding based on content type
        List<double>? embedding;

        print('Processing shared item of type: ${item.contentType}');

        switch (item.contentType) {
          case SharedItemType.text:
            if (item.text != null && item.text!.isNotEmpty) {
              embedding = await embeddingRepository.generateTextEmbedding(item.text!, task: NomicTask.searchDocument);
            }
            break;

          case SharedItemType.image:
            if (item.imagePath != null) {
              embedding = await embeddingRepository.generateImageEmbedding(item.imagePath!);
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

              embedding = await embeddingRepository.generateTextEmbedding(
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
            embedding = await embeddingRepository.generateTextEmbedding(item.text!, task: NomicTask.searchDocument);
          }
          break;

        case SharedItemType.image:
          if (item.imagePath != null) {
            embedding = await embeddingRepository.generateImageEmbedding(item.imagePath!);
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

            embedding = await embeddingRepository.generateTextEmbedding(
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

      if (item.userCaption != null || item.userCaption!.isNotEmpty) {
        final captionEmbedding = await embeddingRepository.generateTextEmbedding(
          item.userCaption!,
          task: NomicTask.searchDocument,
        );
        item.userCaptionEmbedding = captionEmbedding;
      }

      return insertSharedItem(item);
    } catch (e) {
      print('Error reprocessing shared item: $e');
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
