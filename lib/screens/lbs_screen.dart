import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../data/bajo_locations.dart';
import '../theme/app_palette.dart';
import '../utils/app_toast.dart';
import 'detail_gear_screen.dart';

/// Radar peta: filter destinasi, marker, hitung jarak GPS, dan garis ke pilihan aktif.
class LbsScreen extends StatefulWidget {
  const LbsScreen({super.key});

  @override
  State<LbsScreen> createState() => _LbsScreenState();
}

class _LbsScreenState extends State<LbsScreen> {
  final MapController _mapController = MapController();
  final ScrollController _carouselController = ScrollController();

  Position? _currentPosition;
  bool _isLoadingLocation = false;
  bool _isTopoMap = false;
  bool _hasCalculatedDistance = false;
  LocationData? _selectedLocation;

  int _selectedFilterIndex = 0;
  late List<LocationData> _sortedDestinations;
  List<LatLng> _currentRoute = [];

  final List<String> _filters = [
    'Semua',
    'Pulau',
    'Pantai',
    'Trekking',
    'Diving',
    'Gua',
    'Kuliner',
  ];

  // Titik pusat kepulauan Labuan Bajo & Komodo
  static const LatLng _initialCenter = LatLng(-8.5900, 119.6400);
  static const double _initialZoom = 10.4;

  // Koordinat Pelabuhan Utama Marina Labuan Bajo
  static const LatLng _marinaPort = LatLng(-8.4964, 119.8732);

  @override
  void initState() {
    super.initState();
    _sortedDestinations = List<LocationData>.from(bajoDestinations);
    if (_sortedDestinations.isNotEmpty) {
      _selectedLocation = _sortedDestinations.first;
    }
  }

  @override
  void dispose() {
    _carouselController.dispose();
    super.dispose();
  }

  /// Meminta izin GPS dan mengambil posisi koordinat pengguna saat ini
  Future<void> _getCurrentLocation() async {
    // Alur GPS: cek layanan/izin, ambil posisi, hitung semua jarak, lalu buat rute aktif.
    setState(() => _isLoadingLocation = true);

    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingLocation = false);
        AppToast.warning(
          'GPS Nonaktif',
          'Silakan aktifkan layanan lokasi (GPS) pada perangkat Anda.',
        );
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingLocation = false);
          AppToast.warning(
            'Izin Ditolak',
            'Izin akses lokasi diperlukan untuk mengukur jarak destinasi.',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingLocation = false);
        AppToast.error(
          'Izin Ditolak Permanen',
          'Buka pengaturan aplikasi untuk memberikan izin GPS.',
        );
        await Geolocator.openAppSettings();
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final userLatLng = LatLng(position.latitude, position.longitude);

      // Hitung jarak dari posisi pengguna ke setiap destinasi Labuan Bajo
      for (final dest in bajoDestinations) {
        dest.distanceInMeters = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          dest.latitude,
          dest.longitude,
        );
      }

      // Urutkan dari yang paling dekat ke yang paling jauh
      final sorted = List<LocationData>.from(bajoDestinations)
        ..sort(
          (a, b) =>
              (a.distanceInMeters ?? 0).compareTo(b.distanceInMeters ?? 0),
        );

      final startPoint = userLatLng;
      final selectedDestination = _selectedLocation ?? sorted.first;
      final selectedIndex = sorted.indexWhere(
        (destination) => destination.id == selectedDestination.id,
      );

      setState(() {
        _currentPosition = position;
        _sortedDestinations = sorted;
        _selectedLocation = selectedDestination;
        _hasCalculatedDistance = true;
        _isLoadingLocation = false;
        _currentRoute = _generateRealisticRoute(
          startPoint,
          selectedDestination,
        );
      });

      // Arahkan kamera peta langsung ke lokasi GPS riil pengguna saat ini
      _mapController.move(userLatLng, 12.0);

      // Gulir carousel ke destinasi yang jaraknya baru dihitung
      if (_carouselController.hasClients && selectedIndex >= 0) {
        _carouselController.animateTo(
          selectedIndex * 302.0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }

      AppToast.success(
        'Jarak Berhasil Dihitung',
        'Jarak ke ${selectedDestination.name}: ${selectedDestination.formattedDistance}.',
      );
    } catch (_) {
      setState(() => _isLoadingLocation = false);
      AppToast.error(
        'Gagal Mendeteksi Lokasi',
        'Pastikan GPS aktif dan perangkat memiliki koneksi internet.',
      );
    }
  }

  /// Membuat garis rute lurus langsung sebagai ilustrasi jarak ke destinasi terpilih
  List<LatLng> _generateRealisticRoute(LatLng start, LocationData dest) {
    // Garis hanya visualisasi garis lurus antara dua koordinat, bukan rute navigasi jalan/laut.
    return [start, LatLng(dest.latitude, dest.longitude)];
  }

  /// Memfilter destinasi sesuai chip filter yang sinkron dengan halaman Explore
  List<LocationData> _getFilteredDestinations() {
    final selectedCat = _filters[_selectedFilterIndex];
    if (selectedCat == 'Semua') {
      return _hasCalculatedDistance ? _sortedDestinations : bajoDestinations;
    }

    final baseList = _hasCalculatedDistance
        ? _sortedDestinations
        : bajoDestinations;
    final search = selectedCat.toLowerCase();

    final filtered = baseList.where((d) {
      final cat = d.category.toLowerCase();
      final name = d.name.toLowerCase();
      if (search == 'gua') {
        return cat.contains('gua') ||
            cat.contains('goa') ||
            name.contains('gua') ||
            name.contains('goa');
      }
      return cat.contains(search) || name.contains(search);
    }).toList();

    return filtered.isNotEmpty ? filtered : baseList;
  }

  /// Memilih destinasi dari marker atau carousel
  void _onSelectDestination(LocationData dest, {int? index}) {
    setState(() {
      _selectedLocation = dest;
      if (_hasCalculatedDistance && _currentPosition != null) {
        _currentRoute = _generateRealisticRoute(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          dest,
        );
      }
    });

    // Pindahkan fokus kamera ke destinasi
    _mapController.move(LatLng(dest.latitude, dest.longitude), 11.5);

    // Gulir carousel ke kartu yang dipilih
    if (index != null && _carouselController.hasClients) {
      final double targetOffset = index * 302.0; // card width 290 + margin 12
      _carouselController.animateTo(
        targetOffset.clamp(0.0, _carouselController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _getFilteredDestinations();

    return Scaffold(
      backgroundColor: AppPalette.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ─── 1. PETA INTERAKTIF FULLFRAME (Background Penuh) ────────────
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _initialCenter,
              initialZoom: _initialZoom,
              minZoom: 4.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: _isTopoMap
                    ? 'https://tile.opentopomap.org/{z}/{x}/{y}.png'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.bajoland',
              ),

              // Polyline kosong sebelum tombol cek jarak ditekan; pilihan baru memperbaruinya.
              // Garis ke destinasi terpilih muncul setelah jarak GPS dihitung.
              if (_currentRoute.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _currentRoute,
                      color: AppPalette.primary.withValues(alpha: 0.90),
                      strokeWidth: 4.0,
                    ),
                  ],
                ),

              MarkerLayer(
                markers: [
                  // Marker Titik Awal Pelayaran (GPS Pengguna atau Pelabuhan Marina jika belum hitung)
                  Marker(
                    point: (_hasCalculatedDistance && _currentPosition != null)
                        ? LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          )
                        : _marinaPort,
                    width: 52,
                    height: 52,
                    child: _buildStartLocationMarker(
                      isGps: _hasCalculatedDistance && _currentPosition != null,
                    ),
                  ),

                  // Marker Seluruh Destinasi Labuan Bajo Sesuai Filter
                  for (int i = 0; i < filteredList.length; i++) ...[
                    Marker(
                      point: LatLng(
                        filteredList[i].latitude,
                        filteredList[i].longitude,
                      ),
                      width: _selectedLocation?.id == filteredList[i].id
                          ? 150
                          : 42,
                      height: _selectedLocation?.id == filteredList[i].id
                          ? 72
                          : 42,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () =>
                            _onSelectDestination(filteredList[i], index: i),
                        child: _buildDestinationMarker(
                          dest: filteredList[i],
                          rank: _hasCalculatedDistance ? i + 1 : null,
                          isSelected:
                              _selectedLocation?.id == filteredList[i].id,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          // ─── 2. FLOATING HEADER ATAS (Back Button, Title Pill, & Layer Switch) ───
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Tombol Back Bulat Konsisten
                    InkWell(
                      onTap: () => Get.back(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppPalette.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppPalette.border),
                          boxShadow: AppPalette.cardShadow,
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          size: 19,
                          color: AppPalette.textPrimary,
                        ),
                      ),
                    ),

                    // Tombol Layer Switcher (OSM <-> Topo)
                    InkWell(
                      onTap: () {
                        setState(() => _isTopoMap = !_isTopoMap);
                        AppToast.info(
                          'Layer Peta Diubah',
                          _isTopoMap
                              ? 'Beralih ke OpenTopoMap (Topografi).'
                              : 'Beralih ke OpenStreetMap Standard.',
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _isTopoMap
                              ? AppPalette.primarySubtle
                              : AppPalette.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isTopoMap
                                ? AppPalette.primary
                                : AppPalette.border,
                          ),
                          boxShadow: AppPalette.cardShadow,
                        ),
                        child: Icon(
                          _isTopoMap
                              ? Icons.terrain_rounded
                              : Icons.layers_rounded,
                          size: 19,
                          color: _isTopoMap
                              ? AppPalette.primary
                              : AppPalette.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── 3. TOMBOL KANAN MELAYANG (Recenter & Focus) ───────────────────
          Positioned(
            right: 16,
            bottom: 420,
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    if (_currentPosition != null) {
                      _mapController.move(
                        LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        12.0,
                      );
                    } else {
                      _mapController.move(_marinaPort, 12.0);
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppPalette.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppPalette.border),
                      boxShadow: AppPalette.cardShadow,
                    ),
                    child: const Icon(
                      Icons.my_location_rounded,
                      size: 19,
                      color: AppPalette.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () =>
                      _mapController.move(_initialCenter, _initialZoom),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppPalette.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppPalette.border),
                      boxShadow: AppPalette.cardShadow,
                    ),
                    child: const Icon(
                      Icons.crop_free_rounded,
                      size: 19,
                      color: AppPalette.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Panel bawah memakai radius hanya di sudut atas agar terasa menumpang di atas peta.
          // ─── 4. BOTTOM CARD SEDIKIT ROUNDED (Judul + Penjelasan + Filter + Carousel + Tombol) ───
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppPalette.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border(
                    top: BorderSide(color: AppPalette.border, width: 1.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x180B1220),
                      blurRadius: 20,
                      offset: Offset(0, -6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),

                    // Judul Radar Destinasi Bajo & Penjelasan 1-2 Kalimat
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Radar Destinasi Bajo',
                            style: AppPalette.h2().copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Jelajahi dan ukur jarak destinasi wisata terbaik Labuan Bajo langsung dari lokasi Anda.',
                            style: AppPalette.bodyMd(
                              color: AppPalette.textSecondary,
                            ).copyWith(fontSize: 12, height: 1.4),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Filter Chips Bar
                    SizedBox(
                      height: 32,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filters.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final isSelected = _selectedFilterIndex == index;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedFilterIndex = index;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppPalette.primary
                                    : AppPalette.surfaceMuted,
                                borderRadius: AppPalette.radiusFull,
                                border: Border.all(
                                  color: isSelected
                                      ? AppPalette.primary
                                      : AppPalette.border,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _filters[index],
                                  style:
                                      AppPalette.labelXs(
                                        color: isSelected
                                            ? Colors.white
                                            : AppPalette.textSecondary,
                                      ).copyWith(
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        fontSize: 11,
                                      ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Carousel Card Destinasi (Rapi, Sesuai Design System, Tanpa Panah)
                    SizedBox(
                      height: 195,
                      child: ListView.separated(
                        controller: _carouselController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredList.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final dest = filteredList[index];
                          final isSelected = _selectedLocation?.id == dest.id;
                          return _buildDestinationCard(
                            dest: dest,
                            rank: index + 1,
                            isSelected: isSelected,
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Tombol Kapsul Penuh "Cek Jarak Lokasi Saya"
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _isLoadingLocation
                              ? null
                              : _getCurrentLocation,
                          icon: _isLoadingLocation
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.map_rounded, size: 20),
                          label: Text(
                            _isLoadingLocation
                                ? 'Mengambil Titik GPS...'
                                : (_hasCalculatedDistance
                                      ? 'Perbarui Jarak Lokasi Saya'
                                      : 'Cek Jarak Lokasi Saya'),
                            style: AppPalette.bodyMd(color: Colors.white)
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppPalette.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: const RoundedRectangleBorder(
                              borderRadius: AppPalette.radiusFull,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Marker Titik Awal (GPS Pengguna atau Pelabuhan Marina)
  Widget _buildStartLocationMarker({required bool isGps}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppPalette.primary.withValues(alpha: 0.22),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppPalette.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            isGps ? Icons.person_rounded : Icons.directions_boat_rounded,
            size: 13,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  /// Marker Destinasi di Atas Peta dengan Tooltip Nama saat Dipilih
  Widget _buildDestinationMarker({
    required LocationData dest,
    int? rank,
    required bool isSelected,
  }) {
    if (isSelected) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Bubble Nama Destinasi yang Sedang Aktif Dipilih
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppPalette.primary,
              borderRadius: AppPalette.radiusFull,
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              dest.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 3),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppPalette.accentGold,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: AppPalette.accentGold.withValues(alpha: 0.50),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.network(
                dest.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.place_rounded,
                  color: AppPalette.textPrimary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppPalette.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: AppPalette.primary.withValues(alpha: 0.35),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.network(
          dest.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.place_rounded, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  /// Card Destinasi pada Carousel (Design System BajoLand / Bookify)
  Widget _buildDestinationCard({
    required LocationData dest,
    required int rank,
    required bool isSelected,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onSelectDestination(dest, index: rank - 1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 290,
        decoration: BoxDecoration(
          color: AppPalette.surface,
          borderRadius: AppPalette.radiusLg,
          border: Border.all(
            color: isSelected ? AppPalette.primary : AppPalette.border,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppPalette.primary.withValues(alpha: 0.16)
                  : const Color(0x120B1220),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar Destinasi dengan Badge Ranking
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                  child: Image.network(
                    dest.imageUrl,
                    width: double.infinity,
                    height: 104,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 104,
                      color: AppPalette.surfaceMuted,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image_rounded,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_hasCalculatedDistance)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: const BoxDecoration(
                        color: AppPalette.primary,
                        borderRadius: AppPalette.radiusSm,
                      ),
                      child: Text(
                        '#$rank Terdekat',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Informasi Konten Kartu
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                dest.name,
                                style: AppPalette.h3().copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 13,
                                  color: Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 1),
                                Text(
                                  dest.rating.toString(),
                                  style: AppPalette.labelXs(
                                    color: AppPalette.textPrimary,
                                  ).copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
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
                                dest.location,
                                style: AppPalette.caption(
                                  color: AppPalette.textSecondary,
                                ).copyWith(fontSize: 10),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Badge Jarak & Tombol Detail
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _hasCalculatedDistance
                                ? AppPalette.primarySubtle
                                : AppPalette.surfaceMuted,
                            borderRadius: AppPalette.radiusSm,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.near_me_rounded,
                                size: 10,
                                color: _hasCalculatedDistance
                                    ? AppPalette.primary
                                    : AppPalette.textSecondary,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                dest.formattedDistance,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _hasCalculatedDistance
                                      ? AppPalette.primary
                                      : AppPalette.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => Get.to(
                            () => DetailGearScreen(productId: dest.id),
                          ),
                          borderRadius: AppPalette.radiusSm,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: const BoxDecoration(
                              color: AppPalette.primary,
                              borderRadius: AppPalette.radiusSm,
                            ),
                            child: const Text(
                              'Detail',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
