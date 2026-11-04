import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/design/widgets.dart';
import '../core/l10n_ext.dart';
import '../services/auth_errors.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isLogin = true; // true ise Giriş Yap, false ise Kayıt Ol ekranı
  bool _obscurePassword = true;

  // Supabase yetkilendirme fonksiyonu
  Future<void> _authenticate() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final l = context.l10n;
    if (email.isEmpty || password.isEmpty) {
      _showError(l.loginMissingFields);
      return;
    }
    // Supabase'e gitmeden önce basit kontroller: kullanıcı ağ isteği beklemeden uyarı alır
    if (!isValidEmail(email)) {
      _showError(l.authErrorInvalidEmail);
      return;
    }
    if (password.length < minPasswordLength) {
      _showError(l.authErrorPasswordTooShort);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await Supabase.instance.client.auth
            .signInWithPassword(email: email, password: password)
            .timeout(authRequestTimeout);
      } else {
        // E-posta doğrulaması kapalı olduğu için kayıt olan kullanıcı hemen oturum açmış olur
        await Supabase.instance.client.auth
            .signUp(email: email, password: password)
            .timeout(authRequestTimeout);
      }

      // Ana ekrana geçişi AuthGate yapar (oturum değişikliğini dinliyor);
      // burada yalnızca tanıtım/giriş rotaları kapatılır
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) _showError(authErrorMessage(context.l10n, e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: context.tokens.danger),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: t.paper,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const EditorialOverline('SeeItOn'),
                const HairlineDivider(verticalPadding: 14),
                EditorialHeading(_isLogin ? l.loginTitle : l.signupTitle),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? l.loginSubtitle : l.signupSubtitle,
                  style: text.bodyMedium!.copyWith(color: t.muted),
                ),
                const SizedBox(height: 36),

                _buildTextField(
                  controller: _emailController,
                  hintText: l.loginEmailHint,
                  icon: Icons.email_outlined,
                  obscureText: false,
                  textInputAction: TextInputAction.next, // Enter'a basınca şifreye geçer
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _passwordController,
                  hintText: l.loginPasswordHint,
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffix: IconButton(
                    tooltip: _obscurePassword ? l.loginShowPassword : l.loginHidePassword,
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: t.muted,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (!_isLoading) _authenticate();
                  },
                ),
                const SizedBox(height: 28),

                PillButton(
                  label: _isLogin ? l.loginButton : l.signupButton,
                  expand: true,
                  busy: _isLoading,
                  onPressed: _authenticate,
                ),
                const SizedBox(height: 16),

                // Ekran değiştirme (Giriş <-> Kayıt)
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text.rich(
                      TextSpan(
                        text: _isLogin ? l.loginNoAccount : l.loginHaveAccount,
                        style: text.bodyMedium!.copyWith(color: t.muted, fontSize: 13),
                        children: [
                          TextSpan(
                            text: _isLogin ? l.signupButton : l.loginButton,
                            style: TextStyle(color: t.ink, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Sadece debug derlemede görünür; release (teslim) sürümünde derlenmez.
                // Gardıroba kaydetme gibi oturum gerektiren işlemler bu modda çalışmaz.
                if (kDebugMode)
                  Center(
                    child: TextButton.icon(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                      ),
                      icon: Icon(Icons.developer_mode, size: 16, color: t.muted),
                      label: Text(l.loginSkipDev, style: text.bodySmall),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Yüzey zeminli, ince çerçeveli giriş alanı
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool obscureText,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
    Widget? suffix,
  }) {
    final t = context.tokens;
    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(SeeItOnTokens.radiusMd),
          borderSide: BorderSide(color: c),
        );
    return TextField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: TextStyle(color: t.ink),
      cursorColor: t.ink,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: t.muted),
        prefixIcon: Icon(icon, color: t.muted, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: t.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        enabledBorder: border(t.line),
        focusedBorder: border(t.ink.withValues(alpha: 0.4)),
      ),
    );
  }
}
