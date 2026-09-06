import 'dart:math';

import 'package:flutter/material.dart';

class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key, required this.colors});

  final List<Color> colors;

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiPiece {
  _ConfettiPiece({
    required this.x,
    required this.delay,
    required this.duration,
    required this.color,
    required this.size,
    required this.swayPhase,
  });

  final double x;
  final double delay;
  final double duration;
  final Color color;
  final double size;
  final double swayPhase;
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ConfettiPiece> _pieces;

  @override
  void initState() {
    super.initState();
    final random = Random();
    _pieces = List.generate(36, (i) {
      final color = widget.colors[i % widget.colors.length];
      return _ConfettiPiece(
        x: random.nextDouble(),
        delay: random.nextDouble() * 0.4,
        duration: 0.6 + random.nextDouble() * 0.4,
        color: color,
        size: 6 + random.nextDouble() * 6,
        swayPhase: random.nextDouble() * pi * 2,
      );
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _ConfettiPainter(pieces: _pieces, t: _controller.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.pieces, required this.t});

  final List<_ConfettiPiece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in pieces) {
      final localT = ((t - piece.delay) / piece.duration).clamp(0.0, 1.0);
      if (localT <= 0) continue;
      final dy = localT * size.height;
      final sway = sin(localT * pi * 4 + piece.swayPhase) * size.width * 0.05;
      final dx = piece.x * size.width + sway;
      final paint = Paint()..color = piece.color.withValues(alpha: 1 - localT * 0.3);
      final rect = Rect.fromCenter(
        center: Offset(dx, dy),
        width: piece.size,
        height: piece.size * 1.6,
      );
      canvas.save();
      canvas.translate(rect.center.dx, rect.center.dy);
      canvas.rotate(localT * pi * 3 + piece.swayPhase);
      canvas.translate(-rect.center.dx, -rect.center.dy);
      canvas.drawRect(rect, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.t != t;
}
