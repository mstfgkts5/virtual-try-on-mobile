import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase Veritabanı Bağlantısı
  await Supabase.initialize(
    url: 'https://ysdjntpvutlggrgrkslt.supabase.co', // Sonda /rest/v1/ yok!
    anonKey: 'sb_publishable_kOYogPWRG8skMNbp-sym4w_r1tCcyOU',
  );

  runApp(const SeeItOnApp());
}

class SeeItOnApp extends StatelessWidget {
  const SeeItOnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SeeItOn',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light, // Projemizin açık krem temasına uygun
        scaffoldBackgroundColor: const Color(0xFFF6F4EF),
      ),
      home: const OnboardingScreen(),
    );
  }
}