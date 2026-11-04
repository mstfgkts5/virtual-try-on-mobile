import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:see_it_on/models/tryon_request.dart';
import 'package:see_it_on/screens/login_screen.dart';
import 'package:see_it_on/screens/onboarding_screen.dart';
import 'package:see_it_on/services/api_service.dart';

import 'helpers.dart';

void main() {
  test('TryOnRequest kategoriyi backend formatında gönderir', () {
    final request = TryOnRequest(
      personImageBytes: Uint8List(0),
      garmentImageBytes: Uint8List(0),
      category: 'LOWER',
    );
    expect(request.toFieldsMap(), {'category': 'lower', 'steps': '30'});
  });

  test('Kategori etiketleri Türkçe', () {
    expect(ApiService.categoryLabel('upper'), 'Üst Giyim Sonucu');
    expect(ApiService.categoryLabel('lower'), 'Alt Giyim Sonucu');
    expect(ApiService.categoryLabel('overall'), 'Tam Kıyafet Sonucu');
  });

  testWidgets('Açılış ekranı marka adını gösterir', (tester) async {
    await tester.pumpWidget(localized(const OnboardingScreen()));
    expect(find.text('SeeItOn'), findsOneWidget);
  });

  testWidgets('Açılış ekranı TR başlığı', (tester) async {
    await tester.pumpWidget(localized(const OnboardingScreen()));
    expect(find.text('Her Kıyafeti\nAnında Dene'), findsOneWidget);
  });

  testWidgets('Açılış ekranı EN başlığı', (tester) async {
    await tester.pumpWidget(localized(const OnboardingScreen(), lang: 'en'));
    expect(find.text('Try On Any Outfit\nInstantly'), findsOneWidget);
  });

  testWidgets('Giriş ekranı TR', (tester) async {
    await tester.pumpWidget(localized(const LoginScreen()));
    expect(find.text('Tekrar Hoş Geldin'), findsOneWidget);
  });

  testWidgets('Giriş ekranı EN', (tester) async {
    await tester.pumpWidget(localized(const LoginScreen(), lang: 'en'));
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
