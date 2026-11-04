import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/l10n_ext.dart';
import 'core/locale_controller.dart';
import 'screens/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase Veritabanı Bağlantısı
  await Supabase.initialize(
    url: 'https://ysdjntpvutlggrgrkslt.supabase.co', // Sonda /rest/v1/ yok!
    anonKey: 'sb_publishable_kOYogPWRG8skMNbp-sym4w_r1tCcyOU',
  );

  localeController = await LocaleController.load();

  runApp(const SeeItOnApp());
}

class SeeItOnApp extends StatelessWidget {
  const SeeItOnApp({super.key, this.home = const OnboardingScreen()});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    // Dil değişince MaterialApp yeniden kurulur; tüm ekranlar yeni dilde çizilir
    return ValueListenableBuilder<Locale>(
      valueListenable: localeController,
      builder: (context, locale, _) => MaterialApp(
        title: 'SeeItOn',
        debugShowCheckedModeBanner: false,
        locale: locale,
        supportedLocales: LocaleController.supported,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: ThemeData(
          brightness: Brightness.light, // Projemizin açık krem temasına uygun
          scaffoldBackgroundColor: const Color(0xFFF6F4EF),
        ),
        home: home,
      ),
    );
  }
}
