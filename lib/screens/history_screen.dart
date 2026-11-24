import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../models/itinerary_item.dart';
import '../theme/app_palette.dart';
import '../utils/date_formatter.dart';
import 'add_itinerary_screen.dart';

/// Riwayat agenda dari Hive; jika belum ada yang lewat, agenda tersimpan tetap ditampilkan.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Format mata uang dibuat terpisah agar tampilan kartu selalu konsisten.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        title: Text('Riwayat Perjalanan', style: AppPalette.h2()),
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
      // Dengarkan box Hive agar riwayat selalu berasal dari penyimpanan lokal terbaru.
      body: ValueListenableBuilder<Box<ItineraryItem>>(
        valueListenable: Hive.box<ItineraryItem>('itineraries').listenable(),
        builder: (context, box, _) {
          final allItems = box.values.toList();
          final now = DateTime.now();

          // Riwayat: perjalanan yang tanggalnya telah lewat atau riwayat tersimpan
          final pastItems = allItems.where((item) => item.scheduledDate.isBefore(now)).toList();
          final displayItems = pastItems.isNotEmpty ? pastItems.reversed.toList() : allItems.reversed.toList();

          double totalHistorySpent = 0.0;
          for (final item in displayItems) {
            totalHistorySpent += item.budget;
          }

          // Tampilan kosong mengarahkan pengguna membuat agenda pertama.
          if (displayItems.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
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
                        Icons.history_toggle_off_rounded,
                        size: 36,
                        color: AppPalette.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Belum Ada Riwayat Perjalanan', style: AppPalette.h3()),
                    const SizedBox(height: 6),
                    Text(
                      'Perjalanan yang telah selesai akan otomatis tercatat di sini',
                      textAlign: TextAlign.center,
                      style: AppPalette.caption(color: AppPalette.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => Get.to(() => const AddItineraryScreen()),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Buat Rencana Baru'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPalette.primary,
                        foregroundColor: AppPalette.onPrimary,
                        elevation: 0,
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kartu ringkasan membedakan total dana tercatat dari daftar agenda di bawahnya.
                // ─── Kartu Ringkasan Riwayat Pengeluaran
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    ),
                    borderRadius: AppPalette.radiusLg,
                    boxShadow: AppPalette.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Dana Terekam',
                            style: AppPalette.caption(color: const Color(0xFF94A3B8)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF334155),
                              borderRadius: AppPalette.radiusSm,
                            ),
                            child: Text(
                              '${displayItems.length} Selesai',
                              style: AppPalette.labelXs(color: const Color(0xFFE2E8F0)).copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatRupiah(totalHistorySpent),
                        style: AppPalette.h1(color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Riwayat aktivitas dan perjalanan wisata di Labuan Bajo',
                        style: AppPalette.caption(color: const Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Text('Catatan Perjalanan', style: AppPalette.h2()),
                const SizedBox(height: 12),

                // ─── Daftar Riwayat Perjalanan
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = displayItems[index];

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppPalette.surface,
                        borderRadius: AppPalette.radiusLg,
                        border: Border.all(color: AppPalette.border),
                        boxShadow: AppPalette.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.destination,
                                  style: AppPalette.h3(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFDCFCE7),
                                  borderRadius: AppPalette.radiusSm,
                                ),
                                child: Text(
                                  'Selesai',
                                  style: AppPalette.labelXs(color: AppPalette.success).copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.activity,
                            style: AppPalette.bodyMd(color: AppPalette.textSecondary),
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 1, color: AppPalette.border),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_circle_outline_rounded,
                                      size: 14, color: AppPalette.success),
                                  const SizedBox(width: 4),
                                  Text(
                                    AppDateFormatter.formatFull(item.scheduledDate),
                                    style: AppPalette.labelXs(color: AppPalette.textSecondary),
                                  ),
                                ],
                              ),
                              Text(
                                _formatRupiah(item.budget),
                                style: AppPalette.caption(color: AppPalette.textPrimary).copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
