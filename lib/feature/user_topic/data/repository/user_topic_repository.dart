import 'package:digipocket/feature/fonnex/fonnex.dart';
import 'package:digipocket/feature/shared_item/data/isolates/shared_item_isolate.dart';
import 'package:digipocket/feature/user_topic/user_topic.dart';
import 'package:digipocket/global/services/glove_service.dart';

class UserTopicRepository {
  final UserTopicDb database;
  // final FonnexEmbeddingRepository embeddingRepository;
  final EmbeddingIsolateManager embeddingIsolateManager;

  UserTopicRepository({required this.database, required this.embeddingIsolateManager});

  Future<void> processNewTopic(UserTopic topic) async {
    try {
      // Generate embedding for the topic
      // Combine name + description for richer semantic representation

      final gloveService = GloveService();
      await gloveService.initialize();

      final gloveInput = topic.description != null ? '${topic.name} ${topic.description}' : topic.name;

      final expandedText = gloveService.expandTopic(gloveInput, maxRelated: 5, minSimilarity: 0.75);
      gloveService.dispose();

      print('📝 Expanded "${topic.name}" → "$expandedText"');

      final embedding = await embeddingIsolateManager.generateTextEmbedding(
        expandedText, // Already includes original words + related
        task: NomicTask.searchDocument,
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
}
