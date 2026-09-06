import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_history_entry.dart';

class StatsService {
  StatsService._();

  static final StatsService instance = StatsService._();

  static const _key = 'game_history_v1';

  Future<List<GameHistoryEntry>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const [];
    return raw
        .map((s) => GameHistoryEntry.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList()
        .reversed
        .toList();
  }

  Future<void> addEntry(GameHistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? <String>[];
    raw.add(jsonEncode(entry.toJson()));
    if (raw.length > 200) {
      raw.removeAt(0);
    }
    await prefs.setStringList(_key, raw);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
