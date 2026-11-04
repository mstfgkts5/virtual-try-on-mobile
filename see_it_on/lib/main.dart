import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/design/theme.dart';
import 'core/l10n_ext.dart';
import 'core/locale_controller.dart';
import 'core/theme_mode_controller.dart';
import 'screens/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase Veritabanı Bağlantısı
  await Supabase.initialize(
    url: 'https://ysdjntpvutlggrgrkslt.supabase.co', // Sonda /rest/v1/ yok!
    anonKey: 'sb_publishable_kOYogPWRG8skMNbp-sym4w_r1tCcyOU',
  );

  localeController = await LocaleController.load();
  themeModeController = await ThemeModeController.load();

  runApp(const SeeItOnApp());
}

final _lightTheme = buildTheme(Brightness.light);
final _darkTheme = buildTheme(Brightness.dark);

class SeeItOnApp extends StatelessWidget {
  const SeeItOnApp({super.key, this.home = const AuthGate()});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    // Dil veya tema modu değişince MaterialApp yeniden kurulur; tüm ekranlar yeni hâliyle çizilir
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeController,
      builder: (context, mode, _) => ValueListenableBuilder<Locale>(
        valueListenable: localeController,
        builder: (context, locale, _) => MaterialApp(
          title: 'SeeItOn',
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: LocaleController.supported,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: _lightTheme,
          darkTheme: _darkTheme,
          themeMode: mode,
          home: home,
        ),
      ),
    );
  }
}
