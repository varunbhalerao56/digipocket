import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;

class ImageDownloader {
  final http.Client _client;
  final String _imagesDirectory;

  ImageDownloader({required String basePath, http.Client? client})
    : _client = client ?? http.Client(),
      _imagesDirectory = '$basePath/images';

  /// Downloads image from URL and saves locally
  Future<String?> downloadAndSave(String imageUrl) async {
    try {
      if (!imageUrl.startsWith('http')) {
        return imageUrl; // Already local
      }

      print('📥 Downloading image: $imageUrl');

      final response = await _client.get(Uri.parse(imageUrl)).timeout(const Duration(seconds: 2));

      if (response.statusCode != 200) {
        print('⚠️ Image download failed: ${response.statusCode}');
        return null;
      }

      final extension = _getExtension(response.headers['content-type'], imageUrl);

      final uniqueId = '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';

      final filename = '$uniqueId$extension';
      final localPath = '$_imagesDirectory/$filename';

      // Ensure directory exists
      final dir = Directory(_imagesDirectory);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final file = File(localPath);
      await file.writeAsBytes(response.bodyBytes);

      print('✅ Image saved: $localPath');
      return localPath;
    } catch (e) {
      print('❌ Image download error: $e');
      return null;
    }
  }

  String _getExtension(String? contentType, String url) {
    if (contentType != null) {
      if (contentType.contains('jpeg') || contentType.contains('jpg')) return '.jpg';
      if (contentType.contains('png')) return '.png';
      if (contentType.contains('gif')) return '.gif';
      if (contentType.contains('webp')) return '.webp';
    }

    final urlPath = Uri.parse(url).path.toLowerCase();
    if (urlPath.endsWith('.png')) return '.png';
    if (urlPath.endsWith('.gif')) return '.gif';
    if (urlPath.endsWith('.webp')) return '.webp';

    return '.jpg';
  }

  void dispose() {
    _client.close();
  }
}
