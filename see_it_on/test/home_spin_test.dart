import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:see_it_on/screens/home_screen.dart';
import 'package:see_it_on/screens/live_tryon_screen.dart';
import 'package:see_it_on/screens/loading_screen.dart';
import 'package:see_it_on/screens/spin_screen.dart';
import 'package:see_it_on/services/media_picker.dart';

import 'helpers.dart';

// 1x1 şeffaf PNG
final _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

class FakePicker implements MediaPicker {
  FakePicker({this.videoBytes = 10});
  final int videoBytes;

  @override
  Future<XFile?> pickImage(ImageSource source) async => XFile.fromData(_png, name: 'photo.png');

  @override
  Future<XFile?> pickVideo(ImageSource source) async => XFile.fromData(Uint8List(videoBytes), name: 'turn.mov');
}

/// Hazır set manifest'ini ve karelerini sağlayan sahte varlık paketi; diğer varlıklar gerçek paketten.
class FakeBundle extends CachingAssetBundle {
  FakeBundle({this.withPreset = true});
  final bool withPreset;

  @override
  Future<ByteData> load(String key) async {
    if (key.startsWith('assets/images/spin/demo/')) {
      if (key.endsWith('manifest.json')) {
        if (!withPreset) throw FlutterError('yok');
        final json = utf8.encode(jsonEncode({'title_tr': 'Demo', 'title_en': 'Demo', 'frames': 3}));
        return ByteData.sublistView(Uint8List.fromList(json));
      }
      return ByteData.sublistView(_png);
    }
    return rootBundle.load(key);
  }
}

Widget home({bool preset = true, int videoBytes = 10}) => DefaultAssetBundle(
      bundle: FakeBundle(withPreset: preset),
      child: HomeScreen(picker: FakePicker(videoBytes: videoBytes)),
    );

Future<void> tapText(WidgetTester tester, String text) async {
  final f = find.text(text).first;
  await tester.ensureVisible(f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  final l = l10nFor('tr');

  setUp(() {});

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(localized(home()));
    await tester.pumpAndSettle();
  }

  testWidgets('video seçilince dönüş etiketi ve arka görsel alanı görünür', (tester) async {
    await open(tester);
    expect(find.text(l.homeGarmentBack), findsNothing);
    await tapText(tester, l.homeSpinVideo);
    expect(find.text(l.homeSpinSelected), findsOneWidget);
    expect(find.text(l.homeGarmentBack), findsOneWidget);
  });

  testWidgets('60 MB üstü video seçilmez ve uyarı gösterilir', (tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(localized(home(videoBytes: 60 * 1024 * 1024 + 1)));
    await tester.pumpAndSettle();
    await tapText(tester, l.homeSpinVideo);
    expect(find.text(l.homeSpinTooLarge), findsOneWidget);
    expect(find.text(l.homeSpinSelected), findsNothing);
  });

  testWidgets('Canlı dene örnek kıyafetlerle canlı ekranı açar', (tester) async {
    await open(tester);
    // Canlı ekranda kamera açılırken dönen gösterge olduğu için pumpAndSettle yerine birkaç kare ilerletilir
    final btn = find.text(l.homeLive);
    await tester.ensureVisible(btn);
    await tester.tap(btn);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    final live = tester.widget<LiveTryOnScreen>(find.byType(LiveTryOnScreen, skipOffstage: false));
    expect(live.garments.map((g) => g.id), contains('blazer'));
    expect(live.garments.length, 10);
    expect(live.garments.where((g) => g.category == 'upper').map((g) => g.id),
        ['blazer', 'shirt-stripe', 'hoodie', 'sweater-wave', 'turtleneck']);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('video ve fotoğraf birbirini temizler', (tester) async {
    await open(tester);
    await tapText(tester, l.homeSpinVideo);
    expect(find.text(l.homeSpinSelected), findsOneWidget);
    await tapText(tester, l.homeGallery); // 1. adımın Galeri düğmesi
    expect(find.text(l.homeSpinSelected), findsNothing);
    await tapText(tester, l.homeSpinVideo);
    expect(find.text(l.homeSpinSelected), findsOneWidget);
  });

  testWidgets('video varken Üzerimde Gör SpinScreen açar', (tester) async {
    await open(tester);
    await tapText(tester, l.homeSpinVideo);
    await tester.tap(find.text(l.homeGallery).at(1)); // 2. adım: kıyafet
    await tester.pumpAndSettle();
    final tryOn = find.text(l.homeTryOn);
    await tester.ensureVisible(tryOn);
    await tester.tap(tryOn);
    await tester.pump(); // yeni rota ilk karede sahne dışında kurulur
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(SpinScreen), findsOneWidget);
    expect(find.byType(LoadingScreen, skipOffstage: false), findsNothing);
  });

  testWidgets('fotoğrafla Üzerimde Gör LoadingScreen açar', (tester) async {
    await open(tester);
    await tapText(tester, l.homeGallery);
    await tester.tap(find.text(l.homeGallery).at(1));
    await tester.pumpAndSettle();
    final tryOn = find.text(l.homeTryOn);
    await tester.ensureVisible(tryOn);
    await tester.tap(tryOn);
    await tester.pump();
    // Testte backend isteği hata döner ve ekran kendini kapatır; bu yüzden rota kurulduğu ilk karede bakılır
    expect(find.byType(LoadingScreen, skipOffstage: false), findsOneWidget);
    expect(find.byType(SpinScreen, skipOffstage: false), findsNothing);
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
  });

  testWidgets('hazır set kartı manken seçicide görünür ve SpinScreen açar', (tester) async {
    await open(tester);
    await tapText(tester, l.homeMannequin);
    expect(find.text(l.homeSpinPreset), findsOneWidget);
    await tester.tap(find.text(l.homeSpinPreset));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(SpinScreen), findsOneWidget);
  });

  testWidgets('manifest yoksa hazır set kartı gizli', (tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(localized(home(preset: false)));
    await tester.pumpAndSettle();
    await tapText(tester, l.homeMannequin);
    expect(find.text(l.homeSpinPreset), findsNothing);
  });

  for (final (lang, b) in [('tr', Brightness.light), ('en', Brightness.dark)]) {
    testWidgets('video seçili ana ekran $lang/${b.name} 360 taşmasız', (tester) async {
      await expectNoOverflow(tester, home(), lang: lang, b: b);
      final l2 = l10nFor(lang);
      final video = find.text(l2.homeSpinVideo);
      await tester.ensureVisible(video);
      await tester.tap(video);
      await tester.pumpAndSettle();
      expect(find.text(l2.homeSpinSelected), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
