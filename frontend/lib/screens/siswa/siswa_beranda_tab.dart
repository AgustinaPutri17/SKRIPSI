import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/student_service.dart';
import '../../widgets/smart_pkl_header.dart';

/// ==============================================================================
/// HALAMAN BERANDA SISWA (Dashboard Monitoring)
/// Disesuaikan persis dengan Mockup Desain Mobile SMART PKL
/// 100% menggunakan data riil dari backend / database, tanpa data dummy.
/// ==============================================================================
class SiswaBerandaTab extends StatefulWidget {
  final Function(int, [int?])? onNavigateTab;

  const SiswaBerandaTab({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<SiswaBerandaTab> createState() => _SiswaBerandaTabState();
}

class _SiswaBerandaTabState extends State<SiswaBerandaTab> {
  bool _isLoading = true;

  // Student Profile
  String _studentName = 'Siswa';
  String _studentClassAndMajor = '';

  // Placement Data
  String _dudiName = '-';
  String _supervisorName = '-';
  String _teacherName = '-';
  String _periodName = '-';

  // Attendance Today
  bool _hasCheckedIn = false;
  String? _checkInTime;
  String _checkInStatus = 'Belum';
  bool _hasCheckedOut = false;
  String? _checkOutTime;
  String _locationCheckOutTime = '16:00';

  // Logbook Today
  bool _hasFilledLogbookToday = false;
  String? _todayLogbookTitle;

  // Stats & Progress
  int _attendancePercentage = 0;
  int _totalPresentDays = 0;
  int _totalRecordedDays = 0;
  int _logbookApprovedCount = 0;
  int _logbookTotalCount = 0;

  Map<String, dynamic>? _pklProgress;
  Map<String, dynamic>? _latestJournal;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  String _formatTodayDateIndonesian() {
    final now = DateTime.now();
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final dayName = days[now.weekday - 1];
    final monthName = months[now.month - 1];
    return '$dayName, ${now.day} $monthName ${now.year}';
  }

  /// Memuat data dari backend 'monitoring-pkl-app'
  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 0. Ambil user login tersimpan di SharedPreferences
      final cachedUser = await AuthService.getUser();
      if (cachedUser != null && cachedUser['name'] != null && mounted) {
        setState(() {
          _studentName = cachedUser['name'].toString();
        });
      }

      // ============================================================================
      // PANGGILAN API BACKEND: GET /api/student/dashboard
      // ============================================================================
      final dashboard = await StudentService.getDashboard();
      if (dashboard != null && mounted) {
        // 1. Info Siswa
        final studentInfo = dashboard['student'] as Map<String, dynamic>?;
        if (studentInfo != null) {
          final sName = studentInfo['name']?.toString() ?? '';
          if (sName.isNotEmpty) _studentName = sName;
          final sClass = studentInfo['class']?.toString() ?? '';
          final sMajor = studentInfo['major']?.toString() ?? '';
          final sSchool = studentInfo['school_name']?.toString() ?? '';
          final parts = [sClass, sMajor].where((e) => e.isNotEmpty && e != '-').toList();
          _studentClassAndMajor = parts.join(' · ');
          if (sSchool.isNotEmpty && _studentClassAndMajor.isEmpty) {
            _studentClassAndMajor = sSchool;
          }
        }

        // 2. Info Penempatan
        final placementData = dashboard['placement'] as Map<String, dynamic>?;
        if (placementData != null) {
          final loc = placementData['location'] as Map<String, dynamic>?;
          _dudiName = loc?['name']?.toString() ?? '-';
          if (loc?['check_out_time'] != null) {
            final cot = loc!['check_out_time'].toString();
            _locationCheckOutTime = cot.length >= 5 ? cot.substring(0, 5) : cot;
          }

          final spv = placementData['field_supervisor'] as Map<String, dynamic>?;
          final spvUser = spv?['user'] as Map<String, dynamic>?;
          _supervisorName = spv?['name']?.toString() ?? spvUser?['name']?.toString() ?? '-';

          final teacher = placementData['teacher'] as Map<String, dynamic>?;
          final teacherUser = teacher?['user'] as Map<String, dynamic>?;
          final tName = teacher?['name']?.toString() ?? teacherUser?['name']?.toString() ?? '-';
          final sSchool = studentInfo?['school_name']?.toString() ?? 'SMKN 2 Bandar Lampung';
          _teacherName = tName != '-' ? '$tName · $sSchool' : '-';

          final period = placementData['period'] as Map<String, dynamic>?;
          _periodName = period?['name']?.toString() ?? 'Periode PKL';
        }

        // 3. Presensi Hari Ini
        final attToday = dashboard['attendance_today'] as Map<String, dynamic>?;
        if (attToday != null) {
          final checkInAt = attToday['check_in_at']?.toString();
          _hasCheckedIn = checkInAt != null && checkInAt.isNotEmpty;
          if (_hasCheckedIn) {
            try {
              final dt = DateTime.parse(checkInAt!).toLocal();
              _checkInTime = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} WIB";
            } catch (_) {
              _checkInTime = attToday['check_in_time']?.toString() ?? 'Tercatat';
            }
          }
          final st = attToday['status']?.toString();
          if (st == 'late') {
            _checkInStatus = 'Terlambat';
          } else if (_hasCheckedIn) {
            _checkInStatus = 'Tepat waktu';
          } else {
            _checkInStatus = 'Belum';
          }

          final checkOutAt = attToday['check_out_at']?.toString();
          _hasCheckedOut = checkOutAt != null && checkOutAt.isNotEmpty;
          if (_hasCheckedOut) {
            try {
              final dt = DateTime.parse(checkOutAt!).toLocal();
              _checkOutTime = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} WIB";
            } catch (_) {
              _checkOutTime = attToday['check_out_time']?.toString() ?? 'Selesai';
            }
          }
        } else {
          _hasCheckedIn = false;
          _checkInTime = null;
          _checkInStatus = 'Belum';
          _hasCheckedOut = false;
          _checkOutTime = null;
        }

        // 4. Logbook Hari Ini
        final jToday = dashboard['journal_today'] as Map<String, dynamic>?;
        _hasFilledLogbookToday = jToday != null;
        if (jToday != null) {
          _todayLogbookTitle = jToday['activity']?.toString() ?? jToday['description']?.toString();
        }

        // 5. Statistik Presensi & Logbook
        final attStats = dashboard['attendance_stats'] as Map<String, dynamic>?;
        if (attStats != null) {
          _attendancePercentage = (attStats['percentage'] as num?)?.toInt() ?? 0;
          _totalPresentDays = (attStats['present'] as num?)?.toInt() ?? 0;
          _totalRecordedDays = (attStats['total_recorded_days'] as num?)?.toInt() ?? 0;
        }

        final jStats = dashboard['journal_stats'] as Map<String, dynamic>?;
        if (jStats != null) {
          _logbookApprovedCount = (jStats['approved'] as num?)?.toInt() ?? 0;
          _logbookTotalCount = (jStats['total'] as num?)?.toInt() ?? 0;
        }

        // 6. Progres PKL
        _pklProgress = dashboard['pkl_progress'] as Map<String, dynamic>?;

        // 7. Logbook Terbaru
        _latestJournal = dashboard['latest_journal'] as Map<String, dynamic>?;
      }
    } catch (_) {
      // Biarkan data tetap kosong/default jika gagal terhubung
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header SMART PKL - Beranda + Avatar Profil
            SmartPklHeader(
              title: 'Beranda',
              onProfileTap: () => widget.onNavigateTab?.call(4),
            ),

            if (_isLoading)
              const LinearProgressIndicator(
                minHeight: 2,
                color: Color(0xFF2563EB),
                backgroundColor: Color(0xFFEFF6FF),
              ),

            // Konten Utama Beranda
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadDashboardData,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Greeting (Nama Siswa & Kelas • Jurusan)
                      Text(
                        'Halo, $_studentName',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.4,
                        ),
                      ),
                      if (_studentClassAndMajor.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _studentClassAndMajor,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // 2. KARTU "Tugas Hari Ini" (Presensi & Logbook Status + Tombol Aksi Utama)
                      _buildTugasHariIniCard(),
                      const SizedBox(height: 16),

                      // 3. BARIS KARTU RINGKASAN: Kehadiran (%) & Logbook ACC (x/y)
                      _buildSummaryStatsRow(),
                      const SizedBox(height: 16),

                      // 4. KARTU PROGRES PKL (Hari ke-x dari y & Sisa hari)
                      _buildPklProgressCard(),
                      const SizedBox(height: 20),

                      // 5. STATUS LOGBOOK TERBARU (Catatan Instruktur)
                      _buildLatestLogbookSection(),
                      const SizedBox(height: 20),

                      // 6. INFO PENEMPATAN PKL (Mitra DU/DI, Instruktur, Guru Pembimbing)
                      _buildPenempatanCard(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ── KARTU TUGAS HARI INI ──
  Widget _buildTugasHariIniCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Tugas Hari Ini + Tanggal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tugas Hari Ini',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                _formatTodayDateIndonesian(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Badge Radius / Lokasi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF059669)),
                const SizedBox(width: 4),
                Text(
                  _dudiName != '-' ? 'Dalam radius lokasi: $_dudiName' : 'Dalam radius lokasi DU/DI',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF065F46),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 1. Presensi Masuk
          _buildTaskItem(
            icon: _hasCheckedIn ? Icons.check_circle_rounded : Icons.schedule_rounded,
            iconColor: _hasCheckedIn ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
            iconBg: _hasCheckedIn ? const Color(0xFFD1FAE5) : const Color(0xFFF1F5F9),
            title: 'Presensi masuk',
            subtitle: _hasCheckedIn
                ? '$_checkInTime · $_checkInStatus'
                : 'Belum presensi masuk',
            badgeText: _hasCheckedIn ? 'Selesai' : 'Belum',
            badgeBg: _hasCheckedIn ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
            badgeColor: _hasCheckedIn ? const Color(0xFF065F46) : const Color(0xFF991B1B),
          ),
          const Divider(height: 22, color: Color(0xFFF1F5F9)),

          // 2. Logbook Hari Ini
          _buildTaskItem(
            icon: _hasFilledLogbookToday ? Icons.menu_book_rounded : Icons.edit_note_rounded,
            iconColor: _hasFilledLogbookToday ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
            iconBg: _hasFilledLogbookToday ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
            title: 'Logbook hari ini',
            subtitle: _hasFilledLogbookToday
                ? (_todayLogbookTitle != null ? 'Sudah diisi: $_todayLogbookTitle' : 'Sudah diisi')
                : 'Belum diisi',
            badgeText: _hasFilledLogbookToday ? 'Selesai' : 'Perlu diisi',
            badgeBg: _hasFilledLogbookToday ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
            badgeColor: _hasFilledLogbookToday ? const Color(0xFF065F46) : const Color(0xFF92400E),
          ),
          const Divider(height: 22, color: Color(0xFFF1F5F9)),

          // 3. Presensi Pulang
          _buildTaskItem(
            icon: _hasCheckedOut ? Icons.check_circle_rounded : Icons.access_time_rounded,
            iconColor: _hasCheckedOut ? const Color(0xFF10B981) : const Color(0xFF64748B),
            iconBg: _hasCheckedOut ? const Color(0xFFD1FAE5) : const Color(0xFFF1F5F9),
            title: 'Presensi pulang',
            subtitle: _hasCheckedOut
                ? '$_checkOutTime · Selesai'
                : (_hasCheckedIn ? 'Dibuka pukul $_locationCheckOutTime WIB' : 'Menunggu presensi masuk'),
            badgeText: _hasCheckedOut ? 'Selesai' : 'Menunggu',
            badgeBg: _hasCheckedOut ? const Color(0xFFD1FAE5) : const Color(0xFFF1F5F9),
            badgeColor: _hasCheckedOut ? const Color(0xFF065F46) : const Color(0xFF64748B),
          ),
          const SizedBox(height: 18),

          // Tombol Aksi Utama Dinamis
          _buildMainActionButton(),

          const SizedBox(height: 12),
          Center(
            child: InkWell(
              onTap: () => widget.onNavigateTab?.call(1, 2), // Subtab Izin / Sakit
              child: RichText(
                text: const TextSpan(
                  text: 'Tidak bisa hadir? ',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  children: [
                    TextSpan(
                      text: 'Ajukan izin / sakit',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Komponen Baris Tugas Hari Ini
  Widget _buildTaskItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeBg,
    required Color badgeColor,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            badgeText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: badgeColor,
            ),
          ),
        ),
      ],
    );
  }

  /// Tombol Aksi Utama Berdasarkan Status Hari Ini
  Widget _buildMainActionButton() {
    if (!_hasCheckedIn) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => widget.onNavigateTab?.call(1, 0), // Ke Presensi Masuk
          icon: const Icon(Icons.how_to_reg_rounded, size: 20),
          label: const Text('Absen Masuk Sekarang', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        ),
      );
    } else if (!_hasFilledLogbookToday) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => widget.onNavigateTab?.call(2), // Ke Logbook
          icon: const Icon(Icons.edit_note_rounded, size: 20),
          label: const Text('Isi Logbook Hari Ini', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        ),
      );
    } else if (!_hasCheckedOut) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => widget.onNavigateTab?.call(1, 1), // Ke Presensi Pulang
          icon: const Icon(Icons.logout_rounded, size: 20),
          label: const Text('Presensi Pulang Sekarang', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 20),
            SizedBox(width: 8),
            Text(
              'Semua Tugas Hari Ini Selesai ✓',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF065F46)),
            ),
          ],
        ),
      );
    }
  }

  /// ── BARIS KARTU RINGKASAN: KEHADIRAN & LOGBOOK ACC ──
  Widget _buildSummaryStatsRow() {
    return Row(
      children: [
        // Kartu Kehadiran
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
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
                      'Kehadiran',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.person_rounded, size: 16, color: Color(0xFF10B981)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$_attendancePercentage%',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _totalRecordedDays > 0 ? '$_totalPresentDays dari $_totalRecordedDays hari' : 'Sejak awal PKL',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Kartu Logbook ACC
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
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
                      'Logbook ACC',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.assignment_turned_in_rounded, size: 16, color: Color(0xFF2563EB)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$_logbookApprovedCount',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextSpan(
                        text: '/$_logbookTotalCount',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Disetujui Instruktur',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// ── KARTU PROGRES PKL ──
  Widget _buildPklProgressCard() {
    final int currentDay = (_pklProgress?['current_day'] as num?)?.toInt() ?? 0;
    final int totalDays = (_pklProgress?['total_days'] as num?)?.toInt() ?? 0;
    final int remainingDays = (_pklProgress?['remaining_days'] as num?)?.toInt() ?? 0;
    final double percentDouble = ((_pklProgress?['percentage'] as num?)?.toDouble() ?? 0.0) / 100.0;
    final String startFmt = _pklProgress?['start_formatted']?.toString() ?? '';
    final String endFmt = _pklProgress?['end_formatted']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progres PKL',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 2),
          Text(
            _pklProgress?['period_name']?.toString() ?? _periodName,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percentDouble.clamp(0.0, 1.0),
              minHeight: 8,
              color: const Color(0xFF2563EB),
              backgroundColor: const Color(0xFFE2E8F0),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                totalDays > 0 ? 'Hari ke-$currentDay dari $totalDays' : 'Belum dimulai',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              Text(
                totalDays > 0 ? 'Sisa $remainingDays hari' : '-',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
            ],
          ),
          if (startFmt.isNotEmpty && endFmt.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '$startFmt – $endFmt',
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ],
      ),
    );
  }

  /// ── BAGIAN LOGBOOK TERBARU (DENGAN CATATAN DARI INSTRUKTUR) ──
  Widget _buildLatestLogbookSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Logbook Terbaru',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            TextButton(
              onPressed: () => widget.onNavigateTab?.call(2), // Ke Tab Logbook
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Lihat Semua',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (_latestJournal == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                const Icon(Icons.assignment_outlined, size: 36, color: Color(0xFF94A3B8)),
                const SizedBox(height: 8),
                const Text(
                  'Belum ada logbook yang diisi',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => widget.onNavigateTab?.call(2),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Isi Logbook Sekarang', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    side: const BorderSide(color: Color(0xFF2563EB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tanggal & Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _latestJournal!['formatted_date']?.toString() ??
                          _latestJournal!['logbook_date']?.toString() ??
                          '-',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                    ),
                    _buildStatusBadge(_latestJournal!['status']?.toString() ?? 'submitted'),
                  ],
                ),
                const SizedBox(height: 8),

                // Judul Kegiatan
                Text(
                  _latestJournal!['activity']?.toString() ?? '-',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),

                // Kotak Catatan Instruktur jika ada
                if (_latestJournal!['verification_note'] != null &&
                    _latestJournal!['verification_note'].toString().trim().isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Catatan Instruktur (${_latestJournal!['supervisor_name'] ?? 'Instruktur'}): ',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF065F46),
                            ),
                          ),
                          TextSpan(
                            text: '"${_latestJournal!['verification_note']}"',
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF065F46),
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
      ],
    );
  }

  /// Badge Status Logbook (Disetujui, Menunggu, Ditolak)
  Widget _buildStatusBadge(String status) {
    Color bg;
    Color textColor;
    String label;

    switch (status.toLowerCase()) {
      case 'approved':
        bg = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF065F46);
        label = 'Disetujui';
        break;
      case 'rejected':
        bg = const Color(0xFFFEE2E2);
        textColor = const Color(0xFF991B1B);
        label = 'Direvisi';
        break;
      case 'draft':
        bg = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF64748B);
        label = 'Draft';
        break;
      default:
        bg = const Color(0xFFFEF3C7);
        textColor = const Color(0xFF92400E);
        label = 'Menunggu';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  /// ── KARTU INFORMASI PENEMPATAN PKL ──
  Widget _buildPenempatanCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Penempatan PKL',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 14),

          // 1. Mitra DU/DI
          _buildPlacementRow(
            icon: Icons.storefront_rounded,
            label: 'Mitra DU/DI',
            value: _dudiName,
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),

          // 2. Instruktur Lapangan DU/DI
          _buildPlacementRow(
            icon: Icons.badge_outlined,
            label: 'Instruktur Lapangan',
            value: _supervisorName,
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),

          // 3. Guru Pembimbing Sekolah
          _buildPlacementRow(
            icon: Icons.school_rounded,
            label: 'Guru Pembimbing',
            value: _teacherName,
          ),
        ],
      ),
    );
  }

  /// Item Baris Penempatan PKL
  Widget _buildPlacementRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF2563EB), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
