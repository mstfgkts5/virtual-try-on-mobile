import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:see_it_on/core/theme_mode_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('varsayılan sistem', () async {
    SharedPreferences.setMockInitialValues({});
    expect((await ThemeModeController.load()).value, ThemeMode.system);
  });

  test('kayıtlı koyu', () async {
    SharedPreferences.setMockInitialValues({'app_theme_mode': 'dark'});
    expect((await ThemeModeController.load()).value, ThemeMode.dark);
  });

  test('bozuk değer sisteme düşer', () async {
    SharedPreferences.setMockInitialValues({'app_theme_mode': 'blue'});
    expect((await ThemeModeController.load()).value, ThemeMode.system);
  });

  test('setMode kalıcı', () async {
    SharedPreferences.setMockInitialValues({});
    final c = await ThemeModeController.load();
    await c.setMode(ThemeMode.light);
    expect((await SharedPreferences.getInstance()).getString('app_theme_mode'), 'light');
    expect((await ThemeModeController.load()).value, ThemeMode.light);
  });

  test('depolama hatasında sistem, çökme yok', () async {
    final c = await ThemeModeController.load(prefs: () => Future.error(StateError('x')));
    expect(c.value, ThemeMode.system);
    await c.setMode(ThemeMode.dark);
    expect(c.value, ThemeMode.dark);
  });
}
