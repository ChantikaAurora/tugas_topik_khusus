import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_service.dart';

/// Handler untuk pesan yang masuk saat app benar-benar tertutup (background/terminated).
/// Harus berupa top-level function (bukan method di dalam class) karena dijalankan
/// di isolate terpisah oleh Firebase.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Tidak perlu apa-apa di sini -- FCM otomatis menampilkan notifikasi
  // system tray untuk pesan tipe "notification" saat app di background/terminated.
}

class PushNotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'match_notifications', // id
    'Notifikasi Match', // nama yang terlihat di pengaturan notifikasi HP
    description: 'Notifikasi saat ada laporan yang cocok dengan laporanmu',
    importance: Importance.high,
  );

  /// Panggil ini sekali saat app start (setelah Firebase.initializeApp()).
  static Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Setup local notifications (dipakai untuk tampilkan popup saat app foreground,
    // karena FCM tidak otomatis menampilkan notifikasi kalau app sedang dibuka)
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _localNotifications.initialize(initSettings);
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // Minta izin notifikasi (wajib di iOS, dan Android 13+)
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Tampilkan notifikasi manual saat app sedang dibuka (foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    });
  }

  /// Panggil ini setelah user berhasil login/register: ambil FCM token
  /// device ini, lalu kirim ke backend supaya bisa dipakai kirim push nanti.
  static Future<void> registerDeviceToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      final url = Uri.parse('${ApiConfig.baseUrl}/auth/device-token');
      final authHeader = await AuthService.authHeader();
      await http.post(
        url,
        headers: {'Content-Type': 'application/json', ...authHeader},
        body: jsonEncode({'device_token': token}),
      );
    } catch (e) {
      // Gagal daftar device token tidak boleh menghentikan alur login,
      // jadi cukup di-print saja untuk debugging.
      // ignore: avoid_print
      print('Gagal mendaftarkan device token: $e');
    }
  }
}
