// Dev-only tool: renders the app launcher icon to a PNG using Flutter's
// test rendering pipeline (dart:ui needs the Flutter engine, which only
// `flutter test` provides outside of a running app). Run with:
//   flutter test tool/icon_gen_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _accent = Color(0xFFFB8C00);
const _accentDark = Color(0xFFE65100);

class _AppIcon extends StatelessWidget {
  const _AppIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1024,
      height: 1024,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_accent, _accentDark],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ladder motif, bottom-left.
          Positioned(
            left: 90,
            bottom: 70,
            child: Transform.rotate(
              angle: -0.25,
              child: CustomPaint(size: const Size(260, 420), painter: _LadderPainter()),
            ),
          ),
          // Snake motif, top-right.
          Positioned(
            right: 60,
            top: 60,
            child: CustomPaint(size: const Size(300, 300), painter: _SnakePainter()),
          ),
          // Dice, centred.
          Container(
            width: 460,
            height: 460,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(90),
              boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 30, offset: Offset(0, 18))],
            ),
            padding: const EdgeInsets.all(70),
            child: Column(
              children: [
                Expanded(child: Row(children: [_pip(true), _pip(false), _pip(true)])),
                Expanded(child: Row(children: [_pip(false), _pip(true), _pip(false)])),
                Expanded(child: Row(children: [_pip(true), _pip(false), _pip(true)])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pip(bool show) {
    return Expanded(
      child: Center(
        child: show
            ? Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(color: _accentDark, shape: BoxShape.circle),
              )
            : const SizedBox(),
      ),
    );
  }
}

class _LadderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rail = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(40, 0), Offset(40, size.height), rail);
    canvas.drawLine(Offset(size.width - 40, 0), Offset(size.width - 40, size.height), rail);
    final rung = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;
    for (var y = 30.0; y < size.height; y += 70) {
      canvas.drawLine(Offset(40, y), Offset(size.width - 40, y), rung);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SnakePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.85, size.height * 0.1)
      ..quadraticBezierTo(size.width * 1.05, size.height * 0.35, size.width * 0.7, size.height * 0.45)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.55, size.width * 0.55, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.65, size.height * 0.95, size.width * 0.4, size.height * 1.05);

    final outline = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 58
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, outline);

    final body = Paint()
      ..color = const Color(0xFF66BB6A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 48
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, body);

    final head = Paint()..color = const Color(0xFF388E3C);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.1), 40, head);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void main() {
  testWidgets('generate app icon', (tester) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(key: key, child: const _AppIcon()),
      ),
    );
    await tester.pump();
    final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;

    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('assets/icon/app_icon.png');
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}
