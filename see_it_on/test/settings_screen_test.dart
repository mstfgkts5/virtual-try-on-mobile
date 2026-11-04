import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:see_it_on/core/locale_controller.dart';
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
}
