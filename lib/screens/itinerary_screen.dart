import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/itinerary_item.dart';
import '../services/notification_service.dart';
import '../theme/app_palette.dart';
import '../utils/app_toast.dart';
import '../utils/date_formatter.dart';
import 'add_itinerary_screen.dart';
import 'root_screen.dart';

/// Daftar itinerary reaktif: batas/total anggaran, filter waktu, dan timeline per hari.
class ItineraryScreen extends StatefulWidget {
  final int? initialFilter;

  const ItineraryScreen({super.key, this.initialFilter});

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  // Batas anggaran dan filter waktu merupakan state lokal layar rundown.
  double _maxBudget = 5000000.0;
  int _selectedFilter = 0; // 0: Semua, 1: Mendatang, 2: Selesai

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter ?? 0;
    _loadMaxBudget();

    if (Get.isRegistered<RootNavigationController>()) {
      final rootCtrl = Get.find<RootNavigationController>();
      if (widget.initialFilter != null) {
        rootCtrl.itineraryFilter.value = widget.initialFilter!;
      } else {
        _selectedFilter = rootCtrl.itineraryFilter.value;
      }
      ever(rootCtrl.itineraryFilter, (int val) {
        if (mounted) {
          setState(() {
            _selectedFilter = val;
          });
        }
      });
    }
  }

  /// Membaca batas pengeluaran terakhir dari preferensi lokal.
  Future<void> _loadMaxBudget() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _maxBudget = prefs.getDouble('maxBudget') ?? 5000000.0;
    });
  }

  /// Menyimpan batas baru, menyegarkan ringkasan, lalu memberi konfirmasi notifikasi.
  Future<void> _saveMaxBudget(double newBudget) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('maxBudget', newBudget);
    setState(() {
      _maxBudget = newBudget;
    });
    await NotificationService.instance.showInstantNotification(
      id: 9992,
      title: 'Batas Anggaran Diperbarui',
      body: 'Batas total anggaran liburan Anda sekarang ${_formatRupiah(newBudget)}.',
    );
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

  void _showSetBudgetDialog(BuildContext context) {
    final controller = TextEditingController(text: _maxBudget.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppPalette.radiusLg),
        backgroundColor: AppPalette.surface,
        title: Text('Atur Batas Anggaran', style: AppPalette.h2()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tentukan batas maksimal pengeluaran untuk seluruh perjalanan liburan Anda di Labuan Bajo:',
              style: AppPalette.caption(color: AppPalette.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                prefixText: 'Rp ',
                labelText: 'Batas Anggaran (IDR)',
                border: const OutlineInputBorder(borderRadius: AppPalette.radiusMd),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: AppPalette.radiusMd,
                  borderSide: BorderSide(color: AppPalette.primary, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: AppPalette.caption(color: AppPalette.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text.trim());
              if (val != null && val > 0) {
                _saveMaxBudget(val);
                Navigator.pop(ctx);
                AppToast.success(
                  'Anggaran Diperbarui',
                  'Batas anggaran wisata diatur ke ${_formatRupiah(val)}',
                );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        title: Text('Rundown & Itinerary', style: AppPalette.h2()),
        backgroundColor: AppPalette.surface,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppPalette.border, height: 1),
        ),
      ),
      // Hive memberi notifikasi perubahan sehingga total, filter, dan timeline ikut dirender ulang.
      body: ValueListenableBuilder<Box<ItineraryItem>>(
        valueListenable: Hive.box<ItineraryItem>('itineraries').listenable(),
        builder: (context, box, _) {
          final allItems = box.values.toList();

          // Ringkasan dihitung dari semua agenda, bukan hanya agenda yang lolos filter.
          // Hitung total anggaran
          double totalSpent = 0.0;
          for (final item in allItems) {
            totalSpent += item.budget;
          }
          final double remainingBudget = _maxBudget - totalSpent;
          final bool isOverbudget = remainingBudget < 0;

          // Pengecekan ada tidaknya bentrok jadwal di seluruh daftar
          bool hasAnyConflict = false;
          for (var i = 0; i < allItems.length; i++) {
            for (var j = i + 1; j < allItems.length; j++) {
              final a = allItems[i];
              final b = allItems[j];
              final isSameDay = a.scheduledDate.year == b.scheduledDate.year &&
                  a.scheduledDate.month == b.scheduledDate.month &&
                  a.scheduledDate.day == b.scheduledDate.day;
              if (isSameDay) {
                final diff = a.scheduledDate.difference(b.scheduledDate).inMinutes.abs();
                if (diff < 90) {
                  hasAnyConflict = true;
                  break;
                }
              }
            }
            if (hasAnyConflict) break;
          }

          // Filter logic (Mendatang / Selesai / Semua)
          final now = DateTime.now();
          final filteredItems = <ItineraryItem>[];
          for (final item in allItems) {
            if (_selectedFilter == 1 && item.scheduledDate.isBefore(now)) continue;
            if (_selectedFilter == 2 && item.scheduledDate.isAfter(now)) continue;
            filteredItems.add(item);
          }

          // Urutkan item secara kronologis dari pagi ke malam
          filteredItems.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

          // Kelompokkan itinerary berdasarkan Tanggal / Hari (Rundown Harian)
          final Map<String, List<ItineraryItem>> groupedByDay = {};
          final Map<String, DateTime> dateReferenceMap = {};

          for (final item in filteredItems) {
            final dateKey = DateFormat('yyyy-MM-dd').format(item.scheduledDate);
            groupedByDay.putIfAbsent(dateKey, () => []).add(item);
            dateReferenceMap[dateKey] = item.scheduledDate;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ─── 1. Ringkasan Anggaran Wisata; warna berubah saat melewati batas ──
              _buildBudgetCard(
                totalSpent: totalSpent,
                remainingBudget: remainingBudget,
                isOverbudget: isOverbudget,
                totalItems: allItems.length,
                onEditBudget: () => _showSetBudgetDialog(context),
              ),

              const SizedBox(height: 16),

              // ─── 2. Banner Peringatan Jika Ada Jadwal Bentrok ─────────────
              if (hasAnyConflict)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: AppPalette.radiusMd,
                    border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
                    boxShadow: AppPalette.cardShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFEF3C7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.schedule_rounded,
                          color: Color(0xFFD97706),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Perhatian: Terdapat Jadwal Berdekatan',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF92400E),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Ada agenda yang berselisih waktu kurang dari 90 menit di hari yang sama. Cek kartu bertanda khusus di bawah.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFFB45309),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // ─── 3. Filter Kategori Rundown (Rata Kanan Kiri) ────────────
              Row(
                children: [
                  Expanded(child: _buildFilterPill(label: 'Semua', index: 0)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildFilterPill(label: 'Mendatang', index: 1)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildFilterPill(label: 'Selesai', index: 2)),
                ],
              ),

              const SizedBox(height: 16),

              // ─── 4. Agenda dikelompokkan per tanggal dan ditampilkan sebagai timeline.
              //       Kartu merah menandai jadwal yang berselisih kurang dari 90 menit.
              // ─── 4. Konten Rundown Harian ─────────────────────────────────
              if (allItems.isEmpty)
                _buildEmptyState()
              else if (filteredItems.isEmpty)
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppPalette.surface,
                    borderRadius: AppPalette.radiusLg,
                    border: Border.all(color: AppPalette.border),
                  ),
                  child: Center(
                    child: Text(
                      'Tidak ada jadwal perjalanan untuk kategori ini.',
                      style: AppPalette.bodyMd(color: AppPalette.textSecondary),
                    ),
                  ),
                )
              else
                ...groupedByDay.entries.map((entry) {
                  final dateKey = entry.key;
                  final dayItems = entry.value;
                  final dayDate = dateReferenceMap[dateKey]!;

                  // Total budget harian
                  double dayTotalBudget = 0.0;
                  for (final item in dayItems) {
                    dayTotalBudget += item.budget;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Tanggal / Hari Rundown
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppPalette.surface,
                            borderRadius: AppPalette.radiusMd,
                            border: Border.all(color: AppPalette.border),
                            boxShadow: AppPalette.cardShadow,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppPalette.primarySubtle,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.calendar_month_rounded,
                                  size: 16,
                                  color: AppPalette.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  AppDateFormatter.formatDateWithDay(dayDate),
                                  style: AppPalette.h3().copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppPalette.surfaceMuted,
                                  borderRadius: AppPalette.radiusFull,
                                  border: Border.all(color: AppPalette.border),
                                ),
                                child: Text(
                                  '${dayItems.length} Agenda • ${_formatRupiah(dayTotalBudget)}',
                                  style: AppPalette.labelXs(color: AppPalette.textPrimary).copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Timeline Items Rundown dalam Sehari
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: dayItems.length,
                          itemBuilder: (context, idx) {
                            final item = dayItems[idx];
                            final isLast = idx == dayItems.length - 1;

                            // Error Handling: Deteksi Bentrok Jadwal di Hari yang Sama (< 90 menit)
                            bool isClashing = false;
                            String? clashingWith;
                            for (var other in dayItems) {
                              if (other != item) {
                                final diff = (other.scheduledDate.difference(item.scheduledDate)).inMinutes.abs();
                                if (diff < 90) {
                                  isClashing = true;
                                  clashingWith = '${other.destination} (${DateFormat('HH:mm').format(other.scheduledDate)} WITA)';
                                  break;
                                }
                              }
                            }

                            final originalIndex = allItems.indexOf(item);

                            return _buildTimelineItem(
                              context: context,
                              box: box,
                              item: item,
                              index: originalIndex,
                              isLast: isLast,
                              isClashing: isClashing,
                              clashingWith: clashingWith,
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const AddItineraryScreen()),
        backgroundColor: AppPalette.primary,
        foregroundColor: AppPalette.onPrimary,
        elevation: 3,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  // Node kiri menunjukkan waktu/status; kartu kanan memuat detail, edit, dan swipe-hapus.
  // ─── Widget Timeline Node & Card Rundown ─────────────────────────────────
  Widget _buildTimelineItem({
    required BuildContext context,
    required Box<ItineraryItem> box,
    required ItineraryItem item,
    required int index,
    required bool isLast,
    required bool isClashing,
    String? clashingWith,
  }) {
    final timeStr = DateFormat('HH:mm').format(item.scheduledDate);
    final isCompleted = item.scheduledDate.isBefore(DateTime.now());

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Kolom Kiri: Waktu & Garis Timeline
          SizedBox(
            width: 65,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: isClashing
                        ? const Color(0xFFFEF2F2)
                        : (isCompleted ? const Color(0xFFF0FDF4) : AppPalette.primarySubtle),
                    borderRadius: AppPalette.radiusSm,
                    border: Border.all(
                      color: isClashing
                          ? AppPalette.error
                          : (isCompleted
                              ? const Color(0xFF86EFAC)
                              : AppPalette.primary.withValues(alpha: 0.2)),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        timeStr,
                        style: AppPalette.labelXs(
                          color: isClashing
                              ? AppPalette.error
                              : (isCompleted ? const Color(0xFF16A34A) : AppPalette.primary),
                        ).copyWith(fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                      Text(
                        'WITA',
                        style: AppPalette.labelXs(
                          color: isClashing
                              ? AppPalette.error
                              : (isCompleted ? const Color(0xFF16A34A) : AppPalette.primary),
                        ).copyWith(fontSize: 9),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Titik Node Timeline (Merah jika bentrok, Hijau jika selesai, Biru jika mendatang)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isClashing
                        ? AppPalette.error
                        : (isCompleted ? const Color(0xFF10B981) : AppPalette.primary),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isClashing
                                ? AppPalette.error
                                : (isCompleted
                                    ? const Color(0xFF10B981)
                                    : AppPalette.primary))
                            .withValues(alpha: 0.35),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                // Garis Vertikal Timeline
                Expanded(
                  child: isLast
                      ? const SizedBox.shrink()
                      : Container(
                          width: 2,
                          color: isClashing
                              ? const Color(0xFFFCA5A5)
                              : (isCompleted ? const Color(0xFFCBD5E1) : AppPalette.border),
                        ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Kolom Kanan: Kartu Agenda Rundown (Mendukung Geser / Swipe untuk Hapus)
          Expanded(
            child: Dismissible(
              key: ValueKey(item.key ?? '${item.destination}_${item.scheduledDate.millisecondsSinceEpoch}_$index'),
              direction: DismissDirection.endToStart,
              background: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.only(right: 18),
                alignment: Alignment.centerRight,
                decoration: BoxDecoration(
                  color: AppPalette.error,
                  borderRadius: AppPalette.radiusLg,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [
                    Text(
                      'Hapus',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
                  ],
                ),
              ),
              confirmDismiss: (direction) async {
                return await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: const RoundedRectangleBorder(borderRadius: AppPalette.radiusLg),
                    backgroundColor: AppPalette.surface,
                    title: Text('Hapus Agenda?', style: AppPalette.h2()),
                    content: Text(
                      'Apakah Anda yakin ingin menghapus agenda "${item.destination}" dari rundown?',
                      style: AppPalette.bodyMd(),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text('Batal', style: AppPalette.caption(color: AppPalette.textSecondary)),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppPalette.error,
                          foregroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(borderRadius: AppPalette.radiusMd),
                          elevation: 0,
                        ),
                        child: const Text('Hapus'),
                      ),
                    ],
                  ),
                ) ?? false;
              },
              onDismissed: (_) async {
                final title = item.destination;
                await item.delete();
                AppToast.info(
                  'Agenda Terhapus',
                  'Agenda "$title" berhasil dihapus dari rundown.',
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isClashing
                      ? const Color(0xFFFFF7F7)
                      : (isCompleted ? const Color(0xFFF8FAFC) : AppPalette.surface),
                  borderRadius: AppPalette.radiusLg,
                  border: Border.all(
                    color: isClashing
                        ? const Color(0xFFFCA5A5)
                        : (isCompleted ? const Color(0xFFE2E8F0) : AppPalette.border),
                    width: isClashing ? 1.5 : 1,
                  ),
                  boxShadow: AppPalette.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Peringatan Bentrok di Kartu
                    if (isClashing && clashingWith != null) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFDE68A), width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.schedule_rounded, size: 13, color: Color(0xFFD97706)),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                'Jadwal berdekatan dengan: $clashingWith',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFB45309),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Baris Judul & Aksi (Jika Selesai: Label Selesai di Pojok Kanan Atas, Jika Belum: Tombol Edit)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            item.destination,
                            style: AppPalette.h3(
                              color: isCompleted ? AppPalette.textSecondary : AppPalette.textPrimary,
                            ).copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.check_circle_rounded, size: 11, color: Color(0xFF059669)),
                                SizedBox(width: 4),
                                Text(
                                  'Selesai',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: () => Get.to(
                              () => AddItineraryScreen(item: item, index: index),
                            ),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: AppPalette.surfaceMuted,
                                borderRadius: AppPalette.radiusFull,
                              ),
                              child: const Icon(
                                Icons.edit_outlined,
                                size: 15,
                                color: AppPalette.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.directions_walk_rounded,
                          size: 14,
                          color: AppPalette.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.activity,
                            style: AppPalette.bodyMd(color: AppPalette.textSecondary).copyWith(
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    const Divider(height: 1, thickness: 0.8, color: AppPalette.border),
                    const SizedBox(height: 8),

                    // Estimasi Anggaran
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Estimasi Biaya:',
                          style: AppPalette.caption(color: AppPalette.textSecondary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isCompleted ? AppPalette.surfaceMuted : AppPalette.primarySubtle,
                            borderRadius: AppPalette.radiusSm,
                          ),
                          child: Text(
                            _formatRupiah(item.budget),
                            style: AppPalette.labelXs(
                              color: isCompleted ? AppPalette.textSecondary : AppPalette.primary,
                            ).copyWith(
                              fontWeight: FontWeight.w700,
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
        ],
      ),
    );
  }

  // ─── Kartu Anggaran Wisata ───────────────────────────────────────────────
  Widget _buildBudgetCard({
    required double totalSpent,
    required double remainingBudget,
    required bool isOverbudget,
    required int totalItems,
    required VoidCallback onEditBudget,
  }) {
    // Kartu ringkasan memakai radius besar; gradien merah menandakan anggaran terlampaui.
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOverbudget
              ? [const Color(0xFFDC2626), const Color(0xFFEF4444)]
              : [const Color(0xFF1A5FFF), const Color(0xFF124AD1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppPalette.radiusXl,
        boxShadow: AppPalette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isOverbudget ? '⚠️ MELEBIHI ANGGARAN' : 'KONTROL ANGGARAN WISATA',
                style: AppPalette.labelXs(color: Colors.white.withValues(alpha: 0.9)).copyWith(
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: onEditBudget,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _formatRupiah(remainingBudget),
            style: AppPalette.h1(color: Colors.white).copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Sisa Anggaran Tersedia',
            style: AppPalette.caption(color: Colors.white.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 14),
          Container(color: Colors.white.withValues(alpha: 0.2), height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Batas Maksimal:',
                    style: AppPalette.labelXs(color: Colors.white.withValues(alpha: 0.75)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatRupiah(_maxBudget),
                    style: AppPalette.caption(color: Colors.white).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total Terpakai:',
                    style: AppPalette.labelXs(color: Colors.white.withValues(alpha: 0.75)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatRupiah(totalSpent),
                    style: AppPalette.caption(color: Colors.white).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Filter berbentuk pil; pilihannya juga disimpan di controller tab utama.
  // ─── Filter Pills Row ────────────────────────────────────────────────────
  Widget _buildFilterPill({required String label, required int index}) {
    final isSelected = _selectedFilter == index;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = index);
        if (Get.isRegistered<RootNavigationController>()) {
          Get.find<RootNavigationController>().itineraryFilter.value = index;
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppPalette.primary : AppPalette.surface,
          borderRadius: AppPalette.radiusFull,
          border: Border.all(
            color: isSelected ? AppPalette.primary : AppPalette.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppPalette.caption(
            color: isSelected ? AppPalette.onPrimary : AppPalette.textSecondary,
          ).copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ─── Empty State ─────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: AppPalette.radiusLg,
        border: Border.all(color: AppPalette.border, width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppPalette.primarySubtle,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              size: 36,
              color: AppPalette.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text('Belum Ada Rundown Perjalanan', style: AppPalette.h3()),
          const SizedBox(height: 6),
          Text(
            'Susun rundown harian wisatamu di Labuan Bajo agar waktu dan anggaran terkontrol rapi.',
            textAlign: TextAlign.center,
            style: AppPalette.bodyMd(color: AppPalette.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Get.to(() => const AddItineraryScreen()),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Buat Rundown Pertama'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.primary,
              foregroundColor: AppPalette.onPrimary,
              shape: const RoundedRectangleBorder(borderRadius: AppPalette.radiusMd),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
