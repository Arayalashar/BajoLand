import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Satu pintu untuk izin, timezone, notifikasi langsung, dan pengingat terjadwal.
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Mencegah plugin diinisialisasi berulang kali selama aplikasi berjalan.
  bool _isInitialized = false;

  /// Inisialisasi plugin notifikasi dan deteksi timezone lokal perangkat
  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    _configureLocalTimezone();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle ketika notifikasi ditekan
      },
    );

    await requestPermissions();
    _isInitialized = true;
  }

  /// Konfigurasi lokasi timezone lokal sesuai offset perangkat (WIB/WITA/WIT/Global)
  void _configureLocalTimezone() {
    final offset = DateTime.now().timeZoneOffset;
    String locationName = 'UTC';

    // Offset UTC+7/8/9 dipetakan ke zona Indonesia; offset lain dicari dari database timezone.
    if (offset.inHours == 7) {
      locationName = 'Asia/Jakarta';
    } else if (offset.inHours == 8) {
      locationName = 'Asia/Makassar'; // Labuan Bajo (WITA)
    } else if (offset.inHours == 9) {
      locationName = 'Asia/Jayapura';
    } else {
      for (final loc in tz.timeZoneDatabase.locations.values) {
        if (loc.currentTimeZone.offset == offset.inMilliseconds) {
          locationName = loc.name;
          break;
        }
      }
    }

    try {
      tz.setLocalLocation(tz.getLocation(locationName));
    } catch (_) {
      // Fallback tetap berjalan aman
    }
  }

  /// Meminta izin notifikasi dan alarm presisi untuk Android 13+ & iOS
  Future<void> requestPermissions() async {
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  /// Menampilkan Notifikasi Langsung (Immediate Notification)
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'bajoland_instant_channel_v2',
      'Notifikasi Langsung BajoLand',
      channelDescription: 'Pemberitahuan instan aktivitas dan jadwal BajoLand',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  /// Menjadwalkan Notifikasi (Scheduled Notification) sesuai tanggal & jam lokal
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    // Pastikan timezone lokal sudah terpasang
    if (tz.local.name == 'UTC') {
      _configureLocalTimezone();
    }

    // Pastikan waktu jadwal di masa depan
    if (scheduledDate.isBefore(DateTime.now())) {
      // Jika waktu sudah lewat, kirim notifikasi langsung sebagai konfirmasi
      await showInstantNotification(id: id, title: title, body: body, payload: payload);
      return;
    }

    // Plugin menerima TZDateTime supaya pengingat mengikuti zona waktu perangkat.
    final tz.TZDateTime tzScheduled =
        tz.TZDateTime.from(scheduledDate, tz.local);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'bajoland_scheduled_channel_v2',
      'Pengingat Jadwal BajoLand',
      channelDescription: 'Pengingat otomatis jadwal keberangkatan wisata Labuan Bajo',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduled,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (_) {
      // Fallback jika exact alarm dibatasi oleh OS Android
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduled,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    }
  }

  /// Membatalkan notifikasi berdasarkan ID
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}
