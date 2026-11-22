import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/itinerary_item.dart';
import 'screens/login_screen.dart';
import 'screens/root_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_palette.dart';
import 'utils/date_formatter.dart';

void main() async {
  // 1. Memastikan binding Flutter siap sebelum inisialisasi async
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi locale formatting Indonesia untuk DateFormat
  await AppDateFormatter.ensureInitialized();

  // 2. Inisialisasi Database NoSQL Lokal Hive (Modul 6)
  await Hive.initFlutter();
  Hive.registerAdapter(ItineraryItemAdapter());
  await Hive.openBox<ItineraryItem>('itineraries');

  // 3. Inisialisasi Layanan Notifikasi Lokal & Timezone (Modul 7)
  await NotificationService.instance.initialize();

  // 4. Periksa sesi login yang tersimpan di SharedPreferences (Modul 6)
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('loginData') ?? false;
  final String savedName = prefs.getString('userName') ?? 'Wisatawan Bajo';

  // 5. Konfigurasi status bar dan navigation bar sistem (sesuai design system)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppPalette.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(BajoLandApp(isLoggedIn: isLoggedIn, userName: savedName));
}

/// Root Widget Aplikasi BajoLand (Menggunakan Design System BajoLand / Bookify)
class BajoLandApp extends StatelessWidget {
  final bool isLoggedIn;
  final String userName;

  const BajoLandApp({
    super.key,
    required this.isLoggedIn,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'BajoLand',
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.fadeIn,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppPalette.background,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: AppPalette.primary,
          onPrimary: AppPalette.onPrimary,
          secondary: AppPalette.primaryHover,
          onSecondary: AppPalette.onPrimary,
          error: AppPalette.error,
          onError: Colors.white,
          surface: AppPalette.surface,
          onSurface: AppPalette.textPrimary,
        ),
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ).apply(
          bodyColor: AppPalette.textPrimary,
          displayColor: AppPalette.textPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppPalette.surface,
          foregroundColor: AppPalette.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: AppPalette.textPrimary,
          contentTextStyle: TextStyle(color: Colors.white, fontSize: 13),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppPalette.radiusMd),
        ),
      ),
      home: isLoggedIn ? RootScreen(userName: userName) : const LoginScreen(),
    );
  }
}
