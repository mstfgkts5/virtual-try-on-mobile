import 'package:flutter/foundation.dart';

class AppConstants {
  static const String appName = 'SeeItOn';

  // FastAPI backend adresi: web'de sayfayı sunan bilgisayar (bilgisayarın kendi tarayıcısında
  // localhost, telefonda Wi-Fi üzerinden açılınca bilgisayarın IP'si), Android emülatörde 10.0.2.2.
  static String get defaultBaseUrl => kIsWeb ? webBaseUrl(Uri.base) : 'http://10.0.2.2:8000';

  /// Web'de backend, sayfanın açıldığı bilgisayarın 8000 portundadır.
  static String webBaseUrl(Uri page) {
    final host = page.host.isEmpty ? '127.0.0.1' : page.host;
    return 'http://$host:8000';
  }
  static const String tryOnEndpoint = '/api/v1/tryon';
}
