import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:see_it_on/core/locale_controller.dart';
import 'package:see_it_on/screens/settings_screen.dart';
import 'package:see_it_on/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

class _FakeServerApi implements ApiService {
  _FakeServerApi({this.healthy = true});

  final bool healthy;
  String? saved;
  int healthChecks = 0;

  @override
  String baseUrl = 'http://10.0.2.2:8000';

  @override
  Future<void> saveBaseUrl(String url) async {
    saved = url;
    baseUrl = url;
  }

  @override
  Future<bool> checkBackendHealth() async {
    healthChecks++;
    return healthy;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _open(WidgetTester tester, ApiService api, {bool showServer = true, String lang = 'tr'}) async {
  SharedPreferences.setMockInitialValues({});
  localeController = await LocaleController.load(deviceLocale: Locale(lang));
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(localized(SettingsScreen(showServer: showServer, api: api), lang: lang));
  await tester.pumpAndSettle();
}

void main() {
  group('sunucu adresi biçimi', () {
    test('yalnızca IP yazılınca http ve 8000 eklenir', () {
      expect(ApiService.normalizeServerUrl('172.20.10.2'), 'http://172.20.10.2:8000');
      expect(ApiService.normalizeServerUrl(' 172.20.10.2:8000/ '), 'http://172.20.10.2:8000');
    });

    test('şema ve port korunur', () {
      expect(ApiService.normalizeServerUrl('https://172.20.10.2:8443'), 'https://172.20.10.2:8443');
      expect(ApiService.normalizeServerUrl('http://laptop.local'), 'http://laptop.local:8000');
    });

    test('anlamsız adres reddedilir', () {
      expect(ApiService.normalizeServerUrl(''), isNull);
      expect(ApiService.normalizeServerUrl('abc def'), isNull);
      expect(ApiService.normalizeServerUrl('ftp://172.20.10.2'), isNull);
      expect(ApiService.normalizeServerUrl('172.20.10.2:8000/api'), isNull);
    });
  });

  test('kaydedilen adres cihazda saklanır ve açılışta yüklenir', () async {
    final api = ApiService();
    final before = api.baseUrl;
    addTearDown(() => api.baseUrl = before);

    SharedPreferences.setMockInitialValues({});
    await api.saveBaseUrl('http://172.20.10.2:8000');
    expect((await SharedPreferences.getInstance()).getString(ApiService.serverPrefKey), 'http://172.20.10.2:8000');

    api.baseUrl = 'http://10.0.2.2:8000';
    await api.loadSavedBaseUrl();
    expect(api.baseUrl, 'http://172.20.10.2:8000');
  });

  test('kayıt yoksa varsayılan adres kalır', () async {
    final api = ApiService();
    final before = api.baseUrl;
    SharedPreferences.setMockInitialValues({});
    await api.loadSavedBaseUrl();
    expect(api.baseUrl, before);
  });

  testWidgets('Ayarlar: adres kaydedilir ve bağlantı denenir', (tester) async {
    final api = _FakeServerApi();
    await _open(tester, api);
    final l = l10nFor('tr');
    expect(find.text(l.settingsServer), findsOneWidget);

    await tester.enterText(find.byKey(const Key('serverAddress')), '172.20.10.2');
    await tester.tap(find.text(l.settingsServerSave));
    await tester.pumpAndSettle();

    expect(api.saved, 'http://172.20.10.2:8000');
    expect(api.healthChecks, 1);
    expect(find.text(l.settingsServerOk), findsOneWidget);
    expect(find.text('http://172.20.10.2:8000'), findsOneWidget);
  });

  testWidgets('Ayarlar: sunucuya ulaşılamazsa söylenir', (tester) async {
    await _open(tester, _FakeServerApi(healthy: false), lang: 'en');
    await tester.enterText(find.byKey(const Key('serverAddress')), '172.20.10.2');
    await tester.tap(find.text(l10nFor('en').settingsServerSave));
    await tester.pumpAndSettle();
    expect(find.text(l10nFor('en').settingsServerFail), findsOneWidget);
  });

  testWidgets('Ayarlar: geçersiz adres kaydedilmez', (tester) async {
    final api = _FakeServerApi();
    await _open(tester, api);
    await tester.enterText(find.byKey(const Key('serverAddress')), 'abc def');
    await tester.tap(find.text(l10nFor('tr').settingsServerSave));
    await tester.pumpAndSettle();
    expect(api.saved, isNull);
    expect(api.healthChecks, 0);
    expect(find.text(l10nFor('tr').settingsServerInvalid), findsOneWidget);
  });

  testWidgets('web sürümünde sunucu bölümü yok', (tester) async {
    await _open(tester, _FakeServerApi(), showServer: false);
    expect(find.byKey(const Key('serverAddress')), findsNothing);
  });
}
