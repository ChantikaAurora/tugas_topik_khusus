/// Ganti baseUrl sesuai platform yang kamu pakai untuk testing:
/// - Android Emulator  -> http://10.0.2.2:8000
/// - iOS Simulator     -> http://127.0.0.1:8000
/// - Device fisik      -> http://<IP-komputer-kamu>:8000
class ApiConfig {
  static const String baseUrl = "http://127.0.0.1:8000";
}
