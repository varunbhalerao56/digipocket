import 'package:objectbox/objectbox.dart';

enum DigipocketItemType { text, url, image }

@Entity()
class DigipocketItem {
  @Id()
  int id;

  // Core
  @Transient()
  DigipocketItemType contentType;

  @Index()
  int get dbContentType {
    _ensureStableEnumValues();
    return contentType.index;
  }

  set dbContentType(int value) {
    _ensureStableEnumValues();
    if (value >= 0 && value < DigipocketItemType.values.length) {
      contentType = DigipocketItemType.values[value];
    } else {
      contentType = DigipocketItemType.text; // fallback to default
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

  DigipocketItem({
    this.id = 0,
    this.contentType = DigipocketItemType.text,
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
    assert(DigipocketItemType.text.index == 0);
    assert(DigipocketItemType.url.index == 1);
    assert(DigipocketItemType.image.index == 2);
  }
}

@Entity()
class UserTopic {
  @Id()
  int id;

  // Core
  @Unique()
  @Index()
  String name;

  String? description;

  int createdAt;
  int? updatedAt;

  @Index()
  bool isActive; // <-- Add this

  // Vector for semantic matching
  @Property(type: PropertyType.floatVector)
  List<double>? embedding;

  // Optional: Color/icon for UI
  String? color;
  String? icon;

  // Stats
  int itemCount;

  UserTopic({
    this.id = 0,
    required this.name,
    this.description,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true, // <-- Default to active
    this.embedding,
    this.color,
    this.icon,
    this.itemCount = 0,
  });
}
