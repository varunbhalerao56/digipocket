import 'package:digipocket/feature/fonnex/data/model/fonnex_helper_model.dart';
import 'package:digipocket/feature/shared_item/shared_item.dart';

class SearchRepository {
  final SharedItemRepository sharedItemRepository;
  final EmbeddingIsolateManager embeddingIsolateManager;

  SearchRepository({required this.sharedItemRepository, required this.embeddingIsolateManager});

  Future<List<SharedItem>> searchItems({
    String? searchQuery,
    SharedItemType? typeFilter,
    String? userTopic,
    bool? keywordSearch,
  }) async {
    List<double>? queryEmbedding;

    // Generate embedding if search query exists
    if (searchQuery != null && searchQuery.isNotEmpty) {
      try {
        queryEmbedding = await embeddingIsolateManager.generateTextEmbedding(searchQuery, task: NomicTask.searchQuery);
      } catch (e) {
        print('Error generating search embedding: $e');
        // Continue with keyword-only search
      }
    }

    print('🔍 Performing search with query: "$searchQuery", typeFilter: $typeFilter, userTopic: $userTopic');
    print('🔍 Query embedding: ${queryEmbedding != null ? "Generated (${queryEmbedding.length}D)" : "Not generated"}');

    print(keywordSearch);

    return await sharedItemRepository.searchItems(
      queryEmbedding: queryEmbedding,
      searchQuery: searchQuery,
      typeFilter: typeFilter,
      userTopic: userTopic,
      keywordSearch: keywordSearch,
    );
  }
}
