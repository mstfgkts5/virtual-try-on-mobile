import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/design/widgets.dart';
import '../core/l10n_ext.dart';
import '../core/locale_controller.dart';
import '../core/theme_mode_controller.dart';
import '../services/wardrobe_repository.dart';
import 'consent_screen.dart';

class SettingsScreen extends StatelessWidget {
  /// [userEmail] verilmezse Supabase oturumundan okunur; [onSignOut] verilmezse
  /// Supabase'den çıkış yapılır. İkisi de yalnızca testlerde dışarıdan verilir.
  /// [onDeleteAccount] verilmezse Supabase'deki tüm veriler ve hesap silinir (testlerde dışarıdan verilir).
  const SettingsScreen({super.key, this.userEmail, this.onSignOut, this.onDeleteAccount});

  final String? userEmail;
  final Future<void> Function()? onSignOut;
  final Future<void> Function()? onDeleteAccount;

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

  Future<void> _deleteAccount(BuildContext context) async {
    final l = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.settingsDeleteConfirmTitle),
        content: Text(l.settingsDeleteConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.settingsDeleteCancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error),
            child: Text(l.settingsDeleteConfirmYes),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await (onDeleteAccount ?? SupabaseWardrobeRepository().deleteAccount)();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.settingsDeleteDone)));
      // Oturum kapandı; kök ekran (AuthGate) tanıtım ekranını gösterir
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      debugPrint('[SettingsScreen] Hesap silinemedi: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.settingsDeleteFailed)));
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
              const HairlineDivider(verticalPadding: 24),
              EditorialOverline(l.settingsPrivacy),
              const SizedBox(height: 10),
              PillButton(
                label: l.settingsPrivacyNotice,
                icon: Icons.privacy_tip_outlined,
                expand: true,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ConsentScreen(readOnly: true)),
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
                const SizedBox(height: 10),
                PillButton(
                  label: l.settingsDeleteAccount,
                  icon: Icons.delete_forever_outlined,
                  expand: true,
                  onPressed: () => _deleteAccount(context),
                ),
                const SizedBox(height: 8),
                Caption(l.settingsDeleteHint),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
