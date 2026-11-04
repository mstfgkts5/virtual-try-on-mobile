import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:see_it_on/core/design/theme.dart';
import 'package:see_it_on/core/design/widgets.dart';

Widget _host(Widget child, Brightness b) => MaterialApp(
      theme: buildTheme(b),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

Widget _all() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const EditorialOverline('NE DENEMEK İSTİYORSUN?'),
        const EditorialHeading('Stüdyo Kabin'),
        const Caption('Alt Giyim — 40 sn, yerel GPU', italic: true),
        const HairlineDivider(),
        PillButton(label: 'Confirm and Add to Wardrobe', icon: Icons.check, onPressed: () {}),
        PillButton(label: 'Paylaş', primary: false, onPressed: () {}),
        SegmentedPills<String>(
          options: const [('upper', 'Upper wear'), ('lower', 'Lower wear'), ('overall', 'Full outfit')],
          value: 'upper',
          onChanged: (_) {},
        ),
        const EditorialCard(child: Text('kart')),
      ],
    );

void main() {
  for (final b in Brightness.values) {
    testWidgets('bileşenler ${b.name} temada 360 px taşmasız', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_host(_all(), b));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('SegmentedPills seçim bildirir', (tester) async {
    String? picked;
    await tester.pumpWidget(_host(
      SegmentedPills<String>(
        options: const [('a', 'A'), ('b', 'B'), ('c', 'C')],
        value: 'a',
        onChanged: (v) => picked = v,
      ),
      Brightness.light,
    ));
    await tester.tap(find.text('B'));
    expect(picked, 'b');
  });

  testWidgets('PillButton busy iken basılmaz', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(PillButton(label: 'Kaydet', busy: true, onPressed: () => taps++), Brightness.light));
    await tester.tap(find.byType(PillButton));
    expect(taps, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('pushEditorial ekranı açar', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(Brightness.light),
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => pushEditorial(context, const Scaffold(body: Text('YENİ'))),
          child: const Text('AÇ'),
        ),
      ),
    ));
    await tester.tap(find.text('AÇ'));
    await tester.pumpAndSettle();
    expect(find.text('YENİ'), findsOneWidget);
  });
}
