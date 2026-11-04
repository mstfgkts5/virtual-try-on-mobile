import 'package:flutter/material.dart';

import '../core/l10n_ext.dart';
import '../core/locale_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _textColor = Color(0xFF1E1C1A);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
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
