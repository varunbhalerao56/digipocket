import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:digipocket/feature/data_export/data_export.dart';
import 'package:digipocket/feature/shared_item/shared_item.dart';
import 'package:digipocket/feature/user_topic/user_topic.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class MarkdownDataExportRepository {
  final SharedItemRepository sharedItemRepository;
  final UserTopicRepository userTopicRepository;

  MarkdownDataExportRepository({required this.sharedItemRepository, required this.userTopicRepository});

  /// Export items to Markdown files (one per basket/topic)
  Future<ExportResult> exportToMarkdown() async {
    try {
      print('🔍 Starting Markdown export...');

      // Get platform-specific directory
      Directory exportDirectory;
      if (Platform.isAndroid) {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir == null) throw Exception('External storage not available');
        exportDirectory = Directory('${externalDir.path}/Exports');
      } else if (Platform.isIOS) {
        final appDocDir = await getApplicationDocumentsDirectory();
        exportDirectory = Directory('${appDocDir.path}/Exports');
      } else {
        throw Exception('Unsupported platform');
      }

      if (!await exportDirectory.exists()) {
        await exportDirectory.create(recursive: true);
      }

      // Generate timestamp for export folder
      final timestamp = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
      final exportName = 'markdown_export_$timestamp';
      final tempDir = Directory('${exportDirectory.path}/$exportName');
      await tempDir.create(recursive: true);

      // Copy images to export directory
      final imagesDir = Directory('${tempDir.path}/images');
      await imagesDir.create();

      // Get all items and topics
      final items = await sharedItemRepository.getAllSharedItems();
      final topics = await userTopicRepository.getAllUserTopics();

      // Group items by topic
      final itemsByTopic = <String, List<SharedItem>>{};
      final untaggedItems = <SharedItem>[];

      for (var item in items) {
        if (item.userTags == null || item.userTags!.isEmpty) {
          untaggedItems.add(item);
        } else {
          // Add item to each topic it's tagged with
          for (var tag in item.userTags!) {
            itemsByTopic.putIfAbsent(tag, () => []).add(item);
          }
        }
      }

      int fileCount = 0;
      int imageCount = 0;

      // Create markdown file for each topic
      for (var topic in topics) {
        final topicItems = itemsByTopic[topic.name] ?? [];
        if (topicItems.isEmpty) continue;

        final markdown = await _generateTopicMarkdown(topic, topicItems, imagesDir);
        final file = File('${tempDir.path}/${_sanitizeFilename(topic.name)}.md');
        await file.writeAsString(markdown);
        fileCount++;

        // Copy images for this topic
        for (var item in topicItems) {
          imageCount += await _copyItemImagesToMarkdown(item, imagesDir);
        }
      }

      // Create Untagged.md if there are untagged items
      if (untaggedItems.isNotEmpty) {
        final markdown = await _generateUntaggedMarkdown(untaggedItems, imagesDir);
        final file = File('${tempDir.path}/Untagged.md');
        await file.writeAsString(markdown);
        fileCount++;

        // Copy images for untagged items
        for (var item in untaggedItems) {
          imageCount += await _copyItemImagesToMarkdown(item, imagesDir);
        }
      }

      // Create ZIP
      print('📦 Creating ZIP file...');
      final zipFile = await _createZipFromDirectory(tempDir, exportDirectory, exportName);

      // Cleanup temp directory
      print('🗑️ Cleaning up temp directory...');
      await tempDir.delete(recursive: true);
      print('✅ Cleanup complete');

      return ExportResult(
        success: true,
        message: 'Markdown export completed successfully',
        itemCount: items.length,
        topicCount: fileCount,
        imageCount: imageCount,
        filePath: zipFile.path,
      );
    } catch (e) {
      print('❌ Markdown export error: $e');
      return ExportResult(
        success: false,
        message: 'Markdown export failed: $e',
        itemCount: 0,
        topicCount: 0,
        imageCount: 0,
      );
    }
  }

  /// Generate markdown for a topic
  Future<String> _generateTopicMarkdown(UserTopic topic, List<SharedItem> items, Directory imagesDir) async {
    final buffer = StringBuffer();

    String topicNameNoSpace = topic.name.replaceAll(' ', '');
    topicNameNoSpace = _sanitizeFilename(topicNameNoSpace);
    topicNameNoSpace = topicNameNoSpace.replaceAll('&', '');

    // Topic header
    buffer.writeln('### Basket **${topic.name}**');
    buffer.writeln("#$topicNameNoSpace");
    buffer.writeln();
    if (topic.description != null && topic.description!.isNotEmpty) {
      buffer.writeln('**Basket Description**');
      buffer.writeln(topic.description);
      buffer.writeln();
    }
    buffer.writeln('---');
    buffer.writeln();

    // Sort items by creation date (newest first)
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Add each item
    for (var item in items) {
      buffer.writeln(await _generateItemMarkdown(item, imagesDir));
    }

    return buffer.toString();
  }

  /// Generate markdown for untagged items
  Future<String> _generateUntaggedMarkdown(List<SharedItem> items, Directory imagesDir) async {
    final buffer = StringBuffer();

    // Sort items by creation date (newest first)
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    for (var item in items) {
      buffer.writeln(await _generateItemMarkdown(item, imagesDir));
    }

    return buffer.toString();
  }

  /// Generate markdown for a single item based on its type
  Future<String> _generateItemMarkdown(SharedItem item, Directory imagesDir) async {
    final buffer = StringBuffer();

    final tagsNamesWithNoSpace = item.userTags?.map((tag) => tag.replaceAll(' ', '')).toList() ?? [];

    final tags = tagsNamesWithNoSpace.join(', ');

    String finalTags = tags != "" ? tags.split(', ').map((tag) => '#$tag').join(', ') : '';

    finalTags = _sanitizeFilename(finalTags);
    finalTags = finalTags.replaceAll('&', '');

    if (finalTags.isEmpty) {
      finalTags = '#Untagged';
    }

    switch (item.contentType) {
      case SharedItemType.url:
        buffer.writeln("#### Created on ${_formatDate(item.createdAt)}");
        buffer.writeln("Baskets $finalTags");
        buffer.writeln();

        // Thumbnail if exists
        if (item.urlThumbnailPath != null && item.urlThumbnailPath!.isNotEmpty) {
          final filename = path.basename(item.urlThumbnailPath!);
          buffer.writeln('<img src="images/$filename" style="max-height: 200px;" alt="Image">');
          buffer.writeln();
        }

        // Title with link or just URL
        if (item.urlTitle != null && item.urlTitle!.isNotEmpty) {
          buffer.writeln('**[${item.urlTitle}](${item.url})**');
        } else if (item.url != null) {
          buffer.writeln('**[${item.url}](${item.url})**');
        }
        buffer.writeln();

        // Description if exists
        if (item.urlDescription != null && item.urlDescription!.isNotEmpty) {
          buffer.writeln('**Content**');
          buffer.writeln(item.urlDescription);
          buffer.writeln();
        }

        // Caption if exists
        if (item.userCaption != null && item.userCaption!.isNotEmpty) {
          buffer.writeln('**Caption**');
          buffer.writeln(item.userCaption);
          buffer.writeln();
        }
        break;

      case SharedItemType.image:
        buffer.writeln("#### Created on ${_formatDate(item.createdAt)}");
        buffer.writeln("Baskets $finalTags");
        buffer.writeln();

        // Image
        if (item.imagePath != null && item.imagePath!.isNotEmpty) {
          final filename = path.basename(item.imagePath!);
          buffer.writeln('<img src="images/$filename" style="max-height: 200px;" alt="Image">');
          buffer.writeln();
        }

        // Caption if exists
        if (item.userCaption != null && item.userCaption!.isNotEmpty) {
          buffer.writeln('**Caption**');
          buffer.writeln(item.userCaption);
          buffer.writeln();
        }
        break;

      case SharedItemType.text:
        buffer.writeln("#### Created on ${_formatDate(item.createdAt)}");
        buffer.writeln("Baskets $finalTags");
        buffer.writeln();

        // Text content
        if (item.text != null && item.text!.isNotEmpty) {
          buffer.writeln('**Content**');
          buffer.writeln(item.text);
          buffer.writeln();
        }

        // Caption if exists
        if (item.userCaption != null && item.userCaption!.isNotEmpty) {
          buffer.writeln('**Caption**');
          buffer.writeln(item.userCaption);
          buffer.writeln();
        }
        break;
    }

    buffer.writeln('---');
    return buffer.toString();
  }

  /// Copy item images to markdown export directory
  Future<int> _copyItemImagesToMarkdown(SharedItem item, Directory imagesDir) async {
    int count = 0;

    // Copy main image
    if (item.imagePath != null && item.imagePath!.isNotEmpty) {
      final sourceFile = File(item.imagePath!);
      if (await sourceFile.exists()) {
        final filename = path.basename(item.imagePath!);
        await sourceFile.copy('${imagesDir.path}/$filename');
        count++;
      }
    }

    // Copy URL thumbnail
    if (item.urlThumbnailPath != null && item.urlThumbnailPath!.isNotEmpty) {
      final sourceFile = File(item.urlThumbnailPath!);
      if (await sourceFile.exists()) {
        final filename = path.basename(item.urlThumbnailPath!);
        await sourceFile.copy('${imagesDir.path}/$filename');
        count++;
      }
    }

    return count;
  }

  /// Format timestamp to "2024-01-15 02:30 PM"
  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('yyyy-MM-dd hh:mm a').format(date);
  }

  /// Sanitize filename (remove invalid characters)
  String _sanitizeFilename(String filename) {
    return filename.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }

  /// Create ZIP file from directory (for markdown export)
  Future<File> _createZipFromDirectory(Directory sourceDir, Directory destDir, String zipName) async {
    final zipFile = File('${destDir.path}/$zipName.zip');
    final archive = Archive();

    // Add all markdown files
    final mdFiles = sourceDir.listSync().whereType<File>().where((f) => f.path.endsWith('.md'));

    for (var file in mdFiles) {
      final filename = path.basename(file.path);
      final fileBytes = await file.readAsBytes();
      archive.addFile(ArchiveFile(filename, fileBytes.length, fileBytes));
    }

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
    print('✅ Markdown ZIP created: ${zipFile.path}');

    return zipFile;
  }
}
