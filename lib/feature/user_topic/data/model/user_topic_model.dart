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
