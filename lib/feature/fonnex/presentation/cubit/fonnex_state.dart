part of 'fonnex_cubit.dart';

sealed class FonnexState extends Equatable {
  const FonnexState();
}

final class FonnexInitial extends FonnexState {
  @override
  List<Object?> get props => [];
}

final class FonnexLoading extends FonnexState {
  @override
  List<Object> get props => [];
}

final class FonnexError extends FonnexState {
  final AppException exception;

  const FonnexError(this.exception);

  @override
  List<Object> get props => [exception];
}

final class FonnexDataLoaded extends FonnexState {
  final FonnexEmbeddingRepository repository;

  const FonnexDataLoaded(this.repository);

  @override
  List<Object> get props => [repository];
}
