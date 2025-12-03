import 'package:digipocket/feature/fonnex/fonnex.dart';
import 'package:digipocket/feature/setting/data/repository/shared_pref_repository.dart';
import 'package:digipocket/feature/shared_item/shared_item.dart';
import 'package:digipocket/feature/user_topic/user_topic.dart';
import 'package:digipocket/global/services/image_downloader_service.dart';
import 'package:digipocket/global/services/image_labeler_service.dart';
import 'package:digipocket/global/services/image_ocr_service.dart';
import 'package:digipocket/global/services/link_extracter_service.dart';
import 'package:digipocket/global/services/match_basket_service.dart';
import 'package:http/http.dart' as http;

class SharedItemRepository {
  final SharedItemDb database;
  final EmbeddingIsolateManager embeddingIsolateManager;
  final UserTopicRepository userTopicRepository;
  final ShareQueueDataSource shareQueueDataSource;
  final SharedPrefRepository sharedPrefRepository;

  SharedItemRepository({
    required this.database,
    required this.userTopicRepository,
    required this.embeddingIsolateManager,
    required this.shareQueueDataSource,
    required this.sharedPrefRepository,
  });

  Future<int> getQueuedItemCount() async {
    return await shareQueueDataSource.getQueuedItemCount();
  }

  /// Process queued items: read from file system and save to database
  Future<int> processQueuedItems() async {
    final queuedItems = await shareQueueDataSource.readQueuedItems();
    final linkExtractor = LinkExtractor();
    final imageLabeler = ImageLabelingService();
    final ocrService = OcrService();

    final basePath = await shareQueueDataSource.getAppGroupPath();
    final imageDownloader = ImageDownloader(basePath: basePath);

    imageLabeler.initialize();
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
        List<double>? secondaryEmbedding;
        String compareText = '';
        String? labelText;
        String? ocrText;

        print('Processing shared item of type: ${item.contentType}');

        if (item.contentType == SharedItemType.text && _trimAndCheckIfIsURL(item.text)) {
          print('Detected URL in text, updating content type to URL');
          item.contentType = SharedItemType.url;
          item.url = item.text!.trim();
          item.text = null;
          print('Processing shared item of type: ${item.contentType}');
        }

        if (item.url != null && _trimAndCheckIfIsURL(item.url)) {
          final isImageLink = await _checkIfLinkEndsInImage(item.url!);

          if (isImageLink) {
            print('Detected image URL, updating content type to Image');
            item.imagePath = await imageDownloader.downloadAndSave(item.url!);
            item.contentType = SharedItemType.image;
            item.url = null;
          }
        }

        switch (item.contentType) {
          case SharedItemType.text:
            if (item.text != null && item.text!.isNotEmpty) {
              embedding = await embeddingIsolateManager.generateTextEmbedding(
                item.text!,
                task: NomicTask.searchDocument,
              );
              compareText = item.text!;
            }
            break;

          case SharedItemType.image:
            if (item.imagePath != null) {
              labelText = await imageLabeler.getLabelsAsText(item.imagePath!, maxLabels: 5);
              ocrText = await ocrService.extractText(item.imagePath!);

              print('Image labels: $labelText');

              print('OCR text: $ocrText');

              final combinedText = [
                if (labelText != null && labelText.isNotEmpty) labelText,
                if (ocrText != null && ocrText.isNotEmpty) ocrText,
              ].whereType<String>().join(' | ');

              compareText = combinedText;

              // 2. Embed the label text for topic matching
              if (combinedText.isNotEmpty) {
                try {
                  secondaryEmbedding = await embeddingIsolateManager.generateTextEmbedding(
                    combinedText,
                    task: NomicTask.searchDocument,
                  );
                } catch (e) {
                  print('Error printing image labels: $e');
                }
              }

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

              compareText = linkData?.combinedText ?? item.url!;

              embedding = await embeddingIsolateManager.generateTextEmbedding(
                linkData?.combinedText ?? item.url!,
                task: NomicTask.searchDocument,
              );

              if (linkData != null && linkData.imageUrl != null) {
                item.urlThumbnailPath = await imageDownloader.downloadAndSave(linkData.imageUrl!);
              }

              if (linkData != null && linkData.hasTitle) {
                item.urlTitle = linkData.title;
              }
              if (linkData != null && linkData.hasDescription) {
                item.urlDescription = linkData.description;
              }

              if (linkData?.imageUrl == '') {
                item.urlThumbnailPath = null;
              }
            }
            break;
        }

        // Store the embedding
        if (embedding != null) {
          item.vectorEmbedding = embedding;

          item.userCaptionEmbedding = secondaryEmbedding;
          item.userCaption = labelText;
          item.ocrText = ocrText;

          item.userTags = await matchTopics(
            embedding,
            activeTopics,
            item,
            compareText,
            secondaryEmbedding: secondaryEmbedding,
          );
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
              if (item.urlTitle == null) {
                linkData = await linkExtractor.extractMetadata(item.url!);
              }
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
        if (item.ocrText != null && item.ocrText!.isNotEmpty) {
          item.userCaption = '${item.userCaption!} | ${item.ocrText!}';
        }

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

  Future<List<SharedItem>> searchItems({
    List<double>? queryEmbedding,
    String? searchQuery,
    SharedItemType? typeFilter,
    String? userTopic,
    bool? keywordSearch,
  }) async {
    return await database.searchItems(
      queryEmbedding: queryEmbedding,
      keyword: searchQuery,
      itemType: typeFilter,
      userTopic: userTopic,
      keywordOnly: keywordSearch == true,
    );
  }

  Future<List<String>> matchTopics(
    List<double> itemEmbedding,
    List<UserTopic> activeTopics,
    SharedItem item,
    String compareText, {
    List<double>? secondaryEmbedding,
  }) async {
    final textTreshold = sharedPrefRepository.getTextEmbeddingMatcher();
    final imageTreshold = sharedPrefRepository.getImageEmbeddingMatcher();
    final combinedTreshold = sharedPrefRepository.getCombinedEmbeddingMatcher();
    final keywordMatcher = sharedPrefRepository.getKeywordMatcher();
    final maxTags = sharedPrefRepository.getMaxTags();
    final matcher = TopicMatcher(
      textThreshold: textTreshold,
      imageThreshold: imageTreshold,
      combinedThreshold: combinedTreshold,
      keywordMatch: keywordMatcher,
      maxTags: maxTags,
    );

    final result = await matcher.matchTopics(
      itemEmbedding,
      activeTopics,
      item.contentType,
      compareText,
      secondaryEmbedding: secondaryEmbedding,
    );

    return result.autoTags;
  }

  int insertSharedItem(SharedItem item) {
    return database.insertSharedItem(item);
  }

  Future<int> insertSharedItemAsync(SharedItem item) async {
    return await database.insertSharedItemAsync(item);
  }

  /// Get all shared items from database
  Future<List<SharedItem>> getAllSharedItems() async {
    return database.getAllSharedItems();
  }

  // Get all shared items by type
  Future<List<SharedItem>> getSharedItemsByType(SharedItemType type) async {
    return database.getSharedItemsByType(type);
  }

  /// Delete a shared item
  Future<bool> deleteSharedItem(int id) async {
    return database.deleteSharedItem(id);
  }

  /// Clear all items from database
  Future<int> clearAllItems() async {
    return database.clearAllItems();
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

  bool _trimAndCheckIfIsURL(String? text) {
    if (text == null || text.isEmpty) {
      return false;
    }

    final trimmed = text.trim();
    final uri = Uri.tryParse(trimmed);

    // Must have scheme AND host to be a real URL
    if (uri == null) return false;

    // Check for http/https scheme
    if (!uri.hasScheme || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      return false;
    }

    // Must have a host
    if (!uri.hasAuthority || uri.host.isEmpty) {
      return false;
    }

    return true;
  }

  Future<bool> _checkIfLinkEndsInImage(String url) async {
    // Quick check: known extensions
    final imageExtensions = ['.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp', '.svg'];
    final lowerUrl = url.toLowerCase().split('?').first; // Remove query params
    if (imageExtensions.any((ext) => lowerUrl.endsWith(ext))) {
      return true;
    }

    // HEAD request to check Content-Type
    try {
      final response = await http
          .head(Uri.parse(url), headers: {'User-Agent': 'Mozilla/5.0 (compatible; LinkPreview/1.0)'})
          .timeout(const Duration(seconds: 5));

      final contentType = response.headers['content-type']?.toLowerCase() ?? '';
      return contentType.startsWith('image/');
    } catch (e) {
      print('⚠️ HEAD request failed: $e');
      return false;
    }
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
