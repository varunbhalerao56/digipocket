part of 'user_topic_cubit.dart';

sealed class UserTopicState extends Equatable {
  const UserTopicState();
}

final class UserTopicInitial extends UserTopicState {
  @override
  List<Object> get props => [];
}
