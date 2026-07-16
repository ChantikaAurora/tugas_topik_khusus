import 'package:flutter/material.dart';
import 'screens/create_report_screen.dart';
import 'screens/search_screen.dart';

void main() {
  runApp(const LostFoundApp());
}

class LostFoundApp extends StatelessWidget {
  const LostFoundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lost & Found',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lost & Found Kampus')),
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
          ],
        ),
      ),
    );
  }
}
