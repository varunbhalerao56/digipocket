import 'package:digipocket/feature/shared_item/shared_item.dart';
import 'package:digipocket/generated/objectbox.g.dart';

enum SearchMode { smart, exact, both }

class SharedItemDb {
  final Store _store;
  late final Box<SharedItem> _itemBox;

  SharedItemDb(this._store) {
    _itemBox = _store.box<SharedItem>();
  }

  /// Insert a shared item
  int insertSharedItem(SharedItem item) {
    return _itemBox.put(item);
  }

  /// Get all shared items, newest first
  Future<List<SharedItem>> getAllSharedItems() async {
    final query = _itemBox.query().order(SharedItem_.createdAt, flags: Order.descending).build();
    final results = await query.findAsync();
    query.close();
    return results;
  }

  /// Get all where content type matches
  Future<List<SharedItem>> getSharedItemsByType(SharedItemType type) async {
    final query = _itemBox
        .query(SharedItem_.dbContentType.equals(type.index))
        .order(SharedItem_.createdAt, flags: Order.descending)
        .build();
    final results = await query.findAsync();
    query.close();
    return results;
  }

  /// Get all where topic matches
  Future<List<SharedItem>> getSharedItemsByTopic(String topic) async {
    final query = _itemBox
        .query(SharedItem_.userTags.containsElement(topic))
        .order(SharedItem_.createdAt, flags: Order.descending)
        .build();
    final results = await query.findAsync();
    query.close();
    return results;
  }

  /// Get via scores
  Future<List<SharedItem>> getSharedItemsByScores(List<double> scores) async {
    final query = _itemBox
        .query(SharedItem_.vectorEmbedding.nearestNeighborsF32(scores, 100))
        .order(SharedItem_.createdAt, flags: Order.descending)
        .build();
    final results = await query.findWithScores();
    query.close();

    final filteredResults = results.where((element) => element.score <= 0.7).map((e) => e.object).toList();

    return filteredResults;
  }

  Future<List<SharedItem>> searchItems({
    List<double>? queryEmbedding,
    String? keyword,
    SharedItemType? itemType,
    String? userTopic,
    int maxResults = 50, // Reduced default to avoid over-fetching unrelated vectors
    // LOWER distance = Better match.
    // 0.35 is strict (good for text-to-text).
    // 0.45 is loose (good for text-to-image).
    double textMaxDistance = 0.55,
    double imageMaxDistance = 0.95,
  }) async {
    // STEP 1: Apply mandatory filters (type and/or topic)
    final conditions = <Condition<SharedItem>>[];

    if (itemType != null) {
      conditions.add(SharedItem_.dbContentType.equals(itemType.index));
      print('🔍 Applying content type filter: ${itemType.name}');
    }

    if (userTopic != null && userTopic.isNotEmpty) {
      conditions.add(SharedItem_.userTags.containsElement(userTopic));
      print('🔍 Applying user topic filter: $userTopic');
    }

    // ADD THIS DEBUG BLOCK:
    print('🔍 DEBUG: conditions.isNotEmpty = ${conditions.isNotEmpty}');
    print('🔍 DEBUG: queryEmbedding == null = ${queryEmbedding == null}');
    print('🔍 DEBUG: keyword == null = ${keyword == null}');

    // STEP 2: Perform searches
    final semanticResults = <int, SharedItem>{}; // id -> item
    final keywordResults = <int, SharedItem>{}; // id -> item
    final bothResults = <SharedItem>[];
    final semanticOnlyResults = <SharedItem>[];
    final keywordOnlyResults = <SharedItem>[];

    // ---------------------------------------------------------
    // A. Semantic Search (Vector / Embedding)
    // ---------------------------------------------------------
    if (queryEmbedding != null && queryEmbedding.isNotEmpty) {
      // Search both vectorEmbedding and userCaptionEmbedding
      final vectorSearchResults = <int, SharedItem>{};
      final captionSearchResults = <int, SharedItem>{};

      // A1. Search vectorEmbedding
      // Note: We ask ObjectBox for slightly more neighbors than we need
      // because we might filter some out based on dynamic thresholds.
      QueryBuilder<SharedItem> queryBuilder = _itemBox.query(
        SharedItem_.vectorEmbedding.nearestNeighborsF32(queryEmbedding, maxResults + 20),
      );

      if (conditions.isNotEmpty) {
        final filterCondition = conditions.reduce((a, b) => a & b);
        // Re-apply neighbors clause AND filter
        queryBuilder = _itemBox.query(
          filterCondition & SharedItem_.vectorEmbedding.nearestNeighborsF32(queryEmbedding, maxResults + 20),
        );
      }

      final query = queryBuilder.build();
      // findWithScores returns { object, score (distance) }
      final results = await query.findWithScoresAsync();
      query.close();

      print('🔍 Semantic search (vectorEmbedding) found ${results.length} raw candidates');

      for (final result in results) {
        final item = result.object;
        final distance = result.score; // ObjectBox Score = Cosine Distance (0.0 - 2.0)

        // DYNAMIC THRESHOLD LOGIC
        // If the item is an Image, we allow a larger distance (looser match)
        // because of the Nomic "Modality Gap".
        final double threshold = (item.contentType == SharedItemType.image) ? imageMaxDistance : textMaxDistance;

        if (distance <= threshold) {
          print(
            '  ✅ Item ${item.id} [${item.contentType.name}] - Dist: ${distance.toStringAsFixed(3)} (Allowed: $threshold)',
          );
          vectorSearchResults[item.id] = item;
        } else {
          // Optional: print skipped items to help debug your thresholds
          print('  ❌ Item ${item.id} [${item.contentType.name}] - Dist: ${distance.toStringAsFixed(3)} > $threshold');
        }
      }

      // A2. Search userCaptionEmbedding
      QueryBuilder<SharedItem> captionQueryBuilder = _itemBox.query(
        SharedItem_.userCaptionEmbedding.nearestNeighborsF32(queryEmbedding, maxResults + 20),
      );

      if (conditions.isNotEmpty) {
        final filterCondition = conditions.reduce((a, b) => a & b);
        // Re-apply neighbors clause AND filter
        captionQueryBuilder = _itemBox.query(
          filterCondition & SharedItem_.userCaptionEmbedding.nearestNeighborsF32(queryEmbedding, maxResults + 20),
        );
      }

      final captionQuery = captionQueryBuilder.build();
      final captionResults = await captionQuery.findWithScoresAsync();
      captionQuery.close();

      print('🔍 Semantic search (userCaptionEmbedding) found ${captionResults.length} raw candidates');

      for (final result in captionResults) {
        final item = result.object;
        final distance = result.score;

        // DYNAMIC THRESHOLD LOGIC
        final double threshold = (item.contentType == SharedItemType.image) ? imageMaxDistance : textMaxDistance;

        if (distance <= threshold) {
          print(
            '  ✅ Item ${item.id} [${item.contentType.name}] (userCaption) - Dist: ${distance.toStringAsFixed(3)} (Allowed: $threshold)',
          );
          captionSearchResults[item.id] = item;
        } else {
          print(
            '  ❌ Item ${item.id} [${item.contentType.name}] (userCaption) - Dist: ${distance.toStringAsFixed(3)} > $threshold',
          );
        }
      }

      // Merge both vector search results (union - take best from either search)
      semanticResults.addAll(vectorSearchResults);
      for (final entry in captionSearchResults.entries) {
        if (!semanticResults.containsKey(entry.key)) {
          semanticResults[entry.key] = entry.value;
        }
      }

      print('🔍 Combined semantic search results: ${semanticResults.length}');
    }

    // ---------------------------------------------------------
    // B. Keyword Search (Text Match)
    // ---------------------------------------------------------
    if (keyword != null && keyword.isNotEmpty) {
      final keywordCondition = SharedItem_.text
          .contains(keyword, caseSensitive: false)
          .or(SharedItem_.url.contains(keyword, caseSensitive: false))
          .or(SharedItem_.ocrText.contains(keyword, caseSensitive: false))
          // Also search generated tags if you have them
          .or(SharedItem_.generatedTags.containsElement(keyword))
          .or(SharedItem_.userTags.containsElement(keyword))
          // Add search in userCaption
          .or(SharedItem_.userCaption.contains(keyword, caseSensitive: false));

      final finalCondition = conditions.isEmpty
          ? keywordCondition
          : conditions.reduce((a, b) => a & b) & keywordCondition;

      final query = _itemBox.query(finalCondition).order(SharedItem_.createdAt, flags: Order.descending).build();

      final results = await query.findAsync();
      query.close();

      print('🔍 Keyword search found ${results.length} results');
      for (final item in results) {
        keywordResults[item.id] = item;
      }
    }

    // ---------------------------------------------------------
    // STEP 3: Categorize & Merge
    // ---------------------------------------------------------

    // 1. Identify items found in BOTH methods (High Confidence)
    for (final id in semanticResults.keys) {
      if (keywordResults.containsKey(id)) {
        bothResults.add(semanticResults[id]!);
      } else {
        semanticOnlyResults.add(semanticResults[id]!);
      }
    }

    // 2. Identify items found ONLY in keyword
    for (final id in keywordResults.keys) {
      if (!semanticResults.containsKey(id)) {
        keywordOnlyResults.add(keywordResults[id]!);
      }
    }

    print('📊 Results breakdown:');
    print('  - Both: ${bothResults.length}');
    print('  - Semantic only: ${semanticOnlyResults.length}');
    print('  - Keyword only: ${keywordOnlyResults.length}');

    // STEP 4: Combine (Both -> Semantic -> Keyword)
    final allResults = <SharedItem>[...bothResults, ...semanticOnlyResults, ...keywordOnlyResults];

    // STEP 5: Fallback - If no specific search was run but filters exist
    if (allResults.isEmpty &&
        conditions.isNotEmpty &&
        (queryEmbedding == null || queryEmbedding.isEmpty) &&
        (keyword == null || keyword.isEmpty)) {
      print('🔄 No search performed, but filters exist. Running filter-only query...');
      final filterCondition = conditions.reduce((a, b) => a & b);
      final query = _itemBox.query(filterCondition).order(SharedItem_.createdAt, flags: Order.descending).build();
      final results = await query.findAsync();
      query.close();
      print('🔍 Filter-only query found ${results.length} items');
      return results;
    }

    print('✅ Total unique results: ${allResults.length}');
    return allResults;
  }

  /// Delete a shared item
  bool deleteSharedItem(int id) {
    return _itemBox.remove(id);
  }

  /// Clear all items
  int clearAllItems() {
    return _itemBox.removeAll();
  }
}
