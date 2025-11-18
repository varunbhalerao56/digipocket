import 'package:digipocket/feature/shared_item/shared_item.dart';
import 'package:digipocket/feature/user_topic/user_topic.dart';
import 'package:digipocket/generated/objectbox.g.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AppDatabase {
  late final Store _store;
  late final SharedItemDb _itemDb;
  late final UserTopicDb _topicDb;

  AppDatabase._create(this._store) {
    _itemDb = SharedItemDb(_store);
    _topicDb = UserTopicDb(_store);
  }

  static Future<AppDatabase> create() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final store = await openStore(directory: p.join(docsDir.path, 'objectbox'));
    return AppDatabase._create(store);
  }

  SharedItemDb get itemDb => _itemDb;
  UserTopicDb get topicDb => _topicDb;

  void close() {
    _store.close();
  }
}
