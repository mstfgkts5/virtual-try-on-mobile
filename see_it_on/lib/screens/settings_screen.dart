import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/l10n_ext.dart';
import '../core/locale_controller.dart';

class SettingsScreen extends StatelessWidget {
  /// [userEmail] verilmezse Supabase oturumundan okunur; [onSignOut] verilmezse
  /// Supabase'den çıkış yapılır. İkisi de yalnızca testlerde dışarıdan verilir.
  const SettingsScreen({super.key, this.userEmail, this.onSignOut});

  final String? userEmail;
  final Future<void> Function()? onSignOut;

  static const _textColor = Color(0xFF1E1C1A);

  // Supabase başlatılmamışsa (testler) oturum yok sayılır
  static String? _sessionEmail() {
    try {
      return Supabase.instance.client.auth.currentUser?.email;
    } catch (_) {
      return null;
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await (onSignOut ?? Supabase.instance.client.auth.signOut)();
    // Kök ekranı AuthGate tanıtım ekranına çevirir; üstteki rotalar kapatılır,
    // böylece geri tuşuyla ana ekrana dönülemez
    if (context.mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final email = userEmail ?? _sessionEmail();
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _textColor,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.settingsTitle,
                style: const TextStyle(color: _textColor, fontSize: 32, fontFamily: 'Georgia', fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 28),
              Text(
                l.settingsLanguage,
                style: TextStyle(color: _textColor.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              const SizedBox(height: 10),
              ValueListenableBuilder<Locale>(
                valueListenable: localeController,
                builder: (context, current, _) => _LanguageSelector(current: current),
              ),
              const SizedBox(height: 10),
              Text(l.settingsLanguageHint, style: TextStyle(color: _textColor.withValues(alpha: 0.5), fontSize: 12)),
              if (email != null) ...[
                const SizedBox(height: 36),
                Text(
                  l.settingsAccount,
                  style: TextStyle(color: _textColor.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 10),
                Text(l.settingsSignedInAs(email), style: const TextStyle(color: _textColor, fontSize: 14)),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _signOut(context),
                    icon: const Icon(Icons.logout, size: 18),
                    label: Text(l.settingsSignOut),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF221F1E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Ana ekrandaki kategori seçiciyle aynı görünüm: krem zemin, seçili seçenek koyu hap
class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({required this.current});

  final Locale current;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final options = [
      (const Locale('tr'), l.settingsLanguageTr),
      (const Locale('en'), l.settingsLanguageEn),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Row(
        children: options.map((o) {
          final isActive = o.$1.languageCode == current.languageCode;
          return Expanded(
            child: GestureDetector(
              onTap: () => localeController.setLocale(o.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF221F1E) : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Text(
                  o.$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isActive ? Colors.white : SettingsScreen._textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
