import 'package:digipocket/feature/shared_item/shared_item.dart';
import 'package:digipocket/generated/objectbox.g.dart';

class SharedItemDb {
  final Store _store;
  late final Box<SharedItem> _itemBox;

  SharedItemDb(this._store) {
    _itemBox = _store.box<SharedItem>();
  }

  /// Insert a shared item
  int insertSharedItem(SharedItem item) {
    return _itemBox.put(item);
  }

  /// Get all shared items, newest first
  List<SharedItem> getAllSharedItems() {
    final query = _itemBox.query().order(SharedItem_.createdAt, flags: Order.descending).build();
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
}
