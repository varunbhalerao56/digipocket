import 'dart:io';
import 'dart:convert';
import 'package:archive/archive_io.dart';
import 'package:digipocket/feature/data_export/data_export.dart';
import 'package:digipocket/feature/shared_item/shared_item.dart';
import 'package:digipocket/feature/user_topic/user_topic.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class DataExportRepository {
  final SharedItemRepository sharedItemRepository;
  final UserTopicRepository userTopicRepository;

  DataExportRepository({required this.sharedItemRepository, required this.userTopicRepository});

  /// Export all data to JSON + images as ZIP
  Future<ExportResult> exportToJson(String exportDirectory) async {
    try {
      Directory exportDirectory;

      if (Platform.isAndroid) {
        // Android: Use Downloads folder
        exportDirectory = Directory('/storage/emulated/0/Download/Digipocket');
      } else if (Platform.isIOS) {
        // iOS: Use Documents directory (visible in Files app)
        final appDocDir = await getApplicationDocumentsDirectory();
        exportDirectory = Directory('${appDocDir.path}/Exports');
      } else {
        throw Exception('Unsupported platform');
      }

      // Create directory if it doesn't exist
      if (!await exportDirectory.exists()) {
        await exportDirectory.create(recursive: true);
      }

      // Generate timestamp for unique export name
      final timestamp = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
      final exportName = 'digipocket_export_$timestamp';
      final tempDir = Directory('${exportDirectory.path}/$exportName');

      // Create temp directory for export
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
      await tempDir.create(recursive: true);

      // 1. Export items
      final items = await sharedItemRepository.getAllSharedItems();
      final itemsJson = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'items': items.map((item) => item.toJson()).toList(),
      };

      final itemsFile = File('${tempDir.path}/items.json');
      await itemsFile.writeAsString(JsonEncoder.withIndent('  ').convert(itemsJson));

      // 2. Export topics
      final topics = await userTopicRepository.getAllUserTopics();
      final topicsJson = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'topics': topics.map((topic) => topic.toJson()).toList(),
      };

      final topicsFile = File('${tempDir.path}/topics.json');
      await topicsFile.writeAsString(JsonEncoder.withIndent('  ').convert(topicsJson));

      // 3. Copy images
      final imagesDir = Directory('${tempDir.path}/images');
      await imagesDir.create();

      int imageCount = 0;
      for (var item in items) {
        // Copy main image
        if (item.imagePath != null && await File(item.imagePath!).exists()) {
          final filename = path.basename(item.imagePath!);
          await File(item.imagePath!).copy('${imagesDir.path}/$filename');
          imageCount++;
        }

        // Copy URL thumbnail
        if (item.urlThumbnailPath != null && await File(item.urlThumbnailPath!).exists()) {
          final filename = path.basename(item.urlThumbnailPath!);
          await File(item.urlThumbnailPath!).copy('${imagesDir.path}/$filename');
          imageCount++;
        }

        // Copy URL favicon
        if (item.urlFaviconPath != null && await File(item.urlFaviconPath!).exists()) {
          final filename = path.basename(item.urlFaviconPath!);
          await File(item.urlFaviconPath!).copy('${imagesDir.path}/$filename');
          imageCount++;
        }
      }

      // 4. Create ZIP
      final zipFile = File('$exportDirectory/$exportName.zip');
      final encoder = ZipFileEncoder();
      encoder.create(zipFile.path);
      encoder.addDirectory(tempDir);
      encoder.close();

      // 5. Cleanup temp directory
      await tempDir.delete(recursive: true);

      return ExportResult(
        success: true,
        message: 'Export completed successfully',
        itemCount: items.length,
        topicCount: topics.length,
        imageCount: imageCount,
        filePath: zipFile.path,
      );
    } catch (e) {
      return ExportResult(success: false, message: 'Export failed: $e', itemCount: 0, topicCount: 0, imageCount: 0);
    }
  }

  /// Import data from JSON (folder or ZIP)
  Future<ImportResult> importFromJson(String importPath) async {
    Directory? tempDir;

    try {
      // Determine if it's a ZIP or folder
      final isZip = importPath.endsWith('.zip');
      Directory sourceDir;

      if (isZip) {
        // Extract ZIP to temp directory
        tempDir = Directory.systemTemp.createTempSync('digipocket_import_');
        final zipFile = File(importPath);
        final bytes = await zipFile.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);

        for (final file in archive) {
          final filename = file.name;
          if (file.isFile) {
            final data = file.content as List<int>;
            final outFile = File('${tempDir.path}/$filename');
            await outFile.create(recursive: true);
            await outFile.writeAsBytes(data);
          }
        }

        sourceDir = tempDir;
      } else {
        // Use folder directly
        sourceDir = Directory(importPath);
      }

      // Validate structure
      final itemsFile = File('${sourceDir.path}/items.json');
      final topicsFile = File('${sourceDir.path}/topics.json');
      final imagesDir = Directory('${sourceDir.path}/images');

      if (!await itemsFile.exists() || !await topicsFile.exists()) {
        throw Exception('Invalid import structure: missing items.json or topics.json');
      }

      // Read JSON files
      final itemsData = jsonDecode(await itemsFile.readAsString()) as Map<String, dynamic>;
      final topicsData = jsonDecode(await topicsFile.readAsString()) as Map<String, dynamic>;

      // Validate embeddings (768 dimensions)
      _validateEmbeddings(itemsData, topicsData);

      // Get app group path for permanent storage
      final appGroupPath = await sharedItemRepository.shareQueueDataSource.getAppGroupPath();
      final permanentImagesDir = Directory('$appGroupPath/images');
      if (!await permanentImagesDir.exists()) {
        await permanentImagesDir.create(recursive: true);
      }

      // Process import with transaction-like behavior
      final result = await _processImport(
        itemsData: itemsData,
        topicsData: topicsData,
        sourceImagesDir: imagesDir,
        permanentImagesDir: permanentImagesDir,
        appGroupPath: appGroupPath,
      );

      // Cleanup temp directory if created
      if (tempDir != null && await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }

      return result;
    } catch (e) {
      // Cleanup temp directory on error
      if (tempDir != null && await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }

      return ImportResult(
        success: false,
        message: 'Import failed: $e',
        itemsAdded: 0,
        itemsUpdated: 0,
        itemsSkipped: 0,
        topicsAdded: 0,
      );
    }
  }

  /// Validate embeddings are 768 dimensions
  void _validateEmbeddings(Map<String, dynamic> itemsData, Map<String, dynamic> topicsData) {
    // Check items
    final items = itemsData['items'] as List<dynamic>?;
    if (items != null) {
      for (var item in items) {
        final embedding = item['vectorEmbedding'] as List<dynamic>?;
        if (embedding != null && embedding.length != 768) {
          throw Exception('Invalid embedding dimension: ${embedding.length}, expected 768');
        }

        final captionEmbedding = item['userCaptionEmbedding'] as List<dynamic>?;
        if (captionEmbedding != null && captionEmbedding.length != 768) {
          throw Exception('Invalid caption embedding dimension: ${captionEmbedding.length}, expected 768');
        }
      }
    }

    // Check topics
    final topics = topicsData['topics'] as List<dynamic>?;
    if (topics != null) {
      for (var topic in topics) {
        final embedding = topic['embedding'] as List<dynamic>?;
        if (embedding != null && embedding.length != 768) {
          throw Exception('Invalid topic embedding dimension: ${embedding.length}, expected 768');
        }
      }
    }
  }

  /// Process import with merge logic
  Future<ImportResult> _processImport({
    required Map<String, dynamic> itemsData,
    required Map<String, dynamic> topicsData,
    required Directory sourceImagesDir,
    required Directory permanentImagesDir,
    required String appGroupPath,
  }) async {
    int itemsAdded = 0;
    int itemsUpdated = 0;
    int itemsSkipped = 0;
    int topicsAdded = 0;

    final importedItems = <SharedItem>[];
    final importedTopics = <UserTopic>[];

    try {
      // 1. Import Topics first (items reference them)
      final topicsList = topicsData['topics'] as List<dynamic>? ?? [];
      final existingTopics = await userTopicRepository.getAllUserTopics();
      final existingTopicsMap = {for (var t in existingTopics) t.id: t};

      for (var topicJson in topicsList) {
        final topic = UserTopicJson.fromJson(topicJson as Map<String, dynamic>);

        // Check if topic exists
        final existing = existingTopicsMap[topic.id];

        if (existing == null) {
          // Add new topic
          await userTopicRepository.inputUserTopicAsync(topic);
          importedTopics.add(topic);
          topicsAdded++;
        } else {
          // Merge: compare updatedAt timestamps
          final existingUpdatedAt = existing.updatedAt ?? existing.createdAt;
          final importUpdatedAt = topic.updatedAt ?? topic.createdAt;

          if (importUpdatedAt > existingUpdatedAt) {
            // Import is newer, update
            final updatedTopic = UserTopic(
              id: existing.id,
              name: topic.name,
              description: topic.description,
              createdAt: existing.createdAt, // Keep original creation time
              updatedAt: topic.updatedAt,
              isActive: topic.isActive,
              embedding: topic.embedding,
              color: topic.color,
              icon: topic.icon,
              itemCount: topic.itemCount,
            );
            await userTopicRepository.inputUserTopicAsync(updatedTopic);
            importedTopics.add(updatedTopic);
          }
        }
      }

      // 2. Import Items
      final itemsList = itemsData['items'] as List<dynamic>? ?? [];
      final existingItems = await sharedItemRepository.getAllSharedItems();
      final existingItemsMap = {for (var i in existingItems) i.id: i};

      for (var itemJson in itemsList) {
        final itemData = itemJson as Map<String, dynamic>;

        // Check if images exist before creating item
        bool shouldSkip = false;

        // For image items, skip if image missing
        if (itemData['contentType'] == SharedItemType.image.index) {
          final imageName = itemData['imagePath'] as String?;
          if (imageName != null) {
            final sourceImageFile = File('${sourceImagesDir.path}/$imageName');
            if (!await sourceImageFile.exists()) {
              print('⚠️ Skipping image item: image file not found ($imageName)');
              itemsSkipped++;
              shouldSkip = true;
            }
          }
        }

        if (shouldSkip) continue;

        // Copy images to permanent storage
        await _copyItemImages(
          itemData: itemData,
          sourceImagesDir: sourceImagesDir,
          permanentImagesDir: permanentImagesDir,
        );

        // Create SharedItem with reconstructed paths
        final item = SharedItemJson.fromJson(itemData, permanentImagesDir.path);

        // Check if item exists
        final existing = existingItemsMap[item.id];

        if (existing == null) {
          // Add new item
          await sharedItemRepository.insertSharedItemAsync(item);
          importedItems.add(item);
          itemsAdded++;
        } else {
          // Merge: compare updatedAt timestamps
          final existingUpdatedAt = existing.updatedAt ?? existing.createdAt;
          final importUpdatedAt = item.updatedAt ?? item.createdAt;

          if (importUpdatedAt > existingUpdatedAt) {
            // Import is newer, update
            final updatedItem = SharedItem(
              id: existing.id,
              contentType: item.contentType,
              createdAt: existing.createdAt, // Keep original creation time
              updatedAt: item.updatedAt,
              schemaVersion: item.schemaVersion,
              isFavorite: item.isFavorite,
              isArchived: item.isArchived,
              sourceApp: item.sourceApp,
              vectorEmbedding: item.vectorEmbedding,
              generatedTags: item.generatedTags,
              summary: item.summary,
              summaryConfidence: item.summaryConfidence,
              tagConfidence: item.tagConfidence,
              userTags: item.userTags,
              userCaptionEmbedding: item.userCaptionEmbedding,
              userCaption: item.userCaption,
              text: item.text,
              url: item.url,
              imagePath: item.imagePath,
              ocrText: item.ocrText,
              checksum: item.checksum,
              domain: item.domain,
              urlTitle: item.urlTitle,
              urlDescription: item.urlDescription,
              urlThumbnailPath: item.urlThumbnailPath,
              urlFaviconPath: item.urlFaviconPath,
              fileType: item.fileType,
            );
            await sharedItemRepository.insertSharedItemAsync(updatedItem);
            importedItems.add(updatedItem);
            itemsUpdated++;
          }
        }
      }

      return ImportResult(
        success: true,
        message: 'Import completed successfully',
        itemsAdded: itemsAdded,
        itemsUpdated: itemsUpdated,
        itemsSkipped: itemsSkipped,
        topicsAdded: topicsAdded,
      );
    } catch (e) {
      // Rollback: delete imported items and topics
      print('❌ Import failed, rolling back: $e');

      for (var item in importedItems) {
        await sharedItemRepository.deleteSharedItem(item.id);
      }

      for (var topic in importedTopics) {
        await userTopicRepository.deleteUserTopic(topic.id);
      }

      rethrow;
    }
  }

  /// Copy item images from source to permanent storage (overwrite if exists)
  Future<void> _copyItemImages({
    required Map<String, dynamic> itemData,
    required Directory sourceImagesDir,
    required Directory permanentImagesDir,
  }) async {
    // Copy main image
    final imageName = itemData['imagePath'] as String?;
    if (imageName != null) {
      final sourceFile = File('${sourceImagesDir.path}/$imageName');
      if (await sourceFile.exists()) {
        final destFile = File('${permanentImagesDir.path}/$imageName');
        await sourceFile.copy(destFile.path);
      }
    }

    // Copy URL thumbnail (skip if missing, don't fail)
    final thumbnailName = itemData['urlThumbnailPath'] as String?;
    if (thumbnailName != null) {
      final sourceFile = File('${sourceImagesDir.path}/$thumbnailName');
      if (await sourceFile.exists()) {
        final destFile = File('${permanentImagesDir.path}/$thumbnailName');
        await sourceFile.copy(destFile.path);
      }
    }

    // Copy URL favicon (skip if missing, don't fail)
    final faviconName = itemData['urlFaviconPath'] as String?;
    if (faviconName != null) {
      final sourceFile = File('${sourceImagesDir.path}/$faviconName');
      if (await sourceFile.exists()) {
        final destFile = File('${permanentImagesDir.path}/$faviconName');
        await sourceFile.copy(destFile.path);
      }
    }
  }
}
