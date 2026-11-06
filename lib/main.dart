import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/itinerary_item.dart';
import 'screens/login_screen.dart';
import 'screens/root_screen.dart';
import 'services/notification_service.dart';

void main() async {
  // 1. Memastikan binding Flutter siap sebelum inisialisasi async
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi locale formatting Indonesia untuk DateFormat
  await initializeDateFormatting('id_ID', null);

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

  // 5. Konfigurasi status bar dan navigation bar sistem
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    BajoLandApp(
      isLoggedIn: isLoggedIn,
      userName: savedName,
    ),
  );
}

/// Root Widget Aplikasi BajoLand (Modul 2: MaterialApp, Theme, ColorScheme)
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
    const primaryColor = Color(0xFF0D5C3A);

    return MaterialApp(
      title: 'BajoLand',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
        ),
        scaffoldBackgroundColor: const Color(0xFFF9F7F2),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          Theme.of(context).textTheme,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: primaryColor,
          elevation: 0.5,
          centerTitle: false,
        ),
      ),
      // Alur Awal: Jika sudah login langsung ke RootScreen, jika belum ke LoginScreen
      home: isLoggedIn
          ? RootScreen(userName: userName)
          : const LoginScreen(),
    );
  }
}
