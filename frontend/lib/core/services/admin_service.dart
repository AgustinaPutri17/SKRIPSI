import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// ==============================================================================
/// SERVICE ADMIN (monitoring-pkl-app)
/// Menangani seluruh interaksi API fitur Administrator:
/// 4.1 Dashboard Administrator
/// 4.2 Manajemen Akun Pengguna (users)
/// 4.3 Master Data Siswa (students)
/// 4.4 Master Data Guru Pembimbing (teachers)
/// Serta Master Data Mitra DU/DI (locations)
/// ==============================================================================
class AdminService {
  /// Helper untuk menyusun header request dengan Bearer Token
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4.1 DASHBOARD ADMINISTRATOR
  // ─────────────────────────────────────────────────────────────────────────────

  /// ============================================================================
  /// API Backend: 4.1 Dashboard Administrator
  /// Endpoint: GET /api/admin/dashboard
  /// Backend File: monitoring-pkl-app/routes/api.php:34
  /// Controller: App\Http\Controllers\Api\Admin\DashboardController@index
  /// Deskripsi:
  ///   Menampilkan ringkasan statistik real-time dari backend:
  ///   - 'total_students': Jumlah seluruh siswa terdaftar
  ///   - 'total_active_placements': Jumlah penempatan PKL aktif
  ///   - 'total_locations': Jumlah mitra DU/DI terdaftar
  ///   - 'total_teachers': Jumlah guru pembimbing terdaftar
  ///   - 'total_field_supervisors': Jumlah pembimbing lapangan DU/DI
  ///   - 'attendance_today': Jumlah siswa yang telah hadir presensi hari ini
  ///   - 'journals_pending': Jumlah logbook siswa berstatus submitted yang menunggu verifikasi
  /// ============================================================================
  static Future<Map<String, dynamic>?> getDashboard() async {
    try {
      final url = Uri.parse('${AuthService.baseUrl}/admin/dashboard');
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 5));

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
  // 4.2 MANAJEMEN AKUN PENGGUNA (users)
  // ─────────────────────────────────────────────────────────────────────────────

  /// ============================================================================
  /// API Backend: 4.2 Manajemen Akun Pengguna
  /// Endpoint: GET /api/admin/users
  /// Backend File: monitoring-pkl-app/routes/api.php:38
  /// Controller: App\Http\Controllers\Api\Admin\UserController@index
  /// Query Params:
  ///   - role: 'admin' | 'teacher' | 'student' | 'field_supervisor'
  ///   - is_active: true | false
  ///   - search: Pencarian berdasarkan nama, username, atau email
  ///   - per_page: Jumlah data per halaman
  /// Deskripsi: Menampilkan daftar pengguna dengan filter dan paginasi
  /// ============================================================================
  static Future<Map<String, dynamic>?> getUsers({
    String? role,
    bool? isActive,
    String? search,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (role != null && role.isNotEmpty) queryParams['role'] = role;
      if (isActive != null) queryParams['is_active'] = isActive ? '1' : '0';
      if (search != null && search.trim().isNotEmpty) queryParams['search'] = search.trim();

      final uri = Uri.parse('${AuthService.baseUrl}/admin/users').replace(queryParameters: queryParams);
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 5));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>?;
        }
      }
    } catch (_) {}
    return null;
  }

  /// ============================================================================
  /// API Backend: 4.2 Manajemen Akun Pengguna
  /// Endpoint: GET /api/admin/users/{id}
  /// Controller: App\Http\Controllers\Api\Admin\UserController@show
  /// Deskripsi: Menampilkan detail pengguna berdasarkan User ID
  /// ============================================================================
  static Future<Map<String, dynamic>?> getUserDetail(int id) async {
    try {
      final url = Uri.parse('${AuthService.baseUrl}/admin/users/$id');
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 5));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>?;
        }
      }
    } catch (_) {}
    return null;
  }

  /// ============================================================================
  /// API Backend: 4.2 Manajemen Akun Pengguna
  /// Endpoint: PUT /api/admin/users/{id}
  /// Controller: App\Http\Controllers\Api\Admin\UserController@update
  /// Body: name, username, email, role, is_active
  /// Deskripsi: Memperbarui data pengguna dan menyinkronkan nama ke profil terkait
  /// ============================================================================
  static Future<Map<String, dynamic>> updateUser({
    required int id,
    String? name,
    String? username,
    String? email,
    String? role,
    bool? isActive,
  }) async {
    try {
      final url = Uri.parse('${AuthService.baseUrl}/admin/users/$id');
      final headers = await _getHeaders();
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (username != null) body['username'] = username;
      if (email != null) body['email'] = email;
      if (role != null) body['role'] = role;
      if (isActive != null) body['is_active'] = isActive;

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 6));

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'message': data['message'] ?? 'Data pengguna berhasil diperbarui.', 'data': data['data']};
      }
      return {'success': false, 'message': data['message'] ?? 'Gagal memperbarui pengguna.'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server ($e).'};
    }
  }

  /// ============================================================================
  /// API Backend: 4.2 Manajemen Akun Pengguna
  /// Endpoint: DELETE /api/admin/users/{id}
  /// Controller: App\Http\Controllers\Api\Admin\UserController@destroy
  /// Deskripsi: Menonaktifkan akun dengan is_active = false dan mencabut token
  /// ============================================================================
  static Future<Map<String, dynamic>> deleteUser(int id) async {
    try {
      final url = Uri.parse('${AuthService.baseUrl}/admin/users/$id');
      final headers = await _getHeaders();
      final response = await http.delete(url, headers: headers).timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'message': data['message'] ?? 'Pengguna berhasil dinonaktifkan.'};
      }
      return {'success': false, 'message': data['message'] ?? 'Gagal menonaktifkan pengguna.'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server ($e).'};
    }
  }

  /// ============================================================================
  /// API Backend: 4.2 Manajemen Akun Pengguna
  /// Endpoint: POST /api/admin/users/{id}/reset-password
  /// Backend File: monitoring-pkl-app/routes/api.php:37
  /// Controller: App\Http\Controllers\Api\Admin\UserController@resetPassword
  /// Body: password (min 8 karakter), password_confirmation
  /// Deskripsi: Mengatur ulang kata sandi pengguna dan mengakhiri sesi aktifnya
  /// ============================================================================
  static Future<Map<String, dynamic>> resetPassword({
    required int userId,
    required String newPassword,
    String? passwordConfirmation,
  }) async {
    try {
      final url = Uri.parse('${AuthService.baseUrl}/admin/users/$userId/reset-password');
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'password': newPassword,
          'password_confirmation': passwordConfirmation ?? newPassword,
        }),
      ).timeout(const Duration(seconds: 6));

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'message': data['message'] ?? 'Password berhasil direset.'};
      }
      return {'success': false, 'message': data['message'] ?? 'Gagal mereset password.'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server ($e).'};
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4.3 MASTER DATA SISWA (students)
  // ─────────────────────────────────────────────────────────────────────────────

  /// ============================================================================
  /// API Backend: 4.3 Master Data Siswa
  /// Endpoint: GET /api/admin/students
  /// Backend File: monitoring-pkl-app/routes/api.php:41
  /// Controller: App\Http\Controllers\Api\Admin\StudentController@index
  /// Query Params:
  ///   - class: Filter kelas siswa (misal: "XII RPL 1")
  ///   - major: Filter jurusan (misal: "Rekayasa Perangkat Lunak")
  ///   - search: Pencarian nama atau NIS siswa
  ///   - per_page: Jumlah data per halaman
  /// Deskripsi: Menampilkan daftar siswa beserta relasi akun pengguna
  /// ============================================================================
  static Future<Map<String, dynamic>?> getStudents({
    String? className,
    String? major,
    String? search,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (className != null && className.isNotEmpty) queryParams['class'] = className;
      if (major != null && major.isNotEmpty) queryParams['major'] = major;
      if (search != null && search.trim().isNotEmpty) queryParams['search'] = search.trim();

      final uri = Uri.parse('${AuthService.baseUrl}/admin/students').replace(queryParameters: queryParams);
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 5));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>?;
        }
      }
    } catch (_) {}
    return null;
  }

  /// ============================================================================
  /// API Backend: 4.3 Master Data Siswa
  /// Endpoint: POST /api/admin/students
  /// Controller: App\Http\Controllers\Api\Admin\StudentController@store
  /// Body: nis, name, class, major, phone, username, email, password
  /// Deskripsi:
  ///   Membuat data siswa, akun pengguna ber-role student, dan profil siswa
  ///   dalam satu transaksi database atomik
  /// ============================================================================
  static Future<Map<String, dynamic>> createStudent({
    required String name,
    required String nis,
    required String className,
    String? major,
    String? phone,
    required String username,
    String? email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('${AuthService.baseUrl}/admin/students');
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'name': name,
          'nis': nis,
          'class': className,
          'major': major ?? 'Rekayasa Perangkat Lunak',
          'phone': phone ?? '',
          'username': username,
          'email': (email != null && email.isNotEmpty) ? email : '$username@smk.sch.id',
          'password': password,
        }),
      ).timeout(const Duration(seconds: 6));

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'message': data['message'] ?? 'Siswa berhasil ditambahkan.', 'data': data['data']};
      }
      return {'success': false, 'message': _extractErrorMessage(data, 'Gagal menambahkan siswa.')};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server ($e).'};
    }
  }

  /// ============================================================================
  /// API Backend: 4.3 Master Data Siswa
  /// Endpoint: GET /api/admin/students/{id}
  /// Controller: App\Http\Controllers\Api\Admin\StudentController@show
  /// Deskripsi: Menampilkan detail profil siswa beserta relasi akun pengguna
  /// ============================================================================
  static Future<Map<String, dynamic>?> getStudentDetail(int id) async {
    try {
      final url = Uri.parse('${AuthService.baseUrl}/admin/students/$id');
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 5));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>?;
        }
      }
    } catch (_) {}
    return null;
  }

  /// ============================================================================
  /// API Backend: 4.3 Master Data Siswa
  /// Endpoint: PUT /api/admin/students/{id}
  /// Controller: App\Http\Controllers\Api\Admin\StudentController@update
  /// Body: nis, name, class, major, phone
  /// Deskripsi:
  ///   Memperbarui profil siswa. Perubahan nama otomatis disinkronkan ke akun pengguna
  /// ============================================================================
  static Future<Map<String, dynamic>> updateStudent({
    required int id,
    required String name,
    required String nis,
    required String className,
    String? major,
    String? phone,
  }) async {
    try {
      final url = Uri.parse('${AuthService.baseUrl}/admin/students/$id');
      final headers = await _getHeaders();
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode({
          'name': name,
          'nis': nis,
          'class': className,
          'major': major ?? 'Rekayasa Perangkat Lunak',
          'phone': phone ?? '',
        }),
      ).timeout(const Duration(seconds: 6));

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'message': data['message'] ?? 'Data siswa berhasil diperbarui.', 'data': data['data']};
      }
      return {'success': false, 'message': data['message'] ?? 'Gagal memperbarui data siswa.'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server ($e).'};
    }
  }

  /// ============================================================================
  /// API Backend: 4.3 Master Data Siswa
  /// Endpoint: DELETE /api/admin/students/{id}
  /// Controller: App\Http\Controllers\Api\Admin\StudentController@destroy
  /// Deskripsi: Menonaktifkan akun siswa (is_active = false) tanpa menghapus riwayat
  /// ============================================================================
  static Future<Map<String, dynamic>> deleteStudent(int id) async {
    try {
      final url = Uri.parse('${AuthService.baseUrl}/admin/students/$id');
      final headers = await _getHeaders();
      final response = await http.delete(url, headers: headers).timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'message': data['message'] ?? 'Akun siswa berhasil dinonaktifkan.'};
      }
      return {'success': false, 'message': _extractErrorMessage(data, 'Gagal menonaktifkan siswa.')};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server ($e).'};
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4.4 MASTER DATA GURU PEMBIMBING (teachers)
  // ─────────────────────────────────────────────────────────────────────────────

  /// ============================================================================
  /// API Backend: 4.4 Master Data Guru Pembimbing
  /// Endpoint: GET /api/admin/teachers
  /// Backend File: monitoring-pkl-app/routes/api.php:44
  /// Controller: App\Http\Controllers\Api\Admin\TeacherController@index
  /// Query Params:
  ///   - search: Pencarian berdasarkan nama atau Kode Guru
  ///   - per_page: Jumlah data per halaman
  /// Deskripsi: Menampilkan daftar guru pembimbing beserta akun pengguna
  /// ============================================================================
  static Future<Map<String, dynamic>?> getTeachers({
    String? search,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (search != null && search.trim().isNotEmpty) queryParams['search'] = search.trim();

      final uri = Uri.parse('${AuthService.baseUrl}/admin/teachers').replace(queryParameters: queryParams);
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 5));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>?;
        }
      }
    } catch (_) {}
    return null;
  }

  /// ============================================================================
  /// API Backend: 4.4 Master Data Guru Pembimbing
  /// Endpoint: POST /api/admin/teachers
  /// Controller: App\Http\Controllers\Api\Admin\TeacherController@store
  /// Body: teacher_code, name, phone, username, email, password
  /// Deskripsi:
  ///   Membuat akun pengguna ber-role teacher dan data guru pembimbing sekolah
  /// ============================================================================
  static Future<Map<String, dynamic>> createTeacher({
    required String name,
    required String teacherCode,
    String? phone,
    required String username,
    String? email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('${AuthService.baseUrl}/admin/teachers');
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'name': name,
          'teacher_code': teacherCode,
          'phone': phone ?? '',
          'username': username,
          'email': (email != null && email.isNotEmpty) ? email : '$username@smk.sch.id',
          'password': password,
        }),
      ).timeout(const Duration(seconds: 6));

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'message': data['message'] ?? 'Guru berhasil ditambahkan.', 'data': data['data']};
      }
      return {'success': false, 'message': _extractErrorMessage(data, 'Gagal menambahkan guru.')};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server ($e).'};
    }
  }

  /// ============================================================================
  /// API Backend: 4.4 Master Data Guru Pembimbing
  /// Endpoint: GET /api/admin/teachers/{id}
  /// Controller: App\Http\Controllers\Api\Admin\TeacherController@show
  /// Deskripsi: Menampilkan detail profil guru pembimbing
  /// ============================================================================
  static Future<Map<String, dynamic>?> getTeacherDetail(int id) async {
    try {
      final url = Uri.parse('${AuthService.baseUrl}/admin/teachers/$id');
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 5));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>?;
        }
      }
    } catch (_) {}
    return null;
  }

  /// ============================================================================
  /// API Backend: 4.4 Master Data Guru Pembimbing
  /// Endpoint: PUT /api/admin/teachers/{id}
  /// Controller: App\Http\Controllers\Api\Admin\TeacherController@update
  /// Body: teacher_code, name, phone
  /// Deskripsi: Memperbarui profil guru pembimbing dan sinkronisasi nama ke akun user
  /// ============================================================================
  static Future<Map<String, dynamic>> updateTeacher({
    required int id,
    required String name,
    required String teacherCode,
    String? phone,
  }) async {
    try {
      final url = Uri.parse('${AuthService.baseUrl}/admin/teachers/$id');
      final headers = await _getHeaders();
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode({
          'name': name,
          'teacher_code': teacherCode,
          'phone': phone ?? '',
        }),
      ).timeout(const Duration(seconds: 6));

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'message': data['message'] ?? 'Data guru berhasil diperbarui.', 'data': data['data']};
      }
      return {'success': false, 'message': _extractErrorMessage(data, 'Gagal memperbarui data guru.')};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server ($e).'};
    }
  }

  /// ============================================================================
  /// API Backend: 4.4 Master Data Guru Pembimbing
  /// Endpoint: DELETE /api/admin/teachers/{id}
  /// Controller: App\Http\Controllers\Api\Admin\TeacherController@destroy
  /// Deskripsi: Menonaktifkan akun guru pembimbing (is_active = false)
  /// ============================================================================
  static Future<Map<String, dynamic>> deleteTeacher(int id) async {
    try {
      final url = Uri.parse('${AuthService.baseUrl}/admin/teachers/$id');
      final headers = await _getHeaders();
      final response = await http.delete(url, headers: headers).timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'message': data['message'] ?? 'Akun guru berhasil dinonaktifkan.'};
      }
      return {'success': false, 'message': _extractErrorMessage(data, 'Gagal menonaktifkan guru.')};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server ($e).'};
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // MASTER DATA MITRA DU/DI (locations)
  // ─────────────────────────────────────────────────────────────────────────────

  /// ============================================================================
  /// API Backend: GET /api/admin/locations
  /// Backend File: monitoring-pkl-app/routes/api.php:50
  /// Controller: App\Http\Controllers\Api\Admin\LocationController@index
  /// ============================================================================
  static Future<Map<String, dynamic>?> getLocations({
    String? search,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (search != null && search.trim().isNotEmpty) queryParams['search'] = search.trim();

      final uri = Uri.parse('${AuthService.baseUrl}/admin/locations').replace(queryParameters: queryParams);
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 5));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>?;
        }
      }
    } catch (_) {}
    return null;
  }

  /// ============================================================================
  /// API Backend: POST /api/admin/locations
  /// Controller: App\Http\Controllers\Api\Admin\LocationController@store
  /// ============================================================================
  static Future<Map<String, dynamic>> createLocation({
    required String name,
    required String address,
    double? latitude,
    double? longitude,
    int radius = 100,
    bool isActive = true,
    List<int>? fieldSupervisorIds,
  }) async {
    try {
      final url = Uri.parse('${AuthService.baseUrl}/admin/locations');
      final headers = await _getHeaders();
      final Map<String, dynamic> body = {
        'name': name,
        'address': address,
        'radius': radius,
        'is_active': isActive,
      };
      if (latitude != null) body['latitude'] = latitude;
      if (longitude != null) body['longitude'] = longitude;
      if (fieldSupervisorIds != null && fieldSupervisorIds.isNotEmpty) {
        body['field_supervisor_ids'] = fieldSupervisorIds;
      }

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 6));

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'message': data['message'] ?? 'Mitra DUDI berhasil ditambahkan.', 'data': data['data']};
      }
      return {'success': false, 'message': _extractErrorMessage(data, 'Gagal menambahkan mitra DUDI.')};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server ($e).'};
    }
  }

  /// ============================================================================
  /// API Backend: PUT /api/admin/locations/{id}
  /// Controller: App\Http\Controllers\Api\Admin\LocationController@update
  /// ============================================================================
  static Future<Map<String, dynamic>> updateLocation({
    required int id,
    required String name,
    required String address,
    double? latitude,
    double? longitude,
    int radius = 100,
    List<int>? fieldSupervisorIds,
  }) async {
    try {
      final url = Uri.parse('${AuthService.baseUrl}/admin/locations/$id');
      final headers = await _getHeaders();
      final Map<String, dynamic> body = {
        'name': name,
        'address': address,
        'radius': radius,
      };
      if (latitude != null) body['latitude'] = latitude;
      if (longitude != null) body['longitude'] = longitude;
      if (fieldSupervisorIds != null) {
        body['field_supervisor_ids'] = fieldSupervisorIds;
      }

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 6));

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'message': data['message'] ?? 'Data mitra berhasil diperbarui.', 'data': data['data']};
      }
      return {'success': false, 'message': _extractErrorMessage(data, 'Gagal memperbarui data mitra.')};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server ($e).'};
    }
  }

  /// ============================================================================
  /// API Backend: DELETE /api/admin/locations/{id}
  /// Controller: App\Http\Controllers\Api\Admin\LocationController@destroy
  /// ============================================================================
  static Future<Map<String, dynamic>> deleteLocation(int id) async {
    try {
      final url = Uri.parse('${AuthService.baseUrl}/admin/locations/$id');
      final headers = await _getHeaders();
      final response = await http.delete(url, headers: headers).timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'message': data['message'] ?? 'Mitra berhasil dinonaktifkan.'};
      }
      return {'success': false, 'message': _extractErrorMessage(data, 'Gagal menghapus mitra.')};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server ($e).'};
    }
  }

  /// Helper untuk mengekstrak pesan error ramah pengguna dari response backend
  static String _extractErrorMessage(dynamic data, String defaultMsg) {
    if (data is Map<String, dynamic>) {
      if (data['errors'] != null && data['errors'] is Map) {
        final errMap = data['errors'] as Map;
        final List<String> errorList = [];
        errMap.forEach((key, val) {
          if (val is List && val.isNotEmpty) {
            errorList.add(val.first.toString());
          } else if (val is String) {
            errorList.add(val);
          }
        });
        if (errorList.isNotEmpty) {
          return errorList.join(', ');
        }
      }
      if (data['message'] != null && data['message'].toString().isNotEmpty) {
        return data['message'].toString();
      }
    }
    return defaultMsg;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4.5 MASTER DATA PEMBIMBING LAPANGAN / DUDI (field-supervisors)
  // ─────────────────────────────────────────────────────────────────────────────

  /// ============================================================================
  /// API Backend: 4.5 Master Data Pembimbing Lapangan
  /// Endpoint: GET /api/admin/field-supervisors
  /// Backend File: monitoring-pkl-app/routes/api.php:47
  /// Controller: App\Http\Controllers\Api\Admin\FieldSupervisorController@index
  /// ============================================================================
  static Future<Map<String, dynamic>?> getFieldSupervisors({
    String? search,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (search != null && search.trim().isNotEmpty) queryParams['search'] = search.trim();

      final uri = Uri.parse('${AuthService.baseUrl}/admin/field-supervisors').replace(queryParameters: queryParams);
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 5));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>?;
        }
      }
    } catch (_) {}
    return null;
  }

  /// ============================================================================
  /// API Backend: 4.5 Master Data Pembimbing Lapangan
  /// Endpoint: POST /api/admin/field-supervisors
  /// Controller: App\Http\Controllers\Api\Admin\FieldSupervisorController@store
  /// Body: name, organization, phone, username, email, password
  /// ============================================================================
  static Future<Map<String, dynamic>> createFieldSupervisor({
    required String name,
    required String organization,
    String? phone,
    required String username,
    String? email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('${AuthService.baseUrl}/admin/field-supervisors');
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'name': name,
          'organization': organization,
          'phone': phone ?? '',
          'username': username,
          'email': (email != null && email.isNotEmpty) ? email : '$username@dudi.id',
          'password': password,
        }),
      ).timeout(const Duration(seconds: 6));

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'message': data['message'] ?? 'Pembimbing DU/DI berhasil ditambahkan.', 'data': data['data']};
      }
      return {'success': false, 'message': _extractErrorMessage(data, 'Gagal menambahkan pembimbing DU/DI.')};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server ($e).'};
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4.7 MASTER DATA PERIODE PKL (periods)
  // ─────────────────────────────────────────────────────────────────────────────

  /// ============================================================================
  /// API Backend: 4.7 Master Data Periode PKL
  /// Endpoint: GET /api/admin/periods
  /// Backend File: monitoring-pkl-app/routes/api.php:53
  /// Controller: App\Http\Controllers\Api\Admin\PeriodController@index
  /// ============================================================================
  static Future<Map<String, dynamic>?> getPeriods({
    String? status,
    String? search,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (search != null && search.trim().isNotEmpty) queryParams['search'] = search.trim();

      final uri = Uri.parse('${AuthService.baseUrl}/admin/periods').replace(queryParameters: queryParams);
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 5));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>?;
        }
      }
    } catch (_) {}
    return null;
  }

  /// ============================================================================
  /// API Backend: 4.7 Master Data Periode PKL
  /// Endpoint: POST /api/admin/periods
  /// Controller: App\Http\Controllers\Api\Admin\PeriodController@store
  /// Body: name, start_date, end_date, status
  /// ============================================================================
  static Future<Map<String, dynamic>> createPeriod({
    required String name,
    required String startDate,
    required String endDate,
    String status = 'active',
  }) async {
    try {
      final url = Uri.parse('${AuthService.baseUrl}/admin/periods');
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'name': name,
          'start_date': startDate,
          'end_date': endDate,
          'status': status,
        }),
      ).timeout(const Duration(seconds: 6));

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'message': data['message'] ?? 'Periode PKL berhasil dibuat.', 'data': data['data']};
      }
      return {'success': false, 'message': _extractErrorMessage(data, 'Gagal membuat periode PKL.')};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server ($e).'};
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4.8 MASTER DATA PENEMPATAN SISWA (placements)
  // ─────────────────────────────────────────────────────────────────────────────

  /// ============================================================================
  /// API Backend: 4.8 Master Data Penempatan Siswa
  /// Endpoint: GET /api/admin/placements
  /// Backend File: monitoring-pkl-app/routes/api.php:56
  /// Controller: App\Http\Controllers\Api\Admin\PlacementController@index
  /// Query: student_id, location_id, period_id, teacher_id, field_supervisor_id, status
  /// ============================================================================
  static Future<List<dynamic>?> getPlacements({
    int? studentId,
    int? locationId,
    int? periodId,
    int? teacherId,
    int? fieldSupervisorId,
    String? status,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (studentId != null) queryParams['student_id'] = studentId.toString();
      if (locationId != null) queryParams['location_id'] = locationId.toString();
      if (periodId != null) queryParams['period_id'] = periodId.toString();
      if (teacherId != null) queryParams['teacher_id'] = teacherId.toString();
      if (fieldSupervisorId != null) queryParams['field_supervisor_id'] = fieldSupervisorId.toString();
      if (status != null && status.isNotEmpty) queryParams['status'] = status;

      final uri = Uri.parse('${AuthService.baseUrl}/admin/placements').replace(queryParameters: queryParams);
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 5));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data']['placements'] as List<dynamic>?;
        }
      }
    } catch (_) {}
    return null;
  }

  /// ============================================================================
  /// API Backend: 4.8 Master Data Penempatan Siswa
  /// Endpoint: POST /api/admin/placements
  /// Controller: App\Http\Controllers\Api\Admin\PlacementController@store
  /// Body: student_id, location_id, period_id, teacher_id, field_supervisor_id, start_date, end_date, status
  /// ============================================================================
  static Future<Map<String, dynamic>> createPlacement({
    required int studentId,
    required int locationId,
    required int periodId,
    required int teacherId,
    int? fieldSupervisorId,
    required String startDate,
    required String endDate,
    String status = 'active',
  }) async {
    try {
      final url = Uri.parse('${AuthService.baseUrl}/admin/placements');
      final headers = await _getHeaders();
      final body = <String, dynamic>{
        'student_id': studentId,
        'location_id': locationId,
        'period_id': periodId,
        'teacher_id': teacherId,
        'start_date': startDate,
        'end_date': endDate,
        'status': status,
      };
      if (fieldSupervisorId != null) {
        body['field_supervisor_id'] = fieldSupervisorId;
      }

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 6));

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'message': data['message'] ?? 'Penempatan siswa berhasil disimpan.', 'data': data['data']};
      }
      return {'success': false, 'message': _extractErrorMessage(data, 'Gagal membuat penempatan siswa.')};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server ($e).'};
    }
  }

  /// ============================================================================
  /// API Backend: 4.8 Master Data Penempatan Siswa
  /// Endpoint: PUT /api/admin/placements/{id}
  /// Controller: App\Http\Controllers\Api\Admin\PlacementController@update
  /// ============================================================================
  static Future<Map<String, dynamic>> updatePlacement({
    required int id,
    int? locationId,
    int? teacherId,
    int? fieldSupervisorId,
    String? startDate,
    String? endDate,
    String? status,
  }) async {
    try {
      final url = Uri.parse('${AuthService.baseUrl}/admin/placements/$id');
      final headers = await _getHeaders();
      final body = <String, dynamic>{};
      if (locationId != null) body['location_id'] = locationId;
      if (teacherId != null) body['teacher_id'] = teacherId;
      if (fieldSupervisorId != null) body['field_supervisor_id'] = fieldSupervisorId;
      if (startDate != null) body['start_date'] = startDate;
      if (endDate != null) body['end_date'] = endDate;
      if (status != null) body['status'] = status;

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 6));

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'message': data['message'] ?? 'Penempatan siswa berhasil diperbarui.', 'data': data['data']};
      }
      return {'success': false, 'message': _extractErrorMessage(data, 'Gagal memperbarui penempatan siswa.')};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server ($e).'};
    }
  }

  /// ============================================================================
  /// API Backend: 4.8 Master Data Penempatan Siswa
  /// Endpoint: DELETE /api/admin/placements/{id}
  /// Controller: App\Http\Controllers\Api\Admin\PlacementController@destroy
  /// Deskripsi: Menonaktifkan penempatan dengan status = 'inactive'
  /// ============================================================================
  static Future<Map<String, dynamic>> deletePlacement(int id) async {
    try {
      final url = Uri.parse('${AuthService.baseUrl}/admin/placements/$id');
      final headers = await _getHeaders();
      final response = await http.delete(url, headers: headers).timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'message': data['message'] ?? 'Penempatan berhasil dinonaktifkan.'};
      }
      return {'success': false, 'message': _extractErrorMessage(data, 'Gagal menonaktifkan penempatan.')};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server ($e).'};
    }
  }

  /// ============================================================================
  /// API Backend: 4.7 Master Data Periode PKL - Aktivasi Periode
  /// Endpoint: POST /api/admin/periods/{id}/activate
  /// ============================================================================
  static Future<Map<String, dynamic>> activatePeriod(int id) async {
    try {
      final url = Uri.parse('${AuthService.baseUrl}/admin/periods/$id/activate');
      final headers = await _getHeaders();
      final response = await http.post(url, headers: headers).timeout(const Duration(seconds: 6));

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'message': data['message'] ?? 'Periode berhasil diaktifkan.', 'data': data['data']};
      }
      return {'success': false, 'message': _extractErrorMessage(data, 'Gagal mengaktifkan periode.')};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server ($e).'};
    }
  }

  /// ============================================================================
  /// API Backend: 4.8 Master Data Penempatan Siswa - Toggle Status (Aktif/Nonaktif)
  /// Endpoint: POST /api/admin/placements/{id}/toggle-status
  /// ============================================================================
  static Future<Map<String, dynamic>> togglePlacementStatus(int id) async {
    try {
      final url = Uri.parse('${AuthService.baseUrl}/admin/placements/$id/toggle-status');
      final headers = await _getHeaders();
      final response = await http.post(url, headers: headers).timeout(const Duration(seconds: 6));

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'message': data['message'] ?? 'Status penempatan berhasil diperbarui.', 'data': data['data']};
      }
      return {'success': false, 'message': _extractErrorMessage(data, 'Gagal mengubah status penempatan.')};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server ($e).'};
    }
  }
}

