import 'package:digipocket/feature/shared_item/data/repository/search_repository.dart';
import 'package:digipocket/feature/user_topic/user_topic.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:digipocket/feature/shared_item/shared_item.dart';
import 'package:equatable/equatable.dart';

part 'shared_items_state.dart';

class SharedItemsCubit extends Cubit<SharedItemsState> {
  final SharedItemRepository repository;
  final SearchRepository searchRepository;

  SharedItemsCubit({required this.repository, required this.searchRepository}) : super(const SharedItemsInitial());

  /// Load all shared items from database
  Future<void> loadSharedItems() async {
    try {
      emit(const SharedItemsLoading());
      final items = await repository.getAllSharedItems();
      emit(SharedItemsLoaded(items));
    } catch (e) {
      emit(SharedItemsError(e.toString()));
    }
  }

  /// Process queued items from share extension
  Future<void> processQueue() async {
    try {
      emit(const SharedItemsLoading());
      final count = await repository.processQueuedItems();
      print('Processed $count items from queue');

      // Reload items after processing
      await loadSharedItems();
    } catch (e) {
      emit(SharedItemsError(e.toString()));
    }
  }

  /// Delete a specific item
  Future<void> deleteItem(int id) async {
    try {
      await repository.deleteSharedItem(id);
      await loadSharedItems();
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
      emit(const SharedItemsLoading());

      if ((searchQuery == null || searchQuery.isEmpty) && typeFilter == null && userTopic == null) {
        // If no filters are applied, load all items
        await loadSharedItems();
        return;
      }

      final items = await searchRepository.searchItems(
        searchQuery: searchQuery,
        typeFilter: typeFilter,
        userTopic: userTopic?.name,
      );
      emit(SharedItemsLoaded(items));
    } catch (e) {
      emit(SharedItemsError(e.toString()));
    }
  }

  /// Clear all items
  Future<void> clearAll() async {
    try {
      await repository.clearAllItems();
      emit(const SharedItemsLoaded([]));
    } catch (e) {
      emit(SharedItemsError(e.toString()));
    }
  }
}
