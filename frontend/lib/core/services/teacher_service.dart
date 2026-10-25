import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// Service untuk menangani seluruh interaksi API Guru Pembimbing
/// dengan backend Laravel 'monitoring-pkl-app' (prefix: /api/teacher)
class TeacherService {
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
  // 6.1 DASHBOARD GURU
  // ─────────────────────────────────────────────────────────────────────────────

  /// GET /api/teacher/dashboard
  /// Mengambil ringkasan statistik bimbingan:
  /// - total_students: Jumlah siswa aktif
  /// - attendance_today: Presensi hadir hari ini
  /// - journals_pending: Logbook yang menunggu verifikasi
  static Future<Map<String, dynamic>?> getDashboard() async {
    final url = Uri.parse('${AuthService.baseUrl}/teacher/dashboard');
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

  // ─────────────────────────────────────────────────────────────────────────────
  // 6.2 DAFTAR & DETAIL SISWA BIMBINGAN
  // ─────────────────────────────────────────────────────────────────────────────

  /// GET /api/teacher/students
  /// Mengambil daftar siswa bimbingan aktif beserta informasi penempatan & lokasi PKL
  static Future<List<Map<String, dynamic>>> getStudents() async {
    final url = Uri.parse('${AuthService.baseUrl}/teacher/students');
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

  /// GET /api/teacher/students/{id}
  /// Mengambil detail profil lengkap siswa bimbingan tertentu
  static Future<Map<String, dynamic>?> getStudentDetail(int studentId) async {
    final url = Uri.parse('${AuthService.baseUrl}/teacher/students/$studentId');
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

  // ─────────────────────────────────────────────────────────────────────────────
  // 6.3 MONITORING PRESENSI SISWA
  // ─────────────────────────────────────────────────────────────────────────────

  /// GET /api/teacher/attendances
  /// Filter opsional:
  /// - date: YYYY-MM-DD
  /// - student_id: int
  /// - page: int
  static Future<Map<String, dynamic>?> getAttendances({
    String? date,
    int? studentId,
    int page = 1,
  }) async {
    final queryParams = <String, String>{'page': page.toString()};
    if (date != null && date.isNotEmpty) queryParams['date'] = date;
    if (studentId != null) queryParams['student_id'] = studentId.toString();

    final uri = Uri.parse('${AuthService.baseUrl}/teacher/attendances').replace(
      queryParameters: queryParams,
    );

    try {
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>?;
        }
      }
    } catch (_) {}
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 6.4 MONITORING LOGBOOK SISWA
  // ─────────────────────────────────────────────────────────────────────────────

  /// GET /api/teacher/logbooks
  /// Filter opsional:
  /// - status: draft | submitted | approved | rejected
  /// - student_id: int
  /// - page: int
  static Future<Map<String, dynamic>?> getLogbooks({
    String? status,
    int? studentId,
    int page = 1,
  }) async {
    final queryParams = <String, String>{'page': page.toString()};
    if (status != null && status.isNotEmpty && status != 'all') queryParams['status'] = status;
    if (studentId != null) queryParams['student_id'] = studentId.toString();

    final uri = Uri.parse('${AuthService.baseUrl}/teacher/logbooks').replace(
      queryParameters: queryParams,
    );

    try {
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>?;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Helper untuk mengambil list logbook siswa secara langsung
  static Future<List<Map<String, dynamic>>> getLogbooksList({
    String? status,
    int? studentId,
    int page = 1,
  }) async {
    final res = await getLogbooks(status: status, studentId: studentId, page: page);
    if (res != null && res['journals'] != null) {
      final list = res['journals'] as List<dynamic>?;
      if (list != null) {
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    }
    return [];
  }

  /// GET /api/teacher/logbooks/{id}
  /// Detail logbook siswa
  static Future<Map<String, dynamic>?> getLogbookDetail(int id) async {
    final url = Uri.parse('${AuthService.baseUrl}/teacher/logbooks/$id');
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

  /// POST /api/teacher/logbooks/{id}/approve
  /// Guru menyetujui logbook (status: approved)
  static Future<Map<String, dynamic>> approveLogbook({
    required int id,
    String? comment,
  }) async {
    final url = Uri.parse('${AuthService.baseUrl}/teacher/logbooks/$id/approve');
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
          'message': data['message'] ?? 'Logbook berhasil disetujui (di-ACC).',
          'data': data['data'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Gagal menyetujui logbook.',
        'errors': data['errors'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server ($e)',
      };
    }
  }

  /// POST /api/teacher/logbooks/{id}/reject
  /// Guru menolak / meminta revisi logbook (status: rejected)
  static Future<Map<String, dynamic>> rejectLogbook({
    required int id,
    required String note,
  }) async {
    final url = Uri.parse('${AuthService.baseUrl}/teacher/logbooks/$id/reject');
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode({
              'comment': note,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'message': data['message'] ?? 'Logbook berhasil ditolak / diminta revisi.',
          'data': data['data'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Gagal menolak logbook.',
        'errors': data['errors'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server ($e)',
      };
    }
  }

  /// POST /api/teacher/logbooks/{id}/comment
  /// Guru memberikan catatan & arahan bimbingan ke siswa
  static Future<Map<String, dynamic>> addComment({
    required int id,
    required String comment,
  }) async {
    final url = Uri.parse('${AuthService.baseUrl}/teacher/logbooks/$id/comment');
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
          'message': data['message'] ?? 'Catatan bimbingan berhasil dikirim ke siswa.',
          'data': data['data'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Gagal mengirim catatan bimbingan.',
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
  // 6.5 VERIFIKASI IZIN & SAKIT SISWA
  // ─────────────────────────────────────────────────────────────────────────────

  /// GET /api/teacher/leave-requests
  /// Mengambil daftar pengajuan izin dan sakit siswa bimbingan
  static Future<List<Map<String, dynamic>>> getLeaveRequests({String status = 'all'}) async {
    final queryParams = status != 'all' ? '?status=$status' : '';
    final url = Uri.parse('${AuthService.baseUrl}/teacher/leave-requests$queryParams');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final list = data['data']['leave_requests'] as List<dynamic>?;
          if (list != null) {
            return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          }
        }
      }
    } catch (_) {}
    return [];
  }

  /// POST /api/teacher/leave-requests/{id}/verify
  /// Guru menyetujui atau menolak pengajuan izin/sakit
  static Future<Map<String, dynamic>> verifyLeaveRequest({
    required int id,
    required String status, // 'approved' atau 'rejected'
    String? note,
  }) async {
    final url = Uri.parse('${AuthService.baseUrl}/teacher/leave-requests/$id/verify');
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode({
              'status': status,
              if (note != null && note.isNotEmpty) 'note': note,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'message': data['message'] ?? (status == 'approved' ? 'Pengajuan izin disetujui.' : 'Pengajuan izin ditolak.'),
          'data': data['data'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Gagal memproses permohonan izin.',
        'errors': data['errors'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server ($e)',
      };
    }
  }
}
