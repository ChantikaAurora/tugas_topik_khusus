import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import '../services/location_service.dart';

class PickedLocation {
  final double latitude;
  final double longitude;
  final String address;

  PickedLocation({required this.latitude, required this.longitude, required this.address});
}

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  // Default: tengah kota Padang, dipakai kalau lokasi GPS tidak tersedia
  static const _defaultCenter = LatLng(-0.9471, 100.4172);

  final MapController _mapController = MapController();
  LatLng _selected = _defaultCenter;
  bool _isLoadingLocation = true;
  bool _isResolvingAddress = false;

  @override
  void initState() {
    super.initState();
    _useCurrentLocation(moveMap: true);
  }

  Future<void> _useCurrentLocation({bool moveMap = false}) async {
    setState(() => _isLoadingLocation = true);
    final position = await LocationService.getCurrentPosition();
    if (position != null) {
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() => _selected = latLng);
      if (moveMap) _mapController.move(latLng, 16);
    } else if (mounted && !moveMap) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa mengambil lokasi saat ini. Pastikan izin lokasi & GPS aktif.')),
      );
    }
    if (mounted) setState(() => _isLoadingLocation = false);
  }

  Future<String> _reverseGeocode(LatLng point) async {
    try {
      final placemarks = await placemarkFromCoordinates(point.latitude, point.longitude);
      if (placemarks.isEmpty) return '';
      final p = placemarks.first;
      final parts = [p.street, p.subLocality, p.locality]
          .where((s) => s != null && s.isNotEmpty)
          .toList();
      return parts.join(', ');
    } catch (_) {
      return '';
    }
  }

  Future<void> _confirmSelection() async {
    setState(() => _isResolvingAddress = true);
    final address = await _reverseGeocode(_selected);
    if (!mounted) return;
    setState(() => _isResolvingAddress = false);

    Navigator.pop(
      context,
      PickedLocation(
        latitude: _selected.latitude,
        longitude: _selected.longitude,
        address: address.isNotEmpty
            ? address
            : '${_selected.latitude.toStringAsFixed(5)}, ${_selected.longitude.toStringAsFixed(5)}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Lokasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Gunakan lokasi saat ini',
            onPressed: () => _useCurrentLocation(moveMap: true),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selected,
              initialZoom: 15,
              onTap: (tapPosition, point) => setState(() => _selected = point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.lostfound_app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selected,
                    width: 44,
                    height: 44,
                    child: const Icon(Icons.location_pin, size: 44, color: Colors.red),
                  ),
                ],
              ),
            ],
          ),
          if (_isLoadingLocation)
            const Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 10),
                        Text('Mencari lokasimu...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Text(
                      'Ketuk peta untuk menandai lokasi barang',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _isResolvingAddress ? null : _confirmSelection,
                  icon: _isResolvingAddress
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check),
                  label: const Text('Gunakan Lokasi Ini'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
