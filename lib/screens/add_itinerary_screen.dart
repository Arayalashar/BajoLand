import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../models/itinerary_item.dart';
import '../services/notification_service.dart';
import '../theme/app_palette.dart';

/// Form Tambah/Edit Jadwal & Anggaran (Modul 3, 6, 7)
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
              primary: Color(0xFF375534),
              onPrimary: Colors.white,
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

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF375534),
              onPrimary: Colors.white,
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

  Future<void> _saveItinerary() async {
    if (!_formKey.currentState!.validate()) return;

    final destination = _destinationController.text.trim();
    final activity = _activityController.text.trim();
    final budget = double.tryParse(_budgetController.text.trim()) ?? 0.0;

    final finalScheduledDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final box = Hive.box<ItineraryItem>('itineraries');

    if (_isEditMode) {
      // Modul 6: Hive CRUD update (putAt)
      final existingItem = widget.item!;
      existingItem.destination = destination;
      existingItem.activity = activity;
      existingItem.budget = budget;
      existingItem.scheduledDate = finalScheduledDate;
      await box.putAt(widget.index!, existingItem);
    } else {
      // Modul 6: Hive CRUD create (add)
      final newItem = ItineraryItem(
        destination: destination,
        activity: activity,
        budget: budget,
        scheduledDate: finalScheduledDate,
      );
      await box.add(newItem);
    }

    // Modul 7: Pemicu Notifikasi Langsung (Immediate) & Terjadwal (Scheduled)
    final notificationId = _isEditMode
        ? widget.index! + 100
        : DateTime.now().millisecondsSinceEpoch % 100000;

    // 1. Notifikasi Langsung Konfirmasi
    await NotificationService.instance.showInstantNotification(
      id: notificationId,
      title: _isEditMode ? 'Jadwal Diperbarui!' : 'Jadwal Baru Disimpan!',
      body: '$destination: $activity berhasil disimpan ke rencanamu.',
    );

    // 2. Notifikasi Terjadwal Keberangkatan
    if (finalScheduledDate.isAfter(DateTime.now())) {
      await NotificationService.instance.scheduleNotification(
        id: notificationId + 1,
        title: 'Pengingat Wisata: $destination',
        body: 'Saatnya bersiap! Jadwal kegiatan "$activity" dimulai sekarang.',
        scheduledDate: finalScheduledDate,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Jadwal berhasil diperbarui!'
                : 'Jadwal berhasil ditambahkan & pengingat diaktifkan!',
          ),
          backgroundColor: const Color(0xFF375534),
        ),
      );
      Get.back();
    }
  }

  Widget _dateTimeCard({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppPalette.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: AppPalette.forest),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.deepGreen,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ubah',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.forest,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, d MMM yyyy', 'id_ID');
    final timeFormat = DateFormat('HH:mm');

    return Scaffold(
      backgroundColor: AppPalette.ivory,
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Ubah Rencana' : 'Rencana Baru',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppPalette.forest,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppPalette.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.place_rounded,
                          size: 20,
                          color: AppPalette.forest,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Tujuan & kegiatan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppPalette.deepGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _destinationController,
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputDecoration(
                        label: 'Destinasi wisata',
                        icon: Icons.location_on_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama destinasi wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _activityController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _inputDecoration(
                        label: 'Apa yang ingin dilakukan?',
                        icon: Icons.hiking_rounded,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Detail kegiatan wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _budgetController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        label: 'Perkiraan biaya',
                        icon: Icons.payments_outlined,
                        prefixText: 'Rp ',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Biaya wajib diisi';
                        }
                        if (double.tryParse(value.trim()) == null) {
                          return 'Masukkan angka nominal yang valid';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppPalette.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          size: 20,
                          color: AppPalette.forest,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Waktu perjalanan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppPalette.deepGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _dateTimeCard(
                            icon: Icons.calendar_today_rounded,
                            label: 'Tanggal',
                            value: dateFormat.format(_selectedDate),
                            onTap: _pickDate,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _dateTimeCard(
                            icon: Icons.schedule_rounded,
                            label: 'Waktu setempat',
                            value: '${timeFormat.format(_selectedDate)} WITA',
                            onTap: _pickTime,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppPalette.ivory.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.notifications_active_outlined,
                            size: 18,
                            color: AppPalette.forest,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Kami akan mengingatkanmu sebelum berangkat.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppPalette.deepGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _saveItinerary,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(
                    _isEditMode ? 'Simpan perubahan' : 'Simpan rencana',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.forest,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
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
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    );

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppPalette.forest),
      prefixText: prefixText,
      filled: true,
      fillColor: AppPalette.ivory.withOpacity(0.48),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppPalette.sage, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}
