import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_screen.dart';
import 'onboarding_screen.dart';

/// Uygulamanın kök ekranı: Supabase oturumunu dinler.
/// Oturum varsa ana ekran, yoksa tanıtım ekranı gösterilir. Giriş/çıkış ekranları
/// yalnızca oturumu değiştirip kendi rotalarını kapatır; kök ekranı burası değiştirir.
/// Parametreler yalnızca testlerde Supabase yerine sahte oturum vermek içindir.
class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    this.authStates,
    this.initialSignedIn,
    this.signedInBuilder,
    this.signedOutBuilder,
  });

  /// true = oturum açık
  final Stream<bool>? authStates;
  final bool? initialSignedIn;
  final WidgetBuilder? signedInBuilder;
  final WidgetBuilder? signedOutBuilder;

  @override
  Widget build(BuildContext context) {
    final auth = authStates == null || initialSignedIn == null ? Supabase.instance.client.auth : null;
    return StreamBuilder<bool>(
      stream: authStates ?? auth!.onAuthStateChange.map((s) => s.session != null),
      initialData: initialSignedIn ?? auth!.currentSession != null,
      builder: (context, snapshot) => snapshot.data == true
          ? (signedInBuilder ?? (_) => const HomeScreen())(context)
          : (signedOutBuilder ?? (_) => const OnboardingScreen())(context),
    );
  }
}
