import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_service.dart';
import '../models/report.dart';

class ReportService {
  /// Upload file foto ke backend, mengembalikan path relatif (photo_url)
  /// yang nanti disimpan di dokumen laporan, misal "/static/uploads/xxx.jpg".
  static Future<String> uploadPhoto(File imageFile) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/upload/photo');
    final request = http.MultipartRequest('POST', url)
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('Gagal mengunggah foto: ${response.body}');
    }
    final data = jsonDecode(response.body);
    return data['photo_url'] as String;
  }

  /// Bangun URL lengkap untuk menampilkan foto dari photo_url relatif
  /// (mis. "/static/uploads/xxx.jpg" -> "http://.../static/uploads/xxx.jpg")
  static String resolvePhotoUrl(String photoUrl) {
    if (photoUrl.startsWith('http')) return photoUrl;
    return '${ApiConfig.baseUrl}$photoUrl';
  }

  static Future<Map<String, dynamic>> createReport(Report report) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/reports/');
    final authHeader = await AuthService.authHeader();
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', ...authHeader},
      body: jsonEncode(report.toJson()),
    );

    if (response.statusCode == 401) {
      throw Exception('Sesi login sudah berakhir, silakan login kembali');
    }
    if (response.statusCode != 200) {
      throw Exception('Gagal membuat laporan: ${response.body}');
    }
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> searchReports(
    String query, {
    String? reportType,
    double? lat,
    double? lon,
    double? radiusKm,
  }) async {
    final params = {
      'query': query,
      if (reportType != null) 'report_type': reportType,
      if (lat != null) 'lat': lat.toString(),
      if (lon != null) 'lon': lon.toString(),
      if (radiusKm != null) 'radius_km': radiusKm.toString(),
    };
    final url = Uri.parse('${ApiConfig.baseUrl}/reports/search').replace(queryParameters: params);
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Gagal mencari laporan: ${response.body}');
    }
    final data = jsonDecode(response.body);
    return data['results'];
  }

  /// Ambil semua laporan milik user yang sedang login.
  static Future<List<dynamic>> getMyReports() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/reports/mine');
    final authHeader = await AuthService.authHeader();
    final response = await http.get(url, headers: authHeader);

    if (response.statusCode == 401) {
      throw Exception('Sesi login sudah berakhir, silakan login kembali');
    }
    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil riwayat laporan: ${response.body}');
    }
    final data = jsonDecode(response.body);
    return data['results'];
  }

  /// Ubah status laporan, mis. tandai sebagai "matched" (sudah ketemu).
  static Future<void> updateReportStatus(String reportId, String status) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/reports/$reportId/status');
    final authHeader = await AuthService.authHeader();
    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json', ...authHeader},
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode == 401) {
      throw Exception('Sesi login sudah berakhir, silakan login kembali');
    }
    if (response.statusCode == 403) {
      throw Exception('Kamu tidak berhak mengubah laporan ini');
    }
    if (response.statusCode != 200) {
      throw Exception('Gagal mengubah status: ${response.body}');
    }
  }
}
