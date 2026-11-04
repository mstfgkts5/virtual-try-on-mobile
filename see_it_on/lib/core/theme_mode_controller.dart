import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uygulama genelindeki tema modu denetleyicisi; main() açılışta kalıcı olanı yükler, Ayarlar değiştirir.
/// Varsayılan bellek içi örnek, tema modunu kurmayan testlerin de `SeeItOnApp`'i açabilmesi içindir.
ThemeModeController themeModeController = ThemeModeController.inMemory();

/// Görünüm tercihi (Sistem / Açık / Koyu), cihazda kalıcı.
class ThemeModeController extends ValueNotifier<ThemeMode> {
  ThemeModeController._(super.value, this._prefs);

  /// Kaydetmeyen örnek (yalnızca varsayılan ve testler için).
  ThemeModeController.inMemory([super.value = ThemeMode.system])
      : _prefs = (() => Future<SharedPreferences>.error(UnsupportedError('in-memory')));

  static const _prefKey = 'app_theme_mode';
  final Future<SharedPreferences> Function() _prefs;

  static Future<ThemeModeController> load({
    Future<SharedPreferences> Function() prefs = SharedPreferences.getInstance,
  }) async {
    var mode = ThemeMode.system;
    try {
      mode = _parse((await prefs()).getString(_prefKey));
    } catch (e) {
      debugPrint('[ThemeModeController] Tema tercihi okunamadı: $e');
    }
    return ThemeModeController._(mode, prefs);
  }

  Future<void> setMode(ThemeMode mode) async {
    value = mode;
    try {
      await (await _prefs()).setString(_prefKey, mode.name);
    } catch (e) {
      debugPrint('[ThemeModeController] Tema tercihi kaydedilemedi: $e');
    }
  }

  static ThemeMode _parse(String? name) =>
      ThemeMode.values.firstWhere((m) => m.name == name, orElse: () => ThemeMode.system);
}
