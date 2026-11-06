import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'root_screen.dart';

/// Halaman Login Autentikasi Pengguna (Modul 2, 3, 4, 6)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
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
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Memeriksa status login yang tersimpan di SharedPreferences (Modul 6)
  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('loginData') ?? false;
    final String savedName = prefs.getString('userName') ?? 'Wisatawan Bajo';

    if (isLoggedIn && mounted) {
      // Modul 4: Navigator.pushReplacement
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RootScreen(userName: savedName),
        ),
      );
    }
  }

  /// Proses validasi dan eksekusi login
  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _isLoading = true;
      _isLoginFailed = false;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    // Modul 3: Validasi menggunakan model class
    final user = UserModel.authenticate(username, password);

    if (user != null) {
      // Modul 6: Simpan sesi login ke SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('loginData', true);
      await prefs.setString('userName', user.fullName);
      if (prefs.getDouble('maxBudget') == null) {
        await prefs.setDouble('maxBudget', 5000000.0);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selamat datang di BajoLand, ${user.fullName}!'),
            backgroundColor: const Color(0xFF0D5C3A),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Modul 4: Navigator.pushReplacement dengan passing data via constructor
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RootScreen(userName: user.fullName),
          ),
        );
      }
    } else {
      // Modul 3: Dynamic Styling (border merah) & Error Handling
      setState(() {
        _isLoginFailed = true;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Username atau Password salah! Silakan coba lagi.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Reusable Input Field Widget dengan Dynamic Border Styling (Modul 2 & Modul 3)
  Widget _inputField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      onChanged: (_) {
        if (_isLoginFailed) {
          setState(() {
            _isLoginFailed = false;
          });
        }
      },
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF0D5C3A)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        // Dynamic Styling: Border berubah menjadi merah saat gagal login
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _isLoginFailed ? Colors.red : Colors.grey.shade300,
            width: _isLoginFailed ? 2.0 : 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _isLoginFailed ? Colors.red : const Color(0xFF0D5C3A),
            width: 2.0,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F2),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Logo & Branding BajoLand
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D5C3A).withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sailing_rounded,
                    size: 64,
                    color: Color(0xFF0D5C3A),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'BajoLand',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Color(0xFF0D5C3A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Perencana Itinerary & Anggaran Wisata Labuan Bajo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 36),

                // Form Login
                _inputField(
                  controller: _usernameController,
                  labelText: 'Username',
                  hintText: 'Masukkan username (misal: arya)',
                  prefixIcon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _inputField(
                  controller: _passwordController,
                  labelText: 'Password',
                  hintText: 'Masukkan password (misal: 123)',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                ),

                // Conditional Error Text
                if (_isLoginFailed) ...[
                  const SizedBox(height: 10),
                  const Text(
                    '* Kredensial tidak valid. Silakan periksa kembali.',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // Tombol Masuk
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D5C3A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Masuk ke BajoLand',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),

                const SizedBox(height: 24),
                // Petunjuk Akun Demo
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '💡 Akun Demo Praktikum:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Username: arya  |  Password: 123',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

