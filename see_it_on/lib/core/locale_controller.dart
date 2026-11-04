import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uygulama genelindeki dil denetleyicisi; main() açılışta yükler, Ayarlar ekranı değiştirir.
/// (Testler kendi örneğini atayabilsin diye `final` değil.)
late LocaleController localeController;

/// Uygulamanın seçili dilini tutar ve cihazda kalıcı olarak saklar.
/// MaterialApp bu bildiriciyi dinlediği için dil değişince tüm ekranlar anında yeniden çizilir.
class LocaleController extends ValueNotifier<Locale> {
  LocaleController._(super.value, this._prefs);

  static const supported = [Locale('tr'), Locale('en')];
  static const _prefKey = 'app_locale';

  final Future<SharedPreferences> Function() _prefs;

  /// Kayıtlı tercih varsa onu, yoksa cihaz dilini kullanır (Türkçe değilse İngilizce).
  /// Depolama okunamazsa uygulama açılışta takılmaz; cihaz diline düşülür.
  /// [prefs] yalnızca testlerde depolama hatası taklit etmek için verilir.
  static Future<LocaleController> load({
    Locale? deviceLocale,
    Future<SharedPreferences> Function() prefs = SharedPreferences.getInstance,
  }) async {
    Locale? saved;
    try {
      saved = _match((await prefs()).getString(_prefKey));
    } catch (e) {
      debugPrint('[LocaleController] Dil tercihi okunamadı: $e');
    }
    final device = deviceLocale ?? PlatformDispatcher.instance.locale;
    return LocaleController._(saved ?? _match(device.languageCode) ?? const Locale('en'), prefs);
  }

  /// Dili hemen değiştirir; kaydetme başarısız olursa yalnızca bu oturum için geçerli kalır.
  Future<void> setLocale(Locale locale) async {
    value = _match(locale.languageCode) ?? value;
    try {
      await (await _prefs()).setString(_prefKey, value.languageCode);
    } catch (e) {
      debugPrint('[LocaleController] Dil tercihi kaydedilemedi: $e');
    }
  }

  // Bölge bilgisi yok sayılır: 'tr_TR' -> tr. Desteklenmeyen kod -> null.
  static Locale? _match(String? code) {
    for (final l in supported) {
      if (l.languageCode == code) return l;
    }
    return null;
  }
}
