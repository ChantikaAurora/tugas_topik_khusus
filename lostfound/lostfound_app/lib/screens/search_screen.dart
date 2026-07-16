import 'package:flutter/material.dart';
import '../services/report_service.dart';
import '../services/location_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _queryCtrl = TextEditingController();
  List<dynamic> _results = [];
  bool _isLoading = false;
  bool _nearMeEnabled = false;
  double _radiusKm = 5;

  Future<void> _search() async {
    if (_queryCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      double? lat;
      double? lon;

      if (_nearMeEnabled) {
        final position = await LocationService.getCurrentPosition();
        if (position == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak bisa mengambil lokasimu. Pastikan izin lokasi & GPS aktif.')),
          );
        } else {
          lat = position.latitude;
          lon = position.longitude;
        }
      }

      final results = await ReportService.searchReports(
        _queryCtrl.text,
        lat: lat,
        lon: lon,
        radiusKm: lat != null ? _radiusKm : null,
      );
      setState(() => _results = results);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cari Barang')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Cari mis: dompet coklat',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _search, child: const Text('Cari')),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Cari di dekat saya'),
              subtitle: _nearMeEnabled ? Text('Radius: ${_radiusKm.toStringAsFixed(0)} km') : null,
              value: _nearMeEnabled,
              onChanged: (v) => setState(() => _nearMeEnabled = v),
            ),
            if (_nearMeEnabled)
              Slider(
                value: _radiusKm,
                min: 1,
                max: 20,
                divisions: 19,
                label: '${_radiusKm.toStringAsFixed(0)} km',
                onChanged: (v) => setState(() => _radiusKm = v),
              ),
            const SizedBox(height: 8),
            if (_isLoading) const CircularProgressIndicator(),
            if (!_isLoading)
              Expanded(
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final item = _results[index];
                    final photoUrl = item['photo_url'] as String?;
                    final distanceKm = item['distance_km'];
                    final subtitleText = '${item['description']}\nLokasi: ${item['location']}'
                        '${distanceKm != null ? '\n📍 ${distanceKm.toStringAsFixed(1)} km dari kamu' : ''}';
                    return Card(
                      child: ListTile(
                        leading: SizedBox(
                          width: 56,
                          height: 56,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: (photoUrl != null && photoUrl.isNotEmpty)
                                ? Image.network(
                                    ReportService.resolvePhotoUrl(photoUrl),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.broken_image, color: Colors.grey),
                                    ),
                                    loadingBuilder: (context, child, progress) {
                                      if (progress == null) return child;
                                      return Container(
                                        color: Colors.grey.shade200,
                                        child: const Center(
                                          child: SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                                  ),
                          ),
                        ),
                        title: Text(item['title'] ?? ''),
                        subtitle: Text(subtitleText),
                        trailing: Chip(
                          label: Text(item['report_type'] ?? ''),
                          backgroundColor: item['report_type'] == 'hilang'
                              ? Colors.red.shade100
                              : Colors.green.shade100,
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
