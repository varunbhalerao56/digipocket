import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';

class ShareQueueDataSource {
  static const platform = MethodChannel('com.vtbh.chuckit.sharing');

  /// Get the App Group container path from iOS
  Future<String> getAppGroupPath() async {
    try {
      final String path = await platform.invokeMethod('getAppGroupPath');
      return path;
    } catch (e) {
      print('Error getting app group path: $e');
      return '';
    }
  }

  Future<int> getQueuedItemCount() async {
    final groupPath = await getAppGroupPath();
    if (groupPath.isEmpty) return 0;

    final queueDir = Directory('$groupPath/share_queue');
    if (!await queueDir.exists()) return 0;

    final files = queueDir.listSync();
    int count = 0;

    for (var file in files) {
      if (file is File && file.path.endsWith('.json')) {
        count++;
      }
    }

    return count;
  }

  /// Read all queued share items from the file system
  Future<List<Map<String, dynamic>>> readQueuedItems() async {
    final groupPath = await getAppGroupPath();
    if (groupPath.isEmpty) return [];

    final queueDir = Directory('$groupPath/share_queue');
    if (!await queueDir.exists()) return [];

    final files = queueDir.listSync();
    List<Map<String, dynamic>> items = [];

    for (var file in files) {
      if (file is File && file.path.endsWith('.json')) {
        try {
          final contents = await file.readAsString();
          final data = jsonDecode(contents) as Map<String, dynamic>;
          items.add(data);
        } catch (e) {
          print('Error reading queue item: $e');
        }
      }
    }

    return items;
  }

  /// Delete a specific queue file
  Future<void> deleteQueueFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting queue file: $e');
    }
  }

  /// Clear all queued items
  Future<void> clearAllQueueFiles() async {
    final groupPath = await getAppGroupPath();
    if (groupPath.isEmpty) return;

    final queueDir = Directory('$groupPath/share_queue');
    if (!await queueDir.exists()) return;

    final files = queueDir.listSync();
    for (var file in files) {
      if (file is File) {
        await file.delete();
      }
    }
  }

  /// Get list of all queue file paths
  Future<List<String>> getQueueFilePaths() async {
    final groupPath = await getAppGroupPath();
    if (groupPath.isEmpty) return [];

    final queueDir = Directory('$groupPath/share_queue');
    if (!await queueDir.exists()) return [];

    return queueDir
        .listSync()
        .where((file) => file is File && file.path.endsWith('.json'))
        .map((file) => file.path)
        .toList();
  }
}
