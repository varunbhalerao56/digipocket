// ignore_for_file: unnecessary_string_escapes

import 'dart:convert';
import 'dart:typed_data';
import 'package:charset/charset.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

/// Robust link metadata extractor with:
/// - Proper charset detection/decoding (EUC-JP, Shift-JIS, etc.)
/// - Platform-specific handlers (YouTube, Reddit, Instagram, TikTok)
/// - Fallback HTML scraping
class LinkExtractor {
  final http.Client _client;
  final Duration _timeout;

  LinkExtractor({http.Client? client, Duration timeout = const Duration(seconds: 10)})
    : _client = client ?? http.Client(),
      _timeout = timeout;

  static const String _linkPreviewApiKey = ''; // This feature is optional and can be left empty

  /// Main entry point - extracts metadata from any URL
  Future<LinkMetadata> extractMetadata(String url) async {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();

      // Try platform-specific handlers first
      final platformResult = await _tryPlatformHandler(url, host);
      if (platformResult != null && platformResult.hasAnyMetadata) {
        print('✅ Platform handler succeeded for: $host');
        return platformResult;
      }

      // Fall back to HTML scraping with proper encoding
      print('📄 Falling back to HTML scraping for: $url');
      final scrapeResult = await _scrapeHtml(url);
      if (scrapeResult.hasTitle || scrapeResult.hasDescription || _linkPreviewApiKey.isEmpty) {
        return scrapeResult;
      }

      // Final fallback: LinkPreview API
      print('🌐 Falling back to LinkPreview API for: $url');
      return await _fetchFromLinkPreviewApi(url);
    } catch (e) {
      print('❌ Error extracting metadata: $e');
      return LinkMetadata.empty();
    }
  }

  // ============================================================
  // LINKPREVIEW API FALLBACK
  // ============================================================

  Future<LinkMetadata> _fetchFromLinkPreviewApi(String url) async {
    try {
      final encodedUrl = Uri.encodeComponent(url);
      final apiUrl = 'https://api.linkpreview.net/?q=$encodedUrl';

      final response = await _client
          .get(Uri.parse(apiUrl), headers: {'X-Linkpreview-Api-Key': _linkPreviewApiKey})
          .timeout(_timeout);

      if (response.statusCode != 200) {
        print('⚠️ LinkPreview API failed: ${response.statusCode}');
        return LinkMetadata.empty();
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      // Check for API error
      if (data.containsKey('error')) {
        print('⚠️ LinkPreview API error: ${data['error']}');
        return LinkMetadata.empty();
      }

      return LinkMetadata(
        title: data['title'] as String?,
        description: data['description'] as String?,
        imageUrl: data['image'] as String?,
      );
    } catch (e) {
      print('❌ LinkPreview API exception: $e');
      return LinkMetadata.empty();
    }
  }

  /// Routes to appropriate platform handler
  Future<LinkMetadata?> _tryPlatformHandler(String url, String host) async {
    try {
      if (_isYouTube(host)) {
        return await _extractYouTube(url);
      } else if (_isReddit(host)) {
        return await _extractReddit(url);
      } else if (_isInstagram(host)) {
        return await _extractInstagram(url);
      } else if (_isTikTok(host)) {
        return await _extractTikTok(url);
      }
    } catch (e) {
      print('⚠️ Platform handler failed: $e');
    }
    return null;
  }

  // ============================================================
  // PLATFORM DETECTION
  // ============================================================

  bool _isYouTube(String host) =>
      host.contains('youtube.com') || host.contains('youtu.be') || host.contains('youtube-nocookie.com');

  bool _isReddit(String host) => host.contains('reddit.com') || host.contains('redd.it');

  bool _isInstagram(String host) => host.contains('instagram.com');

  bool _isTikTok(String host) => host.contains('tiktok.com') || host.contains('vm.tiktok.com');

  // ============================================================
  // YOUTUBE HANDLER
  // ============================================================

  Future<LinkMetadata> _extractYouTube(String url) async {
    print('🎬 Using YouTube handler');

    // Use noembed.com (free, no auth, reliable)
    final oembedUrl = 'https://noembed.com/embed?url=${Uri.encodeComponent(url)}';

    final response = await _client.get(Uri.parse(oembedUrl)).timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('YouTube oEmbed failed: ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;

    // Check for error
    if (data.containsKey('error')) {
      throw Exception('YouTube oEmbed error: ${data['error']}');
    }

    return LinkMetadata(
      title: data['title'] as String?,
      description: data['author_name'] != null ? 'By ${data['author_name']}' : null,
      imageUrl: data['thumbnail_url'] as String?,
    );
  }

  // ============================================================
  // REDDIT HANDLER
  // ============================================================
  Future<LinkMetadata> _extractReddit(String url) async {
    print('🔴 Using Reddit handler');

    String resolvedUrl = url;

    // Handle Reddit share links (/r/subreddit/s/xxxxx)
    if (url.contains('/s/')) {
      print('🔗 Detected Reddit share link, resolving...');
      final resolved = await _resolveRedirect(url);
      if (resolved != null) {
        resolvedUrl = resolved;
        print('🔗 Resolved to: $resolvedUrl');
      } else {
        throw Exception('Failed to resolve Reddit share link');
      }
    }

    // Handle redd.it short links
    if (resolvedUrl.contains('redd.it')) {
      final resolved = await _resolveRedirect(resolvedUrl);
      if (resolved != null) {
        resolvedUrl = resolved;
      }
    }

    // Clean up URL for JSON endpoint
    final uri = Uri.parse(resolvedUrl);
    String path = uri.path;

    // Remove trailing slash
    if (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }

    // Remove existing .json if present
    if (path.endsWith('.json')) {
      path = path.substring(0, path.length - 5);
    }

    // Remove query params that break JSON endpoint
    final jsonUrl = 'https://www.reddit.com$path.json';

    print('🔴 Fetching: $jsonUrl');

    final response = await _client
        .get(Uri.parse(jsonUrl), headers: {'User-Agent': 'Mozilla/5.0 (compatible; LinkPreview/1.0)'})
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('Reddit API failed: ${response.statusCode}');
    }

    // Verify we got JSON, not HTML
    final body = response.body.trim();
    if (body.startsWith('<!') || body.startsWith('<html')) {
      throw Exception('Reddit returned HTML instead of JSON');
    }

    final data = json.decode(body);

    // Reddit returns an array for post pages
    if (data is List && data.isNotEmpty) {
      final postData = data[0]['data']['children'][0]['data'] as Map<String, dynamic>;

      String? imageUrl;

      // Try to get preview image
      if (postData['preview'] != null) {
        final images = postData['preview']['images'] as List?;
        if (images != null && images.isNotEmpty) {
          imageUrl = images[0]['source']['url'] as String?;
          // Reddit HTML encodes the URL
          imageUrl = imageUrl?.replaceAll('&amp;', '&');
        }
      }

      // Fallback to thumbnail
      imageUrl ??= postData['thumbnail'] as String?;
      if (imageUrl == 'self' || imageUrl == 'default' || imageUrl == 'nsfw') {
        imageUrl = null;
      }

      final subreddit = postData['subreddit'] as String?;
      final selftext = postData['selftext'] as String?;

      String? description;
      if (selftext != null && selftext.isNotEmpty) {
        // Truncate long selftext
        description = selftext.length > 200 ? '${selftext.substring(0, 200)}...' : selftext;
      }
      description ??= subreddit != null ? 'r/$subreddit' : null;

      return LinkMetadata(title: postData['title'] as String?, description: description, imageUrl: imageUrl);
    }

    // Subreddit page (not a post)
    if (data is Map && data['data'] != null) {
      final about = data['data'] as Map<String, dynamic>;
      return LinkMetadata(
        title: about['display_name_prefixed'] as String? ?? about['title'] as String?,
        description: about['public_description'] as String?,
        imageUrl: about['icon_img'] as String?,
      );
    }

    throw Exception('Unexpected Reddit response format');
  }

  // ============================================================
  // INSTAGRAM HANDLER
  // ============================================================

  Future<LinkMetadata> _extractInstagram(String url) async {
    print('📸 Using Instagram handler');

    // Instagram oEmbed requires app credentials now, but we can try
    // the public endpoint which sometimes works
    final oembedUrl = 'https://api.instagram.com/oembed?url=${Uri.encodeComponent(url)}';

    try {
      final response = await _client.get(Uri.parse(oembedUrl)).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        return LinkMetadata(
          title: data['title'] as String?,
          description: data['author_name'] != null ? 'By @${data['author_name']}' : null,
          imageUrl: data['thumbnail_url'] as String?,
        );
      }
    } catch (e) {
      print('⚠️ Instagram oEmbed failed, trying noembed: $e');
    }

    // Fallback to noembed
    final noembedUrl = 'https://noembed.com/embed?url=${Uri.encodeComponent(url)}';
    final response = await _client.get(Uri.parse(noembedUrl)).timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('Instagram noembed failed: ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;

    if (data.containsKey('error')) {
      throw Exception('Instagram noembed error: ${data['error']}');
    }

    return LinkMetadata(
      title: data['title'] as String?,
      description: data['author_name'] != null ? 'By @${data['author_name']}' : null,
      imageUrl: data['thumbnail_url'] as String?,
    );
  }

  // ============================================================
  // TIKTOK HANDLER
  // ============================================================

  Future<LinkMetadata> _extractTikTok(String url) async {
    print('🎵 Using TikTok handler');

    // TikTok has a public oEmbed endpoint
    final oembedUrl = 'https://www.tiktok.com/oembed?url=${Uri.encodeComponent(url)}';

    final response = await _client.get(Uri.parse(oembedUrl)).timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('TikTok oEmbed failed: ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;

    return LinkMetadata(
      title: data['title'] as String?,
      description: data['author_name'] != null ? 'By @${data['author_name']}' : null,
      imageUrl: data['thumbnail_url'] as String?,
    );
  }

  // ============================================================
  // HTML SCRAPING WITH CHARSET SUPPORT
  // ============================================================

  Future<LinkMetadata> _scrapeHtml(String url) async {
    final response = await _client
        .get(
          Uri.parse(url),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.9,ja;q=0.8,zh;q=0.7',
          },
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      print('Non-200 status code: ${response.statusCode}');
      return LinkMetadata.empty();
    }

    // Decode with proper charset
    final html = _decodeResponse(response);

    return _parseHtml(html, url);
  }

  /// Decodes HTTP response with proper charset detection
  String _decodeResponse(http.Response response) {
    final bytes = response.bodyBytes;

    // 1. Try Content-Type header
    String? charset = _getCharsetFromContentType(response.headers['content-type']);

    // 2. Try to detect from HTML meta tag (peek at bytes)
    charset ??= _detectCharsetFromHtml(bytes);

    // 3. Default to UTF-8
    charset ??= 'utf-8';

    print('📝 Using charset: $charset');

    return _decodeBytes(bytes, charset);
  }

  /// Extracts charset from Content-Type header
  String? _getCharsetFromContentType(String? contentType) {
    if (contentType == null) return null;

    // Parse: text/html; charset=utf-8
    final regex = RegExp(r'charset=([^\s;]+)', caseSensitive: false);
    final match = regex.firstMatch(contentType);
    return match?.group(1)?.toLowerCase();
  }

  /// Tries to detect charset from HTML meta tags
  /// Tries to detect charset from HTML meta tags
  /// Tries to detect charset from HTML meta tags
  String? _detectCharsetFromHtml(Uint8List bytes) {
    try {
      // Only look at first 1024 bytes for meta tags
      final preview = bytes.length > 1024 ? bytes.sublist(0, 1024) : bytes;

      // Try to decode as ASCII (safe for finding meta tags)
      final previewStr = String.fromCharCodes(preview);

      // Pattern 1: <meta charset="xxx">
      final charsetPattern = RegExp('<meta\\s+charset=["\']?([^"\'>\s]+)', caseSensitive: false);
      final match1 = charsetPattern.firstMatch(previewStr);
      if (match1 != null) {
        return match1.group(1)?.toLowerCase();
      }

      // Pattern 2: charset=xxx (in content-type meta)
      final contentTypePattern = RegExp('charset=([^"\'>\s;]+)', caseSensitive: false);
      final match2 = contentTypePattern.firstMatch(previewStr);
      if (match2 != null) {
        return match2.group(1)?.toLowerCase();
      }
    } catch (e) {
      print('⚠️ Error detecting charset from HTML: $e');
    }
    return null;
  }

  /// Decodes bytes using the specified charset
  String _decodeBytes(Uint8List bytes, String charset) {
    charset = _normalizeCharsetName(charset);

    try {
      switch (charset) {
        // Japanese
        case 'euc-jp':
        case 'eucjp':
          return eucJp.decode(bytes);

        case 'shift-jis':
        case 'shift_jis':
        case 'shiftjis':
        case 'sjis':
        case 'x-sjis':
          return shiftJis.decode(bytes);

        // Korean
        case 'euc-kr':
        case 'euckr':
          return eucKr.decode(bytes);

        // Chinese
        case 'gbk':
        case 'gb2312':
        case 'gb18030':
          return gbk.decode(bytes);

        // Western
        case 'iso-8859-1':
        case 'latin1':
        case 'latin-1':
          return latin1.decode(bytes);

        case 'iso-8859-2':
        case 'latin2':
          return latin2.decode(bytes);

        case 'iso-8859-15':
        case 'latin9':
          return latin9.decode(bytes);

        // UTF variants
        case 'utf-16':
        case 'utf16':
          return utf16.decode(bytes);

        case 'utf-16le':
          return utf16.decode(bytes); // charset package handles BOM

        case 'utf-16be':
          return utf16.decode(bytes); // charset package handles BOM

        // Default to UTF-8
        case 'utf-8':
        case 'utf8':
        default:
          return utf8.decode(bytes, allowMalformed: true);
      }
    } catch (e) {
      print('⚠️ Decoding failed for $charset, falling back to UTF-8: $e');
      return utf8.decode(bytes, allowMalformed: true);
    }
  }

  /// Normalizes charset name for matching
  String _normalizeCharsetName(String charset) {
    return charset.toLowerCase().replaceAll(' ', '').replaceAll('_', '-');
  }

  /// Parses HTML and extracts metadata
  LinkMetadata _parseHtml(String html, String url) {
    final document = html_parser.parse(html);

    // Try Open Graph first
    String? title = document.querySelector('meta[property="og:title"]')?.attributes['content'];
    String? description = document.querySelector('meta[property="og:description"]')?.attributes['content'];
    String? imageUrl = document.querySelector('meta[property="og:image"]')?.attributes['content'];

    // Twitter Card fallback
    title ??= document.querySelector('meta[name="twitter:title"]')?.attributes['content'];
    description ??= document.querySelector('meta[name="twitter:description"]')?.attributes['content'];
    imageUrl ??= document.querySelector('meta[name="twitter:image"]')?.attributes['content'];

    // Standard HTML fallback
    title ??= document.querySelector('title')?.text;
    description ??= document.querySelector('meta[name="description"]')?.attributes['content'];

    // Try favicon if no image
    imageUrl ??= document.querySelector('link[rel="icon"]')?.attributes['href'];
    imageUrl ??= document.querySelector('link[rel="shortcut icon"]')?.attributes['href'];
    imageUrl ??= document.querySelector('link[rel="apple-touch-icon"]')?.attributes['href'];

    // Make relative URLs absolute
    imageUrl = _makeAbsoluteUrl(imageUrl, url);

    return LinkMetadata(title: _cleanText(title), description: _cleanText(description), imageUrl: _cleanText(imageUrl));
  }

  /// Makes a relative URL absolute
  String? _makeAbsoluteUrl(String? imageUrl, String baseUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }

    try {
      final uri = Uri.parse(baseUrl);
      if (imageUrl.startsWith('//')) {
        return '${uri.scheme}:$imageUrl';
      } else if (imageUrl.startsWith('/')) {
        return '${uri.scheme}://${uri.host}$imageUrl';
      } else {
        return '${uri.scheme}://${uri.host}/$imageUrl';
      }
    } catch (e) {
      return imageUrl;
    }
  }

  /// Cleans and trims text
  String? _cleanText(String? text) {
    if (text == null) return null;
    final cleaned = text.trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  /// Resolves a redirect URL to its final destination
  Future<String?> _resolveRedirect(String url) async {
    try {
      final request = http.Request('GET', Uri.parse(url));
      request.followRedirects = false;

      final client = http.Client();
      final response = await client.send(request).timeout(_timeout);
      client.close();

      if (response.statusCode >= 300 && response.statusCode < 400) {
        return response.headers['location'];
      }
    } catch (e) {
      print('⚠️ Failed to resolve redirect: $e');
    }
    return null;
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
