import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../api/api_service.dart';
import '../models/destinasi_model.dart';
import '../services/wishlist_service.dart';
import '../theme/app_palette.dart';
import '../utils/app_toast.dart';
import 'detail_gear_screen.dart';

/// Cocokkan filter kategori; nama "Pulau ..." tetap masuk filter Pulau walau kategori lain.
bool destinationMatchesCategory(DestinasiModel destination, String category) {
  final normalizedCategory = category.toLowerCase();
  return category == 'Semua' ||
      destination.category.toLowerCase().contains(normalizedCategory) ||
      (normalizedCategory == 'pulau' &&
          destination.name.toLowerCase().startsWith('pulau '));
}

/// Katalog lengkap dengan pencarian, filter kategori, favorit, dan tautan ke detail.
class AllDestinationsScreen extends StatefulWidget {
  final String? initialCategory;
  final bool showBackButton;

  const AllDestinationsScreen({
    super.key,
    this.initialCategory,
    this.showBackButton = true,
  });

  @override
  State<AllDestinationsScreen> createState() => _AllDestinationsScreenState();
}

class _AllDestinationsScreenState extends State<AllDestinationsScreen> {
  // Future menyimpan permintaan data API agar dapat dipantau FutureBuilder.
  late Future<List<DestinasiModel>> _destinasiFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  List<DestinasiModel> _loadedDestinations = [];

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
    if (widget.initialCategory != null && widget.initialCategory!.isNotEmpty) {
      _selectedCategory = widget.initialCategory!;
    }
    _loadDestinasi();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadDestinasi() {
    setState(() {
      _destinasiFuture = ApiService.getDestinasi().then((list) {
        _loadedDestinations = list;
        return list;
      });
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

  /// Menampilkan modal bottom sheet daftar destinasi favorit
  void _showFavoritesBottomSheet(List<DestinasiModel> allDestinations) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Obx(() {
        final favList = allDestinations.where((d) => WishlistController.to.isFavorite(d.id)).toList();

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.82,
          ),
          decoration: const BoxDecoration(
            color: AppPalette.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppPalette.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppPalette.primarySubtle,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bookmark_rounded,
                        color: AppPalette.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Destinasi Tersimpan',
                            style: AppPalette.h2(color: AppPalette.textPrimary).copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${favList.length} destinasi tersimpan',
                            style: AppPalette.caption(color: AppPalette.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppPalette.textSecondary),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppPalette.border),
              Expanded(
                child: favList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: const BoxDecoration(
                                color: AppPalette.primarySubtle,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.bookmark_outline_rounded,
                                size: 36,
                                color: AppPalette.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text('Belum Ada Destinasi Tersimpan', style: AppPalette.h3()),
                            const SizedBox(height: 6),
                            Text(
                              'Ketuk ikon simpan pada destinasi untuk menyimpannya di sini',
                              textAlign: TextAlign.center,
                              style: AppPalette.caption(color: AppPalette.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: favList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = favList[index];

                          return InkWell(
                            onTap: () {
                              Navigator.pop(ctx);
                              Get.to(() => DetailGearScreen(productId: item.id));
                            },
                            borderRadius: AppPalette.radiusLg,
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
                                      width: 72,
                                      height: 72,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 72,
                                        height: 72,
                                        color: AppPalette.surfaceMuted,
                                        child: const Icon(
                                          Icons.landscape_rounded,
                                          color: AppPalette.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: AppPalette.h3().copyWith(fontSize: 14),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                              const Icon(
                                                Icons.location_on_outlined,
                                                size: 12,
                                                color: AppPalette.textSecondary,
                                              ),
                                              const SizedBox(width: 2),
                                              Expanded(
                                                child: Text(
                                                  item.location,
                                                  style: AppPalette.caption(color: AppPalette.textSecondary).copyWith(
                                                    fontSize: 11,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.star_rounded,
                                                    size: 13,
                                                    color: AppPalette.accentGold,
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    '${item.rating}',
                                                    style: AppPalette.labelXs().copyWith(
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                _formatRupiah(item.ticketPrice),
                                                style: AppPalette.labelXs(color: AppPalette.primary).copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.bookmark_rounded,
                                        color: AppPalette.primary,
                                        size: 22,
                                      ),
                                      tooltip: 'Hapus dari Daftar Simpan',
                                      onPressed: () => _toggleWishlist(item.id),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        title: Text('Eksplorasi Destinasi', style: AppPalette.h2()),
        backgroundColor: AppPalette.background,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leadingWidth: 54,
        leading: widget.showBackButton
            ? Padding(
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
              )
            : null,
        actions: [
          Obx(() {
            final count = WishlistController.to.wishlist.length;
            return IconButton(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.bookmark_rounded,
                    color: AppPalette.primary,
                    size: 24,
                  ),
                  if (count > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppPalette.accentGold,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Center(
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: AppPalette.textPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              tooltip: 'Destinasi Favorit',
              onPressed: () => _showFavoritesBottomSheet(_loadedDestinations),
            );
          }),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Pencarian dan filter berada di luar daftar agar tetap terlihat saat hasil digulir.
          // ─── Search Bar (Background Menyatu dengan Halaman) ───
          Container(
            color: AppPalette.background,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppPalette.surface,
                borderRadius: AppPalette.radiusMd,
                border: Border.all(color: AppPalette.border),
                boxShadow: AppPalette.cardShadow,
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  const Icon(Icons.search_rounded, size: 20, color: AppPalette.textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      style: AppPalette.bodyMd(color: AppPalette.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Cari destinasi Labuan Bajo...',
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
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.close_rounded, size: 18, color: AppPalette.textSecondary),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ─── Filter Category Chips (Background Menyatu Tanpa Garis Abu-Abu) ───
          Container(
            color: AppPalette.background,
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isActive = _selectedCategory == cat;

                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isActive ? AppPalette.primary : AppPalette.surface,
                      borderRadius: AppPalette.radiusFull,
                      border: Border.all(
                        color: isActive ? AppPalette.primary : AppPalette.border,
                      ),
                      boxShadow: isActive ? AppPalette.cardShadow : null,
                    ),
                    child: Text(
                      cat,
                      style: AppPalette.caption(
                        color: isActive ? AppPalette.onPrimary : AppPalette.textSecondary,
                      ).copyWith(
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // ─── List Destinasi ───
          Expanded(
            child: FutureBuilder<List<DestinasiModel>>(
              future: _destinasiFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppPalette.primary),
                  );
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: AppPalette.error),
                        const SizedBox(height: 12),
                        Text('Gagal memuat destinasi', style: AppPalette.h3()),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadDestinasi,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppPalette.primary,
                            foregroundColor: AppPalette.onPrimary,
                          ),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                final allDest = snapshot.data!;
                // Nama, alamat, dan kategori dicari bersama; hasil lalu dipersempit oleh chip.
                final filtered = allDest.where((d) {
                  final matchQuery = _searchQuery.isEmpty ||
                      d.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      d.location.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      d.category.toLowerCase().contains(_searchQuery.toLowerCase());

                  final matchCat = destinationMatchesCategory(
                    d,
                    _selectedCategory,
                  );

                  return matchQuery && matchCat;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off_rounded, size: 48, color: AppPalette.textSecondary),
                        const SizedBox(height: 12),
                        Text('Tidak Ada Destinasi Ditemukan', style: AppPalette.h3()),
                        const SizedBox(height: 4),
                        Text(
                          'Coba kata kunci atau kategori lain',
                          style: AppPalette.caption(color: AppPalette.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final item = filtered[index];

                    return GestureDetector(
                      onTap: () => Get.to(() => DetailGearScreen(productId: item.id)),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppPalette.surface,
                          borderRadius: AppPalette.radiusLg,
                          border: Border.all(color: AppPalette.border),
                          boxShadow: AppPalette.shadowCard,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Gambar dengan Wishlist Button
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                  child: Image.network(
                                    item.imageUrl,
                                    height: 160,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 160,
                                      color: AppPalette.surfaceMuted,
                                      child: const Center(
                                        child: Icon(Icons.landscape_rounded, color: AppPalette.textSecondary),
                                      ),
                                    ),
                                  ),
                                ),
                                // Rating Pill Top Left
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
                                // Tombol Wishlist Top Right
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Obx(() {
                                    final isFav = WishlistController.to.isFavorite(item.id);
                                    return GestureDetector(
                                      onTap: () => _toggleWishlist(item.id),
                                      child: Container(
                                        width: 36,
                                        height: 36,
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
                              ],
                            ),
                            // Konten Destinasi
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: AppPalette.h3(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_rounded, size: 14, color: AppPalette.primary),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          item.location,
                                          style: AppPalette.caption(color: AppPalette.textSecondary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(height: 1, thickness: 1, color: AppPalette.border),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Estimasi Tiket', style: AppPalette.labelXs(color: AppPalette.textSecondary)),
                                          const SizedBox(height: 2),
                                          Text(
                                            _formatRupiah(item.ticketPrice),
                                            style: AppPalette.h3(color: AppPalette.primary),
                                          ),
                                        ],
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Get.to(() => DetailGearScreen(productId: item.id)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppPalette.primary,
                                          foregroundColor: AppPalette.onPrimary,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: AppPalette.radiusMd),
                                        ),
                                        child: const Text('Detail'),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
