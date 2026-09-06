import 'dart:math';

import 'package:flutter/material.dart';

import '../models/board_data.dart';
import '../models/board_layout.dart';
import '../models/board_theme.dart';

/// Draws the board to look like the reference video's hand-drawn paper
/// sheet: slightly wobbly pencil-style squares (not perfect geometry), each
/// snake styled to match its real-life counterpart (yellow-striped,
/// olive-striped, and a beaded pink/red one), sitting on a "paper on a
/// table" background.
class BoardPainter extends CustomPainter {
  BoardPainter({this.theme = BoardTheme.classic, this.layout = BoardLayout.classic});

  final BoardTheme theme;
  final BoardLayout layout;

  // Video-accurate per-snake styling for the classic theme. Other themes
  // fall back to one unified colour scheme (see [_snakeColorsFor]).
  static const _snakeStyles = <int, (Color, Color, bool)>{
    17: (Color(0xFFFFC107), Color(0xFF1A1A1A), false), // yellow, black stripes
    10: (Color(0xFF9E9D24), Color(0xFF1A1A1A), false), // olive, black stripes
    21: (Color(0xFFEF5350), Color(0xFFB71C1C), true), // pink/red, beaded
  };

  @override
  void paint(Canvas canvas, Size size) {
    final boardWidth = size.width;
    final boardHeight = size.height;
    final cellWidth = boardWidth / boardCols;
    final cellHeight = boardHeight / boardRows;
    // Cells stretch to fill the screen exactly (not necessarily square, just
    // like the reference board), but line weights and decorations still
    // need one reference scale to stay proportionate.
    final cellSize = min(cellWidth, cellHeight);

    // The paper sheet itself, with a softly wobbly cut edge and a drop
    // shadow so it visually sits above the wood background behind it.
    final paperRect = Rect.fromLTWH(0, 0, boardWidth, boardHeight).deflate(cellSize * 0.03);
    final paperPath = _wobblyRectPath(paperRect, seed: 1, jitterFactor: 0.01);
    canvas.drawShadow(paperPath, Colors.black, 6, false);
    canvas.drawPath(paperPath, Paint()..color = theme.paperColor);

    final inkPaint = Paint()
      ..color = theme.gridLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.6, cellSize * 0.018)
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    // Only the 23 real path squares are drawn — no filler decoration — so
    // the board reads as the winding path it actually is, with genuine
    // empty gaps where the path turns a corner. Cell rects are kept here so
    // the label pass below can redraw text on top of the snakes/ladders,
    // which are painted in between (otherwise a snake body can cover a
    // bonus label it happens to curve over).
    final cellRects = <int, Rect>{};
    for (var cell = 1; cell <= totalCells; cell++) {
      final rc = cellRowCol(cell);
      final left = rc.col * cellWidth;
      final top = boardHeight - (rc.row + 1) * cellHeight;
      final rect = Rect.fromLTWH(left, top, cellWidth, cellHeight).deflate(cellSize * 0.06);
      cellRects[cell] = rect;

      final isFinish = cell == finishCell;
      final cellPath = _wobblyRectPath(rect, seed: cell, jitterFactor: 0.05);
      if (isFinish) {
        canvas.drawPath(cellPath, Paint()..color = theme.finishCell);
      }
      canvas.drawPath(cellPath, inkPaint);
    }

    layout.snakesAndLadders.forEach((start, end) {
      final startCentre = cellCenter(start, boardWidth, boardHeight);
      final endCentre = cellCenter(end, boardWidth, boardHeight);
      if (end > start) {
        _drawLadder(canvas, startCentre, endCentre, cellSize);
      } else {
        _drawSnake(canvas, startCentre, endCentre, cellSize, start);
      }
    });

    cellRects.forEach((cell, rect) {
      if (cell == 1) {
        _drawCentredLabel(canvas, rect, 'GO', theme.gridLine, cellSize * 0.26);
        return;
      }
      if (cell == finishCell) {
        _drawIcon(
          canvas,
          Offset(rect.center.dx, rect.center.dy - rect.height * 0.17),
          Icons.emoji_events_rounded,
          theme.gridLine,
          cellSize * 0.32,
        );
        _drawCentredLabel(
          canvas,
          Rect.fromCenter(
            center: Offset(rect.center.dx, rect.center.dy + rect.height * 0.24),
            width: rect.width,
            height: rect.height * 0.3,
          ),
          'FINISH',
          theme.gridLine,
          cellSize * 0.15,
        );
        return;
      }
      final bonus = layout.bonusCells[cell];
      if (bonus != null) {
        _drawCentredLabel(
          canvas,
          rect,
          bonus > 0 ? '+$bonus' : '$bonus',
          bonus > 0 ? theme.bonusText : theme.malusText,
          cellSize * 0.34,
        );
      }
    });
  }

  /// A rectangle redrawn as a slightly irregular hand-drawn path: each
  /// corner is nudged and each edge gently bowed by a deterministic amount
  /// (seeded so it stays put across repaints instead of flickering).
  Path _wobblyRectPath(Rect rect, {required int seed, required double jitterFactor}) {
    final rnd = Random(seed);
    final jitter = rect.shortestSide * jitterFactor;
    Offset j() => Offset((rnd.nextDouble() - 0.5) * jitter, (rnd.nextDouble() - 0.5) * jitter);

    final tl = rect.topLeft + j();
    final tr = rect.topRight + j();
    final br = rect.bottomRight + j();
    final bl = rect.bottomLeft + j();

    Offset bow(Offset a, Offset b) =>
        Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2) + j() * 0.6;

    final path = Path()..moveTo(tl.dx, tl.dy);
    var m = bow(tl, tr);
    path.quadraticBezierTo(m.dx, m.dy, tr.dx, tr.dy);
    m = bow(tr, br);
    path.quadraticBezierTo(m.dx, m.dy, br.dx, br.dy);
    m = bow(br, bl);
    path.quadraticBezierTo(m.dx, m.dy, bl.dx, bl.dy);
    m = bow(bl, tl);
    path.quadraticBezierTo(m.dx, m.dy, tl.dx, tl.dy);
    path.close();
    return path;
  }

  void _drawCentredLabel(
    Canvas canvas,
    Rect rect,
    String text,
    Color color,
    double fontSize,
  ) {
    final haloPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = fontSize * 0.22
            ..color = theme.paperColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    haloPainter.paint(
      canvas,
      rect.center - Offset(haloPainter.width / 2, haloPainter.height / 2),
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w900),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      rect.center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  /// Draws a Material icon glyph directly on the canvas (the standard trick:
  /// icons are just glyphs in the bundled MaterialIcons font).
  void _drawIcon(Canvas canvas, Offset center, IconData icon, Color color, double size) {
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
  }

  void _drawLadder(Canvas canvas, Offset start, Offset end, double cellSize) {
    final direction = (end - start);
    final length = direction.distance;
    final unit = Offset(direction.dx / length, direction.dy / length);
    final perpendicular = Offset(-unit.dy, unit.dx) * (cellSize * 0.14);

    final rail1Start = start + perpendicular;
    final rail1End = end + perpendicular;
    final rail2Start = start - perpendicular;
    final rail2End = end - perpendicular;

    final railPaint = Paint()
      ..color = theme.ladderRail
      ..strokeWidth = cellSize * 0.06
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(rail1Start, rail1End, railPaint);
    canvas.drawLine(rail2Start, rail2End, railPaint);

    final rungPaint = Paint()
      ..color = theme.ladderRung
      ..strokeWidth = cellSize * 0.05
      ..strokeCap = StrokeCap.round;

    final rungCount = max(4, (length / (cellSize * 0.35)).round());
    for (var i = 1; i < rungCount; i++) {
      final t = i / rungCount;
      final p1 = Offset.lerp(rail1Start, rail1End, t)!;
      final p2 = Offset.lerp(rail2Start, rail2End, t)!;
      canvas.drawLine(p1, p2, rungPaint);
    }
  }

  (Color, Color, bool) _snakeColorsFor(int start) {
    if (theme.id == 'classic') {
      final style = _snakeStyles[start];
      if (style != null) return style;
    }
    return (theme.snakeBody, theme.snakeOutline, false);
  }

  void _drawSnake(Canvas canvas, Offset start, Offset end, double cellSize, int startCell) {
    final path = Path()..moveTo(start.dx, start.dy);
    final segments = 4;
    final direction = end - start;
    for (var i = 1; i <= segments; i++) {
      final t = i / segments;
      final base = Offset.lerp(start, end, t)!;
      final wiggle = sin(t * pi * 3) * cellSize * 0.5;
      final perp = Offset(-direction.dy, direction.dx);
      final normPerp = perp / perp.distance;
      final control = base + normPerp * wiggle;
      final prevT = (i - 0.5) / segments;
      final prevBase = Offset.lerp(start, end, prevT)!;
      final prevWiggle = sin(prevT * pi * 3) * cellSize * 0.5;
      final quadControl = prevBase + normPerp * prevWiggle;
      path.quadraticBezierTo(quadControl.dx, quadControl.dy, control.dx, control.dy);
    }

    final (primary, band, beaded) = _snakeColorsFor(startCell);
    final thickness = cellSize * 0.15;

    // A dark ink outline underneath makes the body read clearly against the
    // paper regardless of theme.
    canvas.drawPath(
      path,
      Paint()
        ..color = theme.gridLine.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness + cellSize * 0.05
        ..strokeCap = StrokeCap.round,
    );

    if (beaded) {
      _drawBeadedBody(canvas, path, thickness, primary, band);
    } else {
      _drawStripedBody(canvas, path, thickness, primary, band, cellSize);
    }

    final headRadius = cellSize * 0.12;
    final headPaint = Paint()..color = primary;
    canvas.drawCircle(start, headRadius, headPaint);
    canvas.drawCircle(start, headRadius, Paint()
      ..color = theme.gridLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4);

    final eyeOffset = headRadius * 0.45;
    final eyePaint = Paint()..color = Colors.white;
    canvas.drawCircle(start + Offset(-eyeOffset, -eyeOffset), headRadius * 0.32, eyePaint);
    canvas.drawCircle(start + Offset(eyeOffset, -eyeOffset), headRadius * 0.32, eyePaint);
    final pupilPaint = Paint()..color = Colors.black;
    canvas.drawCircle(start + Offset(-eyeOffset, -eyeOffset), headRadius * 0.15, pupilPaint);
    canvas.drawCircle(start + Offset(eyeOffset, -eyeOffset), headRadius * 0.15, pupilPaint);
  }

  /// Alternating coloured bands along the path, like the yellow and olive
  /// snakes in the video.
  void _drawStripedBody(
    Canvas canvas,
    Path path,
    double thickness,
    Color primary,
    Color stripe,
    double cellSize,
  ) {
    final metric = path.computeMetrics().first;
    final total = metric.length;
    final segmentLen = cellSize * 0.16;
    var distance = 0.0;
    var i = 0;
    while (distance < total) {
      final len = min(segmentLen, total - distance);
      final tangent = metric.getTangentForOffset(distance + len / 2);
      if (tangent == null) break;
      final paint = Paint()..color = i.isEven ? primary : stripe;
      canvas.save();
      canvas.translate(tangent.position.dx, tangent.position.dy);
      canvas.rotate(tangent.angle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: len + 1.5, height: thickness),
          Radius.circular(thickness * 0.25),
        ),
        paint,
      );
      canvas.restore();
      distance += len;
      i++;
    }
  }

  /// Separated oval beads along the path, like the video's pink/red snake.
  void _drawBeadedBody(Canvas canvas, Path path, double thickness, Color primary, Color dark) {
    final metric = path.computeMetrics().first;
    final total = metric.length;
    final beadSpacing = thickness * 0.85;
    var distance = 0.0;
    var i = 0;
    while (distance < total) {
      final tangent = metric.getTangentForOffset(distance);
      if (tangent == null) break;
      final color = i.isEven ? primary : Color.lerp(primary, dark, 0.5)!;
      canvas.save();
      canvas.translate(tangent.position.dx, tangent.position.dy);
      canvas.rotate(tangent.angle);
      final bead = Rect.fromCenter(center: Offset.zero, width: beadSpacing * 0.95, height: thickness);
      canvas.drawOval(bead, Paint()..color = color);
      canvas.drawOval(
        bead,
        Paint()
          ..color = dark.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      canvas.restore();
      distance += beadSpacing;
      i++;
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) =>
      oldDelegate.theme != theme || oldDelegate.layout != layout;
}
