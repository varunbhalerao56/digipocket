import 'package:objectbox/objectbox.dart';

enum SharedItemType { text, url, image }

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
  @Property(type: PropertyType.floatVector)
  List<double>? vectorEmbedding;
  List<String>? generatedTags;
  String? summary;
  double? summaryConfidence;
  double? tagConfidence;
  List<String>? userTags;

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
  });

  void _ensureStableEnumValues() {
    assert(SharedItemType.text.index == 0);
    assert(SharedItemType.url.index == 1);
    assert(SharedItemType.image.index == 2);
  }
}
