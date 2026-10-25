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

  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? _currentUser;
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _logbooks = [];
  List<Map<String, dynamic>> _locations = [];

  String _selectedLogbookFilter = 'submitted'; // 'all', 'submitted', 'approved', 'rejected'

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
    if (safeIndex == 3) _loadLocations();
  }

  Future<void> _loadAllData() async {
    final user = await AuthService.getUser();
    if (mounted) setState(() => _currentUser = user);
    await Future.wait([
      _loadDashboard(),
      _loadStudents(),
      _loadLogbooks(),
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

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildBerandaTab(),
      _buildSiswaTab(),
      _buildLogbookTab(),
      _buildLokasiTab(),
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
                child: Icon(Icons.groups_rounded, size: 22),
              ),
              label: 'Siswa',
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
                child: Icon(Icons.location_on_rounded, size: 22),
              ),
              label: 'Lokasi PKL',
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
        ? (_locations.first['name'] ?? 'PT Solusi Teknologi Mandiri')
        : 'PT Solusi Teknologi Mandiri';

    final supervisorName = _currentUser?['name']?.toString() ?? 'Hendra Wijaya, S.T.';

    final totalStudents = _dashboardData?['total_students']?.toString() ?? (_students.isNotEmpty ? '${_students.length}' : '8');
    final attendanceToday = _dashboardData?['attendance_today']?.toString() ?? '8';
    final logbookPending = _dashboardData?['journals_pending']?.toString() ?? (_logbooks.where((l) => l['status'] == 'submitted').length.toString());

    final radius = _locations.isNotEmpty ? '${_locations.first['radius'] ?? 50} m' : '50 m';

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
                      // Greeting & Mentor Card
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: const Icon(
                              Icons.business_center_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Halo, $supervisorName 👋',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Instruktur Lapangan • $companyName',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      if (_locations.isNotEmpty &&
                          (_locations.first['latitude'] == null || _locations.first['longitude'] == null)) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 18),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFCD34D)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD97706).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.location_off_rounded, color: Color(0xFFD97706), size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Titik Lokasi Kantor Belum Disetel!',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF92400E),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    const Text(
                                      'Admin belum menentukan koordinat kantor. Buka menu Lokasi dan gunakan GPS HP agar siswa dapat presensi.',
                                      style: TextStyle(fontSize: 11, color: Color(0xFF78350F), height: 1.35),
                                    ),
                                    const SizedBox(height: 10),
                                    ElevatedButton.icon(
                                      onPressed: () => _onTabTapped(3),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFD97706),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                        minimumSize: Size.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      icon: const Icon(Icons.my_location_rounded, size: 14),
                                      label: const Text('Ambil Lokasi GPS Sekarang', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Quick Stats 2x2 Grid Sesuai Desain
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
                            'Tepat Waktu',
                            Icons.how_to_reg_rounded,
                            const Color(0xFF16A34A),
                            const Color(0xFFDCFCE7),
                            onTap: () => _onTabTapped(1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildSummaryStat(
                            'Logbook Pending',
                            logbookPending,
                            'Perlu ACC',
                            Icons.pending_actions_rounded,
                            const Color(0xFFD97706),
                            const Color(0xFFFEF3C7),
                            onTap: () => _onTabTapped(2),
                          ),
                          const SizedBox(width: 12),
                          _buildSummaryStat(
                            'Radius Presensi',
                            radius,
                            'Geofence Aktif',
                            Icons.location_on_rounded,
                            const Color(0xFF7C3AED),
                            const Color(0xFFF3E8FF),
                            onTap: () => _onTabTapped(3),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Banner Setup Titik Lokasi
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Pengaturan Titik Lokasi DUDI',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Atur koordinat GPS kantor & radius presensi siswa.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => _onTabTapped(3),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF2563EB),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Kelola', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Logbook Verification Queue Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Logbook Menunggu Validasi',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          TextButton(
                            onPressed: () => _onTabTapped(2),
                            child: const Text('Lihat Semua'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // List Logbook Pending
                      if (_isLoadingLogbooks)
                        const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                      else if (_logbooks.isEmpty)
                        _buildEmptyState('Belum ada logbook siswa yang perlu diverifikasi.')
                      else
                        ..._logbooks.take(3).map((j) => _buildLogbookItemCard(j)),
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

  // ============================================================================
  // 7.1 SISWA BIMBINGAN TAB
  // ============================================================================
  Widget _buildSiswaTab() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SmartPklHeader(
              title: 'Siswa Bimbingan DUDI',
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
                              _buildEmptyState('Tidak ada siswa aktif yang ditempatkan di instansi Anda saat ini.'),
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
    final kelas = student['class']?.toString() ?? 'XII RPL';
    final major = student['major']?.toString() ?? 'Teknologi Informasi';
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'S';

    final int attendancesCount = student['attendances_count'] is int
        ? student['attendances_count'] as int
        : (int.tryParse(student['attendances_count']?.toString() ?? '0') ?? 0);

    final int logbooksCount = student['logbooks_count'] is int
        ? student['logbooks_count'] as int
        : (int.tryParse(student['logbooks_count']?.toString() ?? '0') ?? 0);

    final int projectsCount = student['projects_count'] is int
        ? student['projects_count'] as int
        : (int.tryParse(student['projects_count']?.toString() ?? '0') ?? 0);

    final status = (student['status'] ?? 'active').toString();
    final bool isActive = status == 'active';

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
          // 1. Header: Avatar, Info Siswa & Status Pill
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
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$kelas • $major',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(
                text: isActive ? 'Aktif' : 'Nonaktif',
                style: isActive ? PillStyle.success : PillStyle.neutral,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // 2. Metrics Row: Presensi, Logbook, Projek Akhir
          Row(
            children: [
              // Metric 1: Jumlah Absen / Presensi
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.how_to_reg_rounded, size: 14, color: Color(0xFF16A34A)),
                          const SizedBox(width: 4),
                          Text(
                            '$attendancesCount',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Presensi',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF166534),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Metric 2: Jumlah Logbook
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.assignment_turned_in_rounded, size: 14, color: Color(0xFF2563EB)),
                          const SizedBox(width: 4),
                          Text(
                            '$logbooksCount',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Logbook',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Metric 3: Nilai PKL
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF5FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE9D5FF)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.grade_rounded, size: 14, color: Color(0xFF9333EA)),
                          const SizedBox(width: 4),
                          Text(
                            (student['score'] ?? student['grade'] ?? student['final_score'] ?? student['nilai_pkl'] ?? (projectsCount > 0 ? '$projectsCount' : '-')).toString(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF7E22CE),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Nilai PKL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B21A8),
                        ),
                      ),
                    ],
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
              title: 'Verifikasi Logbook DUDI',
              onProfileTap: () => _onTabTapped(4),
            ),
            // Filter Pills (Semua, Menunggu, Disetujui, Ditolak)
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip('submitted', 'Menunggu'),
                  const SizedBox(width: 8),
                  _buildFilterChip('approved', 'Disetujui'),
                  const SizedBox(width: 8),
                  _buildFilterChip('rejected', 'Perlu Revisi'),
                  const SizedBox(width: 8),
                  _buildFilterChip('all', 'Semua Status'),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadLogbooks,
                child: _isLoadingLogbooks
                    ? const Center(child: CircularProgressIndicator())
                    : _logbooks.isEmpty
                        ? ListView(
                            children: [
                              _buildEmptyState('Tidak ada logbook dengan filter status ini.'),
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

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedLogbookFilter == value;
    return Center(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedLogbookFilter = value);
          _loadLogbooks();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFF2563EB) : AppColors.cardBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
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
                       : (isRejected ? 'Ditolak' : 'Menunggu ACC'),
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
  // 7.2 MANAJEMEN LOKASI PKL TAB
  // ============================================================================
  Widget _buildLokasiTab() {
    return DudiLokasiScreen(
      initialLocation: _locations.isNotEmpty ? _locations.first : null,
      onLocationSaved: () => _loadLocations(),
      onProfileTap: () => _onTabTapped(4),
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

                    // ── Item 6: KELOLA GEOFENCING KANTOR ──
                    InkWell(
                      onTap: () => _onTabTapped(3),
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
                              child: const Icon(Icons.edit_location_alt_rounded, size: 20, color: Color(0xFF2563EB)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'LOKASI PRESENSI',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF94A3B8),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Kelola Titik Geofencing Kantor',
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
