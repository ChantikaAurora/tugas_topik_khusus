import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/report.dart';
import '../services/report_service.dart';
import 'location_picker_screen.dart';

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  String _reportType = 'hilang';
  bool _isLoading = false;
  double? _latitude;
  double? _longitude;

  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  Future<void> _pickLocationOnMap() async {
    final picked = await Navigator.push<PickedLocation>(
      context,
      MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
    );
    if (picked == null) return;
    setState(() {
      _latitude = picked.latitude;
      _longitude = picked.longitude;
      _locationCtrl.text = picked.address;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1280,
      imageQuality: 80,
    );
    if (picked == null) return;
    setState(() => _selectedImage = File(picked.path));
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Ambil Foto'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // 1. Upload foto dulu (kalau ada) supaya dapat photo_url
      String? photoUrl;
      if (_selectedImage != null) {
        photoUrl = await ReportService.uploadPhoto(_selectedImage!);
      }

      // 2. Kirim laporan lengkap dengan photo_url
      final report = Report(
        title: _titleCtrl.text,
        description: _descCtrl.text,
        category: _categoryCtrl.text,
        location: _locationCtrl.text,
        reportType: _reportType,
        photoUrl: photoUrl,
        latitude: _latitude,
        longitude: _longitude,
      );

      final result = await ReportService.createReport(report);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Laporan berhasil dibuat')),
      );
      Navigator.pop(context);

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
      appBar: AppBar(title: const Text('Buat Laporan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'hilang', label: Text('Barang Hilang')),
                  ButtonSegment(value: 'temuan', label: Text('Barang Temuan')),
                ],
                selected: {_reportType},
                onSelectionChanged: (s) => setState(() => _reportType = s.first),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _showImageSourceSheet,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_a_photo_outlined, size: 36, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Tambah Foto (opsional)', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                ),
              ),
              if (_selectedImage != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _selectedImage = null),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Hapus foto'),
                  ),
                ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Judul'),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
                maxLines: 3,
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryCtrl,
                decoration: const InputDecoration(labelText: 'Kategori (mis: dompet, hp, kunci)'),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationCtrl,
                decoration: InputDecoration(
                  labelText: 'Lokasi',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.map_outlined),
                    tooltip: 'Pilih di peta',
                    onPressed: _pickLocationOnMap,
                  ),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              if (_latitude != null && _longitude != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 14, color: Colors.green.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Koordinat tersimpan',
                        style: TextStyle(fontSize: 12, color: Colors.green.shade600),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Kirim Laporan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
