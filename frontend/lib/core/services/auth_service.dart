import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'auth_user';
  static const String _keyCustomBaseUrl = 'custom_base_url';

  /// URL Backend Railway Production 24 Jam Online (Tanpa perlu laptop menyala)
  static const String railwayProductionUrl = 'https://skripsi-production-ce547be8.up.railway.app/api';

  /// URL Cloudflare Tunnel cadangan
  static const String cloudflareTunnelUrl = 'https://slow-halifax-ddr-parties.trycloudflare.com/api';

  static String? _cachedBaseUrl;

  /// Inisialisasi awal (dipanggil saat startup di main.dart)
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedBaseUrl = prefs.getString(_keyCustomBaseUrl);
    } catch (_) {}
  }

  /// Daftar kandidat URL backend yang otomatis dicoba saat menghubungkan
  static List<String> get candidateUrls {
    final list = <String>[];

    if (kIsWeb) {
      try {
        final origin = Uri.base.origin;
        if (origin.isNotEmpty && !origin.startsWith('null')) {
          list.add('$origin/api');
        }
      } catch (_) {}
      const webOptions = [
        'https://skripsi-production-ce547be8.up.railway.app/api',
        'https://slow-halifax-ddr-parties.trycloudflare.com/api',
        'http://localhost:8000/api',
        'http://127.0.0.1:8000/api',
      ];
      for (final opt in webOptions) {
        if (!list.contains(opt)) list.add(opt);
      }
      return list;
    }

    if (Platform.isAndroid) {
      // Prioritas Android:
      // 1. Railway Cloud 24 Jam Permanen (tanpa perlu laptop)
      // 2. 127.0.0.1 (USB adb reverse via kabel Tipe-C)
      // 3. Cloudflare Tunnel URL aktif
      // 4. IP Wi-Fi lokal
      const androidOptions = [
        'https://skripsi-production-ce547be8.up.railway.app/api',
        'http://127.0.0.1:8000/api',
        'https://slow-halifax-ddr-parties.trycloudflare.com/api',
        'http://192.168.100.13:8000/api',
        'http://10.0.2.2:8000/api',
      ];
      for (final opt in androidOptions) {
        if (!list.contains(opt)) list.add(opt);
      }
    } else {
      const desktopOptions = [
        'http://127.0.0.1:8000/api',
        'http://localhost:8000/api',
      ];
      for (final opt in desktopOptions) {
        if (!list.contains(opt)) list.add(opt);
      }
    }

    // Jika cloudflareTunnelUrl aktif diisi, jadikan prioritas online cadangan
    if (cloudflareTunnelUrl.trim().isNotEmpty) {
      final cf = cloudflareTunnelUrl.trim();
      if (!list.contains(cf)) list.add(cf);
    }

    if (_cachedBaseUrl != null && _cachedBaseUrl!.trim().isNotEmpty) {
      final cached = _cachedBaseUrl!.trim();
      if (!list.contains(cached)) list.add(cached);
    }
    return list;
  }

  /// Default baseUrl berdasarkan platform
  static String get defaultBaseUrl {
    if (kIsWeb) {
      try {
        final origin = Uri.base.origin;
        if (origin.isNotEmpty && !origin.startsWith('null')) {
          return '$origin/api';
        }
      } catch (_) {}
    }
    return railwayProductionUrl;
  }

  /// Resolves the active base URL dynamically.
  static String get baseUrl {
    if (kIsWeb) {
      try {
        final origin = Uri.base.origin;
        if (origin.isNotEmpty && !origin.startsWith('null')) {
          return '$origin/api';
        }
      } catch (_) {}
    }
    if (_cachedBaseUrl != null && _cachedBaseUrl!.trim().isNotEmpty) {
      return _cachedBaseUrl!.trim();
    }
    return defaultBaseUrl;
  }

  /// Menyimpan URL backend kustom ke SharedPreferences
  static Future<void> setBaseUrl(String newUrl) async {
    String cleanUrl = newUrl.trim();
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      cleanUrl = 'http://$cleanUrl';
    }
    while (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    if (!cleanUrl.endsWith('/api')) {
      cleanUrl = '$cleanUrl/api';
    }
    _cachedBaseUrl = cleanUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCustomBaseUrl, cleanUrl);
  }

  /// Reset URL ke default
  static Future<void> resetBaseUrl() async {
    _cachedBaseUrl = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCustomBaseUrl);
  }

  /// Menguji apakah URL server dapat dihubungi secara real-time
  static Future<bool> testConnection([String? customUrl]) async {
    final target = (customUrl != null && customUrl.trim().isNotEmpty) ? customUrl.trim() : baseUrl;
    String clean = target;
    if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
      clean = 'https://$clean';
    }
    while (clean.endsWith('/')) {
      clean = clean.substring(0, clean.length - 1);
    }
    if (!clean.endsWith('/api')) {
      clean = '$clean/api';
    }

    try {
      final response = await http
          .get(Uri.parse('$clean/ping'))
          .timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      try {
        final response = await http
            .get(Uri.parse('$clean/login'))
            .timeout(const Duration(seconds: 4));
        return response.statusCode < 500;
      } catch (_) {
        return false;
      }
    }
  }

  /// Memformat URL gambar dari server Laravel agar selalu sesuai dengan host backend aktif
  static String formatImageUrl(String? pathOrUrl) {
    if (pathOrUrl == null || pathOrUrl.trim().isEmpty) return '';
    final trimmed = pathOrUrl.trim();
    final serverHost = baseUrl.replaceAll('/api', '');

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      final uri = Uri.tryParse(trimmed);
      if (uri != null) {
        final serverUri = Uri.parse(serverHost);
        if (uri.path.startsWith('/storage/') ||
            uri.host == 'localhost' ||
            uri.host == '127.0.0.1' ||
            uri.host == serverUri.host ||
            uri.host.endsWith('.trycloudflare.com')) {
          return Uri(
            scheme: serverUri.scheme,
            host: serverUri.host,
            port: serverUri.hasPort ? serverUri.port : null,
            path: uri.path,
            query: uri.hasQuery ? uri.query : null,
          ).toString();
        }
      }
      return trimmed;
    }

    final clean = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
    if (clean.startsWith('storage/')) {
      return '$serverHost/$clean';
    }
    return '$serverHost/storage/$clean';
  }

  /// Melakukan login ke backend Laravel dengan auto-fallback endpoint cerdas
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    String? role,
  }) async {
    final cleanUsername = username.trim();
    final cleanPassword = password.trim();

    final targetsToTry = candidateUrls;
    http.Response? finalResponse;
    String? successfulTarget;
    Object? lastError;

    final requestBody = <String, dynamic>{
      'username': cleanUsername,
      'password': cleanPassword,
    };
    if (role != null && role.isNotEmpty) {
      requestBody['role'] = role;
    }

    // Coba kandidat endpoint secara berurutan hingga menemukan server yang aktif
    for (final targetUrl in targetsToTry) {
      try {
        final url = Uri.parse('$targetUrl/login');
        final response = await http
            .post(
              url,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode(requestBody),
            )
            .timeout(const Duration(seconds: 4));

        finalResponse = response;
        successfulTarget = targetUrl;
        break; // Server ditemukan dan merespons!
      } catch (e) {
        lastError = e;
      }
    }

    if (finalResponse == null) {
      return {
        'success': false,
        'isConnectionError': true,
        'message': 'Gagal terhubung ke backend. Pastikan server Laravel aktif (php artisan serve --host=0.0.0.0 --port=8000).',
        'error': lastError?.toString() ?? 'Koneksi gagal',
      };
    }

    // Simpan target yang berhasil agar request berikutnya (dashboard, presensi, dll.) langsung ke URL ini
    if (successfulTarget != null && successfulTarget != _cachedBaseUrl) {
      await setBaseUrl(successfulTarget);
    }

    Map<String, dynamic>? data;
    try {
      data = jsonDecode(finalResponse.body) as Map<String, dynamic>?;
    } catch (_) {}

    if (finalResponse.statusCode >= 200 && finalResponse.statusCode < 300) {
      if (data != null && data['success'] == true && data['data'] != null) {
        final token = data['data']['token'];
        final user = data['data']['user'];
        final actualRole = user?['role']?.toString();

        // Validasi jika tab peran yang dipilih tidak sesuai dengan peran akun pengguna
        if (role != null && role.isNotEmpty && actualRole != null && actualRole != role) {
          const roleLabels = {
            'student': 'Siswa',
            'teacher': 'Guru',
            'field_supervisor': 'DUDI',
            'admin': 'Admin',
          };
          final actualRoleLabel = roleLabels[actualRole] ?? actualRole;
          final expectedRoleLabel = roleLabels[role] ?? role;
          return {
            'success': false,
            'message': 'Akun ini bukan akun $expectedRoleLabel. Akun ini terdaftar sebagai $actualRoleLabel. Silakan pilih peran $actualRoleLabel untuk masuk.',
            'detectedRole': actualRole,
          };
        }

        final prefs = await SharedPreferences.getInstance();
        if (token != null) {
          await prefs.setString(_keyToken, token.toString());
        }
        if (user != null) {
          await prefs.setString(_keyUser, jsonEncode(user));
        }

        return {
          'success': true,
          'message': data['message'] ?? 'Login berhasil.',
          'user': user,
          'token': token,
        };
      }
    }

    // 401 Unauthorized / 403 Forbidden / 422 Unprocessable
    String message = data?['message'] ?? 'Username atau password salah.';
    if (data != null && data['errors'] != null && data['errors'] is Map) {
      final errors = data['errors'] as Map;
      if (errors.isNotEmpty) {
        final firstKey = errors.keys.first;
        final firstVal = errors[firstKey];
        if (firstVal is List && firstVal.isNotEmpty) {
          message = firstVal.first.toString();
        }
      }
    }

    final detectedRole = data?['detected_role']?.toString();

    final result = <String, dynamic>{
      'success': false,
      'message': message,
    };
    if (detectedRole != null) {
      result['detectedRole'] = detectedRole;
    }
    return result;
  }

  /// Get cached auth token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  /// Get cached user data
  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_keyUser);
    if (userStr != null) {
      try {
        return jsonDecode(userStr);
      } catch (_) {}
    }
    return null;
  }

  /// Logout
  static Future<void> logout() async {
    final token = await getToken();
    if (token != null) {
      try {
        final url = Uri.parse('$baseUrl/logout');
        await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 3));
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
  }

  /// Ganti Password Akun Pengguna Aktif (Semua Role: Siswa, Guru, DUDI, Admin)
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final token = await getToken();
    if (token == null) {
      return {
        'success': false,
        'message': 'Sesi Anda telah berakhir. Silakan login kembali.',
      };
    }

    try {
      final url = Uri.parse('$baseUrl/change-password');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': confirmPassword,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'message': data['message'] ?? 'Password berhasil diperbarui.',
        };
      }

      String message = data['message'] ?? 'Gagal mengubah password.';
      if (data['errors'] != null && data['errors'] is Map) {
        final errors = data['errors'] as Map;
        if (errors.isNotEmpty) {
          final firstKey = errors.keys.first;
          final firstVal = errors[firstKey];
          if (firstVal is List && firstVal.isNotEmpty) {
            message = firstVal.first.toString();
          }
        }
      }

      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server: $e',
      };
    }
  }
}
