import 'dart:ui';

/// Board layout: a 23-square winding path (not a filled rectangle). The
/// path runs along the bottom row (1-7), jogs up a single square at the
/// right edge (8), runs back along a middle row (9-15), jogs up a single
/// square at the left edge (16), then finishes along the top row
/// (17-FIN) — exactly matching the reference board.
const int boardCols = 7;
const int boardRows = 5;

/// Length of the actual playable path.
const int totalCells = 23;

const int finishCell = totalCells;

/// Explicit (row, col) position of every cell along the winding path. Row 0
/// is the bottom row; rows 1 and 3 are single-square "turns" hugging the
/// right and left edges, matching the reference board exactly.
const List<(int, int)> _cellPositions = [
  (0, 0), (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), // 1-7
  (1, 6), // 8
  (2, 6), (2, 5), (2, 4), (2, 3), (2, 2), (2, 1), (2, 0), // 9-15
  (3, 0), // 16
  (4, 0), (4, 1), (4, 2), (4, 3), (4, 4), (4, 5), (4, 6), // 17-23
];

/// Row/column of a cell number (1-based) on the board.
({int row, int col}) cellRowCol(int cellNumber) {
  final (row, col) = _cellPositions[cellNumber - 1];
  return (row: row, col: col);
}

/// Centre point of a cell within a board of [boardWidth] x [boardHeight]
/// pixels (cells are square, sized to fit both dimensions).
Offset cellCenter(int cellNumber, double boardWidth, double boardHeight) {
  final cellWidth = boardWidth / boardCols;
  final cellHeight = boardHeight / boardRows;
  final rc = cellRowCol(cellNumber);
  final x = rc.col * cellWidth + cellWidth / 2;
  final y = boardHeight - (rc.row * cellHeight + cellHeight / 2);
  return Offset(x, y);
}
