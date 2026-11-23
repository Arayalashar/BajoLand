import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/itinerary_item.dart';
import '../services/notification_service.dart';
import '../theme/app_palette.dart';
import '../utils/app_toast.dart';
import '../utils/date_formatter.dart';

/// Form buat atau ubah agenda Hive, termasuk pengecekan bentrok dan pengingat lokal.
class AddItineraryScreen extends StatefulWidget {
  final ItineraryItem? item;
  final int? index;
  final String? initialDestination;
  final double? initialBudget;

  const AddItineraryScreen({
    super.key,
    this.item,
    this.index,
    this.initialDestination,
    this.initialBudget,
  });

  @override
  State<AddItineraryScreen> createState() => _AddItineraryScreenState();
}

class _AddItineraryScreenState extends State<AddItineraryScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _destinationController;
  late final TextEditingController _activityController;
  late final TextEditingController _budgetController;

  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 2));
  TimeOfDay _selectedTime = TimeOfDay.fromDateTime(
    DateTime.now().add(const Duration(hours: 2)),
  );

  bool get _isEditMode => widget.item != null && widget.index != null;

  @override
  void initState() {
    super.initState();
    AppDateFormatter.ensureInitialized();
    NotificationService.instance.requestPermissions();
    _destinationController = TextEditingController(
      text: widget.item?.destination ?? widget.initialDestination ?? '',
    );
    _activityController = TextEditingController(
      text: widget.item?.activity ?? '',
    );
    _budgetController = TextEditingController(
      text: widget.item != null
          ? widget.item!.budget.toStringAsFixed(0)
          : (widget.initialBudget != null
              ? widget.initialBudget!.toStringAsFixed(0)
              : ''),
    );

    if (widget.item != null) {
      _selectedDate = widget.item!.scheduledDate;
      _selectedTime = TimeOfDay.fromDateTime(widget.item!.scheduledDate);
    }
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _activityController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  /// Pilih tanggal lalu gabungkan dengan jam yang sedang dipilih.
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppPalette.primary,
              onPrimary: AppPalette.onPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      });
    }
  }

  /// Pilih jam lalu gabungkan dengan tanggal yang sedang dipilih.
  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppPalette.primary,
              onPrimary: AppPalette.onPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  ItineraryItem? _checkConflict(DateTime candidate) {
    // Agenda pada hari sama dengan jarak waktu < 90 menit dianggap berpotensi bentrok.
    if (!Hive.isBoxOpen('itineraries')) return null;
    final box = Hive.box<ItineraryItem>('itineraries');
    for (var i = 0; i < box.length; i++) {
      if (_isEditMode && widget.index == i) continue;
      final existing = box.getAt(i);
      if (existing == null) continue;

      final isSameDay = existing.scheduledDate.year == candidate.year &&
          existing.scheduledDate.month == candidate.month &&
          existing.scheduledDate.day == candidate.day;

      if (isSameDay) {
        final diff = existing.scheduledDate.difference(candidate).inMinutes.abs();
        if (diff < 90) {
          return existing;
        }
      }
    }
    return null;
  }

  /// Simpan baru/perbarui agenda, jadwalkan notifikasi, lalu cek total batas anggaran.
  Future<void> _saveItinerary() async {
    if (!_formKey.currentState!.validate()) return;

    final String destination = _destinationController.text.trim();
    final String activity = _activityController.text.trim();
    final double budget = double.tryParse(_budgetController.text.trim()) ?? 0.0;

    // Error Handling: Pengecekan Bentrok Jadwal Rundown
    final clashingItem = _checkConflict(_selectedDate);
    if (clashingItem != null) {
      final bool? proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: AppPalette.radiusLg),
          backgroundColor: AppPalette.surface,
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppPalette.warning, size: 26),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Jadwal Bentrok!', style: AppPalette.h2(color: AppPalette.warning)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Waktu yang dipilih bertabrakan dengan agenda rundown lain di hari yang sama:',
                style: AppPalette.bodyMd(),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: AppPalette.radiusMd,
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clashingItem.destination,
                      style: AppPalette.h3(color: const Color(0xFF92400E)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pukul ${DateFormat('HH:mm').format(clashingItem.scheduledDate)} WITA • ${clashingItem.activity}',
                      style: AppPalette.caption(color: const Color(0xFFB45309)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Selisih waktu kurang dari 90 menit berisiko membuat tur terburu-buru. Apakah Anda ingin tetap menyimpannya?',
                style: AppPalette.caption(color: AppPalette.textSecondary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Ubah Jam',
                style: AppPalette.caption(color: AppPalette.primary).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.warning,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const RoundedRectangleBorder(borderRadius: AppPalette.radiusMd),
              ),
              child: const Text('Tetap Simpan'),
            ),
          ],
        ),
      );

      if (proceed != true) return;
    }

    final Box<ItineraryItem> box = Hive.box<ItineraryItem>('itineraries');

    if (_isEditMode) {
      final updatedItem = ItineraryItem(
        destination: destination,
        activity: activity,
        budget: budget,
        scheduledDate: _selectedDate,
      );

      await box.putAt(widget.index!, updatedItem);

      if (_selectedDate.isAfter(DateTime.now())) {
        await NotificationService.instance.scheduleNotification(
          id: widget.index!,
          title: 'Pengingat BajoLand: $destination',
          body: 'Aktivitas: $activity (Anggaran: Rp ${budget.toStringAsFixed(0)})',
          scheduledDate: _selectedDate,
          payload: destination,
        );
      }

      Get.back(result: true);
      AppToast.success(
        'Berhasil Diperbarui',
        'Rencana perjalanan ke $destination berhasil disimpan.',
      );
    } else {
      final newItem = ItineraryItem(
        destination: destination,
        activity: activity,
        budget: budget,
        scheduledDate: _selectedDate,
      );

      final newIndex = await box.add(newItem);

      if (_selectedDate.isAfter(DateTime.now())) {
        await NotificationService.instance.scheduleNotification(
          id: newIndex,
          title: 'Waktunya Menjelajah Bajo: $destination!',
          body: 'Aktivitas: $activity (Anggaran: Rp ${budget.toStringAsFixed(0)})',
          scheduledDate: _selectedDate,
          payload: destination,
        );
      }

      Get.back(result: true);
      AppToast.success(
        'Rencana Disimpan',
        'Jadwal dan pengingat ke $destination berhasil dibuat!',
      );
    }

    // Peringatan otomatis jika akumulasi anggaran melebihi batas anggaran
    try {
      final prefs = await SharedPreferences.getInstance();
      final double maxBudget = prefs.getDouble('maxBudget') ?? 5000000.0;
      final double totalSpent = box.values.fold(0.0, (sum, i) => sum + i.budget);

      if (totalSpent > maxBudget) {
        final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
        await NotificationService.instance.showInstantNotification(
          id: 9991,
          title: '⚠️ Peringatan: Batas Anggaran Terlampaui!',
          body: 'Total alokasi liburan (${formatter.format(totalSpent)}) melebihi batas pagu anggaran (${formatter.format(maxBudget)}).',
        );
      }
    } catch (_) {}
  }

  /// Kartu pemilih tanggal/jam; radius sedang mengikuti bentuk kontrol pada design system.
  Widget _dateTimeCard({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppPalette.radiusMd,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppPalette.surfaceMuted,
          borderRadius: AppPalette.radiusMd,
          border: Border.all(color: AppPalette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AppPalette.primary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppPalette.caption(color: AppPalette.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppPalette.bodyMd().copyWith(fontWeight: FontWeight.w700),
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
        title: Text(
          _isEditMode ? 'Ubah Rencana' : 'Rencana Baru',
          style: AppPalette.h2(),
        ),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Kedua kartu memisahkan informasi agenda dan nominal anggaran agar form mudah dipindai.
              // ─── Kartu Informasi Destinasi & Aktivitas
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppPalette.surface,
                  borderRadius: AppPalette.radiusLg,
                  border: Border.all(color: AppPalette.border),
                  boxShadow: AppPalette.shadowCard,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppPalette.primarySubtle,
                            borderRadius: AppPalette.radiusSm,
                          ),
                          child: const Icon(
                            Icons.place_rounded,
                            size: 18,
                            color: AppPalette.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('Tujuan & Aktivitas', style: AppPalette.h3()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _destinationController,
                      decoration: _inputDecoration(
                        label: 'Nama Destinasi',
                        icon: Icons.location_on_outlined,
                        hint: 'Contoh: Pulau Padar, Pink Beach',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Nama destinasi wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _activityController,
                      decoration: _inputDecoration(
                        label: 'Rencana Aktivitas',
                        icon: Icons.directions_walk_rounded,
                        hint: 'Contoh: Trekking sunrise, Snorkeling spot manta',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Aktivitas wajib diisi';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ─── Kartu Anggaran
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppPalette.surface,
                  borderRadius: AppPalette.radiusLg,
                  border: Border.all(color: AppPalette.border),
                  boxShadow: AppPalette.shadowCard,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppPalette.primarySubtle,
                            borderRadius: AppPalette.radiusSm,
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 18,
                            color: AppPalette.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('Perkiraan Anggaran (IDR)', style: AppPalette.h3()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _budgetController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        label: 'Anggaran',
                        icon: Icons.payments_outlined,
                        prefixText: 'Rp ',
                        hint: '0',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Anggaran wajib diisi';
                        }
                        final parsed = double.tryParse(val.trim());
                        if (parsed == null || parsed < 0) {
                          return 'Masukkan angka anggaran yang valid';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ─── Kartu Tanggal & Waktu
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppPalette.surface,
                  borderRadius: AppPalette.radiusLg,
                  border: Border.all(color: AppPalette.border),
                  boxShadow: AppPalette.shadowCard,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppPalette.primarySubtle,
                            borderRadius: AppPalette.radiusSm,
                          ),
                          child: const Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: AppPalette.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('Jadwal Pelaksanaan', style: AppPalette.h3()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _dateTimeCard(
                            icon: Icons.calendar_month_rounded,
                            label: 'Tanggal',
                            value: AppDateFormatter.formatDateWithDay(_selectedDate),
                            onTap: _pickDate,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _dateTimeCard(
                            icon: Icons.schedule_rounded,
                            label: 'Waktu (WITA)',
                            value: '${AppDateFormatter.formatTime(_selectedDate)} WITA',
                            onTap: _pickTime,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: const BoxDecoration(
                        color: AppPalette.primarySubtle,
                        borderRadius: AppPalette.radiusMd,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.notifications_active_rounded,
                            size: 18,
                            color: AppPalette.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Notifikasi lokal otomatis dijadwalkan pada waktu ini.',
                              style: AppPalette.caption(color: AppPalette.primary).copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Live Warning Jika Waktu Bentrok
                    Builder(
                      builder: (context) {
                        final clashing = _checkConflict(_selectedDate);
                        if (clashing == null) return const SizedBox.shrink();
                        return Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: AppPalette.radiusMd,
                            border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFEF3C7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.schedule_rounded,
                                  color: Color(0xFFD97706),
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Perhatian: Jadwal Berdekatan',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF92400E),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Waktu ini berjarak kurang dari 90 menit dengan "${clashing.destination}" (${DateFormat('HH:mm').format(clashing.scheduledDate)} WITA).',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: const Color(0xFFB45309),
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ─── Tombol Simpan (Primary Action 48px)
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _saveItinerary,
                  icon: const Icon(Icons.check_rounded, size: 20),
                  label: Text(
                    _isEditMode ? 'Simpan Perubahan' : 'Simpan Rencana',
                    style: AppPalette.bodyMd(color: AppPalette.onPrimary).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.primary,
                    foregroundColor: AppPalette.onPrimary,
                    elevation: 0,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppPalette.radiusMd,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? prefixText,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppPalette.bodyMd(color: AppPalette.textSecondary),
      hintText: hint,
      hintStyle: AppPalette.bodyMd(color: AppPalette.textSecondary.withValues(alpha: 0.5)),
      prefixIcon: Icon(icon, color: AppPalette.primary, size: 20),
      prefixText: prefixText,
      prefixStyle: AppPalette.bodyMd().copyWith(fontWeight: FontWeight.w600),
      filled: true,
      fillColor: AppPalette.surfaceMuted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: const OutlineInputBorder(
        borderRadius: AppPalette.radiusMd,
        borderSide: BorderSide(color: AppPalette.border),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: AppPalette.radiusMd,
        borderSide: BorderSide(color: AppPalette.border),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: AppPalette.radiusMd,
        borderSide: BorderSide(color: AppPalette.primary, width: 1.5),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: AppPalette.radiusMd,
        borderSide: BorderSide(color: AppPalette.error),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: AppPalette.radiusMd,
        borderSide: BorderSide(color: AppPalette.error, width: 1.5),
      ),
    );
  }
}
