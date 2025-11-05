import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'shared_items_database.g.dart';

// Define the shared items table
class SharedItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // 'text', 'url', 'image'
  TextColumn get content => text().nullable()(); // Renamed from 'text' to 'content'
  TextColumn get url => text().nullable()();
  TextColumn get imagePath => text().nullable()();
  TextColumn get sourceApp => text()();
  IntColumn get timestamp => integer()(); // milliseconds since epoch
}

@DriftDatabase(tables: [SharedItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Insert a shared item
  Future<int> insertSharedItem(SharedItemsCompanion item) {
    return into(sharedItems).insert(item);
  }

  // Get all shared items, newest first
  Future<List<SharedItem>> getAllSharedItems() {
    return (select(sharedItems)..orderBy([(t) => OrderingTerm.desc(t.timestamp)])).get();
  }

  // Delete a shared item
  Future<int> deleteSharedItem(int id) {
    return (delete(sharedItems)..where((t) => t.id.equals(id))).go();
  }

  // Clear all items
  Future<int> clearAllItems() {
    return delete(sharedItems).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app.db'));
    return NativeDatabase(file);
  });
}
