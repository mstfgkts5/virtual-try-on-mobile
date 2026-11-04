import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:see_it_on/core/locale_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('load() tr_TR cihazda tr döner', () async {
    SharedPreferences.setMockInitialValues({});
    final c = await LocaleController.load(deviceLocale: const Locale('tr', 'TR'));
    expect(c.value.languageCode, 'tr');
  });

  test('load() de cihazda en döner', () async {
    SharedPreferences.setMockInitialValues({});
    final c = await LocaleController.load(deviceLocale: const Locale('de'));
    expect(c.value.languageCode, 'en');
  });

  test('kayıtlı tercih cihaz dilini ezer', () async {
    SharedPreferences.setMockInitialValues({'app_locale': 'en'});
    final c = await LocaleController.load(deviceLocale: const Locale('tr'));
    expect(c.value.languageCode, 'en');
  });

  test('bozuk tercih cihaz diline düşer', () async {
    SharedPreferences.setMockInitialValues({'app_locale': 'de'});
    final c = await LocaleController.load(deviceLocale: const Locale('tr'));
    expect(c.value.languageCode, 'tr');
  });

  test('depolama hatasında çökmez, cihaz diline düşer', () async {
    final c = await LocaleController.load(
      deviceLocale: const Locale('tr'),
      prefs: () => Future.error(StateError('prefs bozuk')),
    );
    expect(c.value.languageCode, 'tr');
    await c.setLocale(const Locale('en')); // kaydedemese de dil değişir, hata fırlatmaz
    expect(c.value.languageCode, 'en');
  });

  test('setLocale kalıcıdır', () async {
    SharedPreferences.setMockInitialValues({});
    final c = await LocaleController.load(deviceLocale: const Locale('tr'));
    await c.setLocale(const Locale('en'));
    expect(c.value.languageCode, 'en');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_locale'), 'en');
    final again = await LocaleController.load(deviceLocale: const Locale('tr'));
    expect(again.value.languageCode, 'en');
  });
}
