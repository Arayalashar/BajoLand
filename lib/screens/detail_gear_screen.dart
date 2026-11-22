import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../api/api_service.dart';
import '../data/bajo_locations.dart';
import '../models/destinasi_model.dart';
import '../services/wishlist_service.dart';
import '../theme/app_palette.dart';
import '../utils/app_toast.dart';
import 'add_itinerary_screen.dart';

/// Halaman Detail Destinasi Wisata BajoLand
class DetailGearScreen extends StatefulWidget {
  final int productId;

  const DetailGearScreen({super.key, required this.productId});

  @override
  State<DetailGearScreen> createState() => _DetailGearScreenState();
}

class _DetailGearScreenState extends State<DetailGearScreen> {
  late Future<DestinasiModel> _destinasiFuture;

  @override
  void initState() {
    super.initState();
    _destinasiFuture = ApiService.getDestinasiDetail(widget.productId);
  }

  List<String> _getGalleryImages(DestinasiModel dest) {
    final list = <String>[dest.imageUrl];
    for (final b in bajoDestinations) {
      if (b.imageUrl != dest.imageUrl && !list.contains(b.imageUrl)) {
        list.add(b.imageUrl);
      }
    }
    return list.take(5).toList();
  }

  Future<void> _toggleWishlist(DestinasiModel dest) async {
    final isAdded = await WishlistController.to.toggleWishlist(widget.productId);
    if (isAdded) {
      AppToast.success('Destinasi Disimpan', '${dest.name} berhasil disimpan di daftar Anda.');
    } else {
      AppToast.info('Dihapus dari Simpan', '${dest.name} dihapus dari daftar simpan.');
    }
  }

  String _formatRupiah(num price) {
    final intPrice = price.round();
    if (intPrice <= 0) return 'Gratis';
    final s = intPrice.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(s[i]);
    }
    return 'Rp ${buffer.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: FutureBuilder<DestinasiModel>(
        future: _destinasiFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppPalette.primary),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Scaffold(
              backgroundColor: AppPalette.background,
              appBar: AppBar(
                title: Text('Detail Destinasi', style: AppPalette.h2()),
                backgroundColor: AppPalette.surface,
                elevation: 0,
                centerTitle: true,
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
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: AppPalette.error,
                      ),
                      const SizedBox(height: 12),
                      Text('Gagal memuat detail destinasi', style: AppPalette.h3()),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _destinasiFuture =
                                ApiService.getDestinasiDetail(widget.productId);
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppPalette.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final dest = snapshot.data!;
          final galleryImages = _getGalleryImages(dest);

          return Scaffold(
            backgroundColor: AppPalette.background,
            body: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Foto Full Frame dengan Judul & Lokasi di Pojok Bawah Kiri
                  Stack(
                    children: [
                      // Gambar Utama Full Frame
                      Image.network(
                        dest.imageUrl,
                        height: 340,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 340,
                          width: double.infinity,
                          color: AppPalette.surfaceMuted,
                          child: const Center(
                            child: Icon(
                              Icons.landscape_rounded,
                              size: 64,
                              color: AppPalette.textSecondary,
                            ),
                          ),
                        ),
                      ),

                      // Gradient Overlay untuk kontras tombol & teks
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.55),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.85),
                              ],
                              stops: const [0.0, 0.45, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // Tombol Navigasi Mengambang di Atas (Kiri Back, Kanan Bookmark)
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildFloatingCircleButton(
                                icon: Icons.arrow_back_rounded,
                                iconColor: AppPalette.textPrimary,
                                onTap: () => Get.back(),
                              ),
                              Obx(() {
                                final isFav =
                                    WishlistController.to.isFavorite(dest.id);
                                return _buildFloatingCircleButton(
                                  icon: isFav
                                      ? Icons.bookmark_rounded
                                      : Icons.bookmark_outline_rounded,
                                  iconColor: isFav
                                      ? AppPalette.primary
                                      : AppPalette.textPrimary,
                                  onTap: () => _toggleWishlist(dest),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),

                      // Tulisan Nama Destinasi & Lokasi di Bawah Pojok Kiri Foto (Nama di Atas, Lokasi di Bawah)
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              dest.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  size: 15,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    dest.location,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 2. Di Bawah Foto Langsung Tentang [Destinasi] Penjelasan 1 Paragraf
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tentang ${dest.name}',
                          style: AppPalette.h2().copyWith(fontSize: 17),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dest.description,
                          style: AppPalette.bodyMd(
                            color: AppPalette.textSecondary,
                          ).copyWith(fontSize: 13, height: 1.6),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // 3. Galeri Foto
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Galeri Foto',
                      style: AppPalette.h2().copyWith(fontSize: 17),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 94,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: galleryImages.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, idx) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            galleryImages[idx],
                            width: 130,
                            height: 94,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 130,
                              height: 94,
                              color: AppPalette.surfaceMuted,
                              child: const Icon(
                                Icons.photo_rounded,
                                color: AppPalette.textSecondary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 4. Ulasan dan Rating
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ulasan & Rating',
                              style: AppPalette.h2().copyWith(fontSize: 17),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: AppPalette.accentGold,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${dest.rating} (120+)',
                                  style: AppPalette.caption(
                                    color: AppPalette.textPrimary,
                                  ).copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildReviewCard(
                          name: 'Rian Pratama',
                          date: '18 Nov 2026',
                          comment:
                              'Pemandangannya luar biasa indah! Sangat direkomendasikan datang saat matahari terbit atau pagi hari.',
                          rating: 5,
                        ),
                        const SizedBox(height: 10),
                        _buildReviewCard(
                          name: 'Sarah Wijaya',
                          date: '12 Nov 2026',
                          comment:
                              'Airnya sangat jernih dan pemandangan pulau-pulaunya memukau. Destinasi wajib jika ke Labuan Bajo!',
                          rating: 5,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 5. Bottom Navigation Bar: Estimasi Biaya & Tombol Rencana
            bottomNavigationBar: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: AppPalette.surface,
                border: Border(
                  top: BorderSide(color: AppPalette.border, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 10,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Kolom Estimasi Biaya
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estimasi Biaya',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppPalette.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatRupiah(dest.ticketPrice),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppPalette.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),

                    // Tombol Tambah ke Rencana
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Get.to(
                              () => AddItineraryScreen(
                                initialDestination: dest.name,
                                initialBudget: dest.ticketPrice,
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.calendar_month_rounded,
                            size: 18,
                          ),
                          label: Text(
                            'Tambah ke Rencana',
                            style: AppPalette.bodyMd(
                              color: AppPalette.onPrimary,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppPalette.primary,
                            foregroundColor: AppPalette.onPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
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
  }

  Widget _buildFloatingCircleButton({
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
      ),
    );
  }

  Widget _buildReviewCard({
    required String name,
    required String date,
    required String comment,
    required int rating,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.border),
        boxShadow: AppPalette.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.textPrimary,
                ),
              ),
              Row(
                children: List.generate(
                  rating,
                  (_) => const Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: AppPalette.accentGold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            date,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppPalette.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            comment,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppPalette.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
