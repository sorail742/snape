import 'game_event.dart';
import 'game_mode.dart';

class GameHistoryEntry {
  GameHistoryEntry({
    required this.dateTimeIso,
    required this.mode,
    required this.playerNames,
    required this.winnerName,
    required this.durationSeconds,
    this.events = const [],
  });

  final String dateTimeIso;
  final GameModeKind mode;
  final List<String> playerNames;
  final String winnerName;
  final int durationSeconds;

  /// The match's activity log, newest-first (as [GameController] keeps it) —
  /// reverse it for a chronological replay. Empty for entries saved before
  /// this field existed.
  final List<GameEvent> events;

  Map<String, dynamic> toJson() => {
        'dateTimeIso': dateTimeIso,
        'mode': mode.name,
        'playerNames': playerNames,
        'winnerName': winnerName,
        'durationSeconds': durationSeconds,
        'events': events.map((e) => e.toJson()).toList(),
      };

  static GameHistoryEntry fromJson(Map<String, dynamic> json) => GameHistoryEntry(
        dateTimeIso: json['dateTimeIso'] as String,
        mode: GameModeKind.values.firstWhere(
          (m) => m.name == json['mode'],
          orElse: () => GameModeKind.local,
        ),
        playerNames: List<String>.from(json['playerNames'] as List),
        winnerName: json['winnerName'] as String,
        durationSeconds: json['durationSeconds'] as int,
        events: (json['events'] as List?)
                ?.map((e) => GameEvent.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
      );
}
