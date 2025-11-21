import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

class LinkExtractor {
  final http.Client _client;

  LinkExtractor({http.Client? client}) : _client = client ?? http.Client();

  /// Extracts title and description from a URL
  Future<LinkMetadata> extractMetadata(String url) async {
    try {
      print('Fetching: $url');

      final response = await _client
          .get(
            Uri.parse(url),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1',
              'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
              'Accept-Language': 'en-US,en;q=0.9',
            },
          )
          .timeout(
            const Duration(seconds: 5), // Increased timeout
          );

      print('Status code: ${response.statusCode}');

      if (response.statusCode != 200) {
        print('Non-200 status code: ${response.statusCode}');
        return LinkMetadata.empty();
      }

      final document = html_parser.parse(response.body);

      // Debug: Print raw meta tags
      print('Looking for meta tags...');

      // Try to extract Open Graph metadata first (most reliable)
      String? title = document.querySelector('meta[property="og:title"]')?.attributes['content'];
      print('OG Title: $title');

      String? description = document.querySelector('meta[property="og:description"]')?.attributes['content'];
      print('OG Description: $description');

      // Fallback to Twitter Card metadata
      title ??= document.querySelector('meta[name="twitter:title"]')?.attributes['content'];
      print('Twitter Title: $title');

      description ??= document.querySelector('meta[name="twitter:description"]')?.attributes['content'];
      print('Twitter Description: $description');

      // Fallback to standard HTML title tag
      title ??= document.querySelector('title')?.text;
      print('HTML Title: $title');

      // Fallback to standard meta description
      description ??= document.querySelector('meta[name="description"]')?.attributes['content'];
      print('Meta Description: $description');

      // Extract favicon/icon
      String? imageUrl = document.querySelector('meta[property="og:image"]')?.attributes['content'];

      imageUrl ??= document.querySelector('meta[name="twitter:image"]')?.attributes['content'];

      imageUrl ??= document.querySelector('link[rel="icon"]')?.attributes['href'];

      imageUrl ??= document.querySelector('link[rel="shortcut icon"]')?.attributes['href'];

      // Clean up extracted text
      title = _cleanText(title);
      description = _cleanText(description);
      imageUrl = _cleanText(imageUrl);

      // Make relative image URLs absolute
      if (imageUrl != null && !imageUrl.startsWith('http')) {
        final uri = Uri.parse(url);
        if (imageUrl.startsWith('//')) {
          imageUrl = '${uri.scheme}:$imageUrl';
        } else if (imageUrl.startsWith('/')) {
          imageUrl = '${uri.scheme}://${uri.host}$imageUrl';
        } else {
          imageUrl = '${uri.scheme}://${uri.host}/${imageUrl}';
        }
      }

      print('Final - Title: $title, Description: $description');

      return LinkMetadata(title: title, description: description, imageUrl: imageUrl);
    } catch (e) {
      print('Error extracting link metadata: $e');
      return LinkMetadata.empty();
    }
  }

  /// Cleans and trims text, returns null if empty
  String? _cleanText(String? text) {
    if (text == null) return null;
    final cleaned = text.trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  /// Closes the HTTP client
  void dispose() {
    _client.close();
  }
}

/// Metadata extracted from a link
class LinkMetadata {
  final String? title;
  final String? description;
  final String? imageUrl;

  LinkMetadata({this.title, this.description, this.imageUrl});

  /// Creates an empty metadata object
  factory LinkMetadata.empty() {
    return LinkMetadata(title: null, description: null, imageUrl: null);
  }

  bool get hasTitle => title != null && title!.isNotEmpty;
  bool get hasDescription => description != null && description!.isNotEmpty;
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasAnyMetadata => hasTitle || hasDescription || hasImage;

  /// Combines title and description for embedding generation
  String? get combinedText {
    final parts = [title, description].where((s) => s != null && s.isNotEmpty);
    return parts.isEmpty ? null : parts.join(' ');
  }

  @override
  String toString() {
    return 'LinkMetadata(title: $title, description: $description, imageUrl: $imageUrl)';
  }
}
