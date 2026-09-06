import 'package:flutter/material.dart';

import '../models/game_event.dart';
import '../models/player.dart';

/// Serialisable snapshot of the players + turn state, used by the host to
/// broadcast authoritative game state to connected clients.
class GameSnapshot {
  GameSnapshot({
    required this.playerPositions,
    required this.currentPlayerIndex,
    required this.diceValue,
    required this.isRolling,
    required this.isMoving,
    required this.winnerIndex,
    required this.events,
  });

  final List<int> playerPositions;
  final int currentPlayerIndex;
  final int diceValue;
  final bool isRolling;
  final bool isMoving;
  final int? winnerIndex;
  final List<GameEvent> events;

  Map<String, dynamic> toJson() => {
        'playerPositions': playerPositions,
        'currentPlayerIndex': currentPlayerIndex,
        'diceValue': diceValue,
        'isRolling': isRolling,
        'isMoving': isMoving,
        'winnerIndex': winnerIndex,
        'events': events.map((e) => e.toJson()).toList(),
      };

  static GameSnapshot fromJson(Map<String, dynamic> json) => GameSnapshot(
        playerPositions: List<int>.from(json['playerPositions'] as List),
        currentPlayerIndex: json['currentPlayerIndex'] as int,
        diceValue: json['diceValue'] as int,
        isRolling: json['isRolling'] as bool,
        isMoving: json['isMoving'] as bool,
        winnerIndex: json['winnerIndex'] as int?,
        events: (json['events'] as List)
            .map((e) => GameEvent.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

  static GameSnapshot capture(List<Player> players, {
    required int currentPlayerIndex,
    required int diceValue,
    required bool isRolling,
    required bool isMoving,
    required List<GameEvent> events,
  }) {
    final winnerIndex = players.indexWhere((p) => p.hasWon);
    return GameSnapshot(
      playerPositions: players.map((p) => p.position).toList(),
      currentPlayerIndex: currentPlayerIndex,
      diceValue: diceValue,
      isRolling: isRolling,
      isMoving: isMoving,
      winnerIndex: winnerIndex == -1 ? null : winnerIndex,
      events: events,
    );
  }
}

/// A player entry as announced during the lobby phase, before a
/// [GameController] exists.
class LobbyPlayer {
  LobbyPlayer({
    required this.id,
    required this.name,
    required this.color,
    this.isHost = false,
  });

  final String id;
  final String name;
  final Color color;
  final bool isHost;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color.toARGB32(),
        'isHost': isHost,
      };

  static LobbyPlayer fromJson(Map<String, dynamic> json) => LobbyPlayer(
        id: json['id'] as String,
        name: json['name'] as String,
        color: Color(json['color'] as int),
        isHost: json['isHost'] as bool? ?? false,
      );
}
