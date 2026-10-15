// Throwaway — renders each AppFullScreenError kind to a PNG for a quick
// visual check. Not a real test; delete after use.
import 'dart:io';
import 'dart:ui' show ImageByteFormat;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eye_care_app/widgets/app_full_screen_error.dart';

Future<void> _capture(WidgetTester tester, AppErrorKind kind, String path, {String? infoPillText}) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      home: RepaintBoundary(
        key: key,
        child: Scaffold(
          appBar: AppBar(title: const Text('Preview')),
          body: AppFullScreenError(
            kind: kind,
            message: 'preview',
            infoPillText: infoPillText,
            secondaryLabel: 'Return to Home',
            onSecondary: () {},
            onRetry: () {},
          ),
        ),
      ),
    ),
  );
  // Several short explicit pumps (never pumpAndSettle — the hero's ambient
  // AnimationController repeats forever by design, so settle() would hang)
  // to give the SVG asset's async decode a few frames to land.
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
  final rb = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final image = await rb.toImage(pixelRatio: 2.0);
  final bytes = await image.toByteData(format: ImageByteFormat.png);
  File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  testWidgets(
    'connection lost',
    (tester) async {
      tester.view.physicalSize = const Size(400, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _capture(tester, AppErrorKind.connectionLost, 'connection_lost.png');
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );

  testWidgets(
    'record not found',
    (tester) async {
      tester.view.physicalSize = const Size(400, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _capture(tester, AppErrorKind.recordNotFound, 'record_not_found.png', infoPillText: 'Last searched: #MRD-90421 · OPD Desk');
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );

  testWidgets(
    'server error',
    (tester) async {
      tester.view.physicalSize = const Size(400, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _capture(tester, AppErrorKind.serverError, 'server_error.png');
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );
}
