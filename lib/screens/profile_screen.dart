import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/itinerary_item.dart';
import '../theme/app_palette.dart';
import 'login_screen.dart';

/// Halaman Profil, Pengaturan Anggaran & Logout (Modul 4 & Modul 6)
class ProfileScreen extends StatefulWidget {
  final String userName;

  const ProfileScreen({super.key, required this.userName});

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
          backgroundColor: Color(0xFF375534),
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
              final newBudget = double.tryParse(
                _budgetDialogController.text.trim(),
              );
              if (newBudget != null && newBudget > 0) {
                Navigator.pop(ctx);
                _updateMaxBudget(newBudget);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF375534),
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

      Get.offAll(() => const LoginScreen());
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

  Widget _profileStat({
    required IconData icon,
    required String value,
    required String label,
    bool compactValue = false,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppPalette.deepGreen.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppPalette.ivory.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: AppPalette.forest),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compactValue ? 14 : 20,
                    fontWeight: FontWeight.bold,
                    color: AppPalette.deepGreen,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3EED4),
      appBar: AppBar(
        title: const Text(
          'Profil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppPalette.forest,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppPalette.forest,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppPalette.forest, AppPalette.deepGreen],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppPalette.deepGreen.withOpacity(0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white.withOpacity(0.16),
                    child: Text(
                      widget.userName.trim().isEmpty
                          ? '?'
                          : widget.userName.trim()[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo,',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.76),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Siap menjelajah Labuan Bajo?',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.82),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.waves_rounded,
                    color: Colors.white.withOpacity(0.34),
                    size: 34,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ─── Statistik Perjalanan & Hive ValueListenable
            ValueListenableBuilder<Box<ItineraryItem>>(
              valueListenable: Hive.box<ItineraryItem>('itineraries')
                  .listenable(),
              builder: (context, box, _) {
                final totalItems = box.length;
                double totalSpent = 0.0;
                for (final item in box.values) {
                  totalSpent += item.budget;
                }

                return Row(
                  children: [
                    Expanded(
                      child: _profileStat(
                        icon: Icons.event_note_rounded,
                        value: '$totalItems',
                        label: 'Rencana tersimpan',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _profileStat(
                        icon: Icons.account_balance_wallet_rounded,
                        value: _formatRupiah(totalSpent),
                        label: 'Dana terencana',
                        compactValue: true,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(bottom: 10, left: 2),
                child: Text(
                  'Pengaturan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppPalette.deepGreen,
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppPalette.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppPalette.deepGreen.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0x1F6B9071),
                      child: Icon(
                        Icons.savings_outlined,
                        color: AppPalette.forest,
                      ),
                    ),
                    title: const Text(
                      'Batas anggaran',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppPalette.deepGreen,
                      ),
                    ),
                    subtitle: Text(_formatRupiah(_maxBudget)),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppPalette.sage,
                    ),
                    onTap: _showEditBudgetDialog,
                  ),
                  Divider(
                    height: 1,
                    indent: 72,
                    endIndent: 16,
                    color: AppPalette.mist.withOpacity(0.55),
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0x1F6B9071),
                      child: Icon(
                        Icons.info_outline_rounded,
                        color: AppPalette.forest,
                      ),
                    ),
                    title: const Text(
                      'Tentang aplikasi',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppPalette.deepGreen,
                      ),
                    ),
                    subtitle: const Text('Versi dan informasi BajoLand'),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppPalette.sage,
                    ),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'BajoLand',
                        applicationVersion: '1.0.0',
                        applicationLegalese:
                            'Teman merencanakan perjalanan di Labuan Bajo.',
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // ─── Tombol Logout (Modul 4 & Modul 6: pushAndRemoveUntil)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Keluar dari akun?'),
                      content: const Text(
                        'Kamu perlu masuk lagi untuk melihat rencana perjalananmu.',
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
                            backgroundColor: const Color(0xFFB5473C),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Keluar'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Keluar dari akun'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB5473C),
                  backgroundColor: const Color(0xFFFFF4F2),
                  side: const BorderSide(color: Color(0xFFE8BDB7)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
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
