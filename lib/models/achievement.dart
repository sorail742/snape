import 'package:flutter/material.dart';

import 'game_history_entry.dart';
import 'game_mode.dart';

class Achievement {
  const Achievement({required this.icon, required this.title, required this.isUnlocked});

  final IconData icon;
  final String title;
  final bool isUnlocked;

  static List<Achievement> compute(List<GameHistoryEntry> entries) {
    final winCounts = <String, int>{};
    for (final e in entries) {
      winCounts[e.winnerName] = (winCounts[e.winnerName] ?? 0) + 1;
    }
    final maxWins = winCounts.values.isEmpty ? 0 : winCounts.values.reduce((a, b) => a > b ? a : b);
    final modesPlayed = entries.map((e) => e.mode).toSet();
    final fastest = entries.isEmpty
        ? null
        : entries.map((e) => e.durationSeconds).reduce((a, b) => a < b ? a : b);
    final longest = entries.isEmpty
        ? null
        : entries.map((e) => e.durationSeconds).reduce((a, b) => a > b ? a : b);

    return [
      Achievement(
        icon: Icons.videogame_asset_rounded,
        title: 'Première partie',
        isUnlocked: entries.isNotEmpty,
      ),
      Achievement(
        icon: Icons.local_fire_department_rounded,
        title: 'Habitué·e (5 parties)',
        isUnlocked: entries.length >= 5,
      ),
      Achievement(
        icon: Icons.military_tech_rounded,
        title: 'Marathonien (20 parties)',
        isUnlocked: entries.length >= 20,
      ),
      Achievement(
        icon: Icons.bolt_rounded,
        title: 'Éclair (partie < 45s)',
        isUnlocked: fastest != null && fastest <= 45,
      ),
      Achievement(
        icon: Icons.hourglass_bottom_rounded,
        title: 'Partie épique (> 5 min)',
        isUnlocked: longest != null && longest >= 300,
      ),
      Achievement(
        icon: Icons.public_rounded,
        title: 'Explorateur (local + Bluetooth + en ligne)',
        isUnlocked: GameModeKind.values.every(modesPlayed.contains),
      ),
      Achievement(
        icon: Icons.emoji_events_rounded,
        title: 'Champion (3 victoires)',
        isUnlocked: maxWins >= 3,
      ),
    ];
  }
}
