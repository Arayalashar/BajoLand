import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_service.dart';
import '../data/bajo_locations.dart';
import '../models/destinasi_model.dart';
import '../models/itinerary_item.dart';
import '../services/wishlist_service.dart';
import '../theme/app_palette.dart';
import '../utils/app_toast.dart';
import 'add_itinerary_screen.dart';
import 'all_destinations_screen.dart';
import 'detail_gear_screen.dart';
import 'itinerary_screen.dart';
import 'notification_screen.dart';
import 'root_screen.dart';

/// Beranda: header profil, pencarian, destinasi populer, dan tiga rencana terdekat.
class ExploreScreen extends StatefulWidget {
  final String? userName;

  const ExploreScreen({super.key, this.userName});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  // Controller pencarian menyimpan teks yang diketik pengguna.
  late Future<List<DestinasiModel>> _destinasiFuture;
  final TextEditingController _searchController = TextEditingController();

  String _userName = 'Wisatawan';
  String _searchQuery = '';
  int _selectedCategoryIndex = 0;

  final List<String> _categories = [
    'Semua',
    'Pulau',
    'Pantai',
    'Trekking',
    'Diving',
    'Gua',
    'Kuliner',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadDestinasi();
  }

  @override
  void didUpdateWidget(covariant ExploreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userName != oldWidget.userName) {
      _loadUserName();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = widget.userName ?? prefs.getString('userName') ?? 'Wisatawan';
    if (mounted) {
      setState(() {
        _userName = name;
      });
    }
  }

  void _loadDestinasi() {
    setState(() {
      _destinasiFuture = ApiService.getDestinasi();
    });
  }

  Future<void> _toggleWishlist(int id) async {
    final isAdded = await WishlistController.to.toggleWishlist(id);
    if (isAdded) {
      AppToast.success('Destinasi Disimpan', 'Destinasi berhasil disimpan di daftar Anda.');
    } else {
      AppToast.info('Dihapus dari Simpan', 'Destinasi dihapus dari daftar simpan.');
    }
  }

  String _formatRupiah(double amount) {
    try {
      final formatter = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      );
      return formatter.format(amount);
    } catch (_) {
      return 'Rp ${amount.toStringAsFixed(0)}';
    }
  }

  String _getDestinationImage(String destinationName) {
    // Cocokkan nama itinerary ke katalog peta agar kartu rencana memakai foto tempatnya.
    final lower = destinationName.toLowerCase().trim();
    for (final b in bajoDestinations) {
      if (b.name.toLowerCase().contains(lower) || lower.contains(b.name.toLowerCase())) {
        return b.imageUrl;
      }
    }
    return 'https://images.unsplash.com/photo-1518509562904-e7ef99cdcc86?w=600';
  }

  String _getDestinationLocation(String destinationName) {
    final lower = destinationName.toLowerCase().trim();
    for (final b in bajoDestinations) {
      if (b.name.toLowerCase().contains(lower) || lower.contains(b.name.toLowerCase())) {
        return b.location;
      }
    }
    return 'Labuan Bajo, NTT';
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _searchQuery.isNotEmpty;

    // Tarik ke bawah memuat ulang destinasi, favorit, dan nama profil sekaligus.
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _loadDestinasi();
            await WishlistController.to.loadWishlist();
            await _loadUserName();
          },
          color: AppPalette.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── 1. Header: Profil di Kiri, Halo (Nama), & Notif di Kanan ───
                _buildTopHeaderWithProfile(),

                const SizedBox(height: 14),

                // ─── 2. Search Bar ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildSearchField(),
                ),

                const SizedBox(height: 18),

                // Saat kolom pencarian terisi, dashboard diganti daftar hasil langsung.
                // Jika kosong, tampilkan banner, katalog populer, dan rencana mendatang.
                // ─── 3. Konten Utama atau Hasil Pencarian ──────────────────────
                if (isSearching)
                  _buildSearchResultsSection()
                else ...[
                  // ─── 3A. Banner CTA Buat Itinerary ───
                  _buildItineraryCtaBanner(),

                  const SizedBox(height: 24),

                  // ─── 3B. Destinasi Populer + Filter Kategori ─────────────────
                  _buildSectionHeader(
                    title: 'Destinasi Populer',
                    actionLabel: 'Lihat Semua',
                    onAction: () {
                      final rootCtrl = Get.isRegistered<RootNavigationController>()
                          ? Get.find<RootNavigationController>()
                          : null;
                      if (rootCtrl != null) {
                        rootCtrl.selectTab(1);
                      } else {
                        Get.to(() => const AllDestinationsScreen(showBackButton: false));
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildPopularDestinationFilters(),
                  const SizedBox(height: 12),
                  _buildPopularDestinationCarousel(),

                  const SizedBox(height: 24),

                  // ─── 3C. Rencana Mendatang (Card Rapi Bebas Overflow) ────────
                  _buildSectionHeader(
                    title: 'Rencana Mendatang',
                    actionLabel: 'Lihat Semua',
                    onAction: () {
                      final rootCtrl = Get.isRegistered<RootNavigationController>()
                          ? Get.find<RootNavigationController>()
                          : null;
                      if (rootCtrl != null) {
                        rootCtrl.selectTab(2, itineraryFilter: 1);
                      } else {
                        Get.to(() => const ItineraryScreen(initialFilter: 1));
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildUpcomingItinerariesSection(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── 1. Header: Profil Kiri, Halo (Nama) & Notif Kanan ──────────────────────
  Widget _buildTopHeaderWithProfile() {
    final rootCtrl = Get.isRegistered<RootNavigationController>()
        ? Get.find<RootNavigationController>()
        : null;

    return Obx(() {
      final currentName = (rootCtrl != null && rootCtrl.userName.value.isNotEmpty)
          ? rootCtrl.userName.value
          : _userName;
      final currentAvatar = (rootCtrl != null && rootCtrl.userAvatar.value.isNotEmpty)
          ? rootCtrl.userAvatar.value
          : '';

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Pojok Kiri Atas: Avatar Sinkron dengan Menu Profil (Foto Profil / Inisial)
            GestureDetector(
              onTap: () {
                if (rootCtrl != null) {
                  rootCtrl.selectTab(4);
                }
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppPalette.primarySubtle,
                  border: Border.all(color: AppPalette.primary, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppPalette.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: currentAvatar.isNotEmpty
                      ? _buildAvatarImage(currentAvatar, currentName)
                      : _buildInitialAvatar(currentName),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 2. Sebelah Kanannya: Halo (Nama) & Mau Liburan ke mana...
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Halo, $currentName',
                    style: AppPalette.bodyMd(color: AppPalette.textSecondary).copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Mau liburan ke mana hari ini?',
                    style: AppPalette.h1(color: AppPalette.textPrimary).copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // 3. Pojok Kanan Atas: Lonceng Notifikasi
            GestureDetector(
              onTap: () => Get.to(() => const NotificationScreen()),
              child: Stack(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppPalette.surface,
                      border: Border.all(color: AppPalette.border, width: 1),
                      borderRadius: AppPalette.radiusFull,
                      boxShadow: AppPalette.cardShadow,
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      size: 21,
                      color: AppPalette.textPrimary,
                    ),
                  ),
                  Positioned(
                    top: 9,
                    right: 9,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppPalette.accentGold,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppPalette.surface, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Render avatar pengguna baik dari file galeri lokal maupun URL web
  Widget _buildAvatarImage(String avatar, String name) {
    if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
      return Image.network(
        avatar,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildInitialAvatar(name),
      );
    } else {
      return Image.file(
        File(avatar),
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildInitialAvatar(name),
      );
    }
  }

  /// Inisial avatar cadangan jika foto profil kosong atau gagal dimuat
  Widget _buildInitialAvatar(String name) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppPalette.primary, Color(0xFF4C86FF)],
        ),
      ),
      child: Center(
        child: Text(
          name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ─── 2. Search Field Component ─────────────────────────────────────────────
  Widget _buildSearchField() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: AppPalette.radiusMd,
        border: Border.all(color: AppPalette.border, width: 1),
        boxShadow: AppPalette.cardShadow,
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search_rounded, size: 22, color: AppPalette.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: AppPalette.bodyMd(color: AppPalette.textPrimary),
              decoration: InputDecoration(
                hintText: 'Cari destinasi, pulau, pantai di Bajo...',
                hintStyle: AppPalette.bodyMd(color: AppPalette.textSecondary),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Icon(Icons.close_rounded, size: 20, color: AppPalette.textSecondary),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Section Header ────────────────────────────────────────────────────────
  Widget _buildSectionHeader({
    required String title,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppPalette.h2()),
          if (actionLabel != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel,
                style: AppPalette.caption(color: AppPalette.primary).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── 3A. Banner CTA Buat Itinerary ─────────────────────────────────────────
  Widget _buildItineraryCtaBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: AppPalette.radiusXl,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A5FFF),
              Color(0xFF124AD1),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppPalette.primary.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: AppPalette.radiusXl,
          child: Stack(
            children: [
              // Background Foto Kapal Layar Bajo (assets/images/kapal.webp) dengan transisi soft fade
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 220,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.50,
                    child: ShaderMask(
                      shaderCallback: (rect) {
                        return const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.transparent,
                            Color(0x33000000),
                            Color(0xB3000000),
                            Colors.black,
                          ],
                          stops: [0.0, 0.18, 0.38, 0.58],
                        ).createShader(rect);
                      },
                      blendMode: BlendMode.dstIn,
                      child: Image.asset(
                        'assets/images/kapal.webp',
                        fit: BoxFit.cover,
                        alignment: const Alignment(0.4, 0.25),
                      ),
                    ),
                  ),
                ),
              ),
              // Banner Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tag Rencana & Anggaran Wisata
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: AppPalette.radiusSm,
                      ),
                      child: Text(
                        'Rencana & Anggaran Wisata',
                        style: AppPalette.labelXs(color: Colors.white).copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rencanakan Liburan Impianmu',
                      style: AppPalette.h2(color: Colors.white).copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Susun jadwal harian & kelola batas anggaran\nwisata Bajo',
                      style: AppPalette.caption(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // CTA Button Putih Bersih
                    ElevatedButton.icon(
                      onPressed: () => Get.to(() => const AddItineraryScreen()),
                      icon: const Icon(Icons.add_rounded, size: 16, color: AppPalette.primary),
                      label: Text(
                        'Buat Itinerary Sekarang',
                        style: AppPalette.labelXs(color: AppPalette.primary).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppPalette.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppPalette.radiusMd,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 3B-1. Filter Kategori Destinasi Populer ───────────────────────────────
  Widget _buildPopularDestinationFilters() {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategoryIndex == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategoryIndex = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppPalette.primary : AppPalette.surface,
                borderRadius: AppPalette.radiusFull,
                border: Border.all(
                  color: isSelected ? AppPalette.primary : AppPalette.border,
                  width: 1,
                ),
                boxShadow: isSelected ? AppPalette.cardShadow : null,
              ),
              child: Center(
                child: Text(
                  cat,
                  style: AppPalette.labelXs(
                    color: isSelected ? AppPalette.onPrimary : AppPalette.textSecondary,
                  ).copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── 3B-2. Carousel Destinasi Populer ──────────────────────────────────────
  Widget _buildPopularDestinationCarousel() {
    return FutureBuilder<List<DestinasiModel>>(
      future: _destinasiFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 180,
            child: Center(
              child: CircularProgressIndicator(color: AppPalette.primary),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            height: 140,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppPalette.surface,
              borderRadius: AppPalette.radiusLg,
              border: Border.all(color: AppPalette.border),
            ),
            child: Center(
              child: Text(
                'Destinasi populer belum tersedia',
                style: AppPalette.bodyMd(color: AppPalette.textSecondary),
              ),
            ),
          );
        }

        final destinations = snapshot.data!;
        final selectedCat = _categories[_selectedCategoryIndex];
        final filteredDestinations = selectedCat == 'Semua'
            ? destinations
            : destinations
                .where((d) => d.category.toLowerCase().contains(selectedCat.toLowerCase()))
                .toList();

        final displayList = filteredDestinations.isNotEmpty ? filteredDestinations : destinations;

        return SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: displayList.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final item = displayList[index];

              return GestureDetector(
                onTap: () => Get.to(() => DetailGearScreen(productId: item.id)),
                child: Container(
                  width: 290,
                  decoration: BoxDecoration(
                    borderRadius: AppPalette.radiusXl,
                    boxShadow: AppPalette.cardShadow,
                  ),
                  child: ClipRRect(
                    borderRadius: AppPalette.radiusXl,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Gambar Background
                        Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppPalette.surfaceMuted,
                            child: const Center(
                              child: Icon(Icons.landscape_rounded, size: 40, color: AppPalette.textSecondary),
                            ),
                          ),
                        ),
                        // Overlay Gradien Hitam Halus
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.15),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.75),
                              ],
                              stops: const [0.0, 0.45, 1.0],
                            ),
                          ),
                        ),
                        // Rating Pill Top Left dengan Secondary Kuning
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: AppPalette.radiusFull,
                              boxShadow: AppPalette.shadowCard,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 14, color: AppPalette.accentGold),
                                const SizedBox(width: 3),
                                Text(
                                  '${item.rating}',
                                  style: AppPalette.caption().copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Tombol Favorit Top Right
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Obx(() {
                            final isFav = WishlistController.to.isFavorite(item.id);
                            return GestureDetector(
                              onTap: () => _toggleWishlist(item.id),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: AppPalette.shadowCard,
                                ),
                                child: Icon(
                                  isFav ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                                  color: isFav ? AppPalette.primary : AppPalette.textPrimary,
                                  size: 18,
                                ),
                              ),
                            );
                          }),
                        ),
                        // Konten Bawah (Nama & Lokasi)
                        Positioned(
                          left: 14,
                          right: 14,
                          bottom: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.name,
                                style: AppPalette.h3(color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.location,
                                style: AppPalette.caption(
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ─── 3C. Rencana Mendatang (Card Rapi, Anti-Overflow, Aksen Kuning) ─────────
  Widget _buildUpcomingItinerariesSection() {
    return ValueListenableBuilder<Box<ItineraryItem>>(
      valueListenable: Hive.box<ItineraryItem>('itineraries').listenable(),
      builder: (context, box, _) {
        final allItems = box.values.toList();
        final now = DateTime.now();

        // Hanya ambil jadwal yang benar-benar akan datang (setelah waktu saat ini)
        final activeItems = allItems
            .where((item) => item.scheduledDate.isAfter(now))
            .toList();
        activeItems.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
        final displayItems = activeItems.take(3).toList();

        if (displayItems.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Belum ada rencana mendatang',
                    textAlign: TextAlign.center,
                    style: AppPalette.bodyMd(color: AppPalette.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => Get.to(() => const AddItineraryScreen()),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text(
                      'Buat Rencana',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppPalette.radiusMd,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = displayItems[index];

              // Deteksi apakah jadwal bentrok dengan agenda lain (< 90 menit)
              bool isClashing = false;
              for (final other in allItems) {
                if (other != item) {
                  final isSameDay = other.scheduledDate.year == item.scheduledDate.year &&
                      other.scheduledDate.month == item.scheduledDate.month &&
                      other.scheduledDate.day == item.scheduledDate.day;
                  if (isSameDay) {
                    final diff = other.scheduledDate.difference(item.scheduledDate).inMinutes.abs();
                    if (diff < 90) {
                      isClashing = true;
                      break;
                    }
                  }
                }
              }

              final imgUrl = _getDestinationImage(item.destination);
              final locationText = _getDestinationLocation(item.destination);

              return InkWell(
                onTap: () {
                  final rootCtrl = Get.isRegistered<RootNavigationController>()
                      ? Get.find<RootNavigationController>()
                      : null;
                  if (rootCtrl != null) {
                    rootCtrl.selectTab(2, itineraryFilter: 1);
                  } else {
                    Get.to(() => const ItineraryScreen(initialFilter: 1));
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppPalette.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isClashing
                          ? const Color(0xFFFCA5A5)
                          : AppPalette.border,
                      width: isClashing ? 1.5 : 1,
                    ),
                    boxShadow: AppPalette.cardShadow,
                  ),
                  child: Row(
                    children: [
                      // 1. Gambar Destinasi (Rounded Thumbnail sesuai referensi)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imgUrl,
                          width: 86,
                          height: 86,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 86,
                            height: 86,
                            color: AppPalette.surfaceMuted,
                            child: const Icon(
                              Icons.landscape_rounded,
                              color: AppPalette.textSecondary,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // 2. Info Card: Judul, Lokasi, Jadwal, Budget (Tanpa Rating & Tanpa Icon Save)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Baris 1: Judul Destinasi
                            Text(
                              item.destination,
                              style: AppPalette.h3(color: AppPalette.textPrimary).copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),

                            // Baris 2: Lokasi Pin Icon + Lokasi
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 13,
                                  color: AppPalette.textSecondary,
                                ),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    locationText,
                                    style: AppPalette.caption(color: AppPalette.textSecondary).copyWith(
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),

                            // Baris 3: Jadwal Tanggal & Jam WITA + Peringatan Bentrok
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 12,
                                  color: AppPalette.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${DateFormat('d MMM, HH:mm').format(item.scheduledDate)} WITA',
                                    style: AppPalette.caption(color: AppPalette.textSecondary).copyWith(
                                      fontSize: 10,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isClashing) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFFFCA5A5)),
                                    ),
                                    child: Text(
                                      'Bentrok',
                                      style: AppPalette.labelXs(color: AppPalette.error).copyWith(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 5),

                            // Baris 4: Budget Biru Tebal /estimasi
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: _formatRupiah(item.budget),
                                    style: AppPalette.h3(color: AppPalette.primary).copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' /estimasi',
                                    style: AppPalette.caption(color: AppPalette.textSecondary).copyWith(
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ─── 4. Hasil Pencarian Real-Time (Ketika Search Berisi Teks) ──────────────
  Widget _buildSearchResultsSection() {
    return FutureBuilder<List<DestinasiModel>>(
      future: _destinasiFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppPalette.primary),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Gagal memuat hasil pencarian', style: AppPalette.bodyMd(color: AppPalette.error)),
            ),
          );
        }

        final all = snapshot.data!;
        final filtered = all.where((d) {
          final queryMatch = d.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              d.location.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              d.category.toLowerCase().contains(_searchQuery.toLowerCase());
          return queryMatch;
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Icon(Icons.search_off_rounded, size: 48, color: AppPalette.textSecondary),
                  const SizedBox(height: 12),
                  Text('Destinasi Tidak Ditemukan', style: AppPalette.h3()),
                  const SizedBox(height: 4),
                  Text(
                    'Tidak ada hasil untuk "$_searchQuery"',
                    style: AppPalette.caption(color: AppPalette.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ditemukan ${filtered.length} destinasi',
                style: AppPalette.caption(color: AppPalette.textSecondary),
              ),
              const SizedBox(height: 10),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = filtered[index];

                  return GestureDetector(
                    onTap: () => Get.to(() => DetailGearScreen(productId: item.id)),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppPalette.surface,
                        borderRadius: AppPalette.radiusLg,
                        border: Border.all(color: AppPalette.border),
                        boxShadow: AppPalette.cardShadow,
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: AppPalette.radiusMd,
                            child: Image.network(
                              item.imageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 80,
                                height: 80,
                                color: AppPalette.surfaceMuted,
                                child: const Icon(Icons.landscape_rounded, color: AppPalette.textSecondary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        style: AppPalette.h3(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Obx(() {
                                      final isFav = WishlistController.to.isFavorite(item.id);
                                      return GestureDetector(
                                        onTap: () => _toggleWishlist(item.id),
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.12),
                                                blurRadius: 4,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            isFav ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                                            color: isFav ? AppPalette.primary : AppPalette.textSecondary,
                                            size: 18,
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.location,
                                  style: AppPalette.caption(color: AppPalette.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded, size: 14, color: AppPalette.accentGold),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${item.rating}',
                                          style: AppPalette.labelXs().copyWith(fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      _formatRupiah(item.ticketPrice),
                                      style: AppPalette.caption(color: AppPalette.primary).copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
