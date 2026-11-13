import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/supervisor_service.dart';
import '../../widgets/smart_pkl_header.dart';
import '../../widgets/custom_button.dart';

/// ==============================================================================
/// 7.2 MANAJEMEN LOKASI PKL OLEH DUDI (locations)
/// Sesuai Mockup 'DUDI - Pengajuan Titik Lokasi Pertama' / 'Detail Lokasi Dudi'
///
/// Fitur:
/// 1. Nama Perusahaan/Instansi DUDI
/// 2. Peringatan: "Wajib Dilakukan di Lingkungan Kantor/Pabrik!"
///    "Koordinat ini akan menjadi acuan radius absensi geofencing siswa PKL Anda"
/// 3. Visual radar & peta interaktif dengan pin lokasi dan indikator GPS Akurat ±4m
/// 4. Tombol "Gunakan Lokasi Saya Sekarang" yang membaca GPS perangkat saat ini
/// 5. Input & Display Latitude, Longitude, Radius (meter), dan Alamat Terdeteksi
/// 6. Tombol "Simpan" -> Memanggil API:
///    - POST /api/supervisor/locations (jika baru)
///    - PUT /api/supervisor/locations/{id} (jika update)
/// ==============================================================================
class DudiLokasiScreen extends StatefulWidget {
  final Map<String, dynamic>? initialLocation;
  final VoidCallback? onLocationSaved;
  final VoidCallback? onProfileTap;

  const DudiLokasiScreen({
    super.key,
    this.initialLocation,
    this.onLocationSaved,
    this.onProfileTap,
  });

  @override
  State<DudiLokasiScreen> createState() => _DudiLokasiScreenState();
}

class _DudiLokasiScreenState extends State<DudiLokasiScreen> {
  int? _locationId;
  final TextEditingController _nameController = TextEditingController(text: 'PT Solusi Teknologi Mandiri');
  final TextEditingController _addressController = TextEditingController(
    text: 'Gedung R&D Lt. 2, Jl. ZA. Pagar Alam No. 42, Gedong Meneng, Bandar Lampung',
  );
  final TextEditingController _radiusController = TextEditingController(text: '50');
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();

  double _latitude = -5.378921;
  double _longitude = 105.251412;
  double _gpsAccuracy = 4.0;
  Offset _pinOffset = Offset.zero;
  double _zoom = 1.0;
  bool _isDraggingMap = false;

  TimeOfDay _checkInTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _checkOutTime = const TimeOfDay(hour: 16, minute: 0);

  bool _isLoadingGps = false;
  bool _isSaving = false;
  bool _isLoadingData = false;
  bool _needsGpsSetup = false;
  String _statusMessage = 'GPS Akurat ±4m';

  TimeOfDay _parseTime(dynamic value, TimeOfDay defaultVal) {
    if (value == null) return defaultVal;
    try {
      final parts = value.toString().split(':');
      if (parts.length >= 2) {
        final h = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        return TimeOfDay(hour: h, minute: m);
      }
    } catch (_) {}
    return defaultVal;
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  void initState() {
    super.initState();
    _latController.text = _latitude.toStringAsFixed(6);
    _lngController.text = _longitude.toStringAsFixed(6);
    if (widget.initialLocation != null) {
      _applyLocationData(widget.initialLocation!);
    } else {
      _fetchExistingLocation();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _radiusController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _applyLocationData(Map<String, dynamic> loc) {
    final bool missingCoords = (loc['latitude'] == null || loc['longitude'] == null);
    setState(() {
      _needsGpsSetup = missingCoords;
      _locationId = loc['id'];
      if (loc['name'] != null && loc['name'].toString().isNotEmpty) {
        _nameController.text = loc['name'].toString();
      }
      if (loc['address'] != null && loc['address'].toString().isNotEmpty) {
        _addressController.text = loc['address'].toString();
      }
      if (loc['latitude'] != null) {
        _latitude = double.tryParse(loc['latitude'].toString()) ?? _latitude;
      }
      if (loc['longitude'] != null) {
        _longitude = double.tryParse(loc['longitude'].toString()) ?? _longitude;
      }
      _latController.text = _latitude.toStringAsFixed(6);
      _lngController.text = _longitude.toStringAsFixed(6);
      _pinOffset = Offset.zero;
      if (loc['radius'] != null) {
        _radiusController.text = loc['radius'].toString();
      }
      if (loc['check_in_time'] != null) {
        _checkInTime = _parseTime(loc['check_in_time'], _checkInTime);
      }
      if (loc['check_out_time'] != null) {
        _checkOutTime = _parseTime(loc['check_out_time'], _checkOutTime);
      }
    });

    if (missingCoords) {
      _getCurrentGpsLocation();
    }
  }

  Future<void> _fetchExistingLocation() async {
    setState(() => _isLoadingData = true);
    try {
      final list = await SupervisorService.getLocations();
      if (list.isNotEmpty && mounted) {
        _applyLocationData(list.first);
      } else if (mounted) {
        // Jika belum ada lokasi terdaftar (Pengajuan Titik Lokasi Pertama), otomatis deteksi GPS asli
        _getCurrentGpsLocation();
      }
    } catch (_) {
      if (mounted) _getCurrentGpsLocation();
    }
    if (mounted) setState(() => _isLoadingData = false);
  }

  /// Membaca koordinat GPS fisik terkini
  Future<void> _getCurrentGpsLocation() async {
    setState(() {
      _isLoadingGps = true;
      _statusMessage = 'Mencari sinyal GPS...';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _isLoadingGps = false;
            _statusMessage = 'Layanan GPS mati';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Layanan lokasi (GPS) pada perangkat belum aktif.')),
          );
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
              _statusMessage = 'Izin GPS ditolak';
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _isLoadingGps = false;
            _statusMessage = 'Izin ditolak permanen';
          });
        }
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _latController.text = _latitude.toStringAsFixed(6);
          _lngController.text = _longitude.toStringAsFixed(6);
          _pinOffset = Offset.zero;
          _gpsAccuracy = position.accuracy > 0 ? position.accuracy : 4.0;
          _statusMessage = 'GPS Akurat ±${_gpsAccuracy.toStringAsFixed(0)}m';
          _isLoadingGps = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lokasi berhasil dideteksi: ${_latitude.toStringAsFixed(6)}, ${_longitude.toStringAsFixed(6)}'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingGps = false;
          _statusMessage = 'Gagal baca sensor GPS';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sensor GPS tidak terdeteksi atau timeout ($e)')),
        );
      }
    }
  }

  Future<void> _saveLocation() async {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final radius = int.tryParse(_radiusController.text.trim()) ?? 50;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama instansi/kantor DUDI wajib diisi')),
      );
      return;
    }
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alamat kantor wajib diisi')),
      );
      return;
    }
    if (radius < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Radius geofencing minimal 10 meter')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final checkInStr = _formatTimeOfDay(_checkInTime);
    final checkOutStr = _formatTimeOfDay(_checkOutTime);

    Map<String, dynamic> result;
    if (_locationId != null) {
      result = await SupervisorService.updateLocation(
        id: _locationId!,
        name: name,
        address: address,
        latitude: _latitude,
        longitude: _longitude,
        radius: radius,
        checkInTime: checkInStr,
        checkOutTime: checkOutStr,
      );
    } else {
      result = await SupervisorService.createLocation(
        name: name,
        address: address,
        latitude: _latitude,
        longitude: _longitude,
        radius: radius,
        checkInTime: checkInStr,
        checkOutTime: checkOutStr,
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result['success'] == true) {
      setState(() {
        _needsGpsSetup = false;
      });
      if (result['data'] != null && result['data']['id'] != null) {
        _locationId = result['data']['id'];
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Lokasi berhasil disimpan.'),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
      if (widget.onLocationSaved != null) {
        widget.onLocationSaved!();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal menyimpan lokasi.'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SmartPklHeader(
              title: 'Lokasi PKL',
              subtitle: 'Penentuan Titik Koordinat Kantor',
              showBackButton: Navigator.canPop(context),
              onBackTap: () => Navigator.maybePop(context),
              onProfileTap: widget.onProfileTap,
            ),
            Expanded(
              child: _isLoadingData
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Judul & Penjelasan Section
                          const Text(
                            'Penentuan Titik Lokasi Kantor',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tentukan koordinat presisi instansi untuk acuan absensi siswa PKL.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Card Nama Instansi / Perusahaan
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.cardBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.apartment_rounded,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _nameController,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      border: InputBorder.none,
                                      hintText: 'Nama Perusahaan / Instansi',
                                      hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                                    ),
                                  ),
                                ),
                                const Icon(Icons.edit_rounded, size: 18, color: AppColors.textMuted),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (_needsGpsSetup) ...[
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF93C5FD)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.gps_fixed_rounded,
                                      color: Color(0xFF2563EB),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Pengambilan Titik Lokasi Kantor via GPS',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF1E40AF),
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Admin mendaftarkan instansi Anda tanpa titik GPS. Posisi Anda saat ini otomatis dideteksi dari sensor GPS HP. Pastikan Anda berada di area kantor, lalu klik Simpan Lokasi di bawah.',
                                          style: TextStyle(fontSize: 11, color: Color(0xFF1E3A8A), height: 1.4),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Warning Banner: Wajib dilakukan di lingkungan kantor
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFFECDD3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF43F5E).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Color(0xFFE11D48),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Wajib Dilakukan di Lingkungan Kantor/Pabrik!',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFFBE123C),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      RichText(
                                        text: const TextSpan(
                                          style: TextStyle(fontSize: 11, color: Color(0xFF9F1239), height: 1.4),
                                          children: [
                                            TextSpan(text: 'Koordinat ini akan menjadi acuan radius absensi '),
                                            TextSpan(
                                              text: 'geofencing ',
                                              style: TextStyle(fontWeight: FontWeight.w800),
                                            ),
                                            TextSpan(text: 'siswa PKL Anda saat check-in harian.'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Visual Map Card Mockup Sesuai Gambar (Interaktif: Geser & Klik Pin Langsung Menghitung Koordinat)
                          Container(
                            height: 250,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFBAE6FD)),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final double mapW = constraints.maxWidth;
                                const double mapH = 250.0;
                                final double centerX = mapW / 2;
                                const double centerY = 95.0; // titik tengah map (di atas tombol Gunakan Lokasi)
                                final double maxDx = (mapW / 2) - 45;
                                const double maxDy = 65.0;

                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Stack(
                                    children: [
                                      // Area interaksi geser & klik peta
                                      Positioned.fill(
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTapDown: (details) {
                                            // Jangan proses jika menekan area tombol bawah
                                            if (details.localPosition.dy > 185) return;
                                            final double targetX = (details.localPosition.dx - centerX).clamp(-maxDx, maxDx);
                                            final double targetY = (details.localPosition.dy - centerY).clamp(-maxDy, maxDy);
                                            final Offset targetOffset = Offset(targetX, targetY);
                                            final Offset delta = targetOffset - _pinOffset;
                                            final double sensitivity = 0.000025 / _zoom;

                                            setState(() {
                                              _pinOffset = targetOffset;
                                              _latitude -= delta.dy * sensitivity;
                                              _longitude += delta.dx * sensitivity;
                                              _latController.text = _latitude.toStringAsFixed(6);
                                              _lngController.text = _longitude.toStringAsFixed(6);
                                            });
                                          },
                                          onPanStart: (_) {
                                            setState(() => _isDraggingMap = true);
                                          },
                                          onPanUpdate: (details) {
                                            final double sensitivity = 0.000025 / _zoom;
                                            final double newX = (_pinOffset.dx + details.delta.dx).clamp(-maxDx, maxDx);
                                            final double newY = (_pinOffset.dy + details.delta.dy).clamp(-maxDy, maxDy);

                                            setState(() {
                                              _pinOffset = Offset(newX, newY);
                                              _latitude -= details.delta.dy * sensitivity;
                                              _longitude += details.delta.dx * sensitivity;
                                              _latController.text = _latitude.toStringAsFixed(6);
                                              _lngController.text = _longitude.toStringAsFixed(6);
                                            });
                                          },
                                          onPanEnd: (_) {
                                            setState(() => _isDraggingMap = false);
                                          },
                                          onPanCancel: () {
                                            setState(() => _isDraggingMap = false);
                                          },
                                          child: CustomPaint(
                                            size: Size(mapW, mapH),
                                            painter: _MockupMapPainter(
                                              panOffset: _pinOffset,
                                              zoom: _zoom,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Pin & Radius Geofence (bergerak real-time mengikuti sentuhan / offset)
                                      Positioned(
                                        left: centerX + _pinOffset.dx - 75,
                                        top: centerY + _pinOffset.dy - 75,
                                        child: IgnorePointer(
                                          child: SizedBox(
                                            width: 150,
                                            height: 150,
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                // Outer Geofence Ring
                                                AnimatedContainer(
                                                  duration: const Duration(milliseconds: 150),
                                                  width: _isDraggingMap ? 160 : 150,
                                                  height: _isDraggingMap ? 160 : 150,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: const Color(0xFF2563EB).withValues(alpha: 0.18),
                                                    border: Border.all(
                                                      color: const Color(0xFF2563EB).withValues(alpha: 0.5),
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                ),

                                                // Inner Geofence Ring
                                                Container(
                                                  width: 80,
                                                  height: 80,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                                                  ),
                                                ),

                                                // Pin Marker
                                                AnimatedScale(
                                                  scale: _isDraggingMap ? 1.15 : 1.0,
                                                  duration: const Duration(milliseconds: 150),
                                                  child: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.all(8),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFF2563EB),
                                                          shape: BoxShape.circle,
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors.black.withValues(alpha: _isDraggingMap ? 0.35 : 0.2),
                                                              blurRadius: _isDraggingMap ? 12 : 8,
                                                              offset: Offset(0, _isDraggingMap ? 6 : 3),
                                                            ),
                                                          ],
                                                        ),
                                                        child: const Icon(
                                                          Icons.location_on_rounded,
                                                          color: Colors.white,
                                                          size: 24,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Container(
                                                        width: 8,
                                                        height: 4,
                                                        decoration: BoxDecoration(
                                                          color: Colors.black26,
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Top-Left GPS Status Pill
                                      Positioned(
                                        top: 12,
                                        left: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.95),
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.08),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF16A34A),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                _statusMessage,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Top-Right Zoom Buttons (+ / -)
                                      Positioned(
                                        top: 12,
                                        right: 12,
                                        child: Column(
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _zoom = (_zoom * 1.25).clamp(0.5, 3.0);
                                                });
                                              },
                                              child: Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(8),
                                                  boxShadow: const [
                                                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                                                  ],
                                                ),
                                                child: const Icon(Icons.add, size: 18, color: AppColors.textPrimary),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _zoom = (_zoom / 1.25).clamp(0.5, 3.0);
                                                });
                                              },
                                              child: Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(8),
                                                  boxShadow: const [
                                                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                                                  ],
                                                ),
                                                child: const Icon(Icons.remove, size: 18, color: AppColors.textPrimary),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Bottom Button: "Gunakan Lokasi Saya Sekarang"
                                      Positioned(
                                        bottom: 12,
                                        left: 16,
                                        right: 16,
                                        child: ElevatedButton.icon(
                                          onPressed: _isLoadingGps ? null : _getCurrentGpsLocation,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: const Color(0xFF2563EB),
                                            elevation: 3,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              side: const BorderSide(color: Color(0xFFBFDBFE), width: 1),
                                            ),
                                          ),
                                          icon: _isLoadingGps
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                )
                                              : const Icon(Icons.my_location_rounded, size: 18, color: Color(0xFF2563EB)),
                                          label: Text(
                                            _isLoadingGps ? 'Mendeteksi...' : 'Gunakan Lokasi Saya Sekarang',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF2563EB),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Petunjuk interaksi pin
                          const Row(
                            children: [
                              Icon(Icons.touch_app_rounded, size: 16, color: AppColors.textMuted),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Geser pin atau klik titik pada peta untuk menentukan koordinat presisi secara otomatis.',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Latitude & Longitude Box (Interaktif: Terhitung otomatis saat pin digeser / dapat diedit manual)
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.arrow_upward_rounded, size: 13, color: AppColors.textMuted),
                                          SizedBox(width: 4),
                                          Text(
                                            'Latitude',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          Spacer(),
                                          Icon(Icons.edit_outlined, size: 12, color: AppColors.textMuted),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      TextField(
                                        controller: _latController,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF2563EB),
                                        ),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(vertical: 2),
                                          border: InputBorder.none,
                                          hintText: '-5.123456',
                                        ),
                                        onChanged: (val) {
                                          final parsed = double.tryParse(val.trim().replaceAll(',', '.'));
                                          if (parsed != null) {
                                            setState(() {
                                              _latitude = parsed;
                                            });
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.arrow_forward_rounded, size: 13, color: AppColors.textMuted),
                                          SizedBox(width: 4),
                                          Text(
                                            'Longitude',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          Spacer(),
                                          Icon(Icons.edit_outlined, size: 12, color: AppColors.textMuted),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      TextField(
                                        controller: _lngController,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF2563EB),
                                        ),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(vertical: 2),
                                          border: InputBorder.none,
                                          hintText: '105.123456',
                                        ),
                                        onChanged: (val) {
                                          final parsed = double.tryParse(val.trim().replaceAll(',', '.'));
                                          if (parsed != null) {
                                            setState(() {
                                              _longitude = parsed;
                                            });
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Radius Geofence Input Box
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3E8FF),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.radar_rounded, color: Color(0xFF7C3AED), size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Radius Geofencing (Meter)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      TextField(
                                        controller: _radiusController,
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          border: InputBorder.none,
                                          hintText: 'Minimal 10 meter (contoh: 50)',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Text(
                                  'Meter',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Card Alamat Terdeteksi Otomatis / Edit
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.business_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Alamat Terdeteksi Otomatis',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      TextField(
                                        controller: _addressController,
                                        maxLines: 2,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                          height: 1.3,
                                        ),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                          border: InputBorder.none,
                                          hintText: 'Tulis alamat lengkap instansi...',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Card Pengaturan Jam Kerja Kantor & Validasi Otomatis DUDI
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.cardBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.schedule_rounded,
                                        color: Color(0xFF2563EB),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Aturan Jam Kerja Kantor Mitra',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            'Diatur oleh DU/DI untuk validasi otomatis kehadiran siswa',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Row 2 Waktu: Jam Masuk & Jam Pulang
                                Row(
                                  children: [
                                    // 1. Jam Masuk Kantor
                                    Expanded(
                                      child: InkWell(
                                        onTap: () async {
                                          final picked = await showTimePicker(
                                            context: context,
                                            initialTime: _checkInTime,
                                            helpText: 'TENTUKAN JAM MASUK KERJA',
                                            cancelText: 'Batal',
                                            confirmText: 'Pilih',
                                          );
                                          if (picked != null) {
                                            setState(() => _checkInTime = picked);
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Row(
                                                children: [
                                                  Icon(Icons.login_rounded, size: 13, color: Color(0xFF16A34A)),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Jam Masuk Kerja',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                      color: Color(0xFF16A34A),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    '${_formatTimeOfDay(_checkInTime)} WIB',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w800,
                                                      color: AppColors.textPrimary,
                                                    ),
                                                  ),
                                                  const Icon(Icons.edit_calendar_rounded, size: 16, color: Color(0xFF2563EB)),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              const Text(
                                                'Batas tepat waktu (<= jam ini)',
                                                style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),

                                    // 2. Jam Pulang Kantor
                                    Expanded(
                                      child: InkWell(
                                        onTap: () async {
                                          final picked = await showTimePicker(
                                            context: context,
                                            initialTime: _checkOutTime,
                                            helpText: 'TENTUKAN JAM PULANG KERJA',
                                            cancelText: 'Batal',
                                            confirmText: 'Pilih',
                                          );
                                          if (picked != null) {
                                            setState(() => _checkOutTime = picked);
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Row(
                                                children: [
                                                  Icon(Icons.logout_rounded, size: 13, color: Color(0xFFD97706)),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Jam Pulang Kerja',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                      color: Color(0xFFD97706),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    '${_formatTimeOfDay(_checkOutTime)} WIB',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w800,
                                                      color: AppColors.textPrimary,
                                                    ),
                                                  ),
                                                  const Icon(Icons.edit_calendar_rounded, size: 16, color: Color(0xFF2563EB)),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              const Text(
                                                'Batas akhir jam kantor',
                                                style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Tombol Simpan
                          CustomButton(
                            text: _isSaving ? 'Menyimpan Titik Lokasi...' : 'Simpan',
                            icon: Icons.send_rounded,
                            color: const Color(0xFF2563EB),
                            isLoading: _isSaving,
                            onPressed: () {
                              if (!_isSaving) {
                                _saveLocation();
                              }
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter untuk menciptakan visual mockup peta yang bersih & modern
class _MockupMapPainter extends CustomPainter {
  final Offset panOffset;
  final double zoom;

  _MockupMapPainter({this.panOffset = Offset.zero, this.zoom = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(panOffset.dx * 0.25, panOffset.dy * 0.25);

    final bgPaint = Paint()..color = const Color(0xFFE8F0FE);
    canvas.drawRect(Rect.fromLTWH(-60, -60, size.width + 120, size.height + 120), bgPaint);

    final double effectiveZoom = zoom.clamp(0.7, 1.6);

    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 14 * effectiveZoom
      ..style = PaintingStyle.stroke;

    final roadOutline = Paint()
      ..color = const Color(0xFFD0E1FD)
      ..strokeWidth = 18 * effectiveZoom
      ..style = PaintingStyle.stroke;

    // Jalan arteri utama
    final Path roadPath1 = Path()
      ..moveTo(-30, size.height * 0.4)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.6, size.width + 30, size.height * 0.3);

    canvas.drawPath(roadPath1, roadOutline);
    canvas.drawPath(roadPath1, roadPaint);

    final Path roadPath2 = Path()
      ..moveTo(size.width * 0.4, -30)
      ..lineTo(size.width * 0.6, size.height + 30);

    canvas.drawPath(roadPath2, roadOutline);
    canvas.drawPath(roadPath2, roadPaint);

    // Green parks
    final parkPaint = Paint()..color = const Color(0xFFD1FAE5).withValues(alpha: 0.7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(10, 10, size.width * 0.3, size.height * 0.35),
        const Radius.circular(16),
      ),
      parkPaint,
    );

    // Building blocks
    final buildingPaint = Paint()..color = const Color(0xFFE2E8F0).withValues(alpha: 0.6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.65, size.height * 0.5, size.width * 0.28, size.height * 0.4),
        const Radius.circular(12),
      ),
      buildingPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MockupMapPainter oldDelegate) {
    return oldDelegate.panOffset != panOffset || oldDelegate.zoom != zoom;
  }
}
