/// The variable part of a board: which cells hold a snake, a ladder or a
/// bonus/malus. The physical shape of the 23-square path itself (see
/// board_data.dart) never changes between layouts — only these mappings do,
/// which is how campaign stages get harder without redrawing the board.
class BoardLayout {
  const BoardLayout({required this.snakesAndLadders, required this.bonusCells});

  /// Maps a cell start to its destination: ladders climb up (end > start),
  /// snakes slide down (end < start).
  final Map<int, int> snakesAndLadders;

  /// Bonus (positive) / malus (negative) squares that immediately shift the
  /// player by a few extra cells after landing on them.
  final Map<int, int> bonusCells;

  bool isLadder(int start) =>
      snakesAndLadders.containsKey(start) && snakesAndLadders[start]! > start;

  bool isSnake(int start) =>
      snakesAndLadders.containsKey(start) && snakesAndLadders[start]! < start;

  /// The original board, exactly matching the reference layout.
  static const classic = BoardLayout(
    snakesAndLadders: {
      // Ladders
      3: 13,
      12: 20,
      // Snakes
      17: 2,
      10: 5,
      21: 11,
    },
    bonusCells: {6: 3, 14: 2, 19: -2},
  );
}
