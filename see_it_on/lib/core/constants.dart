import 'package:flutter/foundation.dart';

class AppConstants {
  static const String appName = 'SeeItOn';

  // FastAPI backend adresi: web'de sayfayı sunan bilgisayar (bilgisayarın kendi tarayıcısında
  // localhost, telefonda Wi-Fi üzerinden açılınca bilgisayarın IP'si), Android emülatörde 10.0.2.2.
  static String get defaultBaseUrl => kIsWeb ? webBaseUrl(Uri.base) : 'http://10.0.2.2:8000';

  /// Web'de backend, sayfanın açıldığı bilgisayarın 8000 portundadır.
  /// Sayfa HTTPS ile açıldıysa backend de HTTPS'tir (tarayıcı karışık içeriği engeller).
  static String webBaseUrl(Uri page) {
    final host = page.host.isEmpty ? '127.0.0.1' : page.host;
    final scheme = page.scheme == 'https' ? 'https' : 'http';
    return '$scheme://$host:8000';
  }
  static const String tryOnEndpoint = '/api/v1/tryon';
}
