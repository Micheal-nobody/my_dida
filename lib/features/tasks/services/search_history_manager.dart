import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class SearchHistoryManager {
  static const String _fileName = 'search_history.json';
  static const int _maxHistoryCount = 10;

  static Future<File> _getHistoryFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  static Future<List<String>> loadHistory() async {
    try {
      final file = await _getHistoryFile();
      if (!await file.exists()) {
        return [];
      }
      final contents = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents);
      return jsonList.map((item) => item.toString()).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveHistory(List<String> history) async {
    try {
      final file = await _getHistoryFile();
      await file.writeAsString(jsonEncode(history));
    } catch (_) {}
  }

  static Future<List<String>> addHistory(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return loadHistory();

    final history = await loadHistory();

    // 排重
    history
      ..remove(trimmed)
      // 放入最前面
      ..insert(0, trimmed);

    // 数量限制
    if (history.length > _maxHistoryCount) {
      history.removeRange(_maxHistoryCount, history.length);
    }

    await saveHistory(history);
    return history;
  }

  static Future<List<String>> removeHistory(String item) async {
    final history = await loadHistory();
    history.remove(item.trim());
    await saveHistory(history);
    return history;
  }

  static Future<void> clearHistory() async {
    try {
      final file = await _getHistoryFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
