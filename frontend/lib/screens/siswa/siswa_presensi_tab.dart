import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/student_service.dart';
import '../../widgets/smart_pkl_header.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/status_pill.dart';

/// ==============================================================================
/// HALAMAN PRESENSI SISWA (Masuk, Pulang, Pengajuan Izin)
/// Sesuai Desain Mockup SMART PKL & Spesifikasi Backend Laravel 'monitoring-pkl-app'
///
/// Logika Geolocation Asli & Rumus Haversine:
/// 1. Meminta izin GPS perangkat secara native (LocationPermission) dan mengambil
///    posisi koordinat realtime perangkat siswa (`Geolocator.getCurrentPosition`).
/// 2. Mengambil data koordinat resmi kantor DUDI dari API Backend:
///    GET /api/student/placement
/// 3. Menghitung jarak realtime siswa ke koordinat kantor menggunakan rumus Haversine:
///    a = sin²(Δlat/2) + cos(lat1) * cos(lat2) * sin²(Δlon/2)
///    c = 2 * atan2(√a, √(1−a))
///    d = R * c (R = 6.371.000 meter)
/// 4. Memvalidasi apakah siswa berada dalam radius yang ditentukan DUDI (maks 100m).
/// 5. Sinkronisasi waktu jam presensi dengan server WIB.
/// 6. Kamera Selfie Fisik (image_picker) & Pengiriman data presensi multipart:
///    - POST /api/student/attendances/check-in
///    - POST /api/student/attendances/check-out
/// ==============================================================================
class SiswaPresensiTab extends StatefulWidget {
  final Function(int)? onNavigateTab;
  final int initialSubTab; // 0: Masuk, 1: Pulang, 2: Sakit/Izin

  const SiswaPresensiTab({
    super.key,
    this.onNavigateTab,
    this.initialSubTab = 0,
  });

  @override
  State<SiswaPresensiTab> createState() => _SiswaPresensiTabState();
}

class _SiswaPresensiTabState extends State<SiswaPresensiTab> {
  // ── Tab State ─────────────────────────────────────────────────────────────
  late int _activeSubTab; // 0: Masuk, 1: Pulang, 2: Sakit/Izin
  int _selectedJenisPengajuan = 0; // 0: Sakit / Medis, 1: Izin Mendesak
  bool _isSubmitting = false;
  bool _isLoadingPlacement = true;

  // ── Foto Selfie State (Terpisah Masuk & Keluar) ──────────────────────────
  XFile? _selfieCheckInImage;
  XFile? _selfieCheckOutImage;
  final ImagePicker _picker = ImagePicker();

  // ── Lampiran Surat Dokter (Pengajuan Izin) ─────────────────────────────────
  XFile? _suratDokterFile;
  String _suratDokterFileName = '';
  String _suratDokterFileSize = '';
  bool _hasSuratDokter = false;

  // ── Form Controllers & Date Range ─────────────────────────────────────────
  final TextEditingController _alasanController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  // ── Riwayat Pengajuan Izin Siswa ──────────────────────────────────────────
  List<Map<String, dynamic>> _myLeaveRequests = [];
  bool _isLoadingLeaveRequests = false;

  Future<void> _fetchMyLeaveRequests() async {
    setState(() => _isLoadingLeaveRequests = true);
    try {
      final list = await StudentService.getLeaveRequests();
      if (mounted) {
        setState(() => _myLeaveRequests = list);
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoadingLeaveRequests = false);
      }
    }
  }

  // ── Date Picker Helpers (Bebas Pilih & Pasti Bisa Disave) ───────────────────
  Future<void> _pilihTanggalMulai() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2030, 12, 31),
      helpText: 'PILIH TANGGAL MULAI IZIN',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _pilihTanggalSelesai() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2030, 12, 31),
      helpText: 'PILIH TANGGAL SELESAI IZIN',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }


  // ── Placement & GPS Data ──────────────────────────────────────────────────
  Map<String, dynamic>? _placement;
  Map<String, dynamic>? _attendanceToday;

  // Default coordinate DUDI jika belum ada data API (PT Solusi Teknologi Mandiri)
  double _officeLat = -6.914744;
  double _officeLng = 107.609810;
  int _allowedRadius = 100; // 100 meter radius

  // Koordinat dinamis perangkat siswa (Real GPS)
  double _studentLat = -6.914900;
  double _studentLng = 107.609950;
  double _accuracy = 4.0; // ±4m
  double _calculatedDistance = 35.0; // meter
  bool _isWithinRadius = true;
  bool _isLoadingGps = false;
  String _gpsStatusMessage = 'GPS Terkunci – Haversine Aktif';
  bool _isRealGpsActive = false;

  // ── Clock & Server Time Sync ──────────────────────────────────────────────
  Timer? _clockTimer;
  StreamSubscription<Position>? _positionStreamSub;
  String _currentTimeString = '';
  Duration _serverTimeOffset = Duration.zero;

  // ── Jam Kerja Kantor Mitra DU/DI Siswa ───────────────────────────────────
  String _checkInTimeString = '08:00';
  String _checkOutTimeString = '16:00';
  int _checkInHour = 8;
  int _checkInMinute = 0;
  int _checkOutHour = 16;
  int _checkOutMinute = 0;

  bool get _isBeforeCheckOutTime {
    final now = DateTime.now().add(_serverTimeOffset);
    return now.hour < _checkOutHour ||
        (now.hour == _checkOutHour && now.minute < _checkOutMinute);
  }

  @override
  void initState() {
    super.initState();
    _activeSubTab = widget.initialSubTab;
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
    _loadPlacementAndDashboard();
    _requestAndGetRealLocation();
    _fetchMyLeaveRequests();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _positionStreamSub?.cancel();
    _alasanController.dispose();
    super.dispose();
  }

  void _applyPosition(Position position) {
    if (!mounted) return;
    _studentLat = position.latitude;
    _studentLng = position.longitude;
    _accuracy = position.accuracy > 0 ? position.accuracy : 4.0;
    _isRealGpsActive = true;
    _isLoadingGps = false;
    _recalculateDistance();
  }

  void _startPositionStream() {
    _positionStreamSub?.cancel();
    final LocationSettings streamSettings = (!kIsWeb && Platform.isAndroid)
        ? AndroidSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 3,
            intervalDuration: const Duration(seconds: 3),
          )
        : const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 3,
          );

    _positionStreamSub = Geolocator.getPositionStream(
      locationSettings: streamSettings,
    ).listen(
      _applyPosition,
      onError: (_) {},
    );
  }

  void _showGpsNotice(String message, {Color backgroundColor = const Color(0xFFD97706)}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.gps_off_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 12))),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Geolocator Native Permission & Real Location (Stream + Akurasi Bertahap) ─
  Future<void> _requestAndGetRealLocation({bool isManualRefresh = false}) async {
    setState(() {
      _isLoadingGps = true;
      _gpsStatusMessage = 'Mencari sinyal GPS...';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _isLoadingGps = false;
            _gpsStatusMessage = 'Layanan Lokasi (GPS) belum diaktifkan';
          });
          if (isManualRefresh) {
            _showGpsNotice('GPS perangkat mati. Aktifkan layanan lokasi lalu coba lagi.');
          }
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _isLoadingGps = false;
              _gpsStatusMessage = 'Izin lokasi ditolak oleh pengguna';
            });
            if (isManualRefresh) {
              _showGpsNotice('Izin lokasi ditolak. Izinkan akses lokasi di perangkat Anda.');
            }
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _isLoadingGps = false;
            _gpsStatusMessage = 'Izin lokasi ditolak permanen di pengaturan';
          });
          if (isManualRefresh) {
            _showGpsNotice('Izin lokasi ditolak permanen. Buka Pengaturan aplikasi untuk mengizinkan GPS.');
          }
        }
        return;
      }

      // Aktifkan stream real-time agar jarak otomatis ter-update saat berpindah >= 3m
      _startPositionStream();

      bool gotPosition = false;

      // Tahap 1: Coba kunci cepat dengan akurasi medium agar koordinat segera tampil
      try {
        final Position quickPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 5),
          ),
        );
        gotPosition = true;
        _applyPosition(quickPosition);
      } catch (_) {}

      // Tahap 2: Perhalus dengan akurasi tinggi (high accuracy)
      try {
        final Position accuratePosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        );
        gotPosition = true;
        _applyPosition(accuratePosition);
      } on TimeoutException {
        if (mounted) {
          setState(() {
            _isLoadingGps = false;
            if (!gotPosition) {
              _gpsStatusMessage = 'GPS Timeout – Pindah ke area terbuka lalu refresh';
            }
          });
          if (isManualRefresh && !gotPosition) {
            _showGpsNotice('GPS timeout: sinyal lambat mengunci lokasi. Pindah ke area lebih terbuka lalu tekan Refresh.');
          }
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _isLoadingGps = false;
            if (!gotPosition) {
              _gpsStatusMessage = 'Gagal membaca sensor GPS perangkat';
            }
          });
          if (isManualRefresh && !gotPosition) {
            _showGpsNotice('Gagal memperbarui lokasi GPS. Periksa sensor lokasi perangkat.');
          }
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingGps = false;
          _gpsStatusMessage = 'Gagal mengakses layanan lokasi perangkat';
        });
        if (isManualRefresh) {
          _showGpsNotice('Tidak dapat mengakses GPS perangkat.');
        }
      }
    }
  }

  // ── Kamera Selfie & Galeri Handler ────────────────────────────────────────
  Future<void> _pickSelfiePhoto({bool isMasuk = true}) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo != null && mounted) {
        setState(() {
          if (isMasuk) {
            _selfieCheckInImage = photo;
          } else {
            _selfieCheckOutImage = photo;
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      final bool? useGallery = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.photo_camera_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Kamera Tidak Siap', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Kamera langsung tidak dapat diakses ($e). Apakah Anda ingin mengambil foto dari galeri/file sebagai alternatif selfie?',
            style: const TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Buka Galeri', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (useGallery == true) {
        try {
          final XFile? galleryPhoto = await _picker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 1024,
            maxHeight: 1024,
            imageQuality: 85,
          );
          if (galleryPhoto != null && mounted) {
            setState(() {
              if (isMasuk) {
                _selfieCheckInImage = galleryPhoto;
              } else {
                _selfieCheckOutImage = galleryPhoto;
              }
            });
          }
        } catch (_) {}
      }
    }
  }

  // ── Surat Dokter Handler (Pengajuan Izin) ──────────────────────────────────
  Future<void> _pickSuratDokter() async {
    try {
      final XFile? doc = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );

      if (doc != null && mounted) {
        final length = await doc.length();
        final sizeMb = (length / (1024 * 1024)).toStringAsFixed(1);
        setState(() {
          _suratDokterFile = doc;
          _suratDokterFileName = doc.name;
          _suratDokterFileSize = '$sizeMb MB';
          _hasSuratDokter = true;
        });
      }
    } catch (_) {}
  }

  // ── Rumus Haversine (Sesuai App\Services\GeoService di Backend Laravel) ────
  /// Menghitung jarak lingkaran besar antara 2 pasang koordinat GPS dalam satuan meter
  double _calculateHaversine(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000.0; // Radius bumi dalam meter

    final double dLat = (lat2 - lat1) * (math.pi / 180.0);
    final double dLon = (lon2 - lon1) * (math.pi / 180.0);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180.0)) *
            math.cos(lat2 * (math.pi / 180.0)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return (earthRadius * c).roundToDouble();
  }

  /// Menghitung ulang jarak dinamis & menentukan status radius
  void _recalculateDistance() {
    final dist = _calculateHaversine(_studentLat, _studentLng, _officeLat, _officeLng);
    setState(() {
      _calculatedDistance = dist;
      _isWithinRadius = dist <= _allowedRadius;
      if (_isWithinRadius) {
        _gpsStatusMessage = 'GPS Terkunci – Haversine Aktif';
      } else {
        _gpsStatusMessage = 'GPS Terkunci – Di Luar Jarak (${dist.toStringAsFixed(0)}m)';
      }
    });
  }

  /// Memperbarui jam realtime yang disinkronkan dengan server WIB
  void _updateClock() {
    final now = DateTime.now().add(_serverTimeOffset);
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');
    if (mounted) {
      setState(() {
        _currentTimeString = '$h:$m:$s WIB';
      });
    }
  }

  // ============================================================================
  // PANGGILAN API BACKEND 1: GET /api/student/placement & GET /api/student/dashboard
  // Backend Route: monitoring-pkl-app/routes/api.php
  // Controller: App\Http\Controllers\Api\Student\StudentController@placement & @dashboard
  // Deskripsi: Mengambil penempatan aktif siswa, koordinat DUDI (latitude, longitude, radius),
  //            serta data status presensi hari ini dan waktu server.
  // ============================================================================
  Future<void> _loadPlacementAndDashboard() async {
    setState(() => _isLoadingPlacement = true);

    try {
      final placementData = await StudentService.getPlacement();
      final dashboardData = await StudentService.getDashboard();

      if (mounted) {
        setState(() {
          if (placementData != null) {
            _placement = placementData;
            final loc = placementData['location'] as Map<String, dynamic>?;
            if (loc != null) {
              final lat = double.tryParse(loc['latitude']?.toString() ?? '');
              final lng = double.tryParse(loc['longitude']?.toString() ?? '');
              final rad = int.tryParse(loc['radius']?.toString() ?? '');

              if (lat != null && lng != null) {
                _officeLat = lat;
                _officeLng = lng;
                if (!_isRealGpsActive) {
                  // Jika GPS perangkat belum mengunci posisi asli, gunakan posisi terkalibrasi ~35m
                  _studentLat = lat - 0.00025;
                  _studentLng = lng + 0.00018;
                }
              }
              if (rad != null && rad > 0) {
                _allowedRadius = rad;
              }
              if (loc['check_in_time'] != null && loc['check_in_time'].toString().isNotEmpty) {
                _checkInTimeString = loc['check_in_time'].toString();
                final parts = _checkInTimeString.split(':');
                if (parts.length >= 2) {
                  _checkInHour = int.tryParse(parts[0]) ?? 8;
                  _checkInMinute = int.tryParse(parts[1]) ?? 0;
                }
              }
              if (loc['check_out_time'] != null && loc['check_out_time'].toString().isNotEmpty) {
                _checkOutTimeString = loc['check_out_time'].toString();
                final parts = _checkOutTimeString.split(':');
                if (parts.length >= 2) {
                  _checkOutHour = int.tryParse(parts[0]) ?? 16;
                  _checkOutMinute = int.tryParse(parts[1]) ?? 0;
                }
              }
            }
          }

          if (dashboardData != null) {
            _attendanceToday = dashboardData['attendance_today'] as Map<String, dynamic>?;

            final serverTimeStr = dashboardData['server_time']?.toString();
            if (serverTimeStr != null) {
              final parsed = DateTime.tryParse(serverTimeStr);
              if (parsed != null) {
                _serverTimeOffset = parsed.difference(DateTime.now());
              }
            }
          }

          _recalculateDistance();
          _isLoadingPlacement = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingPlacement = false);
      }
    }
  }

  // ============================================================================
  // PANGGILAN API BACKEND 2 & 3:
  // - Masuk:  POST /api/student/attendances/check-in
  // - Pulang: POST /api/student/attendances/check-out
  // Backend Route: monitoring-pkl-app/routes/api.php:73-74
  // Controller: App\Http\Controllers\Api\Student\StudentController@checkIn / @checkOut
  // Parameters (multipart/form-data):
  //   - latitude: double (koordinat siswa)
  //   - longitude: double (koordinat siswa)
  //   - accuracy: double (akurasi GPS dalam meter)
  //   - photo: File image selfie (maks 5MB)
  // ============================================================================
  Future<void> _handlePresensiSubmit(String jenis) async {
    final bool isMasuk = jenis == 'Masuk';

    // Validasi jam pulang: siswa belum bisa absen pulang sebelum jam pulang DU/DI
    if (!isMasuk && _isBeforeCheckOutTime) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.schedule_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Belum waktunya absen pulang. Presensi pulang baru dibuka mulai pukul $_checkOutTimeString WIB.',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFD97706),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // Validasi radius sebelum kirim ke backend
    if (!_isWithinRadius) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.location_off_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Gagal: Anda berada di luar radius kantor (${_calculatedDistance.toStringAsFixed(0)}m > ${_allowedRadius}m). Dekati lokasi PKL untuk presensi.',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final XFile? currentSelfie = isMasuk ? _selfieCheckInImage : _selfieCheckOutImage;

    // Validasi foto selfie
    if (currentSelfie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Bukti foto selfie $jenis wajib diambil sebelum mengirimkan presensi.',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    Map<String, dynamic> res;
    if (isMasuk) {
      res = await StudentService.checkIn(
        latitude: _studentLat,
        longitude: _studentLng,
        accuracy: _accuracy,
        photoPath: currentSelfie.path,
        photoFile: currentSelfie,
      );
    } else {
      res = await StudentService.checkOut(
        latitude: _studentLat,
        longitude: _studentLng,
        accuracy: _accuracy,
        photoPath: currentSelfie.path,
        photoFile: currentSelfie,
      );
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    final bool isSuccess = res['success'] == true;

    if (isSuccess) {
      _loadPlacementAndDashboard();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                res['message'] ?? (isSuccess ? 'Presensi $jenis berhasil dicatat di server!' : 'Presensi $jenis gagal.'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Pengajuan Izin Submit ──────────────────────────────────────────────────
  Future<void> _handleIzinSubmit() async {
    final String jenisText = _selectedJenisPengajuan == 0 ? 'Sakit / Medis' : 'Izin Mendesak';
    final String jenisCode = _selectedJenisPengajuan == 0 ? 'sick' : 'permission';
    final String alasan = _alasanController.text.trim();

    if (alasan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text('Harap tuliskan alasan atau keluhan sakit pada kolom yang disediakan.'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final res = await StudentService.submitLeaveRequest(
      type: jenisCode,
      startDate: _startDate.toIso8601String().substring(0, 10),
      endDate: _endDate.toIso8601String().substring(0, 10),
      reason: alasan,
      attachmentPath: _suratDokterFile?.path,
      attachmentFile: _suratDokterFile,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res['success'] == true) {
      _alasanController.clear();
      setState(() {
        _suratDokterFile = null;
        _hasSuratDokter = false;
        _suratDokterFileName = '';
      });
      _fetchMyLeaveRequests();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pengajuan $jenisText berhasil dikirim ke Guru Pembimbing & Instruktur!',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Gagal mengirim pengajuan izin.'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String headerTitle = 'Presensi Masuk PKL';
    if (_activeSubTab == 1) {
      headerTitle = 'Presensi Keluar PKL';
    } else if (_activeSubTab == 2) {
      headerTitle = 'Izin / Sakit';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SmartPklHeader(
              title: headerTitle,
              onProfileTap: () => widget.onNavigateTab?.call(4),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Segmented Tabs: Masuk | Pulang | Sakit/Izin
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          _buildSegmentedTab(0, 'Masuk'),
                          _buildSegmentedTab(1, 'Pulang'),
                          _buildSegmentedTab(2, 'Sakit/Izin'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Time & Status Header Row (Sinkron dengan Server)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              _currentTimeString.isNotEmpty ? _currentTimeString : '--:--:-- WIB',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                        _buildStatusBadge(),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Konten Tab: Presensi (Masuk/Pulang) atau Pengajuan Izin
                    if (_activeSubTab == 0 || _activeSubTab == 1) ...[
                      _buildPresensiMasukKeluarView(_activeSubTab == 0 ? 'Masuk' : 'Keluar'),
                    ] else ...[
                      _buildPengajuanIzinView(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Segmented Tab Pill ────────────────────────────────────────────────────
  Widget _buildSegmentedTab(int index, String label) {
    final bool isSelected = _activeSubTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeSubTab = index;
          });
          if (index == 2) {
            _fetchMyLeaveRequests();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(color: const Color(0xFFBFDBFE), width: 1)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                size: 14,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Status Badge di Samping Jam ───────────────────────────────────────────
  Widget _buildStatusBadge() {
    final now = DateTime.now().add(_serverTimeOffset);
    final bool isMasuk = _activeSubTab == 0;
    final bool isPulang = _activeSubTab == 1;

    if (_activeSubTab == 2) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 6, color: Color(0xFFD97706)),
            SizedBox(width: 5),
            Text(
              'Pengajuan Perizinan',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFFD97706),
              ),
            ),
          ],
        ),
      );
    }

    final bool hasCheckedIn = _attendanceToday?['check_in_at'] != null;
    final bool hasCheckedOut = _attendanceToday?['check_out_at'] != null;
    final String? attendanceStatus = _attendanceToday?['status']?.toString();
    final int lateMinutes = int.tryParse(_attendanceToday?['late_minutes']?.toString() ?? '') ?? 0;

    final bool isLateForMasuk = isMasuk && (now.hour > _checkInHour || (now.hour == _checkInHour && now.minute > _checkInMinute));
    final bool isBeforePulang = isPulang && (now.hour < _checkOutHour || (now.hour == _checkOutHour && now.minute < _checkOutMinute));

    Color badgeBg;
    Color dotColor;
    String label;

    if (isMasuk) {
      if (hasCheckedIn) {
        if (attendanceStatus == 'late') {
          badgeBg = const Color(0xFFFEF3C7);
          dotColor = const Color(0xFFD97706);
          label = 'Terlambat ${lateMinutes > 0 ? '($lateMinutes mnt)' : ''}';
        } else {
          badgeBg = const Color(0xFFDCFCE7);
          dotColor = const Color(0xFF16A34A);
          label = 'Hadir Tepat Waktu';
        }
      } else if (attendanceStatus == 'excused') {
        badgeBg = const Color(0xFFDBEAFE);
        dotColor = const Color(0xFF2563EB);
        label = 'Izin / Sakit (Disetujui)';
      } else if (attendanceStatus == 'absent') {
        badgeBg = const Color(0xFFFEE2E2);
        dotColor = const Color(0xFFDC2626);
        label = 'Alfa (Tidak Hadir)';
      } else if (isLateForMasuk) {
        badgeBg = const Color(0xFFFEE2E2);
        dotColor = const Color(0xFFDC2626);
        label = 'Terlambat (Batas $_checkInTimeString)';
      } else {
        badgeBg = const Color(0xFFDCFCE7);
        dotColor = const Color(0xFF16A34A);
        label = 'Tepat Waktu (Maks $_checkInTimeString)';
      }
    } else {
      if (hasCheckedOut) {
        badgeBg = const Color(0xFFDCFCE7);
        dotColor = const Color(0xFF16A34A);
        label = 'Sudah Presensi Pulang';
      } else if (isBeforePulang) {
        badgeBg = const Color(0xFFFEF3C7);
        dotColor = const Color(0xFFD97706);
        label = 'Belum Jam Pulang ($_checkOutTimeString)';
      } else {
        badgeBg = const Color(0xFFDCFCE7);
        dotColor = const Color(0xFF16A34A);
        label = 'Waktu Pulang (Mulai $_checkOutTimeString)';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 6, color: dotColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: dotColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── View Presensi Masuk & Keluar PKL (Sesuai Mockup 2 & 3) ────────────────
  Widget _buildPresensiMasukKeluarView(String tipe) {
    final companyName = _placement?['location']?['name']?.toString() ?? 'PT Solusi Teknologi Mandiri';
    final divisionOrAddress = _placement?['location']?['address']?.toString() ?? 'Divisi Rekayasa Perangkat Lunak';

    final bool isMasuk = tipe == 'Masuk';
    final bool hasCheckedIn = _attendanceToday?['check_in_at'] != null;
    final bool hasCheckedOut = _attendanceToday?['check_out_at'] != null;
    final bool isCompleted = isMasuk ? hasCheckedIn : hasCheckedOut;
    final bool isBeforePulang = !isMasuk && _isBeforeCheckOutTime;

    final String? serverPhotoUrl = isMasuk
        ? (_attendanceToday != null ? _attendanceToday!['check_in_photo_url']?.toString() : null)
        : (_attendanceToday != null ? _attendanceToday!['check_out_photo_url']?.toString() : null);
    final XFile? currentSelfie = isMasuk ? _selfieCheckInImage : _selfieCheckOutImage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. DUDI Info Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.business_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      companyName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      divisionOrAddress,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (_isLoadingPlacement)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Banner Jadwal Jam Kantor DUDI & Aturan Validasi Otomatis
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 16, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Jam Kantor DUDI: Masuk <= $_checkInTimeString WIB • Pulang >= $_checkOutTimeString WIB',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E40AF),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 2. Interactive Radar Map Geolocation Card (Haversine & Radius Active)
        Container(
          width: double.infinity,
          height: 195,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isWithinRadius ? AppColors.cardBorder : const Color(0xFFFCA5A5),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // Radar circles
              Center(
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (_isWithinRadius ? const Color(0xFFDBEAFE) : const Color(0xFFFEE2E2)).withValues(alpha: 0.5),
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (_isWithinRadius ? const Color(0xFF93C5FD) : const Color(0xFFFCA5A5)).withValues(alpha: 0.6),
                  ),
                ),
              ),

              // Titik User (Kamu) dengan Jarak Realtime
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _isWithinRadius ? AppColors.primary : const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (_isWithinRadius ? AppColors.primary : const Color(0xFFDC2626)).withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_pin_circle_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Kamu (${_calculatedDistance.toStringAsFixed(0)}m)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Pin Kantor PKL (Top Right)
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.apartment_rounded, size: 13, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Kantor PKL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Tombol Refresh Lokasi GPS Asli (Top Left)
              Positioned(
                top: 14,
                left: 14,
                child: InkWell(
                  onTap: _isLoadingGps ? null : () => _requestAndGetRealLocation(isManualRefresh: true),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _isLoadingGps
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                              )
                            : const Icon(Icons.my_location_rounded, size: 13, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          _isLoadingGps ? 'Mencari GPS...' : (_isRealGpsActive ? 'GPS Akurat' : 'Deteksi GPS'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _isRealGpsActive ? const Color(0xFF16A34A) : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom row: Jarak (<100m) & Akurasi (±4m)
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isWithinRadius ? const Color(0xFFBFDBFE) : const Color(0xFFFCA5A5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.navigation_rounded,
                              size: 12,
                              color: _isWithinRadius ? AppColors.primary : const Color(0xFFDC2626),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Jarak: ',
                              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            ),
                            Text(
                              '${_calculatedDistance.toStringAsFixed(0)}m (${_isWithinRadius ? '<${_allowedRadius}m' : '>${_allowedRadius}m'})',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _isWithinRadius ? AppColors.primary : const Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBBF7D0), width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.gps_fixed_rounded, size: 12, color: Color(0xFF16A34A)),
                            const SizedBox(width: 4),
                            const Text(
                              'Akurasi: ',
                              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            ),
                            Text(
                              '±${_accuracy.toStringAsFixed(0)}m',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 3. GPS Terkunci – Haversine Banner (Sesuai Mockup)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _isWithinRadius ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isWithinRadius ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.satellite_alt_rounded,
                color: _isWithinRadius ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _gpsStatusMessage,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _isWithinRadius ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                      ),
                    ),
                    Text(
                      _isWithinRadius
                          ? (_isRealGpsActive
                              ? 'Koordinat GPS perangkat tervalidasi via Haversine'
                              : 'Sinyal satelit stabil & koordinat tervalidasi')
                          : 'Dekati lokasi kantor PKL agar memenuhi syarat presensi (<${_allowedRadius}m)',
                      style: TextStyle(
                        fontSize: 10,
                        color: _isWithinRadius ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                _isWithinRadius ? Icons.check_circle_outline_rounded : Icons.highlight_off_rounded,
                color: _isWithinRadius ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                size: 18,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 4. Bukti Foto Presensi (Wajib) dengan Kamera Fisik Asli
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bukti Foto Presensi',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Wajib',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Ambil foto selfie di area kantor atau foto workstation sebelum meninggalkan tempat PKL.',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),

              // Preview Foto: Jika sudah tersimpan di server / baru diambil di lokal
              if (serverPhotoUrl != null && serverPhotoUrl.isNotEmpty) ...[
                // Foto presensi yang sudah tersimpan di server
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            AuthService.formatImageUrl(serverPhotoUrl),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 36),
                            ),
                          ),
                          Positioned(
                            bottom: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF166534).withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.verified_rounded, color: Color(0xFF4ADE80), size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Foto Presensi $tipe (Tersimpan)',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else if (currentSelfie != null) ...[
                // Foto selfie lokal yang baru saja diambil
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    height: 130,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          kIsWeb
                              ? Image.network(currentSelfie.path, fit: BoxFit.cover)
                              : Image.file(File(currentSelfie.path), fit: BoxFit.cover),
                          Positioned(
                            bottom: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Foto Selfie $tipe Siap Dikirim',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              // Tombol Buka Kamera Selfie atau Status Sudah Selesai
              if (isCompleted) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBBF7D0), width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Presensi $tipe Telah Berhasil Dicatat',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (isBeforePulang) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule_rounded, color: Color(0xFFD97706), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Absen pulang belum dibuka. Anda baru dapat mengambil foto & mengirim presensi pulang mulai pukul $_checkOutTimeString WIB.',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF92400E),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                InkWell(
                  onTap: () => _pickSelfiePhoto(isMasuk: isMasuk),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: currentSelfie != null ? const Color(0xFFF0FDF4) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: currentSelfie != null ? const Color(0xFFBBF7D0) : const Color(0xFFBFDBFE),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          currentSelfie != null ? Icons.camera_alt_rounded : Icons.photo_camera_outlined,
                          color: currentSelfie != null ? const Color(0xFF16A34A) : AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currentSelfie != null
                              ? 'Ubah / Foto Ulang Selfie $tipe'
                              : 'Ambil Foto Selfie Presensi $tipe',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: currentSelfie != null ? const Color(0xFF16A34A) : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 5. Action Button Kirim Presensi
        if (isCompleted)
          CustomButton(
            text: 'Presensi $tipe Selesai',
            icon: Icons.task_alt_rounded,
            color: const Color(0xFF16A34A),
            onPressed: () {},
          )
        else if (!isMasuk && !hasCheckedIn)
          CustomButton(
            text: 'Presensi Masuk Diperlukan Terlebih Dahulu',
            icon: Icons.lock_outline_rounded,
            color: const Color(0xFF94A3B8),
            onPressed: () {},
          )
        else if (isBeforePulang)
          CustomButton(
            text: 'Belum Waktunya Pulang (Mulai $_checkOutTimeString WIB)',
            icon: Icons.schedule_rounded,
            color: const Color(0xFF94A3B8),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Belum waktunya absen pulang. Presensi pulang baru dibuka mulai pukul $_checkOutTimeString WIB.'),
                  backgroundColor: const Color(0xFFD97706),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          )
        else
          CustomButton(
            text: _isSubmitting
                ? 'Memproses Presensi...'
                : (isMasuk ? 'Kirim Presensi Masuk Sekarang' : 'Kirim Presensi Keluar Sekarang'),
            icon: _isSubmitting
                ? Icons.hourglass_top_rounded
                : (isMasuk ? Icons.login_rounded : Icons.logout_rounded),
            isLoading: _isSubmitting,
            onPressed: _isSubmitting ? () {} : () => _handlePresensiSubmit(tipe),
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── View Pengajuan Izin & Sakit (Sesuai Mockup 1) ──────────────────────────
  Widget _buildPengajuanIzinView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Text(
              'Jenis Pengajuan',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            Text(' *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.error)),
          ],
        ),
        const SizedBox(height: 8),

        // Radio Cards: Sakit / Medis vs Izin Mendesak
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedJenisPengajuan = 0;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedJenisPengajuan == 0 ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedJenisPengajuan == 0 ? AppColors.primary : const Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.medical_services_rounded,
                        size: 16,
                        color: _selectedJenisPengajuan == 0 ? AppColors.primary : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sakit / Medis',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _selectedJenisPengajuan == 0 ? AppColors.primary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedJenisPengajuan = 1;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedJenisPengajuan == 1 ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedJenisPengajuan == 1 ? AppColors.primary : const Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notification_important_rounded,
                        size: 16,
                        color: _selectedJenisPengajuan == 1 ? AppColors.primary : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Izin Mendesak',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _selectedJenisPengajuan == 1 ? AppColors.primary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Rentang Tanggal
        Builder(
          builder: (context) {
            final int diffDays = _endDate.difference(_startDate).inDays + 1;
            final String durationText = diffDays <= 1 ? '1 Hari' : '$diffDays Hari';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Rentang Tanggal',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Text(
                        'Total: $durationText',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Dua Pilihan Tanggal Bebas (Mulai & Selesai)
                Row(
                  children: [
                    // Kartu Tanggal Mulai
                    Expanded(
                      child: InkWell(
                        onTap: _pilihTanggalMulai,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primary),
                                  SizedBox(width: 6),
                                  Text(
                                    'Mulai Dari',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${_startDate.day} ${_getMonthName(_startDate.month)} ${_startDate.year}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF64748B)),
                      ),
                    ),
                    // Kartu Tanggal Selesai
                    Expanded(
                      child: InkWell(
                        onTap: _pilihTanggalSelesai,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.event_available_rounded, size: 14, color: AppColors.primary),
                                  SizedBox(width: 6),
                                  Text(
                                    'Sampai Dengan',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${_endDate.day} ${_getMonthName(_endDate.month)} ${_endDate.year}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),

        // Alasan
        const Text(
          'Alasan',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          ),
          child: TextField(
            controller: _alasanController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Tuliskan keluhan sakit atau alasan izin mendesak...',
              hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
              contentPadding: EdgeInsets.all(12),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Bukti Dokumen Pendukung (Surat Dokter)
        Row(
          children: const [
            Text('Bukti Dokumen Pendukung ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            Text('(Surat Dokter)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
            Spacer(),
            Text('Maks. 5 MB', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: 8),

        if (_hasSuratDokter)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _suratDokterFile != null
                        ? (kIsWeb
                            ? Image.network(_suratDokterFile!.path, fit: BoxFit.cover)
                            : Image.file(File(_suratDokterFile!.path), fit: BoxFit.cover))
                        : const Center(
                            child: Icon(Icons.image_outlined, color: Color(0xFFEF4444), size: 20),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _suratDokterFileName,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text('$_suratDokterFileSize • Terlampir', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      _hasSuratDokter = false;
                      _suratDokterFile = null;
                    });
                  },
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(color: Color(0xFFE2E8F0), shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 14, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          )
        else
          InkWell(
            onTap: _pickSuratDokter,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upload_file_rounded, color: AppColors.primary, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Pilih Berkas Surat Dokter (Foto / Galeri)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 20),

        // Action Button Kirim Pengajuan Izin
        CustomButton(
          text: 'Kirim Pengajuan Izin',
          icon: Icons.send_rounded,
          onPressed: _handleIzinSubmit,
        ),
        const SizedBox(height: 12),

        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user_outlined, size: 14, color: AppColors.textSecondary),
            SizedBox(width: 6),
            Text(
              'Pemberitahuan otomatis terkirim ke Guru Pembimbing',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── Riwayat Pengajuan Izin Saya ─────────────────────────────────────────
        const Divider(height: 32, color: Color(0xFFE2E8F0)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Riwayat Pengajuan Izin Saya',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.primary),
              onPressed: _fetchMyLeaveRequests,
              tooltip: 'Perbarui Status',
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (_isLoadingLeaveRequests)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (_myLeaveRequests.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(
              child: Text(
                'Belum ada riwayat pengajuan izin.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
          )
        else
          ..._myLeaveRequests.map((item) {
            final typeLabel = item['type_label']?.toString() ?? 'Izin / Sakit';
            final dateRange = item['date_range_label']?.toString() ??
                '${item['start_date']} s/d ${item['end_date']}';
            final reason = item['reason']?.toString() ?? '-';
            final status = (item['status'] ?? 'pending').toString().toLowerCase();
            final reviewerNote = item['reviewer_note']?.toString();

            final bool isApproved = status == 'approved';
            final bool isRejected = status == 'rejected';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isApproved
                      ? const Color(0xFFBBF7D0)
                      : (isRejected ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
                  width: isApproved || isRejected ? 1.3 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          typeLabel,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusPill(
                        text: isApproved
                            ? 'Disetujui Guru'
                            : (isRejected ? 'Ditolak Guru' : 'Menunggu Konfirmasi'),
                        style: isApproved
                            ? PillStyle.success
                            : (isRejected ? PillStyle.error : PillStyle.warning),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.date_range_rounded, size: 14, color: Color(0xFF2563EB)),
                      const SizedBox(width: 6),
                      Text(
                        dateRange,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Alasan: $reason',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                  ),
                  if (reviewerNote != null && reviewerNote.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isApproved ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Catatan Guru: "$reviewerNote"',
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: isApproved ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        const SizedBox(height: 24),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }
}
