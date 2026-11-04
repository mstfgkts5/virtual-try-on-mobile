import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_localizations.dart';

/// Supabase'in varsayılan şifre alt sınırı.
const int minPasswordLength = 6;

/// İnterneti olmayan Wi-Fi'da (ör. kafe giriş sayfası) istek işletim sisteminin
/// TCP zaman aşımına kadar asılı kalmasın diye giriş/kayıt isteğine üst sınır.
const authRequestTimeout = Duration(seconds: 20);

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Basit biçim kontrolü (x@y.z); asıl doğrulamayı Supabase yapar.
bool isValidEmail(String email) => _emailPattern.hasMatch(email);

/// Supabase / ağ hatalarını kullanıcının dilindeki mesaja çevirir.
/// Supabase hata metinleri İngilizce ve sabit olduğu için bilinen ifadeler eşlenir;
/// bilinmeyen durumda genel hata mesajı gösterilir (ham İngilizce metin gösterilmez).
String authErrorMessage(AppLocalizations l, Object error) {
  if (error is http.ClientException || error is TimeoutException) return l.authErrorNetwork;
  if (error is! AuthException) return l.errorUnexpected;

  final m = error.message.toLowerCase();
  // Art arda kayıt/giriş denemesinde Supabase geçici olarak reddeder
  if (error.statusCode == '429' || m.contains('rate limit') || m.contains('request this after')) {
    return l.authErrorRateLimit;
  }
  if (m.contains('invalid login credentials')) return l.authErrorInvalidCredentials;
  if (m.contains('already registered')) return l.authErrorEmailTaken;
  if (m.contains('password should be at least')) return l.authErrorWeakPassword;
  if (m.contains('validate email')) return l.authErrorInvalidEmail;
  if (m.contains('failed host lookup') || m.contains('socketexception') || m.contains('clientexception')) {
    return l.authErrorNetwork;
  }
  return l.errorUnexpected;
}
