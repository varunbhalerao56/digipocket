import 'package:bloc/bloc.dart';
import 'package:digipocket/feature/user_topic/user_topic.dart';
import 'package:equatable/equatable.dart';

part 'user_topic_state.dart';

class UserTopicsCubit extends Cubit<UserTopicState> {
  final UserTopicRepository repository;

  UserTopicsCubit({required this.repository}) : super(UserTopicInitial());

  /// Load all shared items from database
  Future<void> loadUserTopic() async {
    try {
      emit(const UserTopicLoading());
      final items = await repository.getAllUserTopics();
      emit(UserTopicLoaded(items));
    } catch (e) {
      emit(UserTopicError(e.toString()));
    }
  }

  /// Process queued items from share extension
  Future<void> addUserTopic({required String name, required bool isActive, String? details}) async {
    try {
      emit(const UserTopicLoading());

      final userTopic = UserTopic(
        name: name,
        description: details,
        isActive: isActive,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      await repository.processNewTopic(userTopic);

      // Reload items after processing
      await loadUserTopic();
    } catch (e) {
      emit(UserTopicError(e.toString()));
    }
  }

  /// Update an existing item
  Future<void> updateItem(UserTopic topic) async {
    try {
      emit(const UserTopicLoading());
      await repository.processNewTopic(topic);
      await loadUserTopic();
    } catch (e) {
      emit(UserTopicError(e.toString()));
    }
  }

  /// Delete a specific item
  Future<void> deleteItem(int id) async {
    try {
      await repository.deleteUserTopic(id);
      await loadUserTopic();
    } catch (e) {
      emit(UserTopicError(e.toString()));
    }
  }
}
