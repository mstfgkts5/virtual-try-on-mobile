import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/design/widgets.dart';
import '../core/l10n_ext.dart';
import '../core/locale_controller.dart';
import '../core/theme_mode_controller.dart';

class SettingsScreen extends StatelessWidget {
  /// [userEmail] verilmezse Supabase oturumundan okunur; [onSignOut] verilmezse
  /// Supabase'den çıkış yapılır. İkisi de yalnızca testlerde dışarıdan verilir.
  const SettingsScreen({super.key, this.userEmail, this.onSignOut});

  final String? userEmail;
  final Future<void> Function()? onSignOut;

  // Supabase başlatılmamışsa (testler) oturum yok sayılır
  static String? _sessionEmail() {
    try {
      return Supabase.instance.client.auth.currentUser?.email;
    } catch (_) {
      return null;
    }
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await (onSignOut ?? Supabase.instance.client.auth.signOut)();
    } catch (e) {
      // gotrue yerel oturumu sunucu çağrısından önce siler; çevrimdışıyken sunucu
      // çağrısı hata verse de kullanıcı fiilen çıkış yapmıştır
      debugPrint('[SettingsScreen] Çıkış sırasında sunucu hatası: $e');
    } finally {
      // Kök ekranı AuthGate tanıtım ekranına çevirir; üstteki rotalar kapatılır,
      // böylece geri tuşuyla ana ekrana dönülemez
      if (context.mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final email = userEmail ?? _sessionEmail();
    return Scaffold(
      backgroundColor: context.tokens.paper,
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EditorialHeading(l.settingsTitle),
              const SizedBox(height: 28),
              EditorialOverline(l.settingsLanguage),
              const SizedBox(height: 10),
              ValueListenableBuilder<Locale>(
                valueListenable: localeController,
                builder: (context, current, _) => SegmentedPills<String>(
                  options: [('tr', l.settingsLanguageTr), ('en', l.settingsLanguageEn)],
                  value: current.languageCode,
                  onChanged: (code) => localeController.setLocale(Locale(code)),
                ),
              ),
              const SizedBox(height: 10),
              Caption(l.settingsLanguageHint),
              const HairlineDivider(verticalPadding: 24),
              EditorialOverline(l.settingsAppearance),
              const SizedBox(height: 10),
              ValueListenableBuilder<ThemeMode>(
                valueListenable: themeModeController,
                builder: (context, mode, _) => SegmentedPills<ThemeMode>(
                  options: [
                    (ThemeMode.system, l.settingsThemeSystem),
                    (ThemeMode.light, l.settingsThemeLight),
                    (ThemeMode.dark, l.settingsThemeDark),
                  ],
                  icons: const {
                    ThemeMode.system: Icons.brightness_auto_outlined,
                    ThemeMode.light: Icons.light_mode_outlined,
                    ThemeMode.dark: Icons.dark_mode_outlined,
                  },
                  value: mode,
                  onChanged: themeModeController.setMode,
                ),
              ),
              if (email != null) ...[
                const HairlineDivider(verticalPadding: 24),
                EditorialOverline(l.settingsAccount),
                const SizedBox(height: 10),
                Text(l.settingsSignedInAs(email), style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 14),
                PillButton(
                  label: l.settingsSignOut,
                  icon: Icons.logout,
                  expand: true,
                  onPressed: () => _signOut(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
