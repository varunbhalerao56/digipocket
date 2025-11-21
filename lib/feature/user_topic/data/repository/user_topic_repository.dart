import 'dart:math';
import 'package:digipocket/feature/fonnex/fonnex.dart';
import 'package:digipocket/feature/user_topic/user_topic.dart';
import 'package:digipocket/main.dart';

class UserTopicRepository {
  final UserTopicDb database;
  final FonnexEmbeddingRepository embeddingRepository;

  UserTopicRepository({required this.database, required this.embeddingRepository});

  Future<void> processNewTopic(UserTopic topic) async {
    try {
      // Generate embedding for the topic
      // Combine name + description for richer semantic representation
      final topicText = topic.description != null ? '${topic.name}: ${topic.description}' : topic.name;

      print('🔄 Generating embedding for topic: ${topic.name}');

      final embedding = await embeddingRepository.generateTextEmbedding(
        topicText,
        task: NomicTask.clustering, // Use clustering task for topics
      );

      topic.embedding = embedding;
      topic.updatedAt = DateTime.now().millisecondsSinceEpoch;

      inputUserTopic(topic);

      print('✅ Topic saved with ${embedding.length}D embedding');
    } catch (e) {
      print('❌ Error processing topic: $e');
      rethrow;
    }
  }

  int inputUserTopic(UserTopic topic) {
    return database.inputUserTopic(topic);
  }

  /// Get all shared items from database
  Future<List<UserTopic>> getAllUserTopics() async {
    return database.getAllUserTopics();
  }

  Future<List<UserTopic>> getAllActiveUserTopics() async {
    return database.getAllActiveUserTopics();
  }

  /// Delete a shared item
  Future<bool> deleteUserTopic(int id) async {
    return database.deleteUserTopic(id);
  }

  Future<List<String>> matchTopics(List<double> itemEmbedding, List<UserTopic> activeTopics) async {
    final matchedTopics = <String>[];
    final threshold = 0.7; // adjust based on testing

    for (var topic in activeTopics) {
      final similarity = cosineSimilarity(itemEmbedding, topic.embedding ?? []);

      if (similarity >= threshold) {
        matchedTopics.add(topic.name);
      }
    }

    return matchedTopics;
  }

  double cosineSimilarity(List<double> a, List<double> b) {
    double dotProduct = 0;
    double normA = 0;
    double normB = 0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    return dotProduct / (sqrt(normA) * sqrt(normB));
  }
}
