import 'package:flutter/foundation.dart';

class AppConstants {
  static const String appName = 'SeeItOn';
  static const String appTagline = 'Try On Any Outfit Instantly';
  static const String appDescription =
      'Upload your photo, select any designer garment, and preview realistic photoreal draping in seconds.';

  // Default API configuration for Python FastAPI
  // On Web, use localhost:8000; On Android Emulator use 10.0.2.2:8000
  static String get defaultBaseUrl =>
      kIsWeb ? 'http://127.0.0.1:8000' : 'http://10.0.2.2:8000';
  static const String tryOnEndpoint = '/api/v1/tryon';

  // Asset paths
  static const String heroOnboarding = 'assets/images/onboarding_hero.png';
  static const String sampleMuseElena = 'assets/images/sample_muse_elena.png';
  static const String sampleGarmentBlazer = 'assets/images/sample_garment_blazer.png';
  static const String sampleTryOnResult = 'assets/images/sample_tryon_result.png';
  static const String sampleRecentTrench = 'assets/images/sample_recent_trench.png';
  static const String sampleRecentSilk = 'assets/images/sample_recent_silk.png';
}
