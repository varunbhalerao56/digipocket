import 'package:objectbox/objectbox.dart';

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
  @HnswIndex(dimensions: 768, distanceType: VectorDistanceType.cosine)
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

extension UserTopicJson on UserTopic {
  /// Convert UserTopic to JSON map (for export)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isActive': isActive,
      'embedding': embedding,
      'color': color,
      'icon': icon,
      'itemCount': itemCount,
    };
  }

  /// Create UserTopic from JSON map (for import)
  static UserTopic fromJson(Map<String, dynamic> json) {
    return UserTopic(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      createdAt: json['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      updatedAt: json['updatedAt'],
      isActive: json['isActive'] ?? true,
      embedding: json['embedding'] != null ? List<double>.from(json['embedding']) : null,
      color: json['color'],
      icon: json['icon'],
      itemCount: json['itemCount'] ?? 0,
    );
  }
}
