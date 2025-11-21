import 'dart:math';
import 'package:digipocket/feature/shared_item/shared_item.dart';
import 'package:digipocket/feature/user_topic/user_topic.dart';

class TopicMatchResult {
  final List<String> autoTags;
  final List<TopicMatchDetail> details;

  TopicMatchResult({required this.autoTags, required this.details});
}

class TopicMatchDetail {
  final String topicName;

  /// The raw Cosine Distance between the item and the topic.
  ///
  /// Range: 0.0 to 2.0
  /// * 0.0: Identical (Best Match)
  /// * ~0.3: Contextually Similar
  /// * 1.0: Unrelated
  /// * 2.0: Opposite
  final double distance;

  TopicMatchDetail(this.topicName, this.distance);
}

class TopicMatcher {
  // Thresholds for Nomic v1.5 (Lower distance = stricter match)
  // Text is precise; Images have a "modality gap" so we allow more distance.
  final double textThreshold;
  final double imageThreshold;

  TopicMatcher({this.textThreshold = 0.50, this.imageThreshold = 0.99});

  Future<TopicMatchResult> matchTopics(
    List<double> itemEmbedding,
    List<UserTopic> activeTopics,
    SharedItemType itemType,
  ) async {
    final double threshold = itemType == SharedItemType.image ? imageThreshold : textThreshold;

    print("thresh is $threshold");
    final List<TopicMatchDetail> matches = [];

    print('Calculating distance to topics with threshold $threshold for item type ${itemType.name}');

    for (final topic in activeTopics) {
      if (topic.embedding == null || topic.embedding!.isEmpty) continue;
      final double dist = _calculateCosineDistance(itemEmbedding, topic.embedding!);

      // Filter using raw distance: smaller is better
      if (dist <= threshold) {
        print('  ✅ Distance to topic "${topic.name}": $dist allowed');

        matches.add(TopicMatchDetail(topic.name, dist));
      } else {
        print('  ❌ Distance to topic "${topic.name}": $dist exceeds threshold $threshold');
      }
    }

    // Sort ASCENDING: Smallest distance (closest match) goes first
    matches.sort((a, b) => a.distance.compareTo(b.distance));

    final List<String> tagNames = matches.map((e) => e.topicName).toList();

    return TopicMatchResult(autoTags: tagNames, details: matches);
  }

  double _calculateCosineDistance(List<double> vecA, List<double> vecB) {
    if (vecA.length != vecB.length) throw Exception('Vector mismatch');

    double dot = 0.0, normA = 0.0, normB = 0.0;

    for (int i = 0; i < vecA.length; i++) {
      dot += vecA[i] * vecB[i];
      normA += vecA[i] * vecA[i];
      normB += vecB[i] * vecB[i];
    }

    if (normA == 0 || normB == 0) return 2.0; // Max distance if empty

    // Cosine Similarity = Dot / (MagA * MagB)
    final double similarity = dot / (sqrt(normA) * sqrt(normB));

    // Cosine Distance = 1.0 - Similarity
    return 1.0 - similarity;
  }
}
