import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/student_service.dart';
import '../../widgets/smart_pkl_header.dart';

/// ==============================================================================
/// HALAMAN BERANDA SISWA (Beranda Monitoring)
/// Sesuai UI Mockup Desain Mobile SMART PKL
/// 
/// Interaksi Backend ('monitoring-pkl-app'):
/// 1. GET /api/student/profile
///    -> Mengambil nama siswa, kelas ("XII RPL 1"), dan sekolah ("SMKN 2 Bandar Lampung")
/// 2. GET /api/student/dashboard
///    -> Mengambil ringkasan statistik logbook ACC ("18/20") dan penempatan magang aktif
/// 3. GET /api/student/attendances
///    -> Menghitung persentase presensi kehadiran siswa ("96%")
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

  // Data default untuk rendering
  String _studentName = 'Siswa';
  String _studentClassAndSchool = 'SMK';
  int _attendancePresentCount = 0;
  String _logbookAccApproved = '0';
  String _logbookAccTotal = '0';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  /// Memuat data dari backend 'monitoring-pkl-app'
  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 0. Ambil user login tersimpan di SharedPreferences
      final cachedUser = await AuthService.getUser();
      if (cachedUser != null && cachedUser['name'] != null) {
        if (mounted) {
          setState(() {
            _studentName = cachedUser['name'].toString();
          });
        }
      }

      // ============================================================================
      // PANGGILAN API BACKEND 1: GET /api/student/profile
      // ============================================================================
      final profile = await StudentService.getProfile();
      if (profile != null && mounted) {
        final user = profile['user'] as Map<String, dynamic>?;
        final name = user?['name']?.toString() ?? profile['name']?.toString();
        final studentClass = profile['class']?.toString() ?? 'XII RPL 1';
        final schoolOrMajor = profile['school_name']?.toString() ?? profile['major']?.toString() ?? 'SMKN 2 Bandar Lampung';

        setState(() {
          if (name != null && name.isNotEmpty) {
            _studentName = name;
          }
          _studentClassAndSchool = '$studentClass • $schoolOrMajor';
        });
      }

      // ============================================================================
      // PANGGILAN API BACKEND 2: GET /api/student/dashboard
      // ============================================================================
      final dashboard = await StudentService.getDashboard();
      if (dashboard != null && mounted) {
        final journalStats = dashboard['journal_stats'] as Map<String, dynamic>?;
        if (journalStats != null) {
          final approved = journalStats['approved'] ?? 0;
          final total = journalStats['total'] ?? 0;
          setState(() {
            _logbookAccApproved = approved.toString();
            _logbookAccTotal = total.toString();
          });
        }

        final attendanceStats = dashboard['attendance_stats'] as Map<String, dynamic>?;
        if (attendanceStats != null && attendanceStats['present'] != null) {
          setState(() {
            _attendancePresentCount = attendanceStats['present'] is int 
                ? attendanceStats['present'] 
                : int.tryParse(attendanceStats['present'].toString()) ?? 0;
          });
        }
      }

      // ============================================================================
      // PANGGILAN API BACKEND 3: GET /api/student/attendances (Validasi / Fallback)
      // ============================================================================
      final attendancesData = await StudentService.getAttendances();
      if (attendancesData != null && attendancesData['attendances'] != null && mounted) {
        final list = attendancesData['attendances'] as List<dynamic>;
        final presentCount = list.where((a) => a['status'] == 'present' || a['status'] == 'late' || a['status'] == 'approved').length;
        setState(() {
          _attendancePresentCount = presentCount;
        });
      }
    } catch (_) {
      // Gunakan data fallback jika backend offline
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Greeting & Subtitle (Nama & Kelas • Sekolah)
                      Text(
                        'Halo, $_studentName 👋',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _studentClassAndSchool,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 2. Stats Card: Hadir & Logbook ACC (Persis Mockup Figma)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Sisi Kiri: Hadir
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Hadir',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '$_attendancePresentCount Hari',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Garis Pemisah Vertikal
                            Container(
                              width: 1,
                              height: 38,
                              color: const Color(0xFFE2E8F0),
                            ),

                            // Sisi Kanan: Logbook ACC
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Logbook ACC',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: _logbookAccApproved,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF2563EB),
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                        TextSpan(
                                          text: '/$_logbookAccTotal',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 3. Grid Menu Cepat (3 Kolom Sesuai Mockup)
                      // Baris 1: Logbook | Izin / Sakit | Presensi
                      Row(
                        children: [
                          _buildMenuCard(
                            label: 'Logbook',
                            icon: Icons.fact_check_rounded,
                            onTap: () => widget.onNavigateTab?.call(2),
                          ),
                          const SizedBox(width: 14),
                          _buildMenuCard(
                            label: 'Izin / Sakit',
                            icon: Icons.edit_calendar_outlined,
                            onTap: () => widget.onNavigateTab?.call(1, 2),
                          ),
                          const SizedBox(width: 14),
                          _buildMenuCard(
                            label: 'Presensi',
                            icon: Icons.how_to_reg_rounded,
                            onTap: () => widget.onNavigateTab?.call(1, 0),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Baris 2: Projek | Profil | (Kosong agar simetris 3 kolom)
                      Row(
                        children: [
                          _buildMenuCard(
                            label: 'Projek',
                            icon: Icons.assignment_outlined,
                            onTap: () => widget.onNavigateTab?.call(3),
                          ),
                          const SizedBox(width: 14),
                          _buildMenuCard(
                            label: 'Profil',
                            icon: Icons.person_outline_rounded,
                            onTap: () => widget.onNavigateTab?.call(4),
                          ),
                          const SizedBox(width: 14),
                          // Spacer transparan kolom ke-3
                          const Expanded(child: SizedBox()),
                        ],
                      ),
                      const SizedBox(height: 28),
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

  /// Komponen Kartu Menu Grid dengan Icon Lingkaran Lembut
  Widget _buildMenuCard({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: 104,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: const Color(0xFF334155),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
