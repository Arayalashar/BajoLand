import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/itinerary_item.dart';
import '../theme/app_palette.dart';
import '../utils/date_formatter.dart';
import 'root_screen.dart';

/// Pusat notifikasi yang merangkum jadwal dan kondisi anggaran dari penyimpanan lokal.
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final double maxBudget = prefs.getDouble('maxBudget') ?? 5000000.0;

      final box = Hive.box<ItineraryItem>('itineraries');
      final allItems = box.values.toList();
      final now = DateTime.now();

      final List<Map<String, dynamic>> list = [];

      // Daftar ini dirakit dari Hive/SharedPreferences dan informasi edukasi di bawah.
      // Ini bukan riwayat push-notification dari server.
      // 1. Peringatan & Evaluasi Batas Anggaran
      final double totalSpent = allItems.fold(0.0, (sum, item) => sum + item.budget);
      if (totalSpent > maxBudget) {
        list.add({
          'id': 'budget_exceeded',
          'title': '⚠️ Batas Anggaran Terlampaui!',
          'category': 'Peringatan Anggaran',
          'body': 'Total pengeluaran (${_formatRupiah(totalSpent)}) melebihi batas anggaran (${_formatRupiah(maxBudget)}).',
          'detail': 'Perhatian! Total alokasi anggaran liburan pada seluruh agenda saat ini telah mencapai ${_formatRupiah(totalSpent)}, melebihi batas pagu anggaran yang telah ditentukan sebesar ${_formatRupiah(maxBudget)}.\n\nSilakan sesuaikan alokasi pengeluaran per agenda di menu Rundown atau ubah batas pagu anggaran di menu Profil.',
          'time': 'Penting',
          'isRead': false,
          'actionText': 'Atur Anggaran',
          'actionTab': 2,
          'itineraryFilter': 0,
        });
      } else if (totalSpent >= 0.8 * maxBudget && maxBudget > 0) {
        final percent = (totalSpent / maxBudget * 100).toStringAsFixed(0);
        list.add({
          'id': 'budget_warning',
          'title': 'Mendekati Batas Anggaran',
          'category': 'Peringatan Anggaran',
          'body': 'Pengeluaran liburanmu sudah mencapai $percent% dari pagu anggaran tersimpan.',
          'detail': 'Total alokasi anggaran liburanmu saat ini telah mencapai ${_formatRupiah(totalSpent)} dari pagu sebesar ${_formatRupiah(maxBudget)} ($percent%).\n\nPantau terus pengeluaranmu agar liburan tetap nyaman dan terkendali.',
          'time': 'Terkontrol',
          'isRead': false,
          'actionText': 'Cek Rundown',
          'actionTab': 2,
          'itineraryFilter': 0,
        });
      }

      // 2. Pengingat Itinerary Aktual (Jadwal Mendatang & Selesai)
      final sortedItems = List<ItineraryItem>.from(allItems)
        ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

      for (final item in sortedItems) {
        final isUpcoming = item.scheduledDate.isAfter(now);
        final dateStr = AppDateFormatter.formatDateWithDay(item.scheduledDate);
        final timeStr = AppDateFormatter.formatTime(item.scheduledDate);

        list.add({
          'id': 'itinerary_${item.key ?? "${item.destination}_${item.scheduledDate.millisecondsSinceEpoch}"}',
          'title': isUpcoming
              ? 'Pengingat Agenda: ${item.destination}'
              : 'Agenda Selesai: ${item.destination}',
          'category': 'Pengingat Itinerary',
          'body': '$dateStr • $timeStr WITA (${item.activity})',
          'detail': 'Rincian Agenda Liburan:\n• Destinasi: ${item.destination}\n• Aktivitas: ${item.activity}\n• Waktu: $dateStr, $timeStr WITA\n• Estimasi Anggaran: ${_formatRupiah(item.budget)}\n\n${isUpcoming ? "Notifikasi pengingat lokal otomatis aktif untuk agenda ini agar Anda siap tepat waktu!" : "Agenda ini telah selesai terlaksana. Semoga pengalaman wisatamu menyenangkan!"}',
          'time': isUpcoming ? 'Mendatang' : 'Selesai',
          'isRead': !isUpcoming,
          'actionText': isUpcoming ? 'Buka Rundown' : 'Lihat Riwayat',
          'actionTab': 2,
          'itineraryFilter': isUpcoming ? 1 : 2,
        });
      }

      // 3. Batas Anggaran Liburan Tersimpan
      list.add({
        'id': 'budget_info',
        'title': 'Batas Anggaran Liburan Tersimpan',
        'category': 'Keuangan Liburan',
        'body': 'Batas total anggaran liburanmu saat ini tersimpan ${_formatRupiah(maxBudget)}. Cek menu profil untuk menyesuaikan.',
        'detail': 'Sistem mencatat batas total anggaran liburan wisatamu telah disetel sebesar ${_formatRupiah(maxBudget)} dengan pengeluaran aktif saat ini ${_formatRupiah(totalSpent)}.\n\nKamu dapat memantau akumulasi estimasi pengeluaran per hari langsung pada halaman Rundown Itinerary atau mengubah nominal pagu anggaran kapan saja di menu Profil Pengguna agar pengeluaran tetap terkontrol.',
        'time': 'Tersimpan',
        'isRead': true,
        'actionText': 'Cek Menu Profil',
        'actionTab': 4,
      });

      // 4. Informasi Edukasi & Pengumuman Resmi BajoLand
      list.addAll([
        {
          'id': 'welcome',
          'title': 'Selamat Datang di BajoLand!',
          'category': 'Pengumuman Resmi',
          'body': 'Mulai rencanakan liburanmu ke Pulau Padar, Pink Beach, dan destinasi eksotis lainnya.',
          'detail': 'Halo Sobat Wisata! Selamat datang di aplikasi BajoLand.\n\nJelajahi keindahan surga Labuan Bajo mulai dari panorama puncak Pulau Padar yang spektakuler, kelembutan pasir Pink Beach yang memukau, hingga sensasi bertemu langsung hewan purba Komodo di habitat aslinya.\n\nManfaatkan fitur Rundown Harian & Anggaran Wisata kami untuk menyusun liburan impianmu dengan tertib dan tanpa khawatir anggaran membengkak!',
          'time': 'Resmi',
          'isRead': true,
          'actionText': 'Mulai Jelajah',
          'actionTab': 1,
        },
        {
          'id': 'tips_snorkeling',
          'title': 'Tips Snorkeling di Manta Point',
          'category': 'Tips Wisata',
          'body': 'Waktu terbaik melihat pari manta adalah pagi hari saat arus tenang. Pastikan bawa perlengkapan ya!',
          'detail': 'Pari manta adalah salah satu biota laut ikonik Labuan Bajo yang memesona. Arus di perairan Manta Point biasanya paling tenang antara pukul 08:00 - 11:00 WITA.\n\nPanduan keselamatan saat snorkeling:\n• Selalu gunakan life vest jika belum mahir berenang arus lepas.\n• Jaga jarak aman minimal 3 meter dari kawanan pari manta.\n• Jangan menyentuh terumbu karang atau mengejar biota laut.\n• Siapkan action cam dengan casing tahan air untuk momen terbaikmu!',
          'time': 'Tips',
          'isRead': true,
          'actionText': 'Lihat Destinasi',
          'actionTab': 1,
        },
        {
          'id': 'weather_info',
          'title': 'Pengingat Cuaca Bahari Labuan Bajo',
          'category': 'Kondisi Bahari',
          'body': 'Gelombang perairan Taman Nasional Komodo terpantau tenang dan bersahabat untuk sailing.',
          'detail': 'Prakiraan cuaca maritim di sekitar perairan Taman Nasional Komodo dan pelabuhan Labuan Bajo terpantau cerah berawan dengan kecepatan angin 8 - 14 knot.\n\nTinggi gelombang rata-rata 0.5 - 1.25 meter, sangat aman dan kondusif untuk aktivitas liveaboard (sailing), island hopping menggunakan speedboat, maupun trekking di bukit pulau.',
          'time': 'Bahari',
          'isRead': true,
          'actionText': 'Buka Radar Bajo',
          'actionTab': 3,
        },
      ]);

      if (mounted) {
        setState(() {
          _notifications = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatRupiah(num amount) {
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

  /// Menampilkan modal bottom sheet detail pesan notifikasi
  void _showNotificationDetail(Map<String, dynamic> notif) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: const BoxDecoration(
          color: AppPalette.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle pill
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

            // Header Pengirim: App Icon / Logo + BajoLand Official Badge
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppPalette.border,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
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
                          Text(
                            'BajoLand Official',
                            style: AppPalette.h3(color: AppPalette.textPrimary).copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified_rounded,
                            size: 15,
                            color: AppPalette.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${notif['category'] ?? 'Pemberitahuan'} • ${notif['time']}',
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
            const SizedBox(height: 16),
            const Divider(color: AppPalette.border, height: 1),
            const SizedBox(height: 16),

            // Judul Notifikasi
            Text(
              notif['title'] as String,
              style: AppPalette.h2(color: AppPalette.textPrimary).copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),

            // Isi Detail Pesan Lengkap
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppPalette.background,
                borderRadius: AppPalette.radiusMd,
                border: Border.all(color: AppPalette.border),
              ),
              child: Text(
                notif['detail'] as String? ?? notif['body'] as String,
                style: AppPalette.bodyMd(color: AppPalette.textPrimary).copyWith(
                  height: 1.6,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tombol aksi menutup lembar detail lalu memilih tab terkait di RootScreen.
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppPalette.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppPalette.radiusMd,
                      ),
                    ),
                    child: Text(
                      'Tutup',
                      style: AppPalette.bodyMd(color: AppPalette.textSecondary).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (notif['actionTab'] != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Get.back(); // Kembali dari NotificationScreen ke main screen
                        if (Get.isRegistered<RootNavigationController>()) {
                          final tabIdx = notif['actionTab'] as int;
                          final itinFilter = notif['itineraryFilter'] as int?;
                          Get.find<RootNavigationController>().selectTab(
                            tabIdx,
                            itineraryFilter: itinFilter,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPalette.primary,
                        foregroundColor: AppPalette.onPrimary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppPalette.radiusMd,
                        ),
                      ),
                      child: Text(
                        notif['actionText'] as String? ?? 'Buka Fitur',
                        style: AppPalette.bodyMd(color: Colors.white).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        title: Text('Notifikasi', style: AppPalette.h2()),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppPalette.border, height: 1),
        ),
      ),
      // Muat ulang memakai tarik-ke-bawah; warna latar membedakan item belum dibaca.
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppPalette.primary),
            )
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              color: AppPalette.primary,
              child: _notifications.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.7,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppPalette.border, width: 1.2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Image.asset(
                                        'assets/images/logo.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text('Belum Ada Notifikasi', style: AppPalette.h3()),
                                const SizedBox(height: 6),
                                Text(
                                  'Pemberitahuan jadwal dan anggaran akan muncul di sini',
                                  style: AppPalette.caption(color: AppPalette.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        thickness: 0.8,
                        color: AppPalette.border,
                      ),
                      itemBuilder: (context, index) {
                        final notif = _notifications[index];
                        final bool isRead = notif['isRead'] as bool;

                        return InkWell(
                          onTap: () {
                            setState(() {
                              notif['isRead'] = true;
                            });
                            _showNotificationDetail(notif);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                            decoration: BoxDecoration(
                              color: isRead ? AppPalette.surface : const Color(0xFFF8FAFC),
                            ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon Notifikasi: Lingkaran background putih bersih dengan Logo Aplikasi BajoLand
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isRead
                                  ? AppPalette.border
                                  : AppPalette.primary.withValues(alpha: 0.3),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Padding(
                              padding: const EdgeInsets.all(5),
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.contain,
                              ),
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
                                      notif['title'] as String,
                                      style: AppPalette.h3().copyWith(
                                        fontSize: 14,
                                        fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (!isRead) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppPalette.accentGold,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notif['body'] as String,
                                style: AppPalette.bodyMd(
                                  color: isRead ? AppPalette.textSecondary : AppPalette.textPrimary,
                                ).copyWith(fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    notif['time'] as String,
                                    style: AppPalette.labelXs(color: AppPalette.textSecondary),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Lihat detail',
                                        style: AppPalette.labelXs(color: AppPalette.primary).copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        size: 14,
                                        color: AppPalette.primary,
                                      ),
                                    ],
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
          ),
    );
  }
}
