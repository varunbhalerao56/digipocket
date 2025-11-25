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
//
// class SharedItemsLoaded extends SharedItemsState {
//   final List<SharedItem> items;
//
//   const SharedItemsLoaded(this.items);
//
//   @override
//   List<Object?> get props => [items];
// }

class SharedItemsError extends SharedItemsState {
  final String message;

  const SharedItemsError(this.message);

  @override
  List<Object?> get props => [message];
}

class SharedItemsData extends SharedItemsState {
  final bool isLoading;
  final bool processingQueue;
  final SharedItemFilter? filter;
  final List<SharedItem> items;

  const SharedItemsData(this.items, {this.isLoading = false, this.processingQueue = false, this.filter});

  @override
  List<Object?> get props => [items, isLoading, filter, processingQueue];

  SharedItemsData copyWith({
    bool? isLoading,
    bool? processingQueue,
    SharedItemFilter? filter,
    List<SharedItem>? items,
  }) {
    return SharedItemsData(
      items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      processingQueue: processingQueue ?? this.processingQueue,
      filter: filter ?? this.filter,
    );
  }
}
