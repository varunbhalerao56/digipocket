import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:digipocket/feature/shared_items/shared_items.dart';
import 'package:equatable/equatable.dart';

part 'shared_items_state.dart';

class SharedItemsCubit extends Cubit<SharedItemsState> {
  final SharedItemsRepository repository;

  SharedItemsCubit({required this.repository}) : super(const SharedItemsInitial());

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
