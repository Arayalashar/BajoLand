import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../data/bajo_locations.dart';
import '../services/notification_service.dart';

/// Halaman Radar Lokasi Bajo & Kalkulasi Jarak GPS (Modul 3 & Modul 7: LBS & Geolocator)
class LbsScreen extends StatefulWidget {
  const LbsScreen({super.key});

  @override
  State<LbsScreen> createState() => _LbsScreenState();
}

class _LbsScreenState extends State<LbsScreen> {
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  String _statusMessage = 'Tekan tombol di bawah untuk mengukur jarak ke 5 destinasi Labuan Bajo.';

  // State untuk form Set Reminder Lokasi
  LocationData? _selectedLocation;
  DateTime _reminderDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _reminderTime = TimeOfDay.fromDateTime(
    DateTime.now().add(const Duration(hours: 1)),
  );

  @override
  void initState() {
    super.initState();
    _selectedLocation = bajoDestinations.first;
  }

  /// Meminta izin GPS dan mengambil posisi koordinat pengguna saat ini (Modul 7)
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _statusMessage = 'Mengecek sinyal GPS & izin lokasi...';
    });

    try {
      // 1. Cek apakah layanan GPS aktif di perangkat
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoadingLocation = false;
          _statusMessage = 'Layanan GPS tidak aktif. Silakan aktifkan GPS perangkat Anda.';
        });
        return;
      }

      // 2. Cek dan minta izin akses lokasi
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoadingLocation = false;
            _statusMessage = 'Izin lokasi ditolak oleh pengguna.';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoadingLocation = false;
          _statusMessage = 'Izin lokasi ditolak permanen. Buka pengaturan aplikasi untuk mengizinkan.';
        });
        return;
      }

      // 3. Ambil posisi pengguna saat ini
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      // 4. Kalkulasi jarak ke setiap destinasi Labuan Bajo (Modul 7: distanceBetween)
      for (final dest in bajoDestinations) {
        final double distanceInMeters = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          dest.latitude,
          dest.longitude,
        );
        dest.distanceInMeters = distanceInMeters;
      }

      // 5. Urutkan daftar lokasi dari yang paling dekat ke yang paling jauh
      bajoDestinations.sort(
        (a, b) => (a.distanceInMeters ?? 0).compareTo(b.distanceInMeters ?? 0),
      );

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
        _statusMessage =
            'Lokasi terdeteksi! Koordinat: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jarak berhasil dihitung dan diurutkan dari yang terdekat!'),
            backgroundColor: Color(0xFF0D5C3A),
          ),
        );
      }
    } catch (e) {
      // Fallback simulasi posisi Labuan Bajo (Dermaga) jika dijalankan di emulator/desktop tanpa sensor GPS
      _simulateLabuanBajoPosition();
    }
  }

  /// Simulasi posisi di sekitar Labuan Bajo jika GPS hardware emulator tidak merespons
  void _simulateLabuanBajoPosition() {
    const double simLat = -8.4900;
    const double simLng = 119.8820;

    for (final dest in bajoDestinations) {
      final double distanceInMeters = Geolocator.distanceBetween(
        simLat,
        simLng,
        dest.latitude,
        dest.longitude,
      );
      dest.distanceInMeters = distanceInMeters;
    }

    bajoDestinations.sort(
      (a, b) => (a.distanceInMeters ?? 0).compareTo(b.distanceInMeters ?? 0),
    );

    setState(() {
      _currentPosition = Position(
        longitude: simLng,
        latitude: simLat,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 5,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
      _isLoadingLocation = false;
      _statusMessage = 'Posisi disimulasikan di Labuan Bajo (-8.4900, 119.8820).';
    });
  }

  /// Menjadwalkan pengingat notifikasi ke destinasi terpilih (Modul 7)
  Future<void> _setDestinationReminder() async {
    if (_selectedLocation == null) return;

    final finalScheduled = DateTime(
      _reminderDate.year,
      _reminderDate.month,
      _reminderDate.day,
      _reminderTime.hour,
      _reminderTime.minute,
    );

    final notifId = DateTime.now().millisecondsSinceEpoch % 100000;

    await NotificationService.instance.scheduleNotification(
      id: notifId,
      title: 'Pengingat Radar: ${_selectedLocation!.name}',
      body: 'Waktunya berangkat atau mengecek jarak ke ${_selectedLocation!.name}!',
      scheduledDate: finalScheduled,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pengingat ke ${_selectedLocation!.name} dijadwalkan!'),
          backgroundColor: const Color(0xFF0D5C3A),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F2),
      appBar: AppBar(
        title: const Text(
          'Radar Lokasi Bajo (LBS)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D5C3A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Kartu Status GPS & Tombol Cek Lokasi (Modul 7)
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
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D5C3A).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.my_location, color: Color(0xFF0D5C3A)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Location-Based Services (LBS)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _statusMessage,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                      icon: _isLoadingLocation
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.radar),
                      label: Text(
                        _isLoadingLocation ? 'Mengukur Jarak...' : 'Cek Jarak Lokasi Saya',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D5C3A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ─── Daftar 5 Destinasi Labuan Bajo & Jaraknya
            const Text(
              'Jarak ke Destinasi Labuan Bajo:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 10),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bajoDestinations.length,
              itemBuilder: (context, index) {
                final dest = bajoDestinations[index];
                // Modul 3 & Modul 7: Penandaan warna hijau jika jarak < 500 meter
                final bool isNearby = dest.isNear;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isNearby ? const Color(0xFFE8F5E9) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isNearby ? Colors.green : Colors.grey.shade200,
                      width: isNearby ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        dest.imageUrl,
                        width: 54,
                        height: 54,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 54,
                          height: 54,
                          color: const Color(0xFF0D5C3A),
                          child: const Icon(Icons.image, color: Colors.white),
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            dest.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                        if (isNearby)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Dekat (< 500m)',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          dest.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Koordinat: ${dest.latitude}, ${dest.longitude}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isNearby
                            ? Colors.green.shade100
                            : const Color(0xFF0D5C3A).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        dest.formattedDistance,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isNearby ? Colors.green.shade900 : const Color(0xFF0D5C3A),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // ─── Fitur Pengingat Lokasi (Modul 7: Dropdown & DateTime Picker)
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
                      Icon(Icons.alarm_on, color: Color(0xFF0D5C3A)),
                      SizedBox(width: 8),
                      Text(
                        'Set Pengingat ke Lokasi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Dropdown Destinasi
                  DropdownButtonFormField<LocationData>(
                    value: _selectedLocation,
                    decoration: InputDecoration(
                      labelText: 'Pilih Titik Destinasi',
                      prefixIcon: const Icon(Icons.place, color: Color(0xFF0D5C3A)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: bajoDestinations.map((loc) {
                      return DropdownMenuItem<LocationData>(
                        value: loc,
                        child: Text(loc.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedLocation = val;
                      });
                    },
                  ),
                  const SizedBox(height: 14),

                  // Pilih Waktu
                  OutlinedButton.icon(
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _reminderDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (pickedDate != null && mounted) {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: _reminderTime,
                        );
                        if (pickedTime != null) {
                          setState(() {
                            _reminderTime = pickedTime;
                            _reminderDate = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                          });
                        }
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      'Waktu: ${dateFormat.format(DateTime(_reminderDate.year, _reminderDate.month, _reminderDate.day, _reminderTime.hour, _reminderTime.minute))}',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0D5C3A),
                      side: const BorderSide(color: Color(0xFF0D5C3A)),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _setDestinationReminder,
                      icon: const Icon(Icons.notifications_active),
                      label: const Text('Jadwalkan Pengingat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D5C3A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

