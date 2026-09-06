import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/board_layout.dart';

/// A "board of the day": deterministically generated from today's date, so
/// every player sees the exact same layout on a given day and can compare
/// results — no server needed, the date itself is the shared seed.
class DailyChallengeService {
  DailyChallengeService._();

  static final DailyChallengeService instance = DailyChallengeService._();

  String get todayKey {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  }

  String get _yesterdayKey {
    final now = DateTime.now().subtract(const Duration(days: 1));
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  }

  BoardLayout get todayLayout {
    final random = Random(int.parse(todayKey));
    final cells = List.generate(21, (i) => i + 2)..shuffle(random);

    final snakesAndLadders = <int, int>{};
    var idx = 0;
    for (var i = 0; i < 3; i++) {
      final a = cells[idx++];
      final b = cells[idx++];
      snakesAndLadders[min(a, b)] = max(a, b); // ladder: climbs up
    }
    for (var i = 0; i < 3; i++) {
      final a = cells[idx++];
      final b = cells[idx++];
      snakesAndLadders[max(a, b)] = min(a, b); // snake: slides down
    }

    final remaining = cells.skip(idx).toList();
    final bonusCells = <int, int>{
      if (remaining.isNotEmpty) remaining[0]: 2,
      if (remaining.length > 1) remaining[1]: 3,
      if (remaining.length > 2) remaining[2]: -2,
    };

    return BoardLayout(snakesAndLadders: snakesAndLadders, bonusCells: bonusCells);
  }

  Future<Map<String, dynamic>?> loadTodayResult() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('daily_challenge_$todayKey');
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> saveTodayResult({required bool won, required int durationSeconds}) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadTodayResult();
    final wasAlreadyWonToday = existing?['won'] as bool? ?? false;
    // Only overwrite with a better (won, faster) result than what's already
    // recorded today, so retrying after a win can't erase a good time.
    if (existing != null) {
      final existingDuration = existing['durationSeconds'] as int? ?? 1 << 30;
      if (wasAlreadyWonToday && (!won || durationSeconds >= existingDuration)) return;
    }
    await prefs.setString(
      'daily_challenge_$todayKey',
      jsonEncode({'won': won, 'durationSeconds': durationSeconds}),
    );
    if (won && !wasAlreadyWonToday) {
      await _extendStreak(prefs);
    }
  }

  /// Number of consecutive days (ending today) the challenge has been won.
  Future<int> loadStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('daily_streak') ?? 0;
  }

  Future<void> _extendStreak(SharedPreferences prefs) async {
    final yesterdayRaw = prefs.getString('daily_challenge_$_yesterdayKey');
    final yesterdayWon = yesterdayRaw != null &&
        ((jsonDecode(yesterdayRaw) as Map<String, dynamic>)['won'] as bool? ?? false);
    final current = prefs.getInt('daily_streak') ?? 0;
    await prefs.setInt('daily_streak', yesterdayWon ? current + 1 : 1);
  }
}
