import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/user_storage.dart';
import '../theme/app_palette.dart';
import 'all_destinations_screen.dart';
import 'explore_screen.dart';
import 'itinerary_screen.dart';
import 'lbs_screen.dart';
import 'profile_screen.dart';

/// Pemilik lima tab utama serta data profil reaktif yang dipakai oleh layar-layar anak.
class RootScreen extends StatefulWidget {
  final String userName;

  const RootScreen({
    super.key,
    required this.userName,
  });

  @override
  State<RootScreen> createState() => _RootScreenState();
}

/// State bersama untuk tab terpilih, profil, dan filter itinerary yang dibuka dari notifikasi.
class RootNavigationController extends GetxController {
  final selectedIndex = 0.obs;
  final itineraryFilter = 0.obs;
  final userName = ''.obs;
  final userEmail = ''.obs;
  final userAvatar = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }

  /// Memuat profil pengguna dari SharedPreferences secara global
  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('userName');
    String? savedEmail = prefs.getString('userEmail');
    final savedAvatar = prefs.getString('userAvatar');

    if (savedName != null && savedName.isNotEmpty) {
      userName.value = savedName;
    }
    if (savedEmail != null && savedEmail.isNotEmpty) {
      userEmail.value = savedEmail;
    } else if (savedName != null && savedName.isNotEmpty) {
      final user = await UserStorage().findByFullName(savedName) ?? await UserStorage().getLastRegisteredUser();
      if (user != null && user.email.isNotEmpty) {
        userEmail.value = user.email;
        await prefs.setString('userEmail', user.email);
      }
    }
    if (savedAvatar != null && savedAvatar.isNotEmpty) {
      userAvatar.value = savedAvatar;
    }
  }

  /// Memperbarui profil secara reaktif ke seluruh layar aplikasi
  Future<void> updateProfile({String? name, String? email, String? avatar}) async {
    final prefs = await SharedPreferences.getInstance();
    if (name != null && name.isNotEmpty) {
      userName.value = name;
      await prefs.setString('userName', name);
    }
    if (email != null && email.isNotEmpty) {
      userEmail.value = email;
      await prefs.setString('userEmail', email);
    }
    if (avatar != null && avatar.isNotEmpty) {
      userAvatar.value = avatar;
      await prefs.setString('userAvatar', avatar);
    }
  }

  /// Berpindah tab dan, bila diminta, membawa filter untuk halaman itinerary.
  void selectTab(int index, {int? itineraryFilter}) {
    if (itineraryFilter != null) {
      this.itineraryFilter.value = itineraryFilter;
    }
    selectedIndex.value = index;
  }
}

class _RootScreenState extends State<RootScreen> {
  // Controller ditangani bersama dengan lifecycle RootScreen agar data tab tidak bocor antar layar.
  late final RootNavigationController _controller;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(RootNavigationController());
    if (widget.userName.isNotEmpty) {
      _controller.userName.value = widget.userName;
    }
    _screens = [
      ExploreScreen(userName: widget.userName), // Menu Home
      const AllDestinationsScreen(showBackButton: false), // Menu Explore (Full Destinasi)
      const ItineraryScreen(),
      const LbsScreen(), // Menu Radar Bajo
      ProfileScreen(userName: widget.userName),
    ];
  }

  @override
  void dispose() {
    Get.delete<RootNavigationController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: AppPalette.background,
        // IndexedStack menyimpan state tiap tab saat pengguna berpindah menu.
        body: IndexedStack(
          index: _controller.selectedIndex.value,
          children: _screens,
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppPalette.surface,
            border: Border(
              top: BorderSide(color: AppPalette.border, width: 1.0),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Home',
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.explore_outlined,
                    activeIcon: Icons.explore,
                    label: 'Explore',
                  ),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.calendar_today_outlined,
                    activeIcon: Icons.calendar_month,
                    label: 'Itinerary',
                  ),
                  _buildNavItem(
                    index: 3,
                    icon: Icons.map_outlined,
                    activeIcon: Icons.map_rounded,
                    label: 'Radar Bajo',
                  ),
                  _buildNavItem(
                    index: 4,
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: 'Profil',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _controller.selectedIndex.value == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _controller.selectTab(index),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Latar kapsul hanya muncul pada tab aktif; radius penuh membentuk pil.
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? AppPalette.primarySubtle : Colors.transparent,
                  borderRadius: AppPalette.radiusFull,
                ),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  size: 22,
                  color: isSelected ? AppPalette.primary : AppPalette.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppPalette.labelXs(
                  color: isSelected ? AppPalette.primary : AppPalette.textSecondary,
                ).copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
