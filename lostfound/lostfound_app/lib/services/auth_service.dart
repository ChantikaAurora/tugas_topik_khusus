import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_config.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'access_token';
  static const _usernameKey = 'username';

  /// Register akun baru. Backend langsung mengembalikan access_token (auto-login).
  static Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(response.body));
    }

    final data = jsonDecode(response.body);
    await _saveSession(data);
  }

  static Future<void> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(response.body));
    }

    final data = jsonDecode(response.body);
    await _saveSession(data);
  }

  static Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _usernameKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null && token.isNotEmpty;
  }

  static Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  static Future<String?> getUsername() async {
    return _storage.read(key: _usernameKey);
  }

  /// Header siap pakai untuk request yang butuh login, mis:
  /// http.post(url, headers: await AuthService.authHeader());
  static Future<Map<String, String>> authHeader() async {
    final token = await getToken();
    if (token == null) return {};
    return {'Authorization': 'Bearer $token'};
  }

  static Future<void> _saveSession(Map<String, dynamic> data) async {
    final token = data['access_token'] as String;
    final username = data['user']?['username'] as String? ?? '';
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _usernameKey, value: username);
  }

  static String _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded['detail']?.toString() ?? 'Terjadi kesalahan';
    } catch (_) {
      return 'Terjadi kesalahan';
    }
  }
}
