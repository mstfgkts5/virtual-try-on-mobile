import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:see_it_on/screens/camera_capture_screen.dart';
import 'package:see_it_on/services/camera_service.dart';

import 'helpers.dart';

class FakeCameraService implements CameraService {
  FakeCameraService({this.initError});

  final Object? initError;
  // 1x1 şeffaf PNG: Image.memory'nin çözebileceği en küçük geçerli görsel
  final bytes = Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82,
  ]);
  int captures = 0;
  int inits = 0;
  int switches = 0;
  bool disposed = false;

  /// true iken her init bir Completer'da bekler (eşzamanlı başlatma senaryoları için)
  bool holdInits = false;
  final pendingInits = <Completer<void>>[];
  Completer<void>? switchGate;

  @override
  Future<void> init({bool front = true}) async {
    inits++;
    disposed = false;
    if (holdInits) {
      final c = Completer<void>();
      pendingInits.add(c);
      await c.future;
    }
    if (initError != null) throw initError!;
  }

  @override
  Widget preview() => const ColoredBox(color: Colors.grey, key: ValueKey('fake-preview'));

  @override
  Future<Uint8List> capture() async {
    // Gerçek servis gibi: bırakılmış kamerayla çekim yapılamaz
    if (disposed) throw const NoCameraException();
    captures++;
    return bytes;
  }

  @override
  Future<void> switchCamera() async {
    switches++;
    await switchGate?.future;
  }

  @override
  Future<void> dispose() async => disposed = true;

  @override
  bool get hasMultipleCameras => true;
}

/// Kamerayı bir düğmeyle açar; dönen değeri [results]'a yazar.
Future<void> _open(WidgetTester tester, FakeCameraService fake, List<Object?> results) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(localized(Builder(
    builder: (context) => Scaffold(
      body: TextButton(
        onPressed: () async {
          results.add(await Navigator.push<Object>(
            context,
            MaterialPageRoute(builder: (_) => CameraCaptureScreen(service: fake, countdown: Duration.zero)),
          ));
        },
        child: const Text('AÇ'),
      ),
    ),
  )));
  await tester.tap(find.text('AÇ'));
  await tester.pumpAndSettle();
}

/// Uygulamanın arka plana geçip dönmesini taklit eder.
Future<void> _background(WidgetTester tester) async {
  for (final s in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]) {
    tester.binding.handleAppLifecycleStateChanged(s);
  }
  await tester.pump();
  for (final s in [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
    tester.binding.handleAppLifecycleStateChanged(s);
  }
  await tester.pump();
}

void main() {
  final l = l10nFor('tr');

  test('kamera hata kodları doğru sınıflanır', () {
    expect(classifyCameraError('CameraAccessDenied'), isA<CameraAccessDeniedException>());
    expect(classifyCameraError('CameraAccessDeniedWithoutPrompt'), isA<CameraAccessDeniedException>());
    expect(classifyCameraError('CameraAccessRestricted'), isA<CameraAccessDeniedException>());
    expect(classifyCameraError('cameraPermission'), isA<CameraAccessDeniedException>());
    // İzin penceresi hâlâ açık: "izin reddedildi" değildir
    expect(classifyCameraError('CameraPermissionsRequestOngoing'), isNull);
    expect(classifyCameraError('cameraNotFound'), isA<NoCameraException>());
  });

  testWidgets('arka plandan dönünce tekrar çek kamerayı yeniden açar', (tester) async {
    final fake = FakeCameraService();
    await _open(tester, fake, []);
    await tester.tap(find.byKey(const ValueKey('camera-shutter')));
    await tester.pumpAndSettle();
    expect(find.text(l.cameraUse), findsOneWidget);

    await _background(tester);
    await tester.pumpAndSettle();
    // Arka planda bırakılan kamera dönüşte yeniden açıldı; çekilen fotoğraf ekranda kaldı
    expect(fake.inits, 2);
    expect(fake.disposed, isFalse);
    expect(find.text(l.cameraUse), findsOneWidget);
    await tester.tap(find.text(l.cameraRetake));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('camera-shutter')));
    await tester.pumpAndSettle();
    expect(fake.captures, 2);
    expect(find.text(l.cameraUse), findsOneWidget);
  });

  testWidgets('önizlemedeyken arka plandan dönülürse kamera yeniden açılır', (tester) async {
    final fake = FakeCameraService();
    await _open(tester, fake, []);
    await _background(tester);
    await tester.pumpAndSettle();
    expect(fake.inits, 2);
    await tester.tap(find.byKey(const ValueKey('camera-shutter')));
    await tester.pumpAndSettle();
    expect(fake.captures, 1);
  });

  testWidgets('kamera değiştirilirken ikinci dokunuş yok sayılır', (tester) async {
    final fake = FakeCameraService()..switchGate = Completer<void>();
    await _open(tester, fake, []);
    await tester.tap(find.byTooltip(l.cameraSwitch));
    await tester.pump();
    expect(find.byTooltip(l.cameraSwitch), findsNothing);
    fake.switchGate!.complete();
    await tester.pumpAndSettle();
    expect(fake.switches, 1);
    expect(find.byTooltip(l.cameraSwitch), findsOneWidget);
  });

  testWidgets('eski başlatmanın geç gelen hatası yok sayılır', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final fake = FakeCameraService()..holdInits = true;
    await tester.pumpWidget(localized(CameraCaptureScreen(service: fake, countdown: Duration.zero)));
    await tester.pump();
    await _background(tester); // ilk başlatma sürerken arka plan → ikinci başlatma
    expect(fake.pendingInits.length, 2);

    fake.pendingInits[1].complete();
    await tester.pump();
    fake.pendingInits[0].completeError(const NoCameraException());
    await tester.pump();
    await tester.pump();
    expect(find.text(l.cameraUnavailable), findsNothing);
    expect(find.byKey(const ValueKey('fake-preview')), findsOneWidget);
  });

  testWidgets('izin reddi mesajı', (tester) async {
    await _open(tester, FakeCameraService(initError: const CameraAccessDeniedException()), []);
    expect(find.text(l.cameraDenied), findsOneWidget);
    expect(find.text(l.cameraUseGallery), findsOneWidget);
  });

  testWidgets('kamera yok mesajı', (tester) async {
    await _open(tester, FakeCameraService(initError: const NoCameraException()), []);
    expect(find.text(l.cameraUnavailable), findsOneWidget);
  });

  testWidgets('galeriden seç sonucu CameraResult.gallery', (tester) async {
    final results = <Object?>[];
    await _open(tester, FakeCameraService(initError: const CameraAccessDeniedException()), results);
    await tester.tap(find.text(l.cameraUseGallery));
    await tester.pumpAndSettle();
    expect(results, [CameraResult.gallery]);
  });

  testWidgets('önizleme ve silüet rehberi görünür', (tester) async {
    await _open(tester, FakeCameraService(), []);
    expect(find.byKey(const ValueKey('fake-preview')), findsOneWidget);
    expect(find.text(l.cameraHint), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('çek → önizle → kullan baytları döndürür', (tester) async {
    final fake = FakeCameraService();
    final results = <Object?>[];
    await _open(tester, fake, results);
    await tester.tap(find.byKey(const ValueKey('camera-shutter')));
    await tester.pumpAndSettle();
    expect(fake.captures, 1);
    expect(find.text(l.cameraUse), findsOneWidget);

    await tester.tap(find.text(l.cameraUse));
    await tester.pumpAndSettle();
    expect(results, [fake.bytes]);
    expect(fake.disposed, isTrue);
  });

  testWidgets('tekrar çek önizlemeyi kapatır', (tester) async {
    await _open(tester, FakeCameraService(), []);
    await tester.tap(find.byKey(const ValueKey('camera-shutter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.cameraRetake));
    await tester.pumpAndSettle();
    expect(find.text(l.cameraUse), findsNothing);
    expect(find.byKey(const ValueKey('camera-shutter')), findsOneWidget);
  });

  testWidgets('geri sayım rakamı görünür', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final fake = FakeCameraService();
    await tester.pumpWidget(localized(CameraCaptureScreen(service: fake)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('camera-shutter')));
    await tester.pump();
    expect(find.text('3'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('2'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(fake.captures, 1);
  });

  testWidgets('geri dönülünce kamera serbest bırakılır', (tester) async {
    final fake = FakeCameraService();
    final results = <Object?>[];
    await _open(tester, fake, results);
    await tester.tap(find.byTooltip(l.cameraClose));
    await tester.pumpAndSettle();
    expect(fake.disposed, isTrue);
    expect(results, [null]);
  });
}
