import 'package:digipocket/feature/shared_item/data/repository/search_repository.dart';
import 'package:digipocket/feature/user_topic/user_topic.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:digipocket/feature/shared_item/shared_item.dart';
import 'package:equatable/equatable.dart';

part 'shared_items_state.dart';

class SharedItemFilter extends Equatable {
  final String? searchQuery;
  final SharedItemType? typeFilter;
  final int? userTopicId; // ✅ Store ID instead of object
  final String? userTopicName; // Optional: Store name for easier debugging

  const SharedItemFilter({this.searchQuery, this.typeFilter, this.userTopicId, this.userTopicName});

  @override
  List<Object?> get props => [searchQuery, typeFilter, userTopicId, userTopicName];

  @override
  String toString() {
    return 'SharedItemFilter(searchQuery: $searchQuery, typeFilter: $typeFilter, userTopicId: $userTopicId, userTopicName: $userTopicName)';
  }
}

class SharedItemsCubit extends Cubit<SharedItemsState> {
  final SharedItemRepository repository;
  final SearchRepository searchRepository;

  SharedItemsCubit({required this.repository, required this.searchRepository}) : super(const SharedItemsInitial());

  /// Load all shared items from database
  Future<void> loadSharedItems([bool isLoading = true, SharedItemFilter? filter]) async {
    try {
      if (state is! SharedItemsData) {
        emit(SharedItemsData([], isLoading: isLoading));
      }

      final dataState = state as SharedItemsData;

      emit(dataState.copyWith(isLoading: isLoading, filter: filter));

      final items = await repository.getAllSharedItems();

      emit(dataState.copyWith(items: items, filter: filter, isLoading: false));
    } catch (e) {
      emit(SharedItemsError(e.toString()));
    }
  }

  /// Process queued items from share extension
  Future<void> processQueue() async {
    try {
      final queueLength = await repository.getQueuedItemCount();

      if (queueLength == 0) {
        print('No items in queue to process');
        return;
      }

      if (state is SharedItemsData) {
        emit((state as SharedItemsData).copyWith(processingQueue: true));
      }

      final count = await repository.processQueuedItems();
      print('Processed $count items from queue');

      if (state is SharedItemsData) {
        emit((state as SharedItemsData).copyWith(processingQueue: false));
      }

      // Reload items after processing
      await loadSharedItems(false);
    } catch (e) {
      emit(SharedItemsError(e.toString()));
    }
  }

  /// Delete a specific item
  Future<void> deleteItem(int id) async {
    try {
      await repository.deleteSharedItem(id);

      if (state is SharedItemsData) {
        final dataState = state as SharedItemsData;
        final updatedItems = dataState.items.where((item) => item.id != id).toList();
        emit(dataState.copyWith(items: updatedItems));
      }
    } catch (e) {
      emit(SharedItemsError(e.toString()));
    }
  }

  /// Update an existing item
  Future<void> updateItem(SharedItem item) async {
    try {
      emit(const SharedItemsLoading());
      await repository.reprocessExistingItem(item);
      await loadSharedItems();
    } catch (e) {
      emit(SharedItemsError(e.toString()));
    }
  }

  Future<void> searchItems({
    String? searchQuery,
    SharedItemType? typeFilter,
    UserTopic? userTopic,
    SharedItemFilter? filter,
  }) async {
    try {
      if ((state is! SharedItemsData)) {
        // If current state is not SharedItemsData, load all items first
        await loadSharedItems(false);
      }

      final dataState = state as SharedItemsData;

      final seqrchQueryFilter = searchQuery == null || searchQuery.isEmpty ? null : searchQuery;

      final newFilter =
          filter ??
          SharedItemFilter(
            searchQuery: seqrchQueryFilter,
            typeFilter: typeFilter,
            userTopicId: userTopic?.id,
            userTopicName: userTopic?.name,
          );

      if (newFilter == dataState.filter && filter == null) {
        print("Search filter unchanged, skipping search.");
        // If the filter hasn't changed, no need to perform search again
        // emit(state);
        return;
      }

      emit(dataState.copyWith(isLoading: true));

      if (filter == null && (searchQuery == null || searchQuery.isEmpty) && typeFilter == null && userTopic == null) {
        // If no filters are applied, load all items
        await loadSharedItems(true, newFilter);
        return;
      } else if (filter != null &&
          filter.searchQuery == null &&
          filter.typeFilter == null &&
          filter.userTopicId == null) {
        // If filter is empty, load all items
        await loadSharedItems(true, newFilter);
        return;
      }

      final items = await searchRepository.searchItems(
        searchQuery: newFilter.searchQuery,
        typeFilter: newFilter.typeFilter,
        userTopic: newFilter.userTopicName,
        keywordSearch: dataState.keywordSearch,
      );

      emit(SharedItemsData(items, filter: newFilter, keywordSearch: dataState.keywordSearch));
    } catch (e) {
      emit(SharedItemsError(e.toString()));
    }
  }

  Future<void> setKeywordSearch(bool keywordSearch) async {
    if (state is SharedItemsData) {
      final dataState = state as SharedItemsData;

      final tempFilter = dataState.filter;

      print(tempFilter.toString());

      emit(dataState.copyWith(keywordSearch: keywordSearch));

      if (tempFilter == null ||
          (tempFilter.searchQuery == null || tempFilter.searchQuery!.isEmpty) &&
              tempFilter.typeFilter == null &&
              tempFilter.userTopicId == null) {
        return;
      }

      await searchItems(filter: tempFilter);
    }
  }

  /// Clear all items
  Future<void> clearAll() async {
    try {
      await repository.clearAllItems();

      loadSharedItems();
    } catch (e) {
      emit(SharedItemsError(e.toString()));
    }
  }
}
