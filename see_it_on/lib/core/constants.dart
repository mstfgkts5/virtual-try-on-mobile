import 'package:flutter/foundation.dart';

class AppConstants {
  static const String appName = 'SeeItOn';

  // FastAPI backend adresi: web'de sayfayı sunan bilgisayar (bilgisayarın kendi tarayıcısında
  // localhost, telefonda Wi-Fi üzerinden açılınca bilgisayarın IP'si), Android emülatörde 10.0.2.2.
  static String get defaultBaseUrl => kIsWeb ? webBaseUrl(Uri.base) : 'http://10.0.2.2:8000';

  /// Web'de backend, sayfanın açıldığı bilgisayarın 8000 portundadır (tools/lan_server.py
  /// uygulamayı ve backend'i aynı portta sunar; `flutter run` ile geliştirirken backend ayrıca 8000'de).
  /// Sayfa HTTPS ile açıldıysa (iPhone'da kamera için, lan_server 8443) backend aynı adrestedir:
  /// tarayıcı karışık içeriği engeller ve kendi imzalı sertifika tek adres için bir kez onaylanır.
  static String webBaseUrl(Uri page) {
    final host = page.host.isEmpty ? '127.0.0.1' : page.host;
    if (page.scheme == 'https') return page.origin;
    return 'http://$host:8000';
  }
  static const String tryOnEndpoint = '/api/v1/tryon';
}
