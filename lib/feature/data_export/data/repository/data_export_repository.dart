import 'dart:io';
import 'dart:convert';
import 'package:archive/archive_io.dart';
import 'package:digipocket/feature/data_export/data_export.dart';
import 'package:digipocket/feature/shared_item/shared_item.dart';
import 'package:digipocket/feature/user_topic/user_topic.dart';
import 'package:digipocket/global/services/share_outside_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DataExportRepository {
  final SharedItemRepository sharedItemRepository;
  final UserTopicRepository userTopicRepository;

  DataExportRepository({required this.sharedItemRepository, required this.userTopicRepository});

  /// Export all data to JSON + images as ZIP
  /// Export with local save (file picker)
  Future<ExportResult> exportToJsonLocal() async {
    return _exportToJson(useShare: false);
  }

  /// Export with share sheet
  Future<ExportResult> exportToJsonShare() async {
    return _exportToJson(useShare: true);
  }

  /// Internal export method
  Future<ExportResult> _exportToJson({required bool useShare}) async {
    try {
      print('🔍 Starting export...');

      // Generate timestamp for unique export name
      final timestamp = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
      final exportName = 'digipocket_export_$timestamp';

      Directory exportDirectory;

      if (useShare) {
        // For share: use temp directory
        exportDirectory = Directory.systemTemp.createTempSync('digipocket_export_');
      } else {
        // For local: let user pick directory
        String? selectedDirectory = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Select export location');

        if (selectedDirectory == null) {
          // User cancelled
          return ExportResult(
            success: false,
            message: 'Export cancelled by user',
            itemCount: 0,
            topicCount: 0,
            imageCount: 0,
          );
        }

        exportDirectory = Directory(selectedDirectory);
      }

      // Create temp directory for building export structure
      final tempDir = Directory.systemTemp.createTempSync('digipocket_build_');

      // Create temp directory
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
      await File('${tempDir.path}/items.json').writeAsString(JsonEncoder.withIndent('  ').convert(itemsJson));

      // 2. Export topics
      final topics = await userTopicRepository.getAllUserTopics();
      final topicsJson = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'topics': topics.map((topic) => topic.toJson()).toList(),
      };
      await File('${tempDir.path}/topics.json').writeAsString(JsonEncoder.withIndent('  ').convert(topicsJson));

      // 3. Copy images
      final imagesDir = Directory('${tempDir.path}/images');
      await imagesDir.create();

      int imageCount = 0;
      for (var item in items) {
        // Copy main image
        if (item.imagePath != null && item.imagePath!.isNotEmpty) {
          final imageFile = File(item.imagePath!);
          if (await imageFile.exists()) {
            await imageFile.copy('${imagesDir.path}/${path.basename(item.imagePath!)}');
            imageCount++;
          }
        }

        // Copy URL thumbnail
        if (item.urlThumbnailPath != null && item.urlThumbnailPath!.isNotEmpty) {
          final thumbFile = File(item.urlThumbnailPath!);
          if (await thumbFile.exists()) {
            await thumbFile.copy('${imagesDir.path}/${path.basename(item.urlThumbnailPath!)}');
            imageCount++;
          }
        }

        // Copy URL favicon
        if (item.urlFaviconPath != null && item.urlFaviconPath!.isNotEmpty) {
          final faviconFile = File(item.urlFaviconPath!);
          if (await faviconFile.exists()) {
            await faviconFile.copy('${imagesDir.path}/${path.basename(item.urlFaviconPath!)}');
            imageCount++;
          }
        }
      }

      // 4. Create ZIP
      final zipFile = await _createZip(tempDir, exportDirectory, exportName);

      if (useShare) {
        // Share the file
        await ShareHelper.shareFile(
          zipFile.path,
          text: 'Export from ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
        );

        // Cleanup after delay
        Future.delayed(const Duration(seconds: 5), () async {
          try {
            if (await exportDirectory.exists()) {
              await exportDirectory.delete(recursive: true);
            }
          } catch (e) {
            print('⚠️ Failed to cleanup temp directory: $e');
          }
        });
      } else {
        // For local save, scan file on Android
        if (Platform.isAndroid) {
          await _scanFile(zipFile.path);
        }
      }

      // 5. Cleanup build temp directory
      await tempDir.delete(recursive: true);

      return ExportResult(
        success: true,
        message: useShare ? 'Export shared successfully' : 'Export saved successfully',
        itemCount: items.length,
        topicCount: topics.length,
        imageCount: imageCount,
        filePath: zipFile.path,
      );
    } catch (e) {
      return ExportResult(success: false, message: 'Export failed: $e', itemCount: 0, topicCount: 0, imageCount: 0);
    }
  }

  /// Create ZIP file from directory
  Future<File> _createZip(Directory sourceDir, Directory destDir, String zipName) async {
    final zipFile = File('${destDir.path}/$zipName.zip');
    final archive = Archive();

    // Add items.json
    final itemsBytes = await File('${sourceDir.path}/items.json').readAsBytes();
    archive.addFile(ArchiveFile('items.json', itemsBytes.length, itemsBytes));

    // Add topics.json
    final topicsBytes = await File('${sourceDir.path}/topics.json').readAsBytes();
    archive.addFile(ArchiveFile('topics.json', topicsBytes.length, topicsBytes));

    // Add all images
    final imagesDir = Directory('${sourceDir.path}/images');
    if (await imagesDir.exists()) {
      final imageFiles = imagesDir.listSync().whereType<File>();
      for (var file in imageFiles) {
        final filename = path.basename(file.path);
        final imageBytes = await file.readAsBytes();
        archive.addFile(ArchiveFile('images/$filename', imageBytes.length, imageBytes));
      }
    }

    // Encode and write ZIP
    final zipData = ZipEncoder().encode(archive);

    await zipFile.writeAsBytes(zipData);
    return zipFile;
  }

  Future<void> _scanFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        // Trigger media scan
        await Process.run('am', [
          'broadcast',
          '-a',
          'android.intent.action.MEDIA_SCANNER_SCAN_FILE',
          '-d',
          'file://$filePath',
        ]);
        print('✅ File registered with MediaStore: $filePath');
      }
    } catch (e) {
      print('⚠️ Failed to scan file: $e');
    }
  }

  /// Import data from JSON (folder or ZIP)
  Future<ImportResult> importFromJson(String importPath) async {
    Directory? tempDir;

    try {
      Directory sourceDir;

      // Try to decode as ZIP first (regardless of extension)
      final file = File(importPath);

      if (await file.exists()) {
        // It's a file - try to decode as ZIP
        try {
          tempDir = Directory.systemTemp.createTempSync('digipocket_import_');
          final bytes = await file.readAsBytes();
          final archive = ZipDecoder().decodeBytes(bytes);

          // Successfully decoded as ZIP - extract it
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
          print('✅ Decoded as ZIP file');
        } catch (zipError) {
          // Not a valid ZIP - treat as directory path
          print('⚠️ Not a ZIP file, treating as directory: $zipError');
          sourceDir = Directory(importPath);
        }
      } else {
        // Path doesn't exist as file - try as directory
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

      // Process import with merge logic
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

    try {
      // 1. Import Topics first (items reference them)
      final topicsList = topicsData['topics'] as List<dynamic>? ?? [];
      final existingTopics = await userTopicRepository.getAllUserTopics();

      // Build lookup map for topics by name (O(n))
      final existingTopicsMap = <String, UserTopic>{};
      for (var topic in existingTopics) {
        existingTopicsMap[topic.name.toLowerCase()] = topic;
      }

      for (var topicJson in topicsList) {
        final importedTopic = UserTopicJson.fromJson(topicJson as Map<String, dynamic>);
        final existingTopic = existingTopicsMap[importedTopic.name.toLowerCase()];

        if (existingTopic == null) {
          importedTopic.id = 0;
          // New topic - insert with ID 0
          await userTopicRepository.inputUserTopicAsync(importedTopic);
          topicsAdded++;
        } else {
          // Topic exists - compare timestamps
          final existingUpdatedAt = existingTopic.updatedAt ?? existingTopic.createdAt;
          final importUpdatedAt = (topicJson)['updatedAt'] ?? (topicJson)['createdAt'];

          if (importUpdatedAt > existingUpdatedAt) {
            // Import is newer - update
            final updatedTopic = UserTopic(
              id: existingTopic.id, // Keep existing ID
              name: importedTopic.name,
              description: importedTopic.description,
              createdAt: existingTopic.createdAt, // Keep original creation time
              updatedAt: importedTopic.updatedAt,
              isActive: importedTopic.isActive,
              embedding: importedTopic.embedding,
              color: importedTopic.color,
              icon: importedTopic.icon,
              itemCount: importedTopic.itemCount,
            );
            await userTopicRepository.inputUserTopicAsync(updatedTopic);
          }
          // If existing is newer, skip (don't increment counter)
        }
      }

      // 2. Import Items
      final itemsList = itemsData['items'] as List<dynamic>? ?? [];
      final existingItems = await sharedItemRepository.getAllSharedItems();

      // Build lookup map for items (O(n))
      final existingItemsMap = <String, SharedItem>{};
      for (var item in existingItems) {
        final key = _getItemKey(item);
        if (key != null) {
          existingItemsMap[key] = item;
        }
      }

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

        // Create SharedItem with reconstructed paths (ID = 0)
        final importedItem = SharedItemJson.fromJson(itemData, permanentImagesDir.path);

        // Check if item already exists using optimized lookup
        final itemKey = _getItemKey(itemData);
        final existingItem = itemKey != null ? existingItemsMap[itemKey] : null;

        if (existingItem == null) {
          // New item - insert with ID 0 (ObjectBox assigns new ID)
          importedItem.id = 0;

          await sharedItemRepository.insertSharedItemAsync(importedItem);
          itemsAdded++;
        } else {
          // Item exists - compare timestamps
          final existingUpdatedAt = existingItem.updatedAt ?? existingItem.createdAt;
          final importUpdatedAt = itemData['updatedAt'] ?? itemData['createdAt'];

          if (importUpdatedAt > existingUpdatedAt) {
            // Import is newer - update existing item
            final updatedItem = SharedItem(
              id: existingItem.id, // ✅ Keep existing ID
              contentType: importedItem.contentType,
              createdAt: existingItem.createdAt, // Keep original creation time
              updatedAt: importedItem.updatedAt,
              schemaVersion: importedItem.schemaVersion,
              isFavorite: importedItem.isFavorite,
              isArchived: importedItem.isArchived,
              sourceApp: importedItem.sourceApp,
              vectorEmbedding: importedItem.vectorEmbedding,
              generatedTags: importedItem.generatedTags,
              summary: importedItem.summary,
              summaryConfidence: importedItem.summaryConfidence,
              tagConfidence: importedItem.tagConfidence,
              userTags: importedItem.userTags,
              userCaptionEmbedding: importedItem.userCaptionEmbedding,
              userCaption: importedItem.userCaption,
              text: importedItem.text,
              url: importedItem.url,
              imagePath: importedItem.imagePath,
              ocrText: importedItem.ocrText,
              checksum: importedItem.checksum,
              domain: importedItem.domain,
              urlTitle: importedItem.urlTitle,
              urlDescription: importedItem.urlDescription,
              urlThumbnailPath: importedItem.urlThumbnailPath,
              urlFaviconPath: importedItem.urlFaviconPath,
              fileType: importedItem.fileType,
            );
            await sharedItemRepository.insertSharedItem(updatedItem);
            itemsUpdated++;
          } else {
            // Existing is newer or same - skip
            itemsSkipped++;
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
      print('❌ Import failed: $e');
      rethrow;
    }
  }

  /// Generate unique key for an item (works with SharedItem or JSON Map)
  String? _getItemKey(dynamic item) {
    SharedItemType contentType;
    String? text;
    String? url;
    int? createdAt;

    // Handle both SharedItem and JSON Map
    if (item is SharedItem) {
      contentType = item.contentType;
      text = item.text;
      url = item.url;
      createdAt = item.createdAt;
    } else if (item is Map<String, dynamic>) {
      contentType = SharedItemType.values[item['contentType'] ?? 0];
      text = item['text'] as String?;
      url = item['url'] as String?;
      createdAt = item['createdAt'] as int?;
    } else {
      return null;
    }

    switch (contentType) {
      case SharedItemType.text:
        if (text != null && text.isNotEmpty && createdAt != null) {
          return 'text:$createdAt:$text';
        }
        break;
      case SharedItemType.url:
        if (url != null && url.isNotEmpty && createdAt != null) {
          return 'url:$createdAt:$url';
        }
        break;
      case SharedItemType.image:
        if (createdAt != null) {
          return 'image:$createdAt';
        }
        break;
    }
    return null;
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
