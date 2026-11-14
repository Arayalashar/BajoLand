import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'explore_screen.dart';
import 'itinerary_screen.dart';
import 'lbs_screen.dart';
import 'profile_screen.dart';

/// Halaman Induk Navigasi Tab Bar (Modul 4: BottomNavigationBar & Navigation Stack)
class RootScreen extends StatefulWidget {
  final String userName;

  const RootScreen({super.key, required this.userName});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class RootNavigationController extends GetxController {
  final selectedIndex = 0.obs;

  void selectTab(int index) => selectedIndex.value = index;
}

class _RootScreenState extends State<RootScreen> {
  late final RootNavigationController _controller;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(RootNavigationController());
    _screens = [
      const ExploreScreen(),
      const ItineraryScreen(),
      const LbsScreen(),
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
        body: IndexedStack(
          index: _controller.selectedIndex.value,
          children: _screens,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _controller.selectedIndex.value,
            onTap: _controller.selectTab,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF0D5C3A),
            unselectedItemColor: Colors.grey.shade500,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 12,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.explore_outlined),
                activeIcon: Icon(Icons.explore),
                label: 'Explore',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_outlined),
                activeIcon: Icon(Icons.calendar_month),
                label: 'Itinerary',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.radar_outlined),
                activeIcon: Icon(Icons.radar),
                label: 'Radar Bajo',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
