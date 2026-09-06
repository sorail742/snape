enum GameEventType {
  start,
  roll,
  ladder,
  snake,
  bonus,
  malus,
  skip,
  extraTurn,
  tripleSix,
  win,
}

/// A single line of the in-game activity feed, tagged with a type so the UI
/// can render a matching icon instead of guessing from the text.
class GameEvent {
  GameEvent({required this.type, required this.text});

  final GameEventType type;
  final String text;

  Map<String, dynamic> toJson() => {'type': type.name, 'text': text};

  static GameEvent fromJson(Map<String, dynamic> json) => GameEvent(
        type: GameEventType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => GameEventType.roll,
        ),
        text: json['text'] as String,
      );
}
