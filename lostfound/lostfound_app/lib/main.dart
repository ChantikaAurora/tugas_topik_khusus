import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/create_report_screen.dart';
import 'screens/search_screen.dart';
import 'screens/login_screen.dart';
import 'screens/my_reports_screen.dart';
import 'services/auth_service.dart';
import 'services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Membaca konfigurasi dari android/app/google-services.json (Android) atau
  // ios/Runner/GoogleService-Info.plist (iOS) yang sudah kamu tambahkan sendiri
  // dari Firebase Console. Lihat catatan setup di push_notification_service.dart.
  await Firebase.initializeApp();
  await PushNotificationService.initialize();
  runApp(const LostFoundApp());
}

class LostFoundApp extends StatelessWidget {
  const LostFoundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lost & Found',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const AuthGate(),
    );
  }
}

/// Widget gerbang: cek dulu apakah user sudah login sebelum menampilkan
/// HomeScreen. Kalau belum, arahkan ke LoginScreen.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final loggedIn = snapshot.data == true;
        if (loggedIn) {
          // Daftarkan ulang device token tiap app dibuka -- token FCM bisa berubah
          // (mis. setelah reinstall), jadi backend perlu selalu punya token terbaru.
          PushNotificationService.registerDeviceToken();
        }
        return loggedIn ? const HomeScreen() : const LoginScreen();
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthService.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lost & Found Kampus'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Buat Laporan'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateReportScreen()),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Cari Barang'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.history),
              label: const Text('Laporan Saya'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyReportsScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
