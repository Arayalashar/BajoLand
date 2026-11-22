import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Helper formatting tanggal yang aman terhadap Hot Reload dan LocaleDataException
class AppDateFormatter {
  static bool _initialized = false;

  /// Memastikan locale bahasa Indonesia terdaftar
  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    try {
      await initializeDateFormatting('id_ID', null);
      await initializeDateFormatting('id', null);
      _initialized = true;
    } catch (_) {
      // Abaikan jika sudah diinisialisasi atau berjalan di environment terbatas
    }
  }

  /// Format tanggal & jam lengkap (contoh: 21 Nov 2026, 14:30)
  static String formatFull(DateTime dateTime) {
    try {
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dateTime);
    } catch (_) {
      try {
        return DateFormat('dd MMM yyyy, HH:mm', 'id').format(dateTime);
      } catch (_) {
        try {
          return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
        } catch (_) {
          return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} '
              '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
        }
      }
    }
  }

  /// Format tanggal dengan hari (contoh: Sab, 21 Nov 2026)
  static String formatDateWithDay(DateTime dateTime) {
    try {
      return DateFormat('EEE, d MMM yyyy', 'id_ID').format(dateTime);
    } catch (_) {
      try {
        return DateFormat('EEE, d MMM yyyy', 'id').format(dateTime);
      } catch (_) {
        try {
          return DateFormat('EEE, d MMM yyyy').format(dateTime);
        } catch (_) {
          return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
        }
      }
    }
  }

  /// Format jam:menit (contoh: 14:30)
  static String formatTime(DateTime dateTime) {
    try {
      return DateFormat('HH:mm').format(dateTime);
    } catch (_) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
