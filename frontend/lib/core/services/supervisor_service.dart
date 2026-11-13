import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// Service untuk menangani seluruh interaksi API Pembimbing Lapangan/DUDI
/// dengan backend Laravel 'monitoring-pkl-app' (prefix: /api/supervisor)
class SupervisorService {
  /// Helper untuk menyusun header autentikasi HTTP dengan Bearer Token
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 7.1 DASHBOARD & SISWA BIMBINGAN
  // ─────────────────────────────────────────────────────────────────────────────

  /// GET /api/supervisor/dashboard
  /// Statistik DUDI: total siswa aktif, presensi hari ini, logbook pending
  static Future<Map<String, dynamic>?> getDashboard() async {
    final url = Uri.parse('${AuthService.baseUrl}/supervisor/dashboard');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>?;
        }
      }
    } catch (_) {}
    return null;
  }

  /// GET /api/supervisor/students
  /// Daftar siswa PKL yang ditempatkan di instansi pembimbing
  static Future<List<Map<String, dynamic>>> getStudents() async {
    final url = Uri.parse('${AuthService.baseUrl}/supervisor/students');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final list = data['data']['students'] as List<dynamic>?;
          if (list != null) {
            return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          }
        }
      }
    } catch (_) {}
    return [];
  }

  /// GET /api/supervisor/students/{id}
  /// Detail siswa PKL yang dibimbing
  static Future<Map<String, dynamic>?> getStudentDetail(int id) async {
    final url = Uri.parse('${AuthService.baseUrl}/supervisor/students/$id');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Map<String, dynamic>.from(data['data'] as Map);
        }
      }
    } catch (_) {}
    return null;
  }

  /// GET /api/supervisor/students/{id}/assessment
  /// Mengambil data penilaian siswa oleh DUDI
  static Future<Map<String, dynamic>?> getAssessment(int studentId) async {
    final url = Uri.parse('${AuthService.baseUrl}/supervisor/students/$studentId/assessment');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Map<String, dynamic>.from(data['data'] as Map);
        }
      }
    } catch (_) {}
    return null;
  }

  /// POST /api/supervisor/students/{id}/assessment
  /// Menyimpan penilaian siswa oleh DUDI (Indikator 1-4 dan total skor)
  static Future<Map<String, dynamic>> saveAssessment({
    required int studentId,
    required double dudiScore,
    required Map<String, dynamic> components,
    String? notes,
  }) async {
    final url = Uri.parse('${AuthService.baseUrl}/supervisor/students/$studentId/assessment');
    try {
      final headers = await _getHeaders();
      final body = jsonEncode({
        'dudi_score': dudiScore,
        'dudi_components': components,
        'dudi_notes': notes ?? '',
      });

      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 12));

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Penilaian berhasil disimpan',
          'data': data['data'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Gagal menyimpan penilaian (Status ${response.statusCode})',
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 7.2 MANAJEMEN LOKASI PKL OLEH DUDI (locations)
  // ─────────────────────────────────────────────────────────────────────────────

  /// GET /api/supervisor/locations
  /// Menampilkan daftar lokasi PKL yang terafiliasi dengan pembimbing lapangan
  static Future<List<Map<String, dynamic>>> getLocations() async {
    final url = Uri.parse('${AuthService.baseUrl}/supervisor/locations');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final list = data['data']['locations'] as List<dynamic>?;
          if (list != null) {
            return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          }
        }
      }
    } catch (_) {}
    return [];
  }

  /// GET /api/supervisor/locations/{id}
  /// Menampilkan detail lokasi milik pembimbing
  static Future<Map<String, dynamic>?> getLocationDetail(int id) async {
    final url = Uri.parse('${AuthService.baseUrl}/supervisor/locations/$id');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Map<String, dynamic>.from(data['data'] as Map);
        }
      }
    } catch (_) {}
    return null;
  }

  /// POST /api/supervisor/locations
  /// Mendaftarkan lokasi PKL baru dan menghubungkannya dengan akun pembimbing.
  /// Body: name, address, latitude, longitude, radius (min 10), check_in_time, check_out_time, etc.
  static Future<Map<String, dynamic>> createLocation({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    required int radius,
    String? checkInStart,
    String? checkInTime,
    String? checkOutTime,
    String? checkOutEnd,
  }) async {
    final url = Uri.parse('${AuthService.baseUrl}/supervisor/locations');
    try {
      final headers = await _getHeaders();
      final body = {
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
        if (checkInStart != null) 'check_in_start': checkInStart,
        if (checkInTime != null) 'check_in_time': checkInTime,
        if (checkOutTime != null) 'check_out_time': checkOutTime,
        if (checkOutEnd != null) 'check_out_end': checkOutEnd,
      };

      final response = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'message': data['message'] ?? 'Lokasi PKL berhasil didaftarkan.',
          'data': data['data'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Gagal mendaftarkan lokasi PKL.',
        'errors': data['errors'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server ($e)',
      };
    }
  }

  /// PUT /api/supervisor/locations/{id}
  /// Memperbarui koordinat, alamat, radius geofencing, atau jam kerja kantor DUDI
  static Future<Map<String, dynamic>> updateLocation({
    required int id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    int? radius,
    String? checkInStart,
    String? checkInTime,
    String? checkOutTime,
    String? checkOutEnd,
  }) async {
    final url = Uri.parse('${AuthService.baseUrl}/supervisor/locations/$id');
    try {
      final headers = await _getHeaders();
      final Map<String, dynamic> body = {};
      if (name != null) body['name'] = name;
      if (address != null) body['address'] = address;
      if (latitude != null) body['latitude'] = latitude;
      if (longitude != null) body['longitude'] = longitude;
      if (radius != null) body['radius'] = radius;
      if (checkInStart != null) body['check_in_start'] = checkInStart;
      if (checkInTime != null) body['check_in_time'] = checkInTime;
      if (checkOutTime != null) body['check_out_time'] = checkOutTime;
      if (checkOutEnd != null) body['check_out_end'] = checkOutEnd;

      final response = await http
          .put(
            url,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'message': data['message'] ?? 'Lokasi PKL berhasil diperbarui.',
          'data': data['data'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Gagal memperbarui lokasi PKL.',
        'errors': data['errors'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server ($e)',
      };
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 7.3 VERIFIKASI LOGBOOK (Journals)
  // ─────────────────────────────────────────────────────────────────────────────

  /// GET /api/supervisor/logbooks
  /// Menampilkan daftar logbook siswa bimbingan. Filter: status (submitted, approved, rejected)
  static Future<List<Map<String, dynamic>>> getLogbooks({String? status, int page = 1}) async {
    String query = 'page=$page';
    if (status != null && status.isNotEmpty) {
      query += '&status=$status';
    }
    final url = Uri.parse('${AuthService.baseUrl}/supervisor/logbooks?$query');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final list = data['data']['journals'] as List<dynamic>?;
          if (list != null) {
            return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          }
        }
      }
    } catch (_) {}
    return [];
  }

  /// GET /api/supervisor/logbooks/{id}
  /// Detail logbook, lampiran foto pekerjaan, dan riwayat verifikasi
  static Future<Map<String, dynamic>?> getLogbookDetail(int id) async {
    final url = Uri.parse('${AuthService.baseUrl}/supervisor/logbooks/$id');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Map<String, dynamic>.from(data['data'] as Map);
        }
      }
    } catch (_) {}
    return null;
  }

  /// POST /api/supervisor/logbooks/{id}/approve
  /// Menyetujui logbook (status: approved, verified_at, verified_by, comment optional)
  static Future<Map<String, dynamic>> approveLogbook({
    required int id,
    String? comment,
  }) async {
    final url = Uri.parse('${AuthService.baseUrl}/supervisor/logbooks/$id/approve');
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode({
              if (comment != null && comment.isNotEmpty) 'comment': comment,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'message': data['message'] ?? 'Jurnal/Logbook berhasil disetujui.',
          'data': data['data'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Gagal menyetujui logbook.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server ($e)',
      };
    }
  }

  /// POST /api/supervisor/logbooks/{id}/reject
  /// Menolak logbook dan meminta revisi (status: rejected, comment berisi alasan)
  static Future<Map<String, dynamic>> rejectLogbook({
    required int id,
    required String comment,
  }) async {
    final url = Uri.parse('${AuthService.baseUrl}/supervisor/logbooks/$id/reject');
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode({
              'comment': comment,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'message': data['message'] ?? 'Jurnal/Logbook berhasil ditolak untuk revisi.',
          'data': data['data'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Gagal menolak logbook.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server ($e)',
      };
    }
  }

  /// GET /api/supervisor/attendances
  /// Daftar presensi siswa bimbingan DUDI
  static Future<List<Map<String, dynamic>>> getAttendances({String? date}) async {
    String query = '';
    if (date != null && date.isNotEmpty) {
      query = '?date=$date';
    }
    final url = Uri.parse('${AuthService.baseUrl}/supervisor/attendances$query');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final list = data['data']['attendances'] as List<dynamic>?;
          if (list != null) {
            return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          }
        }
      }
    } catch (_) {}
    return [];
  }
}
