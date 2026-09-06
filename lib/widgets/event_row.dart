import 'package:flutter/material.dart';

import '../models/game_event.dart';

/// One line of a match's activity feed, with a coloured icon matching its
/// [GameEventType]. Shared between the live in-game journal and match
/// replays.
class EventRow extends StatelessWidget {
  const EventRow({super.key, required this.event});
  final GameEvent event;

  static const _icons = <GameEventType, (IconData, Color)>{
    GameEventType.start: (Icons.flag_rounded, Color(0xFF607D8B)),
    GameEventType.roll: (Icons.casino_rounded, Color(0xFFFB8C00)),
    GameEventType.ladder: (Icons.trending_up_rounded, Color(0xFF43A047)),
    GameEventType.snake: (Icons.trending_down_rounded, Color(0xFFE53935)),
    GameEventType.bonus: (Icons.add_circle_rounded, Color(0xFF43A047)),
    GameEventType.malus: (Icons.remove_circle_rounded, Color(0xFFE53935)),
    GameEventType.skip: (Icons.block_rounded, Color(0xFF9E9E9E)),
    GameEventType.extraTurn: (Icons.replay_rounded, Color(0xFF1E88E5)),
    GameEventType.tripleSix: (Icons.warning_rounded, Color(0xFFE53935)),
    GameEventType.win: (Icons.emoji_events_rounded, Color(0xFFFFB300)),
  };

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _icons[event.type] ?? (Icons.circle, Colors.grey);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(event.text, style: const TextStyle(fontSize: 13.5)),
            ),
          ),
        ],
      ),
    );
  }
}
