part of 'shared_items_cubit.dart';

abstract class SharedItemsState extends Equatable {
  const SharedItemsState();

  @override
  List<Object?> get props => [];
}

class SharedItemsInitial extends SharedItemsState {
  const SharedItemsInitial();
}

class SharedItemsLoading extends SharedItemsState {
  const SharedItemsLoading();
}

class SharedItemsLoaded extends SharedItemsState {
  final List<DigipocketItem> items; // Changed from SharedItem to DigipocketItem

  const SharedItemsLoaded(this.items);

  @override
  List<Object?> get props => [items];
}

class SharedItemsError extends SharedItemsState {
  final String message;

  const SharedItemsError(this.message);

  @override
  List<Object?> get props => [message];
}
