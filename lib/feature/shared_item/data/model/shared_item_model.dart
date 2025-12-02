import 'package:objectbox/objectbox.dart';
import 'package:path/path.dart' as path;

enum SharedItemType {
  text,
  url,
  image;

  @override
  String toString() {
    switch (this) {
      case SharedItemType.text:
        return 'Text';
      case SharedItemType.url:
        return 'URL';
      case SharedItemType.image:
        return 'Image';
    }
  }
}

@Entity()
class SharedItem {
  @Id()
  int id;

  // Core
  @Transient()
  SharedItemType contentType;

  @Index()
  int get dbContentType {
    _ensureStableEnumValues();
    return contentType.index;
  }

  set dbContentType(int value) {
    _ensureStableEnumValues();
    if (value >= 0 && value < SharedItemType.values.length) {
      contentType = SharedItemType.values[value];
    } else {
      contentType = SharedItemType.text; // fallback to default
    }
  }

  @Index()
  int createdAt;
  int? updatedAt;
  int schemaVersion;

  // User flags
  @Index()
  bool isFavorite;
  @Index()
  bool isArchived;

  // Source
  String? sourceApp;

  // Vector & AI (we'll use these later)
  @HnswIndex(dimensions: 768, distanceType: VectorDistanceType.cosine, indexingSearchCount: 300, neighborsPerNode: 64)
  @Property(type: PropertyType.floatVector)
  List<double>? vectorEmbedding;
  List<String>? generatedTags;
  String? summary;
  double? summaryConfidence;
  double? tagConfidence;
  List<String>? userTags;

  @HnswIndex(dimensions: 768, distanceType: VectorDistanceType.cosine, indexingSearchCount: 300, neighborsPerNode: 64)
  @Property(type: PropertyType.floatVector)
  List<double>? userCaptionEmbedding;

  String? userCaption;

  // Content
  String? text;
  String? url;
  String? imagePath;
  String? ocrText;
  String? checksum;

  // URL metadata
  @Index()
  String? domain;
  String? urlTitle;
  String? urlDescription;
  String? urlThumbnailPath;
  String? urlFaviconPath;

  // Image metadata
  String? fileType;

  SharedItem({
    this.id = 0,
    this.contentType = SharedItemType.text,
    required this.createdAt,
    this.updatedAt,
    this.schemaVersion = 1,
    this.isFavorite = false,
    this.isArchived = false,
    this.sourceApp,
    this.vectorEmbedding,
    this.generatedTags,
    this.summary,
    this.summaryConfidence,
    this.tagConfidence,
    this.userTags,
    this.text,
    this.url,
    this.imagePath,
    this.ocrText,
    this.checksum,
    this.domain,
    this.urlTitle,
    this.urlDescription,
    this.urlThumbnailPath,
    this.urlFaviconPath,
    this.fileType,
    this.userCaption,
    this.userCaptionEmbedding,
  });

  void _ensureStableEnumValues() {
    assert(SharedItemType.text.index == 0);
    assert(SharedItemType.url.index == 1);
    assert(SharedItemType.image.index == 2);
  }
}

extension SharedItemJson on SharedItem {
  /// Convert SharedItem to JSON map (for export)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contentType': contentType.index,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'schemaVersion': schemaVersion,
      'isFavorite': isFavorite,
      'isArchived': isArchived,
      'sourceApp': sourceApp,
      'vectorEmbedding': vectorEmbedding,
      'generatedTags': generatedTags,
      'summary': summary,
      'summaryConfidence': summaryConfidence,
      'tagConfidence': tagConfidence,
      'userTags': userTags,
      'userCaptionEmbedding': userCaptionEmbedding,
      'userCaption': userCaption,
      'text': text,
      'url': url,
      'imagePath': imagePath != null ? path.basename(imagePath!) : null,
      'ocrText': ocrText,
      'checksum': checksum,
      'domain': domain,
      'urlTitle': urlTitle,
      'urlDescription': urlDescription,
      'urlThumbnailPath': urlThumbnailPath != null ? path.basename(urlThumbnailPath!) : null,
      'urlFaviconPath': urlFaviconPath != null ? path.basename(urlFaviconPath!) : null,
      'fileType': fileType,
    };
  }

  /// Create SharedItem from JSON map (for import)
  static SharedItem fromJson(Map<String, dynamic> json, String imagesBasePath) {
    // Reconstruct full paths for images
    String? fullImagePath;
    if (json['imagePath'] != null) {
      fullImagePath = '$imagesBasePath/${json['imagePath']}';
    }

    String? fullThumbnailPath;
    if (json['urlThumbnailPath'] != null) {
      fullThumbnailPath = '$imagesBasePath/${json['urlThumbnailPath']}';
    }

    String? fullFaviconPath;
    if (json['urlFaviconPath'] != null) {
      fullFaviconPath = '$imagesBasePath/${json['urlFaviconPath']}';
    }

    return SharedItem(
      id: json['id'] ?? 0,
      contentType: SharedItemType.values[json['contentType'] ?? 0],
      createdAt: json['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      updatedAt: json['updatedAt'],
      schemaVersion: json['schemaVersion'] ?? 1,
      isFavorite: json['isFavorite'] ?? false,
      isArchived: json['isArchived'] ?? false,
      sourceApp: json['sourceApp'],
      vectorEmbedding: json['vectorEmbedding'] != null ? List<double>.from(json['vectorEmbedding']) : null,
      generatedTags: json['generatedTags'] != null ? List<String>.from(json['generatedTags']) : null,
      summary: json['summary'],
      summaryConfidence: json['summaryConfidence']?.toDouble(),
      tagConfidence: json['tagConfidence']?.toDouble(),
      userTags: json['userTags'] != null ? List<String>.from(json['userTags']) : null,
      userCaptionEmbedding: json['userCaptionEmbedding'] != null
          ? List<double>.from(json['userCaptionEmbedding'])
          : null,
      userCaption: json['userCaption'],
      text: json['text'],
      url: json['url'],
      imagePath: fullImagePath,
      ocrText: json['ocrText'],
      checksum: json['checksum'],
      domain: json['domain'],
      urlTitle: json['urlTitle'],
      urlDescription: json['urlDescription'],
      urlThumbnailPath: fullThumbnailPath,
      urlFaviconPath: fullFaviconPath,
      fileType: json['fileType'],
    );
  }
}
