import 'package:flutter/foundation.dart';

class AppConstants {
  static const String appName = 'SeeItOn';

  // FastAPI backend adresi: web'de localhost, Android emülatörde 10.0.2.2 (bilgisayarın kendisi).
  // Gerçek telefonda bilgisayarın yerel Wi-Fi IP adresi kullanılır.
  static String get defaultBaseUrl =>
      kIsWeb ? 'http://127.0.0.1:8000' : 'http://10.0.2.2:8000';
  static const String tryOnEndpoint = '/api/v1/tryon';
}
