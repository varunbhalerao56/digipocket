import 'package:digipocket/feature/user_topic/user_topic.dart';
import 'package:digipocket/generated/objectbox.g.dart';

class UserTopicDb {
  final Store _store;
  late final Box<UserTopic> _topicBox;

  UserTopicDb(this._store) {
    _topicBox = _store.box<UserTopic>();
  }

  /// Get all active user topics
  List<UserTopic> getActiveUserTopics() {
    final query = _topicBox.query(UserTopic_.isActive.equals(true)).build();
    final results = query.find();
    query.close();
    return results;
  }

  /// Get all user topics (active + inactive)
  List<UserTopic> getAllUserTopics() {
    return _topicBox.getAll();
  }

  ///Get all user topics (active)
  List<UserTopic> getAllActiveUserTopics() {
    final query = _topicBox.query(UserTopic_.isActive.equals(true)).build();
    final results = query.find();
    query.close();
    return results;
  }

  /// Insert or update a user topic
  int inputUserTopic(UserTopic topic) {
    return _topicBox.put(topic);
  }

  /// Delete a user topic
  bool deleteUserTopic(int id) {
    return _topicBox.remove(id);
  }
}
