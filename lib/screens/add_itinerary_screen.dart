import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/itinerary_item.dart';
import '../services/notification_service.dart';

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
              primary: Color(0xFF0D5C3A),
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
              primary: Color(0xFF0D5C3A),
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
    final notificationId =
        _isEditMode ? widget.index! + 100 : DateTime.now().millisecondsSinceEpoch % 100000;

    // 1. Notifikasi Langsung Konfirmasi
    await NotificationService.instance.showInstantNotification(
      id: notificationId,
      title: _isEditMode ? 'Jadwal Diperbarui!' : 'Jadwal Baru Disimpan!',
      body: '$destination: $activity berhasil disimpan ke itinerary BajoLand.',
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
          backgroundColor: const Color(0xFF0D5C3A),
        ),
      );
      // Modul 4: Navigator.pop untuk kembali ke daftar
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
    final timeFormat = DateFormat('HH:mm');

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F2),
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Edit Jadwal Perjalanan' : 'Tambah Jadwal Baru',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0D5C3A),
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Kartu Form Input
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detail Destinasi & Aktivitas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Input Destinasi
                    TextFormField(
                      controller: _destinationController,
                      decoration: InputDecoration(
                        labelText: 'Destinasi Wisata',
                        hintText: 'Misal: Pulau Padar / Pink Beach',
                        prefixIcon: const Icon(Icons.place, color: Color(0xFF0D5C3A)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama destinasi wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Input Aktivitas
                    TextFormField(
                      controller: _activityController,
                      decoration: InputDecoration(
                        labelText: 'Rencana Kegiatan',
                        hintText: 'Misal: Trekking Sunrise & Foto',
                        prefixIcon: const Icon(Icons.directions_walk, color: Color(0xFF0D5C3A)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Detail kegiatan wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Input Anggaran (Budget)
                    TextFormField(
                      controller: _budgetController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Estimasi Biaya (Rp)',
                        hintText: 'Misal: 350000',
                        prefixIcon: const Icon(Icons.payments_outlined, color: Color(0xFF0D5C3A)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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

              // Kartu Waktu & Pengingat Notifikasi
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.notifications_active_outlined,
                            size: 20, color: Color(0xFF0D5C3A)),
                        SizedBox(width: 8),
                        Text(
                          'Jadwal & Pengingat Notifikasi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Pilih Tanggal
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: Color(0x150D5C3A),
                        child: Icon(Icons.calendar_month, color: Color(0xFF0D5C3A)),
                      ),
                      title: const Text('Tanggal Pelaksanaan',
                          style: TextStyle(fontSize: 13, color: Colors.grey)),
                      subtitle: Text(
                        dateFormat.format(_selectedDate),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      trailing: TextButton(
                        onPressed: _pickDate,
                        child: const Text('Ubah'),
                      ),
                    ),
                    const Divider(),

                    // Pilih Jam
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: Color(0x150D5C3A),
                        child: Icon(Icons.access_time, color: Color(0xFF0D5C3A)),
                      ),
                      title: const Text('Waktu Keberangkatan',
                          style: TextStyle(fontSize: 13, color: Colors.grey)),
                      subtitle: Text(
                        '${timeFormat.format(_selectedDate)} WITA',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      trailing: TextButton(
                        onPressed: _pickTime,
                        child: const Text('Ubah'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Tombol Simpan
              ElevatedButton.icon(
                onPressed: _saveItinerary,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  _isEditMode ? 'Simpan Perubahan Jadwal' : 'Tambahkan ke Itinerary',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D5C3A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

