# BajoLand 🏝️
**Aplikasi Perencana Itinerary dan Manajemen Anggaran Wisata di Labuan Bajo**  
*Platform: Mobile (Android / iOS) menggunakan Flutter*

---

## 📌 Ringkasan Proyek
**BajoLand** adalah aplikasi mobile berbasis Flutter yang dirancang untuk membantu wisatawan merencanakan jadwal perjalanan (*itinerary*), mengelola batas anggaran wisata (*budget tracker*), mengecek jarak lokasi wisata secara langsung (*Location-Based Services*), dan mendapatkan pengingat jadwal keberangkatan di kawasan wisata Labuan Bajo, Taman Nasional Komodo, Nusa Tenggara Timur.

Proyek ini mengintegrasikan seluruh materi praktikum **Teknologi dan Pemrograman Mobile (Modul 2 – Modul 7)**:
1. **Modul 2 (Widget):** `MaterialApp`, `Scaffold`, `AppBar`, `Container`, `Stack`, `ListView.builder`, `GridView.builder`, `SingleChildScrollView`.
2. **Modul 3 (State & Data):** `StatefulWidget`, `setState`, `TextEditingController`, *Conditional Rendering*, *Dynamic Styling* (border merah error & peringatan overbudget), dan Model Class.
3. **Modul 4 (Navigation):** `Navigator.push`, `Navigator.pop`, `Navigator.pushReplacement`, `Navigator.pushAndRemoveUntil`, Passing Data via Constructor, dan `BottomNavigationBar`.
4. **Modul 5 (HTTP Request):** Package `http`, `Future`, `async-await`, `jsonDecode`, `try-catch`, `CircularProgressIndicator`, `ApiService` (`static` method), dan Model `TravelGearItem.fromJson()`.
5. **Modul 6 (Local Storage):**
   - `SharedPreferences`: Menyimpan sesi autentikasi (`loginData`), nama pengguna (`userName`), dan nominal batas anggaran (`maxBudget`).
   - `Hive`: Menyimpan daftar itinerary dan pengeluaran (`ItineraryItem`) secara permanen dengan operasi CRUD (`add`, `putAt`, `deleteAt`) dan reaktif (`ValueListenableBuilder`).
6. **Modul 7 (Notification & LBS):**
   - `flutter_local_notifications`: *Immediate Notification* saat jadwal disimpan, dan *Scheduled Notification* sesuai tanggal & jam keberangkatan.
   - `geolocator`: Mengambil koordinat GPS pengguna, menghitung jarak ke 5 destinasi Labuan Bajo (`Pulau Padar`, `Pink Beach`, `Pulau Komodo`, `Dermaga Kampung Ujung`, `Bandara Komodo`), mengurutkan dari terdekat, dan menandai lokasi $< 500\text{ m}$.

---

## 📂 Struktur Direktori Proyek

```text
lib/
├── api/
│   └── api_service.dart              # Modul 5: Class ApiService (static getTravelGears & getSingleGear)
├── data/
│   └── bajo_locations.dart           # Modul 3 & 7: Model LocationData & konstanta koordinat Labuan Bajo
├── models/
│   ├── user_model.dart               # Modul 3: Model User untuk autentikasi login
│   ├── gear_model.dart               # Modul 3 & 5: Model TravelGearItem + factory fromJson()
│   ├── itinerary_item.dart           # Modul 3 & 6: Model HiveObject untuk jadwal & anggaran
│   └── itinerary_item.g.dart         # Modul 6: File TypeAdapter Hive
├── screens/
│   ├── login_screen.dart             # Modul 2, 3, 4, 6: UI Login, Error Border, SharedPreferences
│   ├── root_screen.dart              # Modul 4: BottomNavigationBar pengatur halaman utama
│   ├── explore_screen.dart           # Modul 2, 4, 5: Highlight Bajo & GridView katalog API
│   ├── detail_gear_screen.dart       # Modul 2, 4, 5: Halaman detail item API via passing ID
│   ├── itinerary_screen.dart         # Modul 2, 3, 6: Kalkulator anggaran & ValueListenableBuilder Hive
│   ├── add_itinerary_screen.dart     # Modul 3, 6, 7: Form Create/Update Hive + Trigger Notifikasi
│   ├── lbs_screen.dart               # Modul 7: Radar GPS Geolocator & Reminder Lokasi Bajo
│   └── profile_screen.dart           # Modul 4, 6: Profil user & Logout (pushAndRemoveUntil)
├── services/
│   └── notification_service.dart     # Modul 7: Singleton FlutterLocalNotificationsPlugin + Timezone
└── main.dart                         # Inisialisasi WidgetsFlutterBinding, Hive, Notification, MaterialApp
```

---

## 🚀 Cara Menjalankan Aplikasi

1. Pastikan Flutter SDK sudah terpasang di sistem Anda.
2. Unduh dependencies yang dibutuhkan:
   ```powershell
   flutter pub get
   ```
3. Jalankan aplikasi pada perangkat atau emulator:
   ```powershell
   flutter run
   ```

### 🔑 Akun Demo Login:
- **Username:** `arya` | **Password:** `123`
- *(Atau gunakan username apa pun dengan password apa pun untuk pengujian praktikum)*
