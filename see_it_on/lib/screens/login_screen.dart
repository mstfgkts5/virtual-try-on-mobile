import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  // Supabase yetkilendirme fonksiyonu
  Future<void> _authenticate() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Lütfen e-posta ve şifrenizi girin.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        // Giriş Yapma İşlemi
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } else {
        // Yeni Kayıt Olma İşlemi
        await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
        );
      }

      // Başarılı olursa ana ekrana yönlendir
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on AuthException catch (e) {
      _showError(e.message); // Supabase'den gelen hata mesajı (Örn: Yanlış şifre)
    } catch (e) {
      _showError('Beklenmeyen bir hata oluştu.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE11D48),
        behavior: SnackBarBehavior.floating,
      ),
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
    const textColor = Color(0xFF1E1C1A);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EF), // Açık krem arka plan
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo veya İkon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, spreadRadius: 2)
                    ],
                  ),
                  child: const Icon(Icons.checkroom, color: textColor, size: 32),
                ),
                const SizedBox(height: 24),
                
                // Başlık
                Text(
                  _isLogin ? 'Welcome Back' : 'Join SeeItOn',
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 32,
                    fontFamily: 'Georgia',
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin 
                      ? 'Sign in to access your digital wardrobe.' 
                      : 'Create an account to start fusing your silhouette.',
                  style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 14),
                ),
                const SizedBox(height: 40),

                // E-Posta Alanı
                _buildTextField(
                  controller: _emailController,
                  hintText: 'Email Address',
                  icon: Icons.email_outlined,
                  obscureText: false,
                ),
                const SizedBox(height: 16),

                // Şifre Alanı
                _buildTextField(
                  controller: _passwordController,
                  hintText: 'Password',
                  icon: Icons.lock_outline,
                  obscureText: true,
                ),
                const SizedBox(height: 32),

                // Ana Buton (Giriş veya Kayıt)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _authenticate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF221F1E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            _isLogin ? 'Log In' : 'Sign Up',
                            style: const TextStyle(fontSize: 16, fontFamily: 'Georgia', fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Ekran Değiştirme Butonu (Giriş <-> Kayıt)
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                      });
                    },
                    child: Text.rich(
                      TextSpan(
                        text: _isLogin ? "Don't have an account? " : "Already have an account? ",
                        style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 13),
                        children: [
                          TextSpan(
                            text: _isLogin ? 'Sign Up' : 'Log In',
                            style: const TextStyle(color: textColor, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Özel Tasarımlı Input Alanı
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool obscureText,
  }) {
    const textColor = Color(0xFF1E1C1A);
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: textColor),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: textColor.withValues(alpha: 0.4)),
        prefixIcon: Icon(icon, color: textColor.withValues(alpha: 0.4), size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.6),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: textColor.withValues(alpha: 0.1), width: 2),
        ),
      ),
    );
  }
}