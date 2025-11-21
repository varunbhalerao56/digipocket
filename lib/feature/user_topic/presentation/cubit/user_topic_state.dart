part of 'user_topic_cubit.dart';

sealed class UserTopicState extends Equatable {
  const UserTopicState();
}

final class UserTopicInitial extends UserTopicState {
  @override
  List<Object> get props => [];
}

class UserTopicLoading extends UserTopicState {
  const UserTopicLoading();

  @override
  List<Object> get props => [];
}

class UserTopicLoaded extends UserTopicState {
  final List<UserTopic> items;

  const UserTopicLoaded(this.items);

  @override
  List<Object?> get props => [items];
}

class UserTopicError extends UserTopicState {
  final String message;

  const UserTopicError(this.message);

  @override
  List<Object?> get props => [message];
}
