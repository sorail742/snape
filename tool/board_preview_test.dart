// Dev-only tool: renders BoardPainter to a PNG so it can be visually
// inspected without deploying to a device. Run with:
//   flutter test tool/board_preview_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serpents_party/models/board_theme.dart';
import 'package:serpents_party/widgets/board_painter.dart';

void main() {
  testWidgets('generate board preview', (tester) async {
    tester.view.physicalSize = const Size(1000, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: key,
          child: Container(
            color: const Color(0xFFFCE8CE),
            alignment: Alignment.topCenter,
            child: CustomPaint(
              size: const Size(910, 650),
              painter: BoardPainter(theme: BoardTheme.classic),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;

    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File(
        r'C:\Users\keith\AppData\Local\Temp\claude\c--Users-keith-snape\d5bc627a-d7f5-46ef-8514-5cb21247ff17\scratchpad\board_preview.png',
      );
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}
