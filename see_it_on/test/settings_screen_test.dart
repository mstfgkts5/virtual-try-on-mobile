import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:see_it_on/core/locale_controller.dart';
import 'package:see_it_on/core/theme_mode_controller.dart';
import 'package:see_it_on/main.dart';
import 'package:see_it_on/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('dil değişince başlık anında değişir', (tester) async {
    SharedPreferences.setMockInitialValues({});
    localeController = await LocaleController.load(deviceLocale: const Locale('tr'));

    await tester.pumpWidget(const SeeItOnApp(home: SettingsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Ayarlar'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Ayarlar'), findsNothing);
  });

  testWidgets('Koyu seçilince tema modu dark ve kalıcı', (tester) async {
    SharedPreferences.setMockInitialValues({});
    localeController = await LocaleController.load(deviceLocale: const Locale('tr'));
    themeModeController = await ThemeModeController.load();
    addTearDown(() => themeModeController = ThemeModeController.inMemory());

    await tester.pumpWidget(const SeeItOnApp(home: SettingsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('GÖRÜNÜM'), findsOneWidget);

    await tester.tap(find.text('Koyu'));
    await tester.pumpAndSettle();
    expect(themeModeController.value, ThemeMode.dark);
    expect((await SharedPreferences.getInstance()).getString('app_theme_mode'), 'dark');
    final ctx = tester.element(find.byType(SettingsScreen));
    expect(Theme.of(ctx).brightness, Brightness.dark);
  });

  testWidgets('oturum yoksa hesap bölümü gizli', (tester) async {
    SharedPreferences.setMockInitialValues({});
    localeController = await LocaleController.load(deviceLocale: const Locale('tr'));
    await tester.pumpWidget(const SeeItOnApp(home: SettingsScreen(userEmail: null)));
    await tester.pumpAndSettle();
    expect(find.text('HESAP'), findsNothing);
    expect(find.text('Çıkış yap'), findsNothing);
  });

  testWidgets('oturum varsa e-posta ve çıkış görünür, çıkış çağrılır', (tester) async {
    SharedPreferences.setMockInitialValues({});
    localeController = await LocaleController.load(deviceLocale: const Locale('tr'));
    var signOutCalls = 0;
    await tester.pumpWidget(SeeItOnApp(
      home: SettingsScreen(userEmail: 'a@b.co', onSignOut: () async => signOutCalls++),
    ));
    await tester.pumpAndSettle();
    expect(find.text('HESAP'), findsOneWidget);
    expect(find.text('a@b.co olarak giriş yapıldı'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Çıkış yap'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Çıkış yap'));
    await tester.pumpAndSettle();
    expect(signOutCalls, 1);
  });

  testWidgets('çıkış hata verse de kök ekrana döner', (tester) async {
    SharedPreferences.setMockInitialValues({});
    localeController = await LocaleController.load(deviceLocale: const Locale('tr'));
    await tester.pumpWidget(SeeItOnApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SettingsScreen(
                userEmail: 'a@b.co',
                onSignOut: () => Future.error(Exception('offline')),
              ),
            ),
          ),
          child: const Text('ROOT'),
        ),
      ),
    ));
    await tester.tap(find.text('ROOT'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Çıkış yap'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Çıkış yap'));
    await tester.pumpAndSettle();
    expect(find.text('Çıkış yap'), findsNothing);
    expect(find.text('ROOT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hesap silme: onaylanınca silinir ve kök ekrana dönülür', (tester) async {
    SharedPreferences.setMockInitialValues({});
    localeController = await LocaleController.load(deviceLocale: const Locale('tr'));
    var calls = 0;
    await tester.pumpWidget(SeeItOnApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SettingsScreen(userEmail: 'a@b.co', onDeleteAccount: () async => calls++),
            ),
          ),
          child: const Text('ROOT'),
        ),
      ),
    ));
    await tester.tap(find.text('ROOT'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Hesabımı ve verilerimi sil'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Hesabımı ve verilerimi sil'));
    await tester.pumpAndSettle();
    expect(find.text('Hesap silinsin mi?'), findsOneWidget);
    await tester.tap(find.text('Kalıcı olarak sil'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.text('ROOT'), findsOneWidget);
  });

  testWidgets('hesap silme: vazgeçilirse hiçbir şey silinmez', (tester) async {
    SharedPreferences.setMockInitialValues({});
    localeController = await LocaleController.load(deviceLocale: const Locale('tr'));
    var calls = 0;
    await tester.pumpWidget(SeeItOnApp(
      home: SettingsScreen(userEmail: 'a@b.co', onDeleteAccount: () async => calls++),
    ));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Hesabımı ve verilerimi sil'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Hesabımı ve verilerimi sil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(find.text('Hesabımı ve verilerimi sil'), findsOneWidget);
  });

  testWidgets('hesap silme hata verirse ekranda kalır ve uyarı gösterir', (tester) async {
    SharedPreferences.setMockInitialValues({});
    localeController = await LocaleController.load(deviceLocale: const Locale('tr'));
    await tester.pumpWidget(SeeItOnApp(
      home: SettingsScreen(userEmail: 'a@b.co', onDeleteAccount: () => Future.error(Exception('offline'))),
    ));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Hesabımı ve verilerimi sil'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Hesabımı ve verilerimi sil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kalıcı olarak sil'));
    await tester.pumpAndSettle();
    expect(find.text('Hesap silinemedi. Bağlantını kontrol edip tekrar dene.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('gizlilik bölümü oturum olmadan da görünür ve metni açar', (tester) async {
    SharedPreferences.setMockInitialValues({});
    localeController = await LocaleController.load(deviceLocale: const Locale('tr'));
    await tester.pumpWidget(const SeeItOnApp(home: SettingsScreen(userEmail: null)));
    await tester.pumpAndSettle();
    expect(find.text('GİZLİLİK'), findsOneWidget);
    expect(find.text('Hesabımı ve verilerimi sil'), findsNothing);
    await tester.tap(find.text('KVKK aydınlatma metni'));
    await tester.pumpAndSettle();
    expect(find.text('Fotoğrafların nasıl işlenir?'), findsOneWidget);
  });
}
