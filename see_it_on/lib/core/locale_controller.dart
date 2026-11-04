import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uygulama genelindeki dil denetleyicisi; main() açılışta yükler, Ayarlar ekranı değiştirir.
/// (Testler kendi örneğini atayabilsin diye `final` değil.)
late LocaleController localeController;

/// Uygulamanın seçili dilini tutar ve cihazda kalıcı olarak saklar.
/// MaterialApp bu bildiriciyi dinlediği için dil değişince tüm ekranlar anında yeniden çizilir.
class LocaleController extends ValueNotifier<Locale> {
  LocaleController._(super.value);

  static const supported = [Locale('tr'), Locale('en')];
  static const _prefKey = 'app_locale';

  /// Kayıtlı tercih varsa onu, yoksa cihaz dilini kullanır (Türkçe değilse İngilizce).
  static Future<LocaleController> load({Locale? deviceLocale}) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = _match(prefs.getString(_prefKey));
    final device = deviceLocale ?? PlatformDispatcher.instance.locale;
    return LocaleController._(saved ?? _match(device.languageCode) ?? const Locale('en'));
  }

  Future<void> setLocale(Locale locale) async {
    value = _match(locale.languageCode) ?? value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, value.languageCode);
  }

  // Bölge bilgisi yok sayılır: 'tr_TR' -> tr. Desteklenmeyen kod -> null.
  static Locale? _match(String? code) {
    for (final l in supported) {
      if (l.languageCode == code) return l;
    }
    return null;
  }
}
