import 'dart:math';

import 'package:flutter/material.dart';

/// A few selectable looks for the die, purely cosmetic.
enum DiceSkin { classic, digits, neon, wood }

/// A glossy, chunky "Ludo-style" die: rounded cube face, radial gloss,
/// bevelled pips, sitting on its own shadow tray, with a physical-feeling
/// pseudo-3D tumble animation while [isRolling] is true that settles with a
/// little bounce.
class DiceWidget extends StatefulWidget {
  const DiceWidget({
    super.key,
    required this.value,
    required this.color,
    this.isRolling = false,
    this.size = 84,
    this.skin = DiceSkin.classic,
  });

  final int value;
  final Color color;
  final bool isRolling;
  final double size;
  final DiceSkin skin;

  static const _pipPositions = <int, List<Alignment>>{
    1: [Alignment.center],
    2: [Alignment.topLeft, Alignment.bottomRight],
    3: [Alignment.topLeft, Alignment.center, Alignment.bottomRight],
    4: [
      Alignment.topLeft,
      Alignment.topRight,
      Alignment.bottomLeft,
      Alignment.bottomRight,
    ],
    5: [
      Alignment.topLeft,
      Alignment.topRight,
      Alignment.center,
      Alignment.bottomLeft,
      Alignment.bottomRight,
    ],
    6: [
      Alignment.topLeft,
      Alignment.topRight,
      Alignment.centerLeft,
      Alignment.centerRight,
      Alignment.bottomLeft,
      Alignment.bottomRight,
    ],
  };

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );

  @override
  void didUpdateWidget(covariant DiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRolling && !oldWidget.isRolling) {
      _controller
        ..reset()
        ..repeat();
    } else if (!widget.isRolling && oldWidget.isRolling) {
      _controller.stop();
      _controller.animateTo(1, duration: const Duration(milliseconds: 450), curve: Curves.elasticOut);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 1.25,
      height: widget.size * 1.25,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          final rotY = widget.isRolling ? t * 2 * pi * 2.4 : (1 - t) * 0.4;
          final rotX = widget.isRolling ? sin(t * 4 * pi) * 0.4 : 0.0;
          final rotZ = widget.isRolling ? sin(t * 3 * pi) * 0.12 : 0.0;
          final scale = widget.isRolling ? 1.0 : 0.82 + t * 0.18;
          final lift = widget.isRolling ? sin(t * 4 * pi).abs() * widget.size * 0.12 : 0.0;
          final trayScale = widget.isRolling ? 1 - (lift / widget.size) * 0.6 : 1.0;
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: Offset(0, widget.size * 0.42),
                child: Transform.scale(
                  scale: trayScale,
                  child: Container(
                    width: widget.size * 0.82,
                    height: widget.size * 0.2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Colors.black.withValues(alpha: 0.28), Colors.black.withValues(alpha: 0)],
                      ),
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, -lift),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0028)
                    ..rotateX(rotX)
                    ..rotateY(rotY)
                    ..rotateZ(rotZ)
                    ..scaleByDouble(scale, scale, scale, 1),
                  child: child,
                ),
              ),
            ],
          );
        },
        child: _DiceFace(value: widget.value, color: widget.color, size: widget.size, skin: widget.skin),
      ),
    );
  }
}

class _DiceFace extends StatelessWidget {
  const _DiceFace({required this.value, required this.color, required this.size, required this.skin});

  final int value;
  final Color color;
  final double size;
  final DiceSkin skin;

  @override
  Widget build(BuildContext context) {
    final pips = DiceWidget._pipPositions[value] ?? const [];

    if (skin == DiceSkin.digits) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const RadialGradient(
            center: Alignment(-0.4, -0.4),
            radius: 1.2,
            colors: [Colors.white, Color(0xFFE3E3E3)],
          ),
          borderRadius: BorderRadius.circular(size * 0.24),
          border: Border.all(color: color, width: 3),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 6)),
            BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 16, spreadRadius: -6),
          ],
        ),
        child: Text(
          '$value',
          style: TextStyle(fontSize: size * 0.55, fontWeight: FontWeight.w900, color: color),
        ),
      );
    }

    final isNeon = skin == DiceSkin.neon;
    final isWood = skin == DiceSkin.wood;
    final faceGradient = isNeon
        ? RadialGradient(
            center: const Alignment(-0.3, -0.3),
            colors: [const Color(0xFF1B1B2E), Colors.black],
          )
        : isWood
            ? const RadialGradient(
                center: Alignment(-0.4, -0.4),
                colors: [Color(0xFFD7A86E), Color(0xFF9C6B34)],
              )
            : const RadialGradient(
                center: Alignment(-0.4, -0.4),
                radius: 1.2,
                colors: [Colors.white, Color(0xFFE3E3E3)],
              );
    final pipColor = isNeon ? color : (isWood ? const Color(0xFF3E2611) : color);
    final borderColor = isNeon ? color : (isWood ? const Color(0xFF5C3A1A) : color);

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.17),
      decoration: BoxDecoration(
        gradient: faceGradient,
        borderRadius: BorderRadius.circular(size * 0.24),
        border: Border.all(color: borderColor, width: 3),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 6)),
          if (isNeon)
            BoxShadow(color: color.withValues(alpha: 0.75), blurRadius: 22, spreadRadius: 1)
          else
            BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 16, spreadRadius: -6),
        ],
      ),
      child: Stack(
        children: [
          // Inner bevel line for a moulded-plastic look.
          Positioned.fill(
            child: Container(
              margin: EdgeInsets.all(size * 0.02),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.2),
                border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1),
              ),
            ),
          ),
          // A brighter bevel arc on just the top-left edges — the ones
          // catching the light — for a real moulded-plastic/resin look
          // instead of a flat square with a gradient painted on top.
          Positioned.fill(
            child: CustomPaint(painter: _BevelHighlightPainter(radius: size * 0.2)),
          ),
          // Glossy highlight streak.
          Positioned(
            top: size * 0.04,
            left: size * 0.06,
            child: Transform.rotate(
              angle: -0.5,
              child: Container(
                width: size * 0.4,
                height: size * 0.16,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(size * 0.2),
                ),
              ),
            ),
          ),
          ...pips.map(
            (alignment) => Align(
              alignment: alignment,
              child: Container(
                width: size * 0.18,
                height: size * 0.18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.3, -0.3),
                    colors: [Color.lerp(pipColor, Colors.white, 0.25)!, pipColor],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 2,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws a bright stroke along just the top and left edges of a rounded
/// square, fading out toward the bottom-right — the classic "light hits the
/// upper-left bevel" cue that reads as a real moulded edge rather than a
/// flat gradient-filled square.
class _BevelHighlightPainter extends CustomPainter {
  const _BevelHighlightPainter({required this.radius});
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: pi,
        endAngle: pi * 2.5,
        colors: const [
          Colors.transparent,
          Colors.white,
          Colors.white,
          Colors.transparent,
        ],
        stops: const [0.0, 0.15, 0.55, 0.75],
        transform: GradientRotation(-pi / 4),
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BevelHighlightPainter oldDelegate) => false;
}
