import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Token visual bersama agar warna, jarak, radius, bayangan, dan teks konsisten.
abstract final class AppPalette {
  // Warna utama, latar, permukaan, teks, dan status dipakai lintas halaman.
  static const primary = Color(0xFF1A5FFF);
  static const primaryHover = Color(0xFF1550DB);
  static const primarySubtle = Color(0xFFEBF1FF);
  static const onPrimary = Color(0xFFFFFFFF);

  static const accentGold = Color(0xFFF5B301); // Rating stars only

  static const background = Color(0xFFF4F6FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF0F3F8);

  static const textPrimary = Color(0xFF0B1220);
  static const textSecondary = Color(0xFF64748B);

  static const border = Color(0xFFE6EAF0);

  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFDC2626);

  // Backward-compatibility aliases if any old code references them
  static const deepGreen = primary;
  static const forest = primary;
  static const sage = textSecondary;
  static const mist = primarySubtle;
  static const ivory = background;

  // Semua radius memakai logical pixel: 8/12 untuk elemen kecil, 16/20 untuk kartu,
  // dan 9999 untuk bentuk pil. Gunakan token ini agar bentuk UI seragam.
  // Gunakan token ini alih-alih angka radius baru agar bentuk UI seragam.
  static const radiusSm = BorderRadius.all(Radius.circular(8));
  static const radiusMd = BorderRadius.all(Radius.circular(12));
  static const radiusLg = BorderRadius.all(Radius.circular(16));
  static const radiusXl = BorderRadius.all(Radius.circular(20));
  static const radiusFull = BorderRadius.all(Radius.circular(9999));

  // Skala jarak bertahap dalam logical pixel untuk padding dan sela antar-widget.
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 20.0;
  static const double spacingXl = 24.0;
  static const double spacing2xl = 32.0;
  static const double spacing3xl = 48.0;

  // Bayangan lembut untuk mengangkat kartu dari latar tanpa garis tebal.
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0A0B1220), // rgba(11,18,32,0.04)
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color(0x0D0B1220), // rgba(11,18,32,0.05)
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> shadowCard = cardShadow;

  static const List<BoxShadow> haloShadow = [
    BoxShadow(
      color: Color(0x201A5FFF),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  // Helper tipografi: h1-h3 untuk judul, bodyMd untuk isi, caption/labelXs untuk teks kecil.
  static TextStyle h1({Color color = textPrimary}) => GoogleFonts.inter(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.52, // -0.02em
        color: color,
      );

  static TextStyle h2({Color color = textPrimary}) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: -0.16, // -0.01em
        color: color,
      );

  static TextStyle h3({Color color = textPrimary}) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: color,
      );

  static TextStyle bodyMd({Color color = textSecondary}) => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: color,
      );

  static TextStyle caption({Color color = textSecondary}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.33,
        color: color,
      );

  static TextStyle labelXs({Color color = textSecondary}) => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.45,
        color: color,
      );

  static TextStyle wordmark({Color color = primary}) => GoogleFonts.inter(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.52,
        color: color,
      );
}
