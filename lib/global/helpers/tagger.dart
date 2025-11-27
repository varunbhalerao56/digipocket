import 'dart:math';
import 'package:digipocket/feature/shared_item/shared_item.dart';
import 'package:digipocket/feature/user_topic/user_topic.dart';
import 'package:digipocket/main.dart';

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
  final double textThreshold;
  final double imageThreshold;
  final double combinedThreshold;
  final double relativeMargin;

  TopicMatcher({
    this.textThreshold = kdefaultTextEmbeddingMatcher,
    this.imageThreshold = kdefaultImageEmbeddingMatcher,
    this.combinedThreshold = kdefaultCombinedEmbeddingMatcher,
    this.relativeMargin = 0.05,
  });

  Future<TopicMatchResult> matchTopics(
    List<double> primaryEmbedding,
    List<UserTopic> activeTopics,
    SharedItemType itemType, {
    List<double>? secondaryEmbedding,
  }) async {
    final bool useCombined = secondaryEmbedding != null && secondaryEmbedding.isNotEmpty;
    final double threshold = useCombined
        ? combinedThreshold
        : (itemType == SharedItemType.image ? imageThreshold : textThreshold);

    // Calculate all distances
    final List<TopicMatchDetail> allScores = [];

    print('=== Topic Matching Details ===');
    print('Text Threshold: $textThreshold, Image Threshold: $imageThreshold, Combined Threshold: $combinedThreshold');

    print('=============');

    for (final topic in activeTopics) {
      if (topic.embedding == null || topic.embedding!.isEmpty) continue;

      double finalDistance;

      if (useCombined) {
        final imageDist = _calculateCosineDistance(primaryEmbedding, topic.embedding!);
        print('${passOrFail(imageDist, imageThreshold)} Primary distance to topic "${topic.name}": $imageDist');
        final textDist = _calculateCosineDistance(secondaryEmbedding, topic.embedding!);
        print('${passOrFail(textDist, textThreshold)} Secondary distance to topic "${topic.name}": $textDist');

        finalDistance = (0.4 * imageDist) + (0.6 * textDist);

        final absoluteDiff = (finalDistance - combinedThreshold).abs();

        print(
          '${passOrFail(finalDistance, combinedThreshold)} Combined distance to topic "${topic.name}": $finalDistance',
        );

        if (passOrFailBool(imageDist, imageThreshold) &&
            passOrFailBool(textDist, textThreshold) &&
            absoluteDiff <= 0.32) {
          finalDistance = finalDistance * 0.94;
          print('🔵 Adjusted combined distance due to both embeddings passing thresholds and being close enough');
          print(
            '${passOrFail(finalDistance, combinedThreshold)} Combined distance to topic "${topic.name}": $finalDistance',
          );
        }
      } else {
        finalDistance = _calculateCosineDistance(primaryEmbedding, topic.embedding!);
        print('${passOrFail(finalDistance, textThreshold)} Distance to topic "${topic.name}": $finalDistance');
      }

      allScores.add(TopicMatchDetail(topic.name, finalDistance));
      print('=============');
    }

    // Sort by distance (best first)
    allScores.sort((a, b) => a.distance.compareTo(b.distance));

    if (allScores.isEmpty) {
      return TopicMatchResult(autoTags: [], details: []);
    }

    final best = allScores.first;
    final List<TopicMatchDetail> matches = [];

    // Best must be within absolute threshold
    if (best.distance > threshold) {
      return TopicMatchResult(autoTags: [], details: allScores);
    }

    // Add best match
    matches.add(best);

    // // Check rest with relative margin
    // for (int i = 1; i < allScores.length; i++) {
    //   final candidate = allScores[i];
    //   final gap = candidate.distance - best.distance;
    //
    //   if (gap <= relativeMargin && candidate.distance <= threshold) {
    //     matches.add(candidate);
    //   }
    // }

    final tagNames = matches.map((e) => e.topicName).toList();
    return TopicMatchResult(autoTags: tagNames, details: allScores);
  }

  String passOrFail(double distance, double threshold) {
    return distance <= threshold ? '✅' : '❌';
  }

  bool passOrFailBool(double distance, double threshold) {
    return distance <= threshold;
  }

  double _calculateCosineDistance(List<double> vecA, List<double> vecB) {
    if (vecA.length != vecB.length) throw Exception('Vector mismatch');

    double dot = 0.0, normA = 0.0, normB = 0.0;

    for (int i = 0; i < vecA.length; i++) {
      dot += vecA[i] * vecB[i];
      normA += vecA[i] * vecA[i];
      normB += vecB[i] * vecB[i];
    }

    if (normA == 0 || normB == 0) return 2.0;

    final double similarity = dot / (sqrt(normA) * sqrt(normB));
    return 1.0 - similarity;
  }
}
