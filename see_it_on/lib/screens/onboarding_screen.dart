import 'package:flutter/material.dart';

import '../core/design/widgets.dart';
import '../core/l10n_ext.dart';
import 'login_screen.dart';

/// Dergi kapağı gibi tanıtım: maskelet, künye, kapak fotoğrafı ve başlık.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  void _openLogin(BuildContext context) => pushEditorial(context, const LoginScreen());

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final height = MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: t.paper,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Maskelet ve künye
              Text('SeeItOn', textAlign: TextAlign.center, style: text.displaySmall),
              const SizedBox(height: 4),
              Center(child: EditorialOverline(l.onboardingIssue)),
              const HairlineDivider(verticalPadding: 14),

              // Kapak fotoğrafı; yerel görsel, demo sırasında internet olmasa da açılır
              ClipRRect(
                borderRadius: BorderRadius.circular(SeeItOnTokens.radiusLg),
                child: Image.asset(
                  'assets/images/onboarding_hero.png',
                  height: height * 0.42,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 24),

              EditorialHeading(l.onboardingTitle, size: 34),
              const SizedBox(height: 12),
              Text(l.onboardingSubtitle, style: text.bodyMedium!.copyWith(color: t.muted, height: 1.5)),
              const SizedBox(height: 20),

              const HairlineDivider(),
              const SizedBox(height: 28),

              PillButton(
                label: l.onboardingStart,
                icon: Icons.arrow_forward,
                expand: true,
                onPressed: () => _openLogin(context),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => _openLogin(context),
                  child: Text.rich(
                    TextSpan(
                      text: l.onboardingHaveAccount,
                      style: text.bodyMedium!.copyWith(color: t.muted),
                      children: [
                        TextSpan(text: l.loginButton, style: TextStyle(color: t.ink, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
