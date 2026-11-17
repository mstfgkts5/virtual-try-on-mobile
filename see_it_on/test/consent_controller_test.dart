import 'package:flutter_test/flutter_test.dart';
import 'package:see_it_on/core/consent_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('varsayılan: rıza yok', () async {
    SharedPreferences.setMockInitialValues({});
    expect((await ConsentController.load()).value, isFalse);
  });

  test('accept kalıcı ve güncel sürümle kaydedilir', () async {
    SharedPreferences.setMockInitialValues({});
    final c = await ConsentController.load();
    await c.accept();
    expect(c.value, isTrue);
    expect((await SharedPreferences.getInstance()).getInt('kvkk_consent_version'), ConsentController.version);
    expect((await ConsentController.load()).value, isTrue);
  });

  test('eski sürüm onayı geçersiz', () async {
    SharedPreferences.setMockInitialValues({'kvkk_consent_version': ConsentController.version - 1});
    expect((await ConsentController.load()).value, isFalse);
  });

  test('withdraw rızayı siler', () async {
    SharedPreferences.setMockInitialValues({'kvkk_consent_version': ConsentController.version});
    final c = await ConsentController.load();
    expect(c.value, isTrue);
    await c.withdraw();
    expect(c.value, isFalse);
    expect((await ConsentController.load()).value, isFalse);
  });

  test('depolama hatasında rıza yok, çökme yok', () async {
    final c = await ConsentController.load(prefs: () => Future.error(StateError('x')));
    expect(c.value, isFalse);
    await c.accept();
    expect(c.value, isTrue);
  });
}
