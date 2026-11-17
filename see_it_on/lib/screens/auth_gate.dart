import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/consent_controller.dart';
import 'consent_screen.dart';
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
    this.isSignedIn,
    this.signedInBuilder,
    this.signedOutBuilder,
  });

  /// true = oturum açık
  final Stream<bool>? authStates;

  /// O anki oturum durumu: açılışta ve akış hata verdiğinde kullanılır.
  final bool Function()? isSignedIn;
  final WidgetBuilder? signedInBuilder;
  final WidgetBuilder? signedOutBuilder;

  @override
  Widget build(BuildContext context) {
    final auth = authStates == null || isSignedIn == null ? Supabase.instance.client.auth : null;
    final signedInNow = isSignedIn ?? () => auth!.currentSession != null;
    return StreamBuilder<bool>(
      stream: authStates ?? auth!.onAuthStateChange.map((s) => s.session != null),
      initialData: signedInNow(),
      builder: (context, snapshot) {
        // gotrue, token yenileme hatalarını (ör. 429/5xx) akışa hata olarak basar;
        // bu oturumun kapandığı anlamına gelmez, o yüzden mevcut oturuma bakılır
        final signedIn = snapshot.hasError ? signedInNow() : snapshot.data == true;
        return signedIn
            ? (signedInBuilder ?? (_) => const ConsentGate(child: HomeScreen()))(context)
            : (signedOutBuilder ?? (_) => const OnboardingScreen())(context);
      },
    );
  }
}

/// Oturum açık kullanıcı KVKK açık rızasını vermediyse ana ekran yerine aydınlatma metnini gösterir.
/// Rıza verilince (veya Ayarlar'dan geri çekilince) kendiliğinden yeniden çizilir.
class ConsentGate extends StatelessWidget {
  const ConsentGate({super.key, required this.child, this.controller});

  final Widget child;
  final ConsentController? controller;

  @override
  Widget build(BuildContext context) {
    final c = controller ?? consentController;
    return ValueListenableBuilder<bool>(
      valueListenable: c,
      builder: (context, accepted, _) => accepted ? child : ConsentScreen(controller: c),
    );
  }
}
