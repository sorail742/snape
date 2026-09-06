import 'package:flutter/material.dart';

import 'board_layout.dart';

/// One level of the solo campaign against the AI: each stage is a bit
/// harder than the last (a tougher board, a stronger AI, a tighter turn
/// limit) and awards a more prestigious cup than the previous one.
class Stage {
  const Stage({
    required this.index,
    required this.name,
    required this.layout,
    required this.turnLimit,
    required this.aiHandicap,
    required this.cupIcon,
    required this.cupColor,
  });

  final int index;
  final String name;
  final BoardLayout layout;

  /// The human player must reach the finish within this many of their own
  /// turns, or the stage is lost.
  final int turnLimit;

  /// Chance (0-1) that the bot rerolls a bad dice result and keeps the
  /// better of the two — makes the AI noticeably tougher at later stages
  /// without ever being unbeatable.
  final double aiHandicap;

  final IconData cupIcon;
  final Color cupColor;

  static const all = <Stage>[
    Stage(
      index: 1,
      name: 'Étape 1 — Débutant',
      layout: BoardLayout.classic,
      turnLimit: 30,
      aiHandicap: 0,
      cupIcon: Icons.emoji_events_outlined,
      cupColor: Color(0xFFBF8A5A),
    ),
    Stage(
      index: 2,
      name: 'Étape 2 — Intermédiaire',
      layout: BoardLayout(
        snakesAndLadders: {3: 13, 12: 20, 17: 2, 10: 5, 21: 11, 8: 4},
        bonusCells: {6: 3, 14: 2, 19: -2},
      ),
      turnLimit: 25,
      aiHandicap: 0.2,
      cupIcon: Icons.emoji_events_rounded,
      cupColor: Color(0xFFB0BEC5),
    ),
    Stage(
      index: 3,
      name: 'Étape 3 — Difficile',
      layout: BoardLayout(
        snakesAndLadders: {12: 20, 17: 2, 10: 5, 21: 11, 8: 4, 16: 6},
        bonusCells: {6: 3, 14: 2, 19: -2},
      ),
      turnLimit: 20,
      aiHandicap: 0.35,
      cupIcon: Icons.emoji_events_rounded,
      cupColor: Color(0xFFFFD54F),
    ),
    Stage(
      index: 4,
      name: 'Étape 4 — La Grande Coupe',
      layout: BoardLayout(
        snakesAndLadders: {12: 20, 17: 2, 10: 5, 21: 11, 8: 4, 16: 6, 13: 7},
        bonusCells: {6: 3, 14: 2, 19: -2},
      ),
      turnLimit: 16,
      aiHandicap: 0.5,
      cupIcon: Icons.workspace_premium_rounded,
      cupColor: Color(0xFF29B6F6),
    ),
  ];
}

/// How many numbered levels each [Stage] (world) is broken into.
const int subLevelsPerStage = 30;

/// One playable level of the campaign: the board/cup come from its parent
/// [Stage], but the turn limit tightens and the AI gets sharper level by
/// level within that world, so level 30 of a world is noticeably tougher
/// than level 1 even though they share the same board.
class SubStage {
  const SubStage({
    required this.stage,
    required this.levelInStage,
    required this.globalIndex,
    required this.turnLimit,
    required this.aiHandicap,
  });

  final Stage stage;

  /// 1-based position within the parent stage (1-30).
  final int levelInStage;

  /// 1-based position across the whole campaign (1-120).
  final int globalIndex;

  final int turnLimit;
  final double aiHandicap;

  String get name => '${stage.name} · Niveau $levelInStage';

  /// Every level of every stage, in play order. Computed once — a within-
  /// world difficulty ramp is layered on top of each [Stage]'s base numbers
  /// so the jump into the next world never feels abrupt.
  static final List<SubStage> all = [
    for (final stage in Stage.all)
      for (var level = 1; level <= subLevelsPerStage; level++)
        SubStage(
          stage: stage,
          levelInStage: level,
          globalIndex: (stage.index - 1) * subLevelsPerStage + level,
          turnLimit: (stage.turnLimit - (level - 1) / (subLevelsPerStage - 1) * stage.turnLimit * 0.3)
              .round()
              .clamp(6, 99),
          aiHandicap:
              (stage.aiHandicap + (level - 1) / (subLevelsPerStage - 1) * 0.12).clamp(0.0, 0.85),
        ),
  ];
}
