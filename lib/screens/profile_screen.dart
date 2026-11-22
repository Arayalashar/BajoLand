import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';
import '../services/user_storage.dart';
import '../theme/app_palette.dart';
import '../utils/app_toast.dart';
import 'login_screen.dart';
import 'root_screen.dart';

/// Halaman Profil Sederhana (Simple Profile Screen)
/// Desain bersih & minimalis sesuai Design System BajoLand
/// Mendukung penggantian foto profil dari Galeri perangkat
class ProfileScreen extends StatefulWidget {
  final String userName;

  const ProfileScreen({super.key, required this.userName});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String _userName;
  String _userEmail = '';
  String _avatarUrl = '';
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _userName = widget.userName;
    _loadProfileData();
  }

  /// Memuat data profil & status perizinan notifikasi dari SharedPreferences
  Future<void> _loadProfileData() async {
    final rootCtrl = Get.isRegistered<RootNavigationController>()
        ? Get.find<RootNavigationController>()
        : null;

    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('userName');
    String? savedEmail = prefs.getString('userEmail');
    final savedAvatar = prefs.getString('userAvatar');
    final savedNotif = prefs.getBool('notificationsEnabled');

    // Pastikan email sinkron dengan akun yang didaftarkan di UserStorage
    if (savedEmail == null || savedEmail.isEmpty) {
      final lookupName = savedName ?? (rootCtrl != null && rootCtrl.userName.value.isNotEmpty ? rootCtrl.userName.value : _userName);
      final matchedUser = await UserStorage().findByFullName(lookupName) ?? await UserStorage().getLastRegisteredUser();
      if (matchedUser != null && matchedUser.email.isNotEmpty) {
        savedEmail = matchedUser.email;
        await prefs.setString('userEmail', savedEmail);
        if (rootCtrl != null) {
          rootCtrl.userEmail.value = savedEmail;
        }
      }
    }

    if (mounted) {
      setState(() {
        if (savedName != null && savedName.isNotEmpty) {
          _userName = savedName;
        } else if (rootCtrl != null && rootCtrl.userName.value.isNotEmpty) {
          _userName = rootCtrl.userName.value;
        }
        if (savedEmail != null && savedEmail.isNotEmpty) {
          _userEmail = savedEmail;
        } else if (rootCtrl != null && rootCtrl.userEmail.value.isNotEmpty) {
          _userEmail = rootCtrl.userEmail.value;
        } else {
          _userEmail = '${_userName.toLowerCase().replaceAll(' ', '.')}@gmail.com';
        }
        _avatarUrl = (savedAvatar != null && savedAvatar.isNotEmpty)
            ? savedAvatar
            : ((rootCtrl != null && rootCtrl.userAvatar.value.isNotEmpty)
                ? rootCtrl.userAvatar.value
                : '');
        _notificationsEnabled = savedNotif ?? true;
      });
    }
  }

  /// Mengambil foto profil langsung dari Galeri perangkat
  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (picked != null) {
        final path = picked.path;
        final rootCtrl = Get.isRegistered<RootNavigationController>()
            ? Get.find<RootNavigationController>()
            : null;

        if (rootCtrl != null) {
          await rootCtrl.updateProfile(avatar: path);
        } else {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userAvatar', path);
        }

        if (mounted) {
          setState(() {
            _avatarUrl = path;
          });
          AppToast.success('Foto Profil Diperbarui', 'Foto profil berhasil diambil dari galeri.');
        }
      }
    } catch (_) {
      AppToast.error('Gagal Mengambil Foto', 'Terjadi kesalahan saat membuka galeri.');
    }
  }

  /// Dialog untuk mengubah nama dan email pengguna (Edit Profil)
  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _userName);
    final emailController = TextEditingController(text: _userEmail);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppPalette.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppPalette.radiusLg),
        title: Text('Edit Profil', style: AppPalette.h3()),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nama Lengkap', style: AppPalette.labelXs(color: AppPalette.textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'Masukkan nama lengkap',
                  filled: true,
                  fillColor: AppPalette.surfaceMuted,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: AppPalette.radiusMd,
                    borderSide: const BorderSide(color: AppPalette.border),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('Email', style: AppPalette.labelXs(color: AppPalette.textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Masukkan alamat email',
                  filled: true,
                  fillColor: AppPalette.surfaceMuted,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: AppPalette.radiusMd,
                    borderSide: const BorderSide(color: AppPalette.border),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: AppPalette.bodyMd(color: AppPalette.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              final newEmail = emailController.text.trim();

              if (newName.isNotEmpty) {
                Navigator.pop(ctx);
                final rootCtrl = Get.isRegistered<RootNavigationController>()
                    ? Get.find<RootNavigationController>()
                    : null;
                if (rootCtrl != null) {
                  rootCtrl.updateProfile(
                    name: newName,
                    email: newEmail.isNotEmpty ? newEmail : null,
                  );
                } else {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('userName', newName);
                  if (newEmail.isNotEmpty) {
                    await prefs.setString('userEmail', newEmail);
                  }
                }

                if (mounted) {
                  setState(() {
                    _userName = newName;
                    if (newEmail.isNotEmpty) _userEmail = newEmail;
                  });
                  AppToast.success('Profil Diperbarui', 'Data profil Anda berhasil disimpan.');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const RoundedRectangleBorder(borderRadius: AppPalette.radiusMd),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  /// Dialog Perizinan Notifikasi
  Future<void> _handleNotificationPermission() async {
    final prefs = await SharedPreferences.getInstance();
    final newStatus = !_notificationsEnabled;

    await prefs.setBool('notificationsEnabled', newStatus);

    if (newStatus) {
      await NotificationService.instance.requestPermissions();
      await NotificationService.instance.showInstantNotification(
        id: 9991,
        title: 'Notifikasi Aktif',
        body: 'Pengingat rencana dan info penting BajoLand akan selalu tampil di perangkat Anda.',
      );
      AppToast.success('Izin Notifikasi Aktif', 'Pengingat perjalanan diaktifkan.');
    } else {
      AppToast.warning('Notifikasi Dinonaktifkan', 'Anda tidak akan menerima notifikasi pengingat.');
    }

    if (mounted) {
      setState(() {
        _notificationsEnabled = newStatus;
      });
    }
  }

  /// Dialog Tentang BajoLand
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppPalette.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppPalette.radiusLg),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppPalette.primarySubtle,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.travel_explore_rounded, color: AppPalette.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Text('Tentang BajoLand', style: AppPalette.h3()),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BajoLand v1.0.0',
              style: AppPalette.bodyMd().copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Aplikasi travel planner dan panduan wisata pintar terlengkap untuk menjelajahi keindahan Labuan Bajo dan Kepulauan Komodo.',
              style: AppPalette.bodyMd(color: AppPalette.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppPalette.surfaceMuted,
                borderRadius: AppPalette.radiusMd,
                border: Border.all(color: AppPalette.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fitur Utama:', style: AppPalette.labelXs().copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('• Eksplorasi Destinasi Populer', style: AppPalette.caption(color: AppPalette.textSecondary)),
                  Text('• Itinerary & Budget Manager dengan Notifikasi', style: AppPalette.caption(color: AppPalette.textSecondary)),
                  Text('• Radar Bajo (LBS) & Navigasi Rute Bahari', style: AppPalette.caption(color: AppPalette.textSecondary)),
                  Text('• Manajemen Wishlist & Riwayat Agenda', style: AppPalette.caption(color: AppPalette.textSecondary)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const RoundedRectangleBorder(borderRadius: AppPalette.radiusMd),
            ),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  /// Konfirmasi & Eksekusi Logout
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppPalette.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppPalette.radiusLg),
        title: Text('Keluar dari Akun?', style: AppPalette.h3()),
        content: Text(
          'Anda perlu masuk kembali untuk mengakses seluruh data liburan Anda.',
          style: AppPalette.bodyMd(color: AppPalette.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: AppPalette.bodyMd(color: AppPalette.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('loginData', false);
              Get.offAll(() => const LoginScreen());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const RoundedRectangleBorder(borderRadius: AppPalette.radiusMd),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  /// Helper untuk merender foto profil baik dari file lokal galeri maupun URL web
  Widget _buildAvatarImage(String avatar, String name) {
    if (avatar.isEmpty) {
      return Center(
        child: Text(
          name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U',
          style: const TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.bold,
            color: AppPalette.primary,
          ),
        ),
      );
    }

    if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
      return Image.network(
        avatar,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Center(
          child: Text(
            name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U',
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.bold,
              color: AppPalette.primary,
            ),
          ),
        ),
      );
    } else {
      return Image.file(
        File(avatar),
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Center(
          child: Text(
            name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U',
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.bold,
              color: AppPalette.primary,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        title: Text('Profil', style: AppPalette.h2()),
        backgroundColor: AppPalette.surface,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppPalette.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppPalette.spacingLg,
          vertical: AppPalette.spacingXl,
        ),
        child: Column(
          children: [
            // ─── 1. FOTO DITENGAH, NAMA, & EMAIL ───────────────────────────
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: _pickImageFromGallery,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppPalette.primarySubtle,
                            border: Border.all(color: AppPalette.primary, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: AppPalette.primary.withValues(alpha: 0.20),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _buildAvatarImage(_avatarUrl, _userName),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImageFromGallery,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppPalette.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.camera_alt_rounded, size: 15, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _userName,
                    style: AppPalette.h2().copyWith(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userEmail,
                    style: AppPalette.bodyMd(color: AppPalette.textSecondary).copyWith(
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ─── 2. MENU VERTIKAL SEDERHANA ───────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppPalette.surface,
                borderRadius: AppPalette.radiusLg,
                border: Border.all(color: AppPalette.border),
                boxShadow: AppPalette.cardShadow,
              ),
              child: Column(
                children: [
                  // Menu 1: Edit Profil
                  _buildMenuItem(
                    icon: Icons.edit_note_rounded,
                    title: 'Edit Profil',
                    subtitle: 'Ubah nama lengkap atau alamat email',
                    onTap: _showEditProfileDialog,
                  ),
                  const Divider(height: 1, color: AppPalette.border, indent: 56),

                  // Menu 2: Perizinan Notifikasi
                  _buildMenuItem(
                    icon: Icons.notifications_active_outlined,
                    title: 'Perizinan Notifikasi',
                    subtitle: _notificationsEnabled ? 'Notifikasi Aktif' : 'Notifikasi Dinonaktifkan',
                    trailing: Switch.adaptive(
                      value: _notificationsEnabled,
                      activeTrackColor: AppPalette.primary,
                      onChanged: (_) => _handleNotificationPermission(),
                    ),
                    onTap: _handleNotificationPermission,
                  ),
                  const Divider(height: 1, color: AppPalette.border, indent: 56),

                  // Menu 3: Tentang BajoLand
                  _buildMenuItem(
                    icon: Icons.info_outline_rounded,
                    title: 'Tentang BajoLand',
                    subtitle: 'Versi aplikasi & informasi pembuat',
                    onTap: _showAboutDialog,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),

            // ─── 3. TOMBOL KELUAR ──────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _confirmLogout,
                icon: const Icon(Icons.logout_rounded, size: 20, color: AppPalette.error),
                label: Text(
                  'Keluar dari Akun',
                  style: AppPalette.bodyMd(color: AppPalette.error).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppPalette.surface,
                  side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.2),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppPalette.radiusMd,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget Item Menu Vertikal
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppPalette.primarySubtle,
          borderRadius: AppPalette.radiusMd,
        ),
        child: Icon(icon, color: AppPalette.primary, size: 20),
      ),
      title: Text(
        title,
        style: AppPalette.bodyMd().copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppPalette.caption(color: AppPalette.textSecondary).copyWith(
          fontSize: 12,
        ),
      ),
      trailing: trailing ??
          const Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: AppPalette.textSecondary,
          ),
    );
  }
}
