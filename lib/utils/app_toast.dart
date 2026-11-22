import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_palette.dart';

enum ToastType { success, error, info, warning }

/// Sistem Notifikasi Toast & Feedback SnackBar BajoLand
/// Dibuat rapi, berdurasi singkat (1.8s), dan konsisten dengan design system
class AppToast {
  static void show({
    required String title,
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(milliseconds: 1800),
  }) {
    Color iconColor;
    Color iconBg;
    IconData icon;
    Color borderColor;

    switch (type) {
      case ToastType.success:
        iconColor = AppPalette.success;
        iconBg = const Color(0xFFDCFCE7);
        icon = Icons.check_circle_rounded;
        borderColor = const Color(0xFFBBF7D0);
        break;
      case ToastType.error:
        iconColor = AppPalette.error;
        iconBg = const Color(0xFFFEE2E2);
        icon = Icons.error_rounded;
        borderColor = const Color(0xFFFECACA);
        break;
      case ToastType.warning:
        iconColor = const Color(0xFFD97706);
        iconBg = const Color(0xFFFEF3C7);
        icon = Icons.warning_rounded;
        borderColor = const Color(0xFFFDE68A);
        break;
      case ToastType.info:
        iconColor = AppPalette.primary;
        iconBg = AppPalette.primarySubtle;
        icon = Icons.info_rounded;
        borderColor = AppPalette.border;
        break;
    }

    // Tutup snackbar sebelumnya jika masih ada agar tidak menumpuk
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    Get.rawSnackbar(
      snackPosition: SnackPosition.TOP,
      duration: duration,
      animationDuration: const Duration(milliseconds: 240),
      backgroundColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      messageText: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppPalette.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x180B1220),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppPalette.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void success(String title, String message) =>
      show(title: title, message: message, type: ToastType.success);

  static void error(String title, String message) =>
      show(title: title, message: message, type: ToastType.error);

  static void info(String title, String message) =>
      show(title: title, message: message, type: ToastType.info);

  static void warning(String title, String message) =>
      show(title: title, message: message, type: ToastType.warning);
}
