import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/user_storage.dart';
import '../theme/app_palette.dart';
import '../utils/app_toast.dart';
import 'register_screen.dart';
import 'root_screen.dart';

/// Halaman Login Autentikasi Pengguna (Bahasa Indonesia & Bersih Tanpa Social Login)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoginFailed = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Memeriksa status login yang tersimpan di SharedPreferences
  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('loginData') ?? false;
    final String savedName = prefs.getString('userName') ?? 'Wisatawan Bajo';

    if (isLoggedIn && mounted) {
      Get.offAll(() => RootScreen(userName: savedName));
    }
  }

  /// Proses validasi dan eksekusi login
  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _isLoginFailed = true;
      });
      AppToast.error('Login Gagal', 'Silakan masukkan email dan password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _isLoginFailed = false;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    final user = await UserStorage().authenticate(email, password);

    if (user != null) {
      final authenticatedUser = user;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('loginData', true);
      await prefs.setString('userName', authenticatedUser.fullName);
      if (prefs.getDouble('maxBudget') == null) {
        await prefs.setDouble('maxBudget', 5000000.0);
      }

      if (mounted) {
        Get.offAll(() => RootScreen(userName: authenticatedUser.fullName));
        AppToast.success(
          'Selamat Datang',
          'Halo ${authenticatedUser.fullName}, selamat merencanakan petualangan di Bajo!',
        );
      }
    } else {
      setState(() {
        _isLoginFailed = true;
        _isLoading = false;
      });

      if (mounted) {
        AppToast.error(
          'Login Gagal',
          'Email atau password salah. Silakan periksa kembali atau daftar akun baru.',
        );
      }
    }
  }

  Future<void> _openRegister() async {
    final email = await Get.to<String>(() => const RegisterScreen());
    if (email != null && mounted) {
      _emailController.text = email;
      AppToast.success(
        'Akun Terdaftar',
        'Akun $email berhasil dibuat! Silakan masukkan password untuk masuk.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Logo Saja di Tengah (Tanpa Teks BajoLand)
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 64,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Judul "Selamat Datang" & Subjudul Bahasa Indonesia
                Text(
                  'Selamat Datang',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Masukkan email & password untuk masuk',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppPalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),

                // 3. Field Email dengan Label di Atas
                Text(
                  'Email',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  onChanged: (_) {
                    if (_isLoginFailed) {
                      setState(() => _isLoginFailed = false);
                    }
                  },
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppPalette.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'contoh@gmail.com',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF94A3B8),
                    ),
                    suffixIcon: const Icon(
                      Icons.mail_outline_rounded,
                      size: 20,
                      color: Color(0xFF94A3B8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide(
                        color: _isLoginFailed
                            ? AppPalette.error
                            : const Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide(
                        color: _isLoginFailed
                            ? AppPalette.error
                            : AppPalette.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Field Password dengan Label di Atas
                Text(
                  'Password',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  onChanged: (_) {
                    if (_isLoginFailed) {
                      setState(() => _isLoginFailed = false);
                    }
                  },
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppPalette.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Masukkan password Anda',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF94A3B8),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: const Color(0xFF94A3B8),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide(
                        color: _isLoginFailed
                            ? AppPalette.error
                            : const Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide(
                        color: _isLoginFailed
                            ? AppPalette.error
                            : AppPalette.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                if (_isLoginFailed) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppPalette.error,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Email atau password salah.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppPalette.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 24),

                // 5. Tombol Masuk (Pill Button Penuh)
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Masuk',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // 6. Belum punya akun? Daftar
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Belum punya akun? ',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppPalette.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: _isLoading ? null : _openRegister,
                      child: Text(
                        'Daftar akun',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppPalette.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
