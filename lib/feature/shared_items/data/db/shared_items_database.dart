import 'package:digipocket/feature/shared_items/shared_items.dart';
import 'package:digipocket/generated/objectbox.g.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AppDatabase {
  late final Store _store;
  late final Box<DigipocketItem> _itemBox;
  late final Box<UserTopic> _topicBox;

  AppDatabase._create(this._store) {
    _itemBox = _store.box<DigipocketItem>();
    _topicBox = _store.box<UserTopic>();
  }

  static Future<AppDatabase> create() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final store = await openStore(directory: p.join(docsDir.path, 'objectbox'));
    return AppDatabase._create(store);
  }

  Box<DigipocketItem> get itemBox => _itemBox;
  Box<UserTopic> get topicBox => _topicBox;

  // ========== DigipocketItem Methods ==========

  /// Insert a shared item
  int insertSharedItem(DigipocketItem item) {
    return _itemBox.put(item);
  }

  /// Get all shared items, newest first
  List<DigipocketItem> getAllSharedItems() {
    final query = _itemBox
        .query()
        .order(DigipocketItem_.createdAt, flags: Order.descending)
        .build();
    final results = query.find();
    query.close();
    return results;
  }

  /// Delete a shared item
  bool deleteSharedItem(int id) {
    return _itemBox.remove(id);
  }

  /// Clear all items
  int clearAllItems() {
    return _itemBox.removeAll();
  }

  // ========== UserTopic Methods ==========

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

  /// Insert or update a user topic
  int saveUserTopic(UserTopic topic) {
    return _topicBox.put(topic);
  }

  /// Delete a user topic
  bool deleteUserTopic(int id) {
    return _topicBox.remove(id);
  }

  /// Close the store
  void close() {
    _store.close();
  }
}
