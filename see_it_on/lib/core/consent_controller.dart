import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uygulama genelindeki KVKK onay denetleyicisi; main() açılışta kalıcı olanı yükler.
/// Varsayılan bellek içi örnek, onay kurmayan testlerin de `SeeItOnApp`'i açabilmesi içindir.
ConsentController consentController = ConsentController.inMemory();

/// Kullanıcının KVKK aydınlatma metnini okuyup fotoğraflarının işlenmesine açık rıza verip
/// vermediği; cihazda kalıcı. Metin değişirse [version] artırılır ve onay yeniden istenir.
class ConsentController extends ValueNotifier<bool> {
  ConsentController._(super.value, this._prefs);

  /// Kaydetmeyen örnek (yalnızca varsayılan ve testler için).
  ConsentController.inMemory([super.value = false])
      : _prefs = (() => Future<SharedPreferences>.error(UnsupportedError('in-memory')));

  /// Aydınlatma metninin sürümü. Metin değişince artırılır; eski onay geçersiz olur.
  static const version = 1;
  static const _prefKey = 'kvkk_consent_version';

  final Future<SharedPreferences> Function() _prefs;

  static Future<ConsentController> load({
    Future<SharedPreferences> Function() prefs = SharedPreferences.getInstance,
  }) async {
    var accepted = false;
    try {
      accepted = (await prefs()).getInt(_prefKey) == version;
    } catch (e) {
      debugPrint('[ConsentController] Onay durumu okunamadı: $e');
    }
    return ConsentController._(accepted, prefs);
  }

  Future<void> accept() async {
    value = true;
    try {
      await (await _prefs()).setInt(_prefKey, version);
    } catch (e) {
      debugPrint('[ConsentController] Onay kaydedilemedi: $e');
    }
  }

  /// Rızayı geri çeker; kullanıcı fotoğraf yükleyemez, bir sonraki açılışta metin yeniden gösterilir.
  Future<void> withdraw() async {
    value = false;
    try {
      await (await _prefs()).remove(_prefKey);
    } catch (e) {
      debugPrint('[ConsentController] Onay silinemedi: $e');
    }
  }
}
