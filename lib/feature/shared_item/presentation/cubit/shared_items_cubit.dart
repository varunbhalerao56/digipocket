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

  const SharedItemFilter({this.searchQuery, this.typeFilter, this.userTopicId});

  @override
  List<Object?> get props => [searchQuery, typeFilter, userTopicId];

  @override
  String toString() {
    return 'SharedItemFilter(searchQuery: $searchQuery, typeFilter: $typeFilter, userTopicId: $userTopicId)';
  }
}

class SharedItemsCubit extends Cubit<SharedItemsState> {
  final SharedItemRepository repository;
  final SearchRepository searchRepository;

  SharedItemsCubit({required this.repository, required this.searchRepository}) : super(const SharedItemsInitial());

  /// Load all shared items from database
  Future<void> loadSharedItems([bool isLoading = true, SharedItemFilter? filter]) async {
    try {
      final tempItems = state is SharedItemsData ? (state as SharedItemsData).items : <SharedItem>[];
      emit(SharedItemsData(tempItems, isLoading: isLoading, filter: filter));

      final items = await repository.getAllSharedItems();
      emit(SharedItemsData(items, filter: filter));
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
      await loadSharedItems(false);
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

  Future<void> searchItems({String? searchQuery, SharedItemType? typeFilter, UserTopic? userTopic}) async {
    try {
      final seqrchQueryFilter = searchQuery == null || searchQuery.isEmpty ? null : searchQuery;
      final oldFilter = state is SharedItemsData ? (state as SharedItemsData).filter : null;

      final newFilter = SharedItemFilter(
        searchQuery: seqrchQueryFilter,
        typeFilter: typeFilter,
        userTopicId: userTopic?.id,
      );

      print(oldFilter.toString());

      print('Search Query Match: ${newFilter.searchQuery == oldFilter?.searchQuery}');
      print('Type Filter Match: ${newFilter.typeFilter == oldFilter?.typeFilter}');
      print('User Topic Match: ${newFilter.userTopicId == oldFilter?.userTopicId}');

      print(newFilter == oldFilter);

      if (newFilter == (state is SharedItemsData ? (state as SharedItemsData).filter : null)) {
        // If the filter hasn't changed, no need to perform search again
        // emit(state);
        return;
      }

      emit(
        SharedItemsData(state is SharedItemsData ? (state as SharedItemsData).items : <SharedItem>[], isLoading: true),
      );

      if ((searchQuery == null || searchQuery.isEmpty) && typeFilter == null && userTopic == null) {
        // If no filters are applied, load all items
        await loadSharedItems(true, newFilter);
        return;
      }

      final items = await searchRepository.searchItems(
        searchQuery: searchQuery,
        typeFilter: typeFilter,
        userTopic: userTopic?.name,
      );

      emit(SharedItemsData(items, filter: newFilter));
    } catch (e) {
      emit(SharedItemsError(e.toString()));
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
