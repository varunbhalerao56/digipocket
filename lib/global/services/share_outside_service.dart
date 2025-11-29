import 'package:digipocket/feature/shared_item/shared_item.dart';
import 'package:share_plus/share_plus.dart';

class ShareHelper {
  static Future<ShareResult?> shareItem(SharedItem item) async {
    switch (item.contentType) {
      case SharedItemType.text:
        return await shareText(item.text ?? '', subject: item.userCaption);
      case SharedItemType.url:
        return await shareUrl(item.url ?? '', subject: item.userCaption);
      case SharedItemType.image:
        if (item.imagePath == null) {
          return null;
        }

        return shareImage(item.imagePath!, text: item.text);
    }
  }

  /// Share plain text
  static Future<ShareResult> shareText(String text, {String? subject}) async {
    return await SharePlus.instance.share(ShareParams(text: text, subject: subject));
  }

  /// Share a URL
  static Future<ShareResult> shareUrl(String url, {String? subject}) async {
    return await SharePlus.instance.share(ShareParams(uri: Uri.parse(url), subject: subject));
  }

  /// Share a single image file
  static Future<ShareResult> shareImage(String imagePath, {String? text}) async {
    return await SharePlus.instance.share(ShareParams(files: [XFile(imagePath)], text: text));
  }

  /// Share multiple files
  static Future<ShareResult> shareFiles(List<String> filePaths, {String? text, String? subject}) async {
    final files = filePaths.map((path) => XFile(path)).toList();
    return await SharePlus.instance.share(ShareParams(files: files, text: text, subject: subject));
  }

  /// Share text with an image
  static Future<ShareResult> shareTextWithImage(String text, String imagePath, {String? subject}) async {
    return await SharePlus.instance.share(ShareParams(files: [XFile(imagePath)], text: text, subject: subject));
  }
}
