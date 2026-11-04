import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:see_it_on/services/auth_errors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'helpers.dart';

void main() {
  final tr = l10nFor('tr'), en = l10nFor('en');

  test('hatalı e-posta/şifre', () {
    const e = AuthException('Invalid login credentials');
    expect(authErrorMessage(tr, e), tr.authErrorInvalidCredentials);
    expect(authErrorMessage(en, e), en.authErrorInvalidCredentials);
  });

  test('kayıtlı e-posta', () {
    expect(authErrorMessage(tr, const AuthException('User already registered')), tr.authErrorEmailTaken);
  });

  test('zayıf şifre', () {
    expect(authErrorMessage(tr, const AuthException('Password should be at least 6 characters')),
        tr.authErrorWeakPassword);
  });

  test('geçersiz e-posta', () {
    expect(authErrorMessage(tr, const AuthException('Unable to validate email address: invalid format')),
        tr.authErrorInvalidEmail);
  });

  test('bağlantı hataları', () {
    expect(authErrorMessage(en, http.ClientException('Failed to fetch')), en.authErrorNetwork);
    expect(authErrorMessage(en, const AuthException('ClientException: Failed host lookup')), en.authErrorNetwork);
  });

  test('bilinmeyen hata genel mesaja düşer', () {
    expect(authErrorMessage(tr, const AuthException('weird')), tr.errorUnexpected);
  });

  test('e-posta biçimi', () {
    expect(isValidEmail('a@b.co'), isTrue);
    expect(isValidEmail('  a@b.co  '.trim()), isTrue);
    expect(isValidEmail('ab.co'), isFalse);
    expect(isValidEmail('a@b'), isFalse);
    expect(isValidEmail(''), isFalse);
    expect(minPasswordLength, 6);
  });
}
