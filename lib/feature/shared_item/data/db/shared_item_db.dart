import 'package:digipocket/feature/shared_item/shared_item.dart';
import 'package:digipocket/generated/objectbox.g.dart';

enum SearchMode { smart, exact, both }

class SharedItemDb {
  final Store _store;
  late final Box<SharedItem> _itemBox;

  SharedItemDb(this._store) {
    _itemBox = _store.box<SharedItem>();
  }

  // =============================================================
  // MAIN SEARCH FUNCTION
  // =============================================================

  Future<List<SharedItem>> searchItems({
    List<double>? queryEmbedding,
    String? keyword,
    SharedItemType? itemType,
    String? userTopic,
    int maxResults = 50,
    double textMaxDistance = 0.56,
    double imageMaxDistance = 0.95,
    bool keywordOnly = false,
  }) async {
    // Build filter conditions
    final conditions = _buildFilterConditions(itemType: itemType, userTopic: userTopic);

    // print('🔍 DEBUG: keywordOnly = $keywordOnly');
    // print('🔍 DEBUG: conditions.isNotEmpty = ${conditions.isNotEmpty}');
    // print('🔍 DEBUG: queryEmbedding == null = ${queryEmbedding == null}');
    // print('🔍 DEBUG: keyword = "$keyword"');

    // KEYWORD-ONLY MODE
    if (keywordOnly) {
      return _handleKeywordOnlyMode(keyword: keyword, conditions: conditions);
    }

    // HYBRID MODE (Semantic + Keyword)
    return _handleHybridMode(
      queryEmbedding: queryEmbedding,
      keyword: keyword,
      conditions: conditions,
      maxResults: maxResults,
      textMaxDistance: textMaxDistance,
      imageMaxDistance: imageMaxDistance,
    );
  }

  // =============================================================
  // MODE HANDLERS
  // =============================================================

  Future<List<SharedItem>> _handleKeywordOnlyMode({
    String? keyword,
    required List<Condition<SharedItem>> conditions,
  }) async {
    // Has keyword - search by keyword
    if (keyword != null && keyword.isNotEmpty) {
      final results = await _performKeywordSearch(keyword: keyword, conditions: conditions);
      print('✅ Keyword-only results: ${results.length}');
      return results.values.toList();
    }

    // No keyword but has filters - apply filters only
    if (conditions.isNotEmpty) {
      return _performFilterOnlySearch(conditions: conditions);
    }

    // No keyword, no filters - return all
    return _getAllItems();
  }

  Future<List<SharedItem>> _handleHybridMode({
    List<double>? queryEmbedding,
    String? keyword,
    required List<Condition<SharedItem>> conditions,
    required int maxResults,
    required double textMaxDistance,
    required double imageMaxDistance,
  }) async {
    // Perform searches
    final semanticResults = await _performSemanticSearch(
      queryEmbedding: queryEmbedding,
      conditions: conditions,
      maxResults: maxResults,
      textMaxDistance: textMaxDistance,
      imageMaxDistance: imageMaxDistance,
    );

    final keywordResults = keyword != null && keyword.isNotEmpty
        ? await _performKeywordSearch(keyword: keyword, conditions: conditions)
        : <int, SharedItem>{};

    // Merge results
    final mergedResults = _mergeResults(semanticResults: semanticResults, keywordResults: keywordResults);

    if (mergedResults.isNotEmpty) {
      print('✅ Total unique results: ${mergedResults.length}');
      return mergedResults;
    }

    // Fallback: filters only
    if (conditions.isNotEmpty &&
        (queryEmbedding == null || queryEmbedding.isEmpty) &&
        (keyword == null || keyword.isEmpty)) {
      return _performFilterOnlySearch(conditions: conditions);
    }

    return [];
  }

  // =============================================================
  // FILTER CONDITIONS
  // =============================================================

  List<Condition<SharedItem>> _buildFilterConditions({SharedItemType? itemType, String? userTopic}) {
    final conditions = <Condition<SharedItem>>[];

    if (itemType != null) {
      conditions.add(SharedItem_.dbContentType.equals(itemType.index));
      print('🔍 Applying content type filter: ${itemType.name}');
    }

    if (userTopic != null && userTopic.isNotEmpty) {
      conditions.add(SharedItem_.userTags.containsElement(userTopic));
      print('🔍 Applying user topic filter: $userTopic');
    }

    return conditions;
  }

  // =============================================================
  // SEMANTIC SEARCH
  // =============================================================

  Future<Map<int, SharedItem>> _performSemanticSearch({
    List<double>? queryEmbedding,
    required List<Condition<SharedItem>> conditions,
    required int maxResults,
    required double textMaxDistance,
    required double imageMaxDistance,
  }) async {
    if (queryEmbedding == null || queryEmbedding.isEmpty) {
      return {};
    }

    final vectorResults = await _searchByVectorEmbedding(
      queryEmbedding: queryEmbedding,
      conditions: conditions,
      maxResults: maxResults,
      textMaxDistance: textMaxDistance,
      imageMaxDistance: imageMaxDistance,
    );

    final captionResults = await _searchByCaptionEmbedding(
      queryEmbedding: queryEmbedding,
      conditions: conditions,
      maxResults: maxResults,
      textMaxDistance: textMaxDistance,
    );

    // Merge (union)
    final merged = <int, SharedItem>{...vectorResults};
    for (final entry in captionResults.entries) {
      if (!merged.containsKey(entry.key)) {
        merged[entry.key] = entry.value;
      }
    }

    print('🔍 Combined semantic search results: ${merged.length}');
    return merged;
  }

  Future<Map<int, SharedItem>> _searchByVectorEmbedding({
    required List<double> queryEmbedding,
    required List<Condition<SharedItem>> conditions,
    required int maxResults,
    required double textMaxDistance,
    required double imageMaxDistance,
  }) async {
    final neighborCondition = SharedItem_.vectorEmbedding.nearestNeighborsF32(queryEmbedding, maxResults + 20);

    final queryCondition = conditions.isEmpty
        ? neighborCondition
        : conditions.reduce((a, b) => a & b) & neighborCondition;

    final query = _itemBox.query(queryCondition).build();
    final results = await query.findWithScoresAsync();
    query.close();

    print('🔍 Semantic search (vectorEmbedding) found ${results.length} raw candidates');

    return _filterByDistance(
      results: results,
      textMaxDistance: textMaxDistance,
      imageMaxDistance: imageMaxDistance,
      label: 'vectorEmbedding',
    );
  }

  Future<Map<int, SharedItem>> _searchByCaptionEmbedding({
    required List<double> queryEmbedding,
    required List<Condition<SharedItem>> conditions,
    required int maxResults,
    required double textMaxDistance,
  }) async {
    final neighborCondition = SharedItem_.userCaptionEmbedding.nearestNeighborsF32(queryEmbedding, maxResults + 20);

    final queryCondition = conditions.isEmpty
        ? neighborCondition
        : conditions.reduce((a, b) => a & b) & neighborCondition;

    final query = _itemBox.query(queryCondition).build();
    final results = await query.findWithScoresAsync();
    query.close();

    print('🔍 Semantic search (userCaptionEmbedding) found ${results.length} raw candidates');

    return _filterByDistance(
      results: results,
      textMaxDistance: textMaxDistance,
      imageMaxDistance: textMaxDistance, // Caption is always text
      label: 'userCaptionEmbedding',
    );
  }

  Map<int, SharedItem> _filterByDistance({
    required List<ObjectWithScore<SharedItem>> results,
    required double textMaxDistance,
    required double imageMaxDistance,
    required String label,
  }) {
    final filtered = <int, SharedItem>{};

    for (final result in results) {
      final item = result.object;
      final distance = result.score;

      final threshold = (item.contentType == SharedItemType.image) ? imageMaxDistance : textMaxDistance;

      if (distance <= threshold) {
        print('  ✅ Item ${item.id} [${item.contentType.name}] ($label) - Dist: ${distance.toStringAsFixed(3)}');
        filtered[item.id] = item;
      } else {
        print(
          '  ❌ Item ${item.id} [${item.contentType.name}] ($label) - Dist: ${distance.toStringAsFixed(3)} > $threshold',
        );
      }
    }

    return filtered;
  }

  // =============================================================
  // KEYWORD SEARCH
  // =============================================================

  Future<Map<int, SharedItem>> _performKeywordSearch({
    required String keyword,
    required List<Condition<SharedItem>> conditions,
  }) async {
    final keywordCondition = SharedItem_.text
        .contains(keyword, caseSensitive: false)
        .or(SharedItem_.url.contains(keyword, caseSensitive: false))
        .or(SharedItem_.ocrText.contains(keyword, caseSensitive: false))
        .or(SharedItem_.urlTitle.contains(keyword, caseSensitive: false))
        .or(SharedItem_.urlDescription.contains(keyword, caseSensitive: false))
        .or(SharedItem_.userCaption.contains(keyword, caseSensitive: false));

    final finalCondition = conditions.isEmpty
        ? keywordCondition
        : conditions.reduce((a, b) => a & b) & keywordCondition;

    final query = _itemBox.query(finalCondition).order(SharedItem_.createdAt, flags: Order.descending).build();

    final results = await query.findAsync();
    query.close();

    print('🔍 Keyword search found ${results.length} results');

    final resultMap = <int, SharedItem>{};
    final lowerKeyword = keyword.toLowerCase();

    for (final item in results) {
      resultMap[item.id] = item;
      final matchedField = _findMatchedField(item, lowerKeyword);
      print('  📝 Item ${item.id} matched on: $matchedField');
    }

    return resultMap;
  }

  String _findMatchedField(SharedItem item, String lowerKeyword) {
    if (item.text?.toLowerCase().contains(lowerKeyword) == true) return 'text';
    if (item.url?.toLowerCase().contains(lowerKeyword) == true) return 'url';
    if (item.ocrText?.toLowerCase().contains(lowerKeyword) == true) return 'ocrText';
    if (item.urlTitle?.toLowerCase().contains(lowerKeyword) == true) return 'urlTitle';
    if (item.urlDescription?.toLowerCase().contains(lowerKeyword) == true) return 'urlDescription';
    if (item.userCaption?.toLowerCase().contains(lowerKeyword) == true) return 'userCaption';
    return 'unknown';
  }

  // =============================================================
  // FILTER-ONLY & GET ALL
  // =============================================================

  Future<List<SharedItem>> _performFilterOnlySearch({required List<Condition<SharedItem>> conditions}) async {
    print('🔄 Running filter-only query...');
    final filterCondition = conditions.reduce((a, b) => a & b);
    final query = _itemBox.query(filterCondition).order(SharedItem_.createdAt, flags: Order.descending).build();
    final results = await query.findAsync();
    query.close();
    print('🔍 Filter-only query found ${results.length} items');
    return results;
  }

  Future<List<SharedItem>> _getAllItems() async {
    print('🔄 Returning all items...');
    final query = _itemBox.query().order(SharedItem_.createdAt, flags: Order.descending).build();
    final results = await query.findAsync();
    query.close();
    return results;
  }

  // =============================================================
  // MERGE RESULTS
  // =============================================================

  List<SharedItem> _mergeResults({
    required Map<int, SharedItem> semanticResults,
    required Map<int, SharedItem> keywordResults,
  }) {
    final bothResults = <SharedItem>[];
    final semanticOnlyResults = <SharedItem>[];
    final keywordOnlyResults = <SharedItem>[];

    // Items in BOTH (high confidence)
    for (final id in semanticResults.keys) {
      if (keywordResults.containsKey(id)) {
        bothResults.add(semanticResults[id]!);
      } else {
        semanticOnlyResults.add(semanticResults[id]!);
      }
    }

    // Items in keyword ONLY
    for (final id in keywordResults.keys) {
      if (!semanticResults.containsKey(id)) {
        keywordOnlyResults.add(keywordResults[id]!);
      }
    }

    print('📊 Results breakdown:');
    print('  - Both: ${bothResults.length}');
    print('  - Semantic only: ${semanticOnlyResults.length}');
    print('  - Keyword only: ${keywordOnlyResults.length}');

    // Priority: Both > Semantic > Keyword
    return [...bothResults, ...semanticOnlyResults, ...keywordOnlyResults];
  }

  /// Insert a shared item
  int insertSharedItem(SharedItem item) {
    return _itemBox.put(item);
  }

  /// Insert a shared item asynchronously
  Future<int> insertSharedItemAsync(SharedItem item) async {
    return _itemBox.putAsync(item);
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
    final results = query.findWithScores();
    query.close();

    final filteredResults = results.where((element) => element.score <= 0.7).map((e) => e.object).toList();

    return filteredResults;
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
