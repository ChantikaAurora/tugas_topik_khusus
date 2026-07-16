import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../models/report.dart';

class ReportService {
  static Future<Map<String, dynamic>> createReport(Report report) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/reports/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(report.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal membuat laporan: ${response.body}');
    }
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> searchReports(String query, {String? reportType}) async {
    final params = {'query': query, if (reportType != null) 'report_type': reportType};
    final url = Uri.parse('${ApiConfig.baseUrl}/reports/search').replace(queryParameters: params);
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Gagal mencari laporan: ${response.body}');
    }
    final data = jsonDecode(response.body);
    return data['results'];
  }
}
