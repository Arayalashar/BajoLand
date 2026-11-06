import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/itinerary_item.dart';
import 'login_screen.dart';

/// Halaman Profil, Pengaturan Anggaran & Logout (Modul 4 & Modul 6)
class ProfileScreen extends StatefulWidget {
  final String userName;

  const ProfileScreen({
    super.key,
    required this.userName,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  double _maxBudget = 5000000.0;
  final TextEditingController _budgetDialogController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMaxBudget();
  }

  @override
  void dispose() {
    _budgetDialogController.dispose();
    super.dispose();
  }

  /// Memuat batas anggaran dari SharedPreferences (Modul 6)
  Future<void> _loadMaxBudget() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _maxBudget = prefs.getDouble('maxBudget') ?? 5000000.0;
    });
  }

  /// Memperbarui batas anggaran di SharedPreferences (Modul 6)
  Future<void> _updateMaxBudget(double newBudget) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('maxBudget', newBudget);
    setState(() {
      _maxBudget = newBudget;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Batas total anggaran berhasil diperbarui!'),
          backgroundColor: Color(0xFF0D5C3A),
        ),
      );
    }
  }

  /// Dialog untuk mengubah nominal batas anggaran
  void _showEditBudgetDialog() {
    _budgetDialogController.text = _maxBudget.toStringAsFixed(0);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Batas Anggaran'),
        content: TextField(
          controller: _budgetDialogController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Total Anggaran Maksimal (Rp)',
            prefixText: 'Rp ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final newBudget = double.tryParse(_budgetDialogController.text.trim());
              if (newBudget != null && newBudget > 0) {
                Navigator.pop(ctx);
                _updateMaxBudget(newBudget);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D5C3A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  /// Logout: Hapus status login dan navigasi pushAndRemoveUntil (Modul 4 & 6)
  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('loginData', false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda telah berhasil keluar dari akun.'),
          backgroundColor: Colors.blueGrey,
        ),
      );

      // Modul 4: pushAndRemoveUntil menghapus seluruh history navigation stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  String _formatRupiah(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F2),
      appBar: AppBar(
        title: const Text(
          'Profil Wisatawan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D5C3A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ─── Kartu Informasi Akun User (Modul 4 & 6)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: const Color(0xFF0D5C3A).withOpacity(0.12),
                    child: const Icon(
                      Icons.person,
                      size: 54,
                      color: Color(0xFF0D5C3A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D5C3A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Wisatawan Terverifikasi BajoLand',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0D5C3A),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ─── Statistik Perjalanan & Hive ValueListenable
            ValueListenableBuilder<Box<ItineraryItem>>(
              valueListenable: Hive.box<ItineraryItem>('itineraries').listenable(),
              builder: (context, box, _) {
                final totalItems = box.length;
                double totalSpent = 0.0;
                for (final item in box.values) {
                  totalSpent += item.budget;
                }

                return Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.event_available,
                                color: Color(0xFF0D5C3A), size: 28),
                            const SizedBox(height: 8),
                            Text(
                              '$totalItems',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const Text(
                              'Destinasi Dijadwalkan',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.account_balance_wallet,
                                color: Color(0xFF0D5C3A), size: 28),
                            const SizedBox(height: 8),
                            Text(
                              _formatRupiah(totalSpent),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D5C3A),
                              ),
                            ),
                            const Text(
                              'Alokasi Anggaran',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // ─── Menu Pengaturan Anggaran & Preferensi
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0x150D5C3A),
                      child: Icon(Icons.tune, color: Color(0xFF0D5C3A)),
                    ),
                    title: const Text('Batas Total Anggaran Wisata'),
                    subtitle: Text(_formatRupiah(_maxBudget)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showEditBudgetDialog,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0x150D5C3A),
                      child: Icon(Icons.info_outline, color: Color(0xFF0D5C3A)),
                    ),
                    title: const Text('Tentang BajoLand'),
                    subtitle: const Text('Integrasi Modul 2 - Modul 7 Praktikum TPM'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'BajoLand',
                        applicationVersion: '1.0.0',
                        applicationLegalese:
                            'Aplikasi Perencana Itinerary dan Manajemen Anggaran Wisata di Labuan Bajo.',
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),

            // ─── Tombol Logout (Modul 4 & Modul 6: pushAndRemoveUntil)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Keluar dari Akun?'),
                      content: const Text(
                        'Status sesi login Anda akan direset. Anda harus masuk kembali untuk mengakses jadwal.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Batal'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _handleLogout();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Keluar'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text(
                  'Keluar (Logout)',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

