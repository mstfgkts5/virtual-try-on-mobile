import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:see_it_on/widgets/spin_viewer.dart';

import 'helpers.dart';

// 1x1 şeffaf PNG
final _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

List<ImageProvider> frames(int n) => List.generate(n, (_) => MemoryImage(_png));

Future<SpinViewerController> pumpViewer(WidgetTester tester, int n, {double width = 400}) async {
  final c = SpinViewerController();
  await tester.pumpWidget(localized(Scaffold(
    body: Center(child: SizedBox(width: width, height: width * 4 / 3, child: SpinViewer(frames: frames(n), controller: c))),
  )));
  return c;
}

void main() {
  testWidgets('sürükleme kareyi değiştirir', (tester) async {
    final c = await pumpViewer(tester, 8);
    await tester.drag(find.byType(SpinViewer), const Offset(-50, 0), touchSlopX: 0);
    await tester.pump();
    expect(c.position, closeTo(1.0, 0.05));
  });

  testWidgets('tam genişlik tam tur', (tester) async {
    final c = await pumpViewer(tester, 8);
    await tester.drag(find.byType(SpinViewer), const Offset(-400, 0), touchSlopX: 0);
    await tester.pump();
    expect(c.position, closeTo(0, 0.05));
  });

  testWidgets('tek karede döndürme yok', (tester) async {
    final c = await pumpViewer(tester, 1);
    await tester.drag(find.byType(SpinViewer), const Offset(-100, 0), touchSlopX: 0);
    await tester.pump();
    expect(c.position, 0);
    c.play();
    await tester.pump();
    expect(c.isPlaying, isFalse);
  });

  testWidgets('play tam turu 4 saniyede bitirir', (tester) async {
    final c = await pumpViewer(tester, 8);
    c.play();
    await tester.pump();
    expect(c.isPlaying, isTrue);
    await tester.pump(const Duration(seconds: 2));
    expect(c.position, closeTo(4, 0.3));
    await tester.pump(const Duration(milliseconds: 2100));
    expect(c.isPlaying, isFalse);
    expect(c.position, closeTo(0, 0.05));
  });

  testWidgets('kare eklenince konum korunur', (tester) async {
    final c = SpinViewerController();
    Widget host(int n) => localized(Scaffold(
          body: Center(child: SizedBox(width: 400, height: 533, child: SpinViewer(frames: frames(n), controller: c))),
        ));
    await tester.pumpWidget(host(4));
    await tester.drag(find.byType(SpinViewer), const Offset(-200, 0), touchSlopX: 0);
    await tester.pump();
    expect(c.position, closeTo(2, 0.05));
    await tester.pumpWidget(host(8));
    expect(c.position, closeTo(2, 0.05));
  });

  testWidgets('fırlatınca dönmeye devam eder ve durur', (tester) async {
    final c = await pumpViewer(tester, 48);
    await tester.fling(find.byType(SpinViewer), const Offset(-100, 0), 1500);
    final atRelease = c.position;
    await tester.pump(const Duration(milliseconds: 200));
    final later = c.position;
    // Parmak kalktıktan sonra da ileri dönmeye devam eder
    expect(later, greaterThan(atRelease));
    await tester.pumpAndSettle();
    final settled = c.position;
    await tester.pump(const Duration(milliseconds: 300));
    expect(c.position, settled); // sonunda durur
  });

  testWidgets('dokununca eylemsizlik durur', (tester) async {
    final c = await pumpViewer(tester, 48);
    await tester.fling(find.byType(SpinViewer), const Offset(-100, 0), 1500);
    await tester.pump(const Duration(milliseconds: 50));
    final gesture = await tester.startGesture(tester.getCenter(find.byType(SpinViewer)));
    await tester.pump(const Duration(milliseconds: 50));
    final held = c.position;
    await tester.pump(const Duration(milliseconds: 300));
    expect(c.position, held);
    await gesture.up();
  });

  testWidgets('Döndür fırlatmayı durdurur, tam tur başladığı yere döner', (tester) async {
    final c = await pumpViewer(tester, 48);
    await tester.fling(find.byType(SpinViewer), const Offset(-100, 0), 1500);
    await tester.pump(const Duration(milliseconds: 50));
    final start = c.position;
    c.play();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 4100));
    expect(c.isPlaying, isFalse);
    expect(c.position, closeTo(start, 0.05));
  });

  testWidgets('Durdur fırlatmayı da durdurur', (tester) async {
    final c = await pumpViewer(tester, 48);
    await tester.fling(find.byType(SpinViewer), const Offset(-100, 0), 1500);
    await tester.pump(const Duration(milliseconds: 50));
    c.stop();
    final held = c.position;
    await tester.pump(const Duration(milliseconds: 300));
    expect(c.position, held);
  });

  testWidgets('fırlatma sırasında kare gelince açı sıçramaz', (tester) async {
    final c = SpinViewerController();
    Widget host(int n) => localized(Scaffold(
          body: Center(child: SizedBox(width: 400, height: 533, child: SpinViewer(frames: frames(n), controller: c))),
        ));
    await tester.pumpWidget(host(8));
    await tester.fling(find.byType(SpinViewer), const Offset(-300, 0), 3000);
    await tester.pump(const Duration(milliseconds: 100));
    final before = c.position;
    await tester.pumpWidget(host(12));
    await tester.pump(const Duration(milliseconds: 16));
    expect(c.position, closeTo(before, 0.01));
  });

  for (final b in Brightness.values) {
    testWidgets('görüntüleyici ${b.name} 360 taşmasız', (tester) async {
      await expectNoOverflow(tester, Scaffold(body: SpinViewer(frames: frames(8))), lang: 'tr', b: b);
    });
  }
}
