import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/supervisor_service.dart';
import '../../widgets/smart_pkl_header.dart';
import '../../widgets/status_pill.dart';
import '../../routes/app_routes.dart';
import '../common/ganti_password_screen.dart';
import 'dudi_lokasi_screen.dart';
import 'dudi_logbook_detail_screen.dart';
import 'dudi_penilaian_screen.dart';
import 'dudi_projek_detail_screen.dart';

/// ==============================================================================
/// HALAMAN UTAMA PEMBIMBING DUDI (SMART PKL)
///
/// Modul Terintegrasi:
/// 7.1 Dashboard dan Siswa Bimbingan:
///     - GET /api/supervisor/dashboard
///     - GET /api/supervisor/students
///     - GET /api/supervisor/students/{id}
/// 7.2 Manajemen Lokasi PKL oleh DUDI (locations):
///     - GET /api/supervisor/locations
///     - POST /api/supervisor/locations
///     - GET /api/supervisor/locations/{id}
///     - PUT /api/supervisor/locations/{id}
/// 7.3 Verifikasi Logbook:
///     - GET /api/supervisor/logbooks (filter: submitted, approved, rejected)
///     - GET /api/supervisor/logbooks/{id}
///     - POST /api/supervisor/logbooks/{id}/approve
///     - POST /api/supervisor/logbooks/{id}/reject
/// ==============================================================================
class DudiMainScreen extends StatefulWidget {
  final int initialIndex;

  const DudiMainScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<DudiMainScreen> createState() => _DudiMainScreenState();
}

class _DudiMainScreenState extends State<DudiMainScreen> {
  late int _currentIndex;

  // ── Data States ──
  bool _isLoadingStudents = false;
  bool _isLoadingLogbooks = false;
  bool _isLoadingProjects = false;

  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? _currentUser;
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _logbooks = [];
  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _locations = [];
  final Map<String, double> _studentScores = {};

  final String _selectedLogbookFilter = 'all'; // 'all', 'submitted', 'approved', 'rejected'
  int _studentAttendanceFilter = 0; // 0: Semua, 1: Hadir, 2: Belum Hadir

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadAllData();
  }

  void _onTabTapped(int index) {
    final safeIndex = index.clamp(0, 4);
    setState(() {
      _currentIndex = safeIndex;
    });
    if (safeIndex == 0) _loadDashboard();
    if (safeIndex == 1) _loadStudents();
    if (safeIndex == 2) _loadLogbooks();
    if (safeIndex == 3) _loadProjects();
  }

  Future<void> _loadAllData() async {
    final user = await AuthService.getUser();
    if (mounted) setState(() => _currentUser = user);
    await Future.wait([
      _loadDashboard(),
      _loadStudents(),
      _loadLogbooks(),
      _loadProjects(),
      _loadLocations(),
    ]);
  }

  Future<void> _loadDashboard() async {
    final data = await SupervisorService.getDashboard();
    if (mounted) {
      setState(() {
        _dashboardData = data;
      });
    }
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoadingStudents = true);
    final list = await SupervisorService.getStudents();
    if (mounted) {
      setState(() {
        _students = list;
        for (final s in list) {
          final sId = s['id']?.toString() ?? s['nis']?.toString() ?? s['name']?.toString() ?? '';
          if (s['dudi_score'] != null) {
            final val = double.tryParse(s['dudi_score'].toString());
            if (val != null) _studentScores[sId] = val;
          }
        }
        _isLoadingStudents = false;
      });
    }
  }

  Future<void> _loadLogbooks() async {
    setState(() => _isLoadingLogbooks = true);
    final status = _selectedLogbookFilter == 'all' ? null : _selectedLogbookFilter;
    final list = await SupervisorService.getLogbooks(status: status);
    if (mounted) {
      setState(() {
        _logbooks = list;
        _isLoadingLogbooks = false;
      });
    }
  }

  Future<void> _loadLocations() async {
    final list = await SupervisorService.getLocations();
    if (mounted) {
      setState(() {
        _locations = list;
      });
    }
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoadingProjects = true);
    try {
      final list = await SupervisorService.getProjects();
      if (mounted) {
        setState(() {
          _projects = list;
          _isLoadingProjects = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingProjects = false);
    }
  }

  void _openLokasiSetting() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DudiLokasiScreen(
          initialLocation: _locations.isNotEmpty ? _locations.first : null,
          onLocationSaved: () => _loadLocations(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildBerandaTab(),
      _buildSiswaTab(),
      _buildLogbookTab(),
      _buildProjekTab(),
      _buildProfilTab(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.cardBorder.withValues(alpha: 0.8), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF2563EB),
          unselectedItemColor: const Color(0xFF64748B),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.dashboard_rounded, size: 22),
              ),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.assignment_turned_in_outlined, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.assignment_turned_in_rounded, size: 22),
              ),
              label: 'Nilai PKL',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.fact_check_rounded, size: 22),
              ),
              label: 'Logbook',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.assignment_outlined, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.assignment_rounded, size: 22),
              ),
              label: 'Projek',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.person_outline_rounded, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.person_rounded, size: 22),
              ),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // 7.1 BERANDA / DASHBOARD DUDI
  // ============================================================================
  Widget _buildBerandaTab() {
    final companyName = _locations.isNotEmpty
        ? (_locations.first['name'] ?? 'Mitra DU/DI')
        : (_currentUser?['organization'] ?? 'Mitra DU/DI');

    final supervisorName = _currentUser?['name']?.toString() ?? 'Instruktur Lapangan';

    // 100% Real DB stats, no fake fallback
    final totalStudentsNum = (_dashboardData?['total_students'] as num?)?.toInt() ?? _students.length;
    final totalStudents = totalStudentsNum.toString();

    final attendanceTodayNum = (_dashboardData?['attendance_today'] as num?)?.toInt() ?? 0;
    final attendanceToday = attendanceTodayNum.toString();

    final unattendedCountNum = (_dashboardData?['unattended_today_count'] as num?)?.toInt() ?? (totalStudentsNum - attendanceTodayNum);
    final unattendedCount = unattendedCountNum < 0 ? '0' : unattendedCountNum.toString();

    final attendanceRate = (_dashboardData?['attendance_rate'] as num?)?.toInt().toString() ?? '0';
    final onTimeRate = (_dashboardData?['on_time_rate'] as num?)?.toInt().toString() ?? '100';

    // Strictly filter submitted logbooks for the pending queue (NO approved logbooks in pending!)
    final pendingLogbooks = _logbooks
        .where((l) => (l['status'] ?? '').toString().toLowerCase() == 'submitted')
        .toList();
    final logbookPending = (_dashboardData?['journals_pending'] as num?)?.toInt().toString() ?? pendingLogbooks.length.toString();

    // Assessment Summary
    final assessmentSummary = _dashboardData?['assessment_summary'] as Map<String, dynamic>?;
    final gradedCount = (assessmentSummary?['graded_count'] as num?)?.toInt() ?? _students.where((s) => s['dudi_score'] != null).length;
    final ungradedCount = (assessmentSummary?['ungraded_count'] as num?)?.toInt() ?? (totalStudentsNum - gradedCount);
    final avgScore = assessmentSummary?['average_score']?.toString();

    // Students Today List
    final List<dynamic> todayStudentsRaw = _dashboardData?['students_today'] is List
        ? (_dashboardData!['students_today'] as List)
        : _students.map((s) => {
            'placement_id': s['placement_id'],
            'student_id': s['id'],
            'name': s['name'],
            'nis': s['nis'],
            'class': s['class'],
            'is_present': false,
            'status': 'belum_hadir',
            'status_label': 'Belum Hadir',
            'check_in_time': null,
            'check_out_time': null,
            'is_late': false,
          }).toList();

    final filteredTodayStudents = todayStudentsRaw.where((item) {
      final isPresent = item['is_present'] == true;
      if (_studentAttendanceFilter == 1) return isPresent;
      if (_studentAttendanceFilter == 2) return !isPresent;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SmartPklHeader(
              title: 'Beranda',
              onProfileTap: () => _onTabTapped(4),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadAllData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting & Mentor Info
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Halo, $supervisorName 👋',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Instruktur Lapangan • $companyName',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Compact Location Warning Alert (Hanya jika koordinat GPS belum ditentukan)
                      if (_locations.isNotEmpty &&
                          (_locations.first['latitude'] == null || _locations.first['longitude'] == null)) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFCD34D)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_off_rounded, color: Color(0xFFD97706), size: 18),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Titik lokasi GPS kantor belum diatur.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: _openLokasiSetting,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Text(
                                    'Atur Lokasi',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // 1. Quick Stats 2x2 Grid (Database-driven)
                      Row(
                        children: [
                          _buildSummaryStat(
                            'Siswa Bimbingan',
                            totalStudents,
                            'Siswa Aktif',
                            Icons.groups_rounded,
                            const Color(0xFF2563EB),
                            const Color(0xFFEFF6FF),
                            onTap: () => _onTabTapped(1),
                          ),
                          const SizedBox(width: 12),
                          _buildSummaryStat(
                            'Presensi Masuk',
                            '$attendanceToday/$totalStudents',
                            '$unattendedCount belum hadir',
                            Icons.how_to_reg_rounded,
                            const Color(0xFF16A34A),
                            const Color(0xFFDCFCE7),
                            onTap: () => setState(() => _studentAttendanceFilter = 1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildSummaryStat(
                            'Rata-rata Hadir',
                            '$attendanceRate%',
                            '$onTimeRate% tepat waktu',
                            Icons.insights_rounded,
                            const Color(0xFF0D9488),
                            const Color(0xFFCCFBF1),
                          ),
                          const SizedBox(width: 12),
                          _buildSummaryStat(
                            'Logbook Pending',
                            logbookPending,
                            'Perlu Validasi',
                            Icons.pending_actions_rounded,
                            const Color(0xFFD97706),
                            const Color(0xFFFEF3C7),
                            onTap: () => _onTabTapped(2),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // 2. KARTU RINGKASAN PENILAIAN SISWA PKL
                      _buildAssessmentSummaryCard(
                        totalStudents: totalStudentsNum,
                        gradedCount: gradedCount,
                        ungradedCount: ungradedCount,
                        avgScore: avgScore,
                      ),
                      const SizedBox(height: 20),

                      // 3. DAFTAR SISWA YANG HADIR & BELUM HADIR HARI INI
                      _buildTodayAttendanceSection(
                        totalStudents: totalStudents,
                        attendanceToday: attendanceToday,
                        unattendedCount: unattendedCount,
                        students: filteredTodayStudents,
                      ),
                      const SizedBox(height: 22),

                      // 4. LOGBOOK MENUNGGU VALIDASI (Strictly Submitted only)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Logbook Menunggu Validasi',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (pendingLogbooks.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${pendingLogbooks.length}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFB45309),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          TextButton(
                            onPressed: () => _onTabTapped(2),
                            child: const Text('Lihat Semua'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // List Logbook Pending (Filtered strictly submitted)
                      if (_isLoadingLogbooks)
                        const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                      else if (pendingLogbooks.isEmpty)
                        _buildEmptyState('Tidak ada logbook menunggu validasi saat ini. Semua logbook sudah ditinjau ✓')
                      else
                        ...pendingLogbooks.take(3).map((j) => _buildLogbookItemCard(j)),
                      const SizedBox(height: 20),
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

  /// ── KARTU RINGKASAN PENILAIAN SISWA PKL ──
  Widget _buildAssessmentSummaryCard({
    required int totalStudents,
    required int gradedCount,
    required int ungradedCount,
    String? avgScore,
  }) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.assignment_turned_in_rounded, size: 18, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Penilaian Siswa PKL',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        'Evaluasi & Nilai Akhir DU/DI',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
              TextButton(
                onPressed: () => _onTabTapped(1), // Ke tab Nilai PKL
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Row(
                  children: [
                    Text('Buka Nilai', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF2563EB)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$gradedCount dari $totalStudents Siswa Sudah Dinilai',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              if (avgScore != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Rata-rata: $avgScore',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: totalStudents > 0 ? (gradedCount / totalStudents).clamp(0.0, 1.0) : 0.0,
              minHeight: 7,
              color: const Color(0xFF2563EB),
              backgroundColor: const Color(0xFFE2E8F0),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  ungradedCount > 0
                      ? '$ungradedCount siswa belum diberi penilaian PKL.'
                      : 'Semua siswa bimbingan telah dinilai lengkap ✓',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ungradedCount > 0 ? const Color(0xFFD97706) : const Color(0xFF059669),
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: () => _onTabTapped(1),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  side: const BorderSide(color: Color(0xFF2563EB)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Input Nilai', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ── SEKSI PRESENSI SISWA HARI INI ──
  Widget _buildTodayAttendanceSection({
    required String totalStudents,
    required String attendanceToday,
    required String unattendedCount,
    required List<dynamic> students,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Presensi Siswa Hari Ini',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$attendanceToday/$totalStudents Hadir',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Filter Segmented Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildAttendanceFilterChip('Semua ($totalStudents)', 0),
              const SizedBox(width: 8),
              _buildAttendanceFilterChip('Hadir ($attendanceToday)', 1),
              const SizedBox(width: 8),
              _buildAttendanceFilterChip('Belum Hadir ($unattendedCount)', 2),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // List Siswa
        if (students.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Center(
              child: Text(
                _studentAttendanceFilter == 1
                    ? 'Belum ada siswa yang hadir hari ini.'
                    : (_studentAttendanceFilter == 2
                        ? 'Semua siswa sudah hadir hari ini 🎉'
                        : 'Belum ada data siswa.'),
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ),
          )
        else
          ...students.map((st) => _buildTodayStudentCard(st is Map<String, dynamic> ? st : Map<String, dynamic>.from(st as Map))),
      ],
    );
  }

  /// Chip Filter Presensi
  Widget _buildAttendanceFilterChip(String label, int index) {
    final isSelected = _studentAttendanceFilter == index;
    return InkWell(
      onTap: () => setState(() => _studentAttendanceFilter = index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  /// Kartu Presensi Siswa Hari Ini
  Widget _buildTodayStudentCard(Map<String, dynamic> item) {
    final name = (item['name'] ?? 'Siswa').toString();
    final nis = (item['nis'] ?? '-').toString();
    final className = (item['class'] ?? '-').toString();
    final isPresent = item['is_present'] == true;
    final isLate = item['is_late'] == true;
    final checkInTime = item['check_in_time']?.toString();
    final statusLabel = item['status_label']?.toString() ?? (isPresent ? 'Hadir' : 'Belum Hadir');

    final initial = name.isNotEmpty
        ? name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase()
        : 'S';

    Color badgeBg;
    Color badgeText;
    IconData badgeIcon;

    if (isPresent) {
      if (isLate) {
        badgeBg = const Color(0xFFFEF3C7);
        badgeText = const Color(0xFFB45309);
        badgeIcon = Icons.schedule_rounded;
      } else {
        badgeBg = const Color(0xFFDCFCE7);
        badgeText = const Color(0xFF15803D);
        badgeIcon = Icons.check_circle_rounded;
      }
    } else {
      final st = (item['status'] ?? '').toString();
      if (st == 'sick' || st == 'permission') {
        badgeBg = const Color(0xFFEFF6FF);
        badgeText = const Color(0xFF1D4ED8);
        badgeIcon = Icons.info_outline_rounded;
      } else {
        badgeBg = const Color(0xFFF1F5F9);
        badgeText = const Color(0xFF64748B);
        badgeIcon = Icons.radio_button_unchecked_rounded;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isPresent ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isPresent ? const Color(0xFF15803D) : const Color(0xFF64748B),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'NIS: $nis • $className',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(badgeIcon, size: 12, color: badgeText),
                const SizedBox(width: 4),
                Text(
                  isPresent && checkInTime != null
                      ? (isLate ? 'Terlambat • $checkInTime' : 'Hadir • $checkInTime')
                      : statusLabel,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: badgeText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // 7.1 NILAI PKL TAB (Sebelumnya Siswa Bimbingan)
  // ============================================================================
  Widget _buildSiswaTab() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SmartPklHeader(
              title: 'Nilai PKL',
              onProfileTap: () => _onTabTapped(4),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadStudents,
                child: _isLoadingStudents
                    ? const Center(child: CircularProgressIndicator())
                    : _students.isEmpty
                        ? ListView(
                            children: [
                              _buildEmptyState('Tidak ada siswa yang perlu dinilai saat ini.'),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _students.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final student = _students[index];
                              return _buildStudentListItem(student);
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }





  Widget _buildStudentListItem(Map<String, dynamic> student) {
    final name = student['name']?.toString() ?? 'Siswa PKL';
    final studentId = student['id']?.toString() ?? student['nis']?.toString() ?? name;
    final kelas = student['class']?.toString() ?? 'XII RPL';
    final major = student['major']?.toString() ?? 'Teknologi Informasi';
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'S';

    final double? currentScore = _studentScores[studentId] ??
        (student['score'] != null
            ? double.tryParse(student['score'].toString())
            : (student['nilai'] != null ? double.tryParse(student['nilai'].toString()) : null));

    return Container(
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
          // 1. Header: Avatar & Nama Siswa (Keterangan status 'Aktif' dihilangkan)
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFEFF6FF),
                child: Text(
                  initials,
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 13),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$kelas • $major',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // 2. Baris Nilai PKL & Tombol "Beri Nilai PKL" (Kotak presensi & logbook dihilangkan)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: currentScore != null ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: currentScore != null ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.stars_rounded,
                      size: 20,
                      color: currentScore != null ? const Color(0xFF2563EB) : AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nilai PKL (DU/DI)',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: currentScore != null ? const Color(0xFF2563EB) : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            currentScore != null
                                ? (currentScore % 1 == 0
                                    ? currentScore.toInt().toString()
                                    : currentScore.toStringAsFixed(1))
                                : 'Belum Dinilai',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: currentScore != null ? const Color(0xFF1D4ED8) : AppColors.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DudiPenilaianScreen(
                          student: student,
                          companyName: _locations.isNotEmpty ? _locations.first['name'] : null,
                        ),
                      ),
                    ).then((val) {
                      if (val != null && val is double) {
                        setState(() {
                          _studentScores[studentId] = val;
                        });
                      }
                      _loadStudents();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    currentScore != null ? Icons.edit_note_rounded : Icons.rate_review_rounded,
                    size: 18,
                  ),
                  label: Text(
                    currentScore != null ? 'Ubah Nilai PKL' : 'Beri Nilai PKL',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // 7.3 VERIFIKASI LOGBOOK TAB
  // ============================================================================
  Widget _buildLogbookTab() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SmartPklHeader(
              title: 'Verifikasi Logbook',
              onProfileTap: () => _onTabTapped(4),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadLogbooks,
                child: _isLoadingLogbooks
                    ? const Center(child: CircularProgressIndicator())
                    : _logbooks.isEmpty
                        ? ListView(
                            children: [
                              _buildEmptyState('Belum ada logbook siswa yang tercatat.'),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _logbooks.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final journal = _logbooks[index];
                              return _buildLogbookItemCard(journal);
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogbookItemCard(Map<String, dynamic> journal) {
    final placement = journal['placement'] as Map<String, dynamic>?;
    final student = placement?['student'] as Map<String, dynamic>?;

    final studentName = student?['name']?.toString() ?? 'M. Farel Ardiansyah';
    final role = student?['class'] != null
        ? '${student?['class']} • ${student?['major'] ?? 'Mobile App Dev'}'
        : 'SMK Negeri 1 Cimahi • Rekayasa Perangkat Lunak';

    final date = journal['logbook_date']?.toString() ?? journal['journal_date']?.toString() ?? 'Hari Ini';
    final activity = journal['activity']?.toString() ?? 'Kegiatan PKL Harian';
    final desc = journal['description']?.toString() ?? activity;

    final status = journal['status']?.toString() ?? 'submitted';
    final isApproved = status == 'approved';
    final isRejected = status == 'rejected';

    return GestureDetector(
      onTap: () async {
        final refreshed = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DudiLogbookDetailScreen(
              journal: journal,
              onVerified: _loadAllData,
            ),
          ),
        );
        if (refreshed == true) {
          _loadAllData();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        role,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusPill(
                  text: isApproved
                      ? 'Disetujui'
                      : (isRejected ? 'Direvisi' : 'Menunggu ACC'),
                  style: isApproved
                      ? PillStyle.success
                      : (isRejected ? PillStyle.error : PillStyle.warning),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                Row(
                  children: [
                    if (!isApproved)
                      ElevatedButton.icon(
                        onPressed: () async {
                          final id = journal['id'];
                          if (id != null && id is int) {
                            final res = await SupervisorService.approveLogbook(id: id);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(res['message'] ?? 'Logbook disetujui.'),
                                  backgroundColor: const Color(0xFF16A34A),
                                ),
                              );
                              _loadAllData();
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.check_rounded, size: 14),
                        label: const Text('ACC Langsung', style: TextStyle(fontSize: 11)),
                      ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // 7.4 VERIFIKASI PROJEK SISWA TAB (Halaman Terpisah)
  // ============================================================================
  Widget _buildProjekTab() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SmartPklHeader(
              title: 'Projek',
              onProfileTap: () => _onTabTapped(4),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await _loadProjects();
                  await _loadStudents();
                },
                child: _isLoadingProjects
                    ? const Center(child: CircularProgressIndicator())
                    : _projects.isEmpty
                        ? ListView(
                            children: [
                              _buildEmptyState('Belum ada projek siswa yang diajukan.'),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _projects.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return _buildProjectCardItem(_projects[index]);
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCardItem(Map<String, dynamic> proj) {
    final student = proj['student'] as Map<String, dynamic>? ?? {};
    final status = (proj['status'] ?? 'pending').toString().toLowerCase();

    final name = student['name']?.toString() ?? 'Siswa PKL';
    final sClass = student['class']?.toString() ?? 'XII RPL';
    final major = student['major']?.toString() ?? 'Rekayasa Perangkat Lunak';
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase()
        : 'SW';

    final title = proj['title']?.toString() ?? 'Projek Siswa';
    final plan = proj['plan']?.toString() ?? '';
    final result = proj['result']?.toString() ?? '';
    final docName = proj['document_name']?.toString();
    final docSize = proj['document_size'] as int? ?? 0;

    Color badgeColor;
    Color badgeBg;
    IconData badgeIcon;
    String badgeLabel;

    if (status == 'approved') {
      badgeColor = const Color(0xFF16A34A);
      badgeBg = const Color(0xFFDCFCE7);
      badgeIcon = Icons.check_circle_rounded;
      badgeLabel = 'Disetujui';
    } else if (status == 'revision') {
      badgeColor = const Color(0xFFDC2626);
      badgeBg = const Color(0xFFFEE2E2);
      badgeIcon = Icons.warning_amber_rounded;
      badgeLabel = 'Perlu Revisi';
    } else {
      badgeColor = const Color(0xFFD97706);
      badgeBg = const Color(0xFFFEF3C7);
      badgeIcon = Icons.hourglass_top_rounded;
      badgeLabel = 'Menunggu Verifikasi';
    }

    return Container(
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
          // Header: Avatar Siswa, Nama & Status Badge
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFEFF6FF),
                child: Text(
                  initials,
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$sClass • $major',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 12, color: badgeColor),
                    const SizedBox(width: 4),
                    Text(
                      badgeLabel,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: badgeColor),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Detail Projek
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          if (plan.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Perencanaan: $plan',
              style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (result.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              'Hasil Kerja: $result',
              style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (docName != null && docName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      docName,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    docSize > 0 ? '${(docSize / (1024 * 1024)).toStringAsFixed(1)} MB' : 'PDF',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Tombol Aksi Verifikasi / Detail
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DudiProjekDetailScreen(
                      studentData: student,
                      projectId: proj['id'] as int?,
                    ),
                  ),
                ).then((_) {
                  _loadProjects();
                  _loadStudents();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Periksa dan Berikan Catatan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // PROFIL DUDI TAB
  // ============================================================================
  // TAB PROFIL MITRA DUDI (GAYA TERPADU SEPERTI GURU PEMBIMBING)
  // ============================================================================
  Widget _buildProfilTab() {
    final companyName = _locations.isNotEmpty
        ? (_locations.first['name'] ?? 'PT Solusi Teknologi Mandiri')
        : 'PT Solusi Teknologi Mandiri';
    final address = _locations.isNotEmpty
        ? (_locations.first['address'] ?? 'Bandar Lampung')
        : 'Bandar Lampung';
    final radius = _locations.isNotEmpty ? '${_locations.first['radius'] ?? 50} Meter' : '50 Meter';

    final supervisorName = _currentUser?['name']?.toString() ?? 'Instruktur Lapangan';

    final initial = supervisorName.isNotEmpty
        ? supervisorName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase()
        : 'DU';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            const SmartPklHeader(title: 'Profil'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Card 1: Avatar Inisial & Nama Supervisor (Gaya Profil Guru) ──
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDBEAFE),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1D4ED8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  supervisorName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Pembimbing Lapangan DUDI',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Section Title: Informasi Akun ──
                    const Text(
                      'Informasi Akun',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Item 1: NAMA PERUSAHAAN ──
                    _buildDudiInfoCard(
                      icon: Icons.business_rounded,
                      label: 'NAMA PERUSAHAAN / MITRA DUDI',
                      value: companyName,
                    ),
                    const SizedBox(height: 10),

                    // ── Item 2: INSTRUKTUR LAPANGAN ──
                    _buildDudiInfoCard(
                      icon: Icons.badge_outlined,
                      label: 'INSTRUKTUR LAPANGAN',
                      value: supervisorName,
                    ),
                    const SizedBox(height: 10),



                    // ── Item 4: ALAMAT KANTOR ──
                    _buildDudiInfoCard(
                      icon: Icons.location_on_outlined,
                      label: 'ALAMAT KANTOR / LOKASI PKL',
                      value: address,
                    ),
                    const SizedBox(height: 10),

                    // ── Item 5: RADIUS GEOFENCING ──
                    _buildDudiInfoCard(
                      icon: Icons.radar_rounded,
                      label: 'RADIUS PRESENSI SISWA',
                      value: '$radius (Geofence Valid)',
                    ),
                    const SizedBox(height: 10),

                    // ── Item 5b: JAM OPERASIONAL KANTOR ──
                    _buildDudiInfoCard(
                      icon: Icons.schedule_rounded,
                      label: 'JAM OPERASIONAL KANTOR DUDI',
                      value: '${_locations.isNotEmpty && _locations.first['check_in_time'] != null ? _locations.first['check_in_time'] : '08:00'} WIB - ${_locations.isNotEmpty && _locations.first['check_out_time'] != null ? _locations.first['check_out_time'] : '16:00'} WIB',
                    ),
                    const SizedBox(height: 10),

                    // ── Item 6: PENENTUAN LOKASI PKL ──
                    InkWell(
                      onTap: _openLokasiSetting,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.location_on_rounded, size: 20, color: Color(0xFF2563EB)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'PENGATURAN LOKASI PKL',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF94A3B8),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Penentuan Titik Lokasi & Radius Geofence',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 22),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ── Item 7: GANTI PASSWORD ──
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => GantiPasswordScreen(
                              userRole: 'DUDI',
                              username: _currentUser?['username'] ?? 'dudi',
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.lock_reset_rounded, size: 20, color: Color(0xFF2563EB)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'GANTI PASSWORD',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF94A3B8),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Ubah Password akun DUDI',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 22),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Info note
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF64748B)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Untuk perubahan identitas atau informasi akun perusahaan, hubungi administrator sekolah.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Tombol Logout Merah
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await AuthService.logout();
                          if (!mounted) return;
                          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                        },
                        icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.white),
                        label: const Text(
                          'Logout / Keluar Aplikasi',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB91C1C),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDudiInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF2563EB)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    Color bg, {
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 16, color: color),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inbox_rounded, size: 40, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
