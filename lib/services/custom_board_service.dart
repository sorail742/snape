import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/board_layout.dart';

class CustomBoard {
  const CustomBoard({required this.name, required this.layout});

  final String name;
  final BoardLayout layout;

  Map<String, dynamic> toJson() => {
        'name': name,
        'snakesAndLadders': layout.snakesAndLadders.map((k, v) => MapEntry('$k', v)),
        'bonusCells': layout.bonusCells.map((k, v) => MapEntry('$k', v)),
      };

  static CustomBoard fromJson(Map<String, dynamic> json) => CustomBoard(
        name: json['name'] as String,
        layout: BoardLayout(
          snakesAndLadders: (json['snakesAndLadders'] as Map).map(
            (k, v) => MapEntry(int.parse(k as String), v as int),
          ),
          bonusCells: (json['bonusCells'] as Map).map(
            (k, v) => MapEntry(int.parse(k as String), v as int),
          ),
        ),
      );
}

/// Stores the player's own hand-made board layouts (custom snakes, ladders
/// and bonus/malus placements), so they can be picked instead of the built-
/// in boards when starting a local match.
class CustomBoardService {
  CustomBoardService._();

  static final CustomBoardService instance = CustomBoardService._();

  static const _key = 'custom_boards_v1';

  Future<List<CustomBoard>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const [];
    return raw
        .map((s) => CustomBoard.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(CustomBoard board) async {
    final boards = await loadAll();
    final idx = boards.indexWhere((b) => b.name == board.name);
    final updated = [...boards];
    if (idx >= 0) {
      updated[idx] = board;
    } else {
      updated.add(board);
    }
    await _persist(updated);
  }

  Future<void> delete(String name) async {
    final boards = await loadAll();
    boards.removeWhere((b) => b.name == name);
    await _persist(boards);
  }

  Future<void> _persist(List<CustomBoard> boards) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, boards.map((b) => jsonEncode(b.toJson())).toList());
  }
}
