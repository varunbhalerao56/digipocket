import 'package:digipocket/feature/shared_item/data/model/shared_item_model.dart';
import 'package:flutter/services.dart';
import 'package:pasteboard/pasteboard.dart';
import 'dart:io';

class ClipboardHelper {
  static Future<void> copyItem(SharedItem item) async {
    switch (item.contentType) {
      case SharedItemType.text:
        return await copyText(item.text ?? '');
      case SharedItemType.url:
        return await copyUrl(item.url ?? '');
      case SharedItemType.image:
        if (item.imagePath == null) {
          return;
        }

        return copyImage(item.imagePath!);
    }
  }

  /// Copy plain text to clipboard
  static Future<void> copyText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Copy URL to clipboard
  static Future<void> copyUrl(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
  }

  /// Copy image to clipboard
  static Future<void> copyImage(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    await Pasteboard.writeImage(bytes);
  }

  /// Get text from clipboard
  static Future<String?> pasteText() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text;
  }

  /// Get image from clipboard
  static Future<Uint8List?> pasteImage() async {
    return await Pasteboard.image;
  }

  /// Check if clipboard has text
  static Future<bool> hasText() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text != null && data!.text!.isNotEmpty;
  }

  /// Check if clipboard has image
  static Future<bool> hasImage() async {
    final image = await Pasteboard.image;
    return image != null;
  }

  /// Get all clipboard files (paths)
  static Future<List<String>?> pasteFiles() async {
    return await Pasteboard.files();
  }

  /// Clear clipboard
  static Future<void> clear() async {
    await Clipboard.setData(const ClipboardData(text: ''));
  }
}
