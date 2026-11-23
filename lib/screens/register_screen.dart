import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../services/user_storage.dart';
import '../theme/app_palette.dart';
import '../utils/app_toast.dart';

/// Form daftar yang memvalidasi data, menyimpan akun lokal, lalu mengembalikan email ke Login.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _agreeTerms = true;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Validasi formulir dan persetujuan, lalu simpan akun sebelum kembali ke halaman login.
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeTerms) {
      AppToast.warning(
        'Persetujuan',
        'Harap setujui syarat dan ketentuan untuk melanjutkan.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final registered = await UserStorage().register(
      UserModel(
        email: email,
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
      ),
    );

    if (!mounted) return;
    if (!registered) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Email sudah terdaftar. Gunakan email lain.';
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userEmail', email);
    await prefs.setString('userName', _fullNameController.text.trim());

    Get.back<String>(result: email);
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required Widget suffixIcon,
  }) {
    // Satu dekorasi dipakai semua field agar padding, border, dan radius konsisten.
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.inter(
        fontSize: 14,
        color: const Color(0xFF94A3B8),
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 14,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(
          color: Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(
          color: AppPalette.primary,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(
          color: AppPalette.error,
          width: 1.2,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(
          color: AppPalette.error,
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 54,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: InkWell(
              onTap: () => Get.back(),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppPalette.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppPalette.border, width: 1),
                  boxShadow: AppPalette.cardShadow,
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppPalette.textPrimary,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo, judul, dan subjudul menjadi pengenal awal halaman pendaftaran.
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 64,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Judul "Buat Akun Baru" & Subjudul Bahasa Indonesia
                  Text(
                    'Buat Akun Baru',
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
                    'Lengkapi data Anda untuk mendaftar akun',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppPalette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. Field Nama Lengkap
                  Text(
                    'Nama Lengkap',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _fullNameController,
                    style: GoogleFonts.inter(fontSize: 14, color: AppPalette.textPrimary),
                    decoration: _inputDecoration(
                      hintText: 'Masukkan nama lengkap',
                      suffixIcon: const Icon(
                        Icons.person_outline_rounded,
                        size: 20,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Nama lengkap wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // 4. Field Email
                  Text(
                    'Email',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.inter(fontSize: 14, color: AppPalette.textPrimary),
                    decoration: _inputDecoration(
                      hintText: 'contoh@gmail.com',
                      suffixIcon: const Icon(
                        Icons.mail_outline_rounded,
                        size: 20,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Email wajib diisi';
                      }
                      if (!val.contains('@') || !val.contains('.')) {
                        return 'Format email tidak valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // 5. Field Password
                  Text(
                    'Password',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: GoogleFonts.inter(fontSize: 14, color: AppPalette.textPrimary),
                    decoration: _inputDecoration(
                      hintText: 'Masukkan password',
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
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Password wajib diisi';
                      }
                      if (val.length < 3) {
                        return 'Password minimal 3 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // 6. Field Konfirmasi Password
                  Text(
                    'Konfirmasi Password',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmation,
                    style: GoogleFonts.inter(fontSize: 14, color: AppPalette.textPrimary),
                    decoration: _inputDecoration(
                      hintText: 'Masukkan ulang password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmation
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: const Color(0xFF94A3B8),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmation = !_obscureConfirmation;
                          });
                        },
                      ),
                    ),
                    validator: (val) {
                      if (val != _passwordController.text) {
                        return 'Konfirmasi password tidak cocok';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // 7. Checkbox Syarat & Ketentuan
                  Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: _agreeTerms,
                          onChanged: (val) {
                            setState(() {
                              _agreeTerms = val ?? false;
                            });
                          },
                          activeColor: AppPalette.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          side: const BorderSide(
                            color: Color(0xFFCBD5E1),
                            width: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Saya menyetujui Syarat & Ketentuan Layanan',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppPalette.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppPalette.error, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.inter(fontSize: 12, color: AppPalette.error),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 22),

                  // 8. Tombol Daftar (Pill Button Penuh)
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
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
                              'Daftar Akun',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 9. Sudah punya akun? Masuk
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sudah punya akun? ',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppPalette.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Text(
                          'Masuk',
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
      ),
    );
  }
}
