import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:see_it_on/core/l10n_ext.dart';
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

  test('Sonuç başlığı iki dilde', () {
    final tr = l10nFor('tr'), en = l10nFor('en');
    expect(tr.resultTitle(categoryName(tr, 'lower')), 'Alt Giyim Sonucu');
    expect(en.resultTitle(categoryName(en, 'overall')), 'Full outfit result');
  });

  test('Yükleme adımları iki dilde', () {
    expect(l10nFor('tr').loadingStepMask, 'Vücut Maskesi');
    expect(l10nFor('en').loadingStepMask, 'Body mask');
  });

  test('Bilinen hatalar çevrilir', () {
    final en = l10nFor('en');
    expect(ApiService.friendlyError(en, TimeoutException('x')), en.errorTimeout);
    expect(ApiService.friendlyError(en, Exception('Model henüz yükleniyor')), 'Model henüz yükleniyor');
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

  // Doğrulama Supabase'e gitmeden önce yapılır; bu yüzden testte Supabase başlatılmasına gerek yok
  Future<void> submitLogin(WidgetTester tester, String email, String password) async {
    await tester.pumpWidget(localized(const LoginScreen()));
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), email);
    await tester.enterText(fields.at(1), password);
    await tester.tap(find.text(l10nFor('tr').loginButton));
    await tester.pump();
  }

  testWidgets('geçersiz e-posta uyarısı', (tester) async {
    await submitLogin(tester, 'abc', '123456');
    expect(find.text(l10nFor('tr').authErrorInvalidEmail), findsOneWidget);
  });

  testWidgets('kısa şifre uyarısı', (tester) async {
    await submitLogin(tester, 'a@b.co', '123');
    expect(find.text(l10nFor('tr').authErrorPasswordTooShort), findsOneWidget);
  });

  testWidgets('şifre göster/gizle', (tester) async {
    await tester.pumpWidget(localized(const LoginScreen()));
    TextField password() => tester.widget<TextField>(find.byType(TextField).at(1));
    expect(password().obscureText, isTrue);
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    expect(password().obscureText, isFalse);
  });
}
