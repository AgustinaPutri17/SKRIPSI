import 'package:flutter/material.dart';
import '../../core/services/admin_service.dart';
import '../../widgets/smart_pkl_header.dart';

class AdminDashboardTab extends StatefulWidget {
  final Function(int tabIndex, {int? subIndex})? onNavigateTab;

  const AdminDashboardTab({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  // ============================================================================
  // PANGGILAN API BACKEND: 4.1 Dashboard Administrator
  // Endpoint: GET /api/admin/dashboard
  // Backend File: monitoring-pkl-app/routes/api.php:34
  // Controller: App\Http\Controllers\Api\Admin\DashboardController@index
  // Deskripsi: Menampilkan statistik ringkasan real-time dari backend:
  // - total_students: Total seluruh siswa terdaftar
  // - total_teachers: Total guru pembimbing terdaftar
  // - total_locations: Total mitra DU/DI terdaftar
  // - attendance_today: Presensi kehadiran hari ini
  // - journals_pending: Logbook berstatus submitted yang menunggu verifikasi
  // ============================================================================
  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final data = await AdminService.getDashboard();
    if (mounted) {
      setState(() {
        _isLoading = false;
        _dashboardData = data;
        if (data == null) {
          _errorMessage = 'Mode Offline (Menggunakan data lokal)';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalStudents = _dashboardData?['total_students'] ?? 64;
    final totalTeachers = _dashboardData?['total_teachers'] ?? 21;
    final totalLocations = _dashboardData?['total_locations'] ?? 21;
    final attendanceToday = _dashboardData?['attendance_today'] ?? 0;

    final activePeriod = _dashboardData?['active_period'] as Map<String, dynamic>?;
    final activePeriodName = (activePeriod?['name'] ?? 'PKL Semester Genap 2024/2025').toString();
    final activePeriodDates = (activePeriod != null && activePeriod['start_date'] != null)
        ? '${activePeriod['start_date']} s/d ${activePeriod['end_date'] ?? '-'}'
        : null;

    final belumAbsen = (totalStudents - attendanceToday) > 0 ? (totalStudents - attendanceToday) : 0;
    final double hadirPercentage = totalStudents > 0 ? (attendanceToday / totalStudents) * 100 : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            SmartPklHeader(
              title: 'Beranda',
              onProfileTap: () => widget.onNavigateTab?.call(3),
            ),
            if (_isLoading)
              const LinearProgressIndicator(
                minHeight: 2,
                color: Color(0xFF2563EB),
                backgroundColor: Color(0xFFEFF6FF),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchDashboardData,
                color: const Color(0xFF2563EB),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Offline banner if server is not reachable
                      if (_errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFD97706)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFFD97706)),
                                onPressed: _fetchDashboardData,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),

                      // 1. Blue Hero Banner Card (Connected with Backend Active Period)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E40AF), Color(0xFF2563EB), Color(0xFF3B82F6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.28),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF4ADE80),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            activePeriodName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.3,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (activePeriodDates != null) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    activePeriodDates,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Halo, Administrator Utama',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Pantau aktivitas PKL periode $activePeriodName dan status absensi harian secara real-time.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. 2x2 Metric Cards (Matching Screenshot 1)
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              title: 'Total Siswa',
                              value: '$totalStudents',
                              unit: 'Siswa',
                              icon: Icons.people_alt_rounded,
                              iconColor: const Color(0xFF2563EB),
                              bgColor: const Color(0xFFEFF6FF),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              title: 'Pembimbing',
                              value: '$totalTeachers',
                              unit: 'Guru',
                              icon: Icons.assignment_ind_rounded,
                              iconColor: const Color(0xFF4F46E5),
                              bgColor: const Color(0xFFEEF2FF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              title: 'Mitra DU/DI',
                              value: '$totalLocations',
                              unit: 'Industri',
                              icon: Icons.business_rounded,
                              iconColor: const Color(0xFF0284C7),
                              bgColor: const Color(0xFFE0F2FE),
                              onTap: () => widget.onNavigateTab?.call(1, subIndex: 2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              title: 'Kehadiran Hari Ini',
                              value: '$attendanceToday/$totalStudents',
                              unit: '',
                              icon: Icons.assignment_turned_in_rounded,
                              iconColor: const Color(0xFFD97706),
                              bgColor: const Color(0xFFFFFBEB),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // 3. Akses Cepat Data Master (Matching Screenshot 1)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
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
                                  'Akses Cepat Data Master',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => widget.onNavigateTab?.call(1, subIndex: 0),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    child: Text(
                                      'Kelola',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildQuickActionButton(
                                  label: 'Data Guru',
                                  icon: Icons.school_outlined,
                                  color: const Color(0xFF2563EB),
                                  bgColor: const Color(0xFFEFF6FF),
                                  onTap: () => widget.onNavigateTab?.call(1, subIndex: 1),
                                ),
                                _buildQuickActionButton(
                                  label: 'Data Siswa',
                                  icon: Icons.badge_outlined,
                                  color: const Color(0xFF2563EB),
                                  bgColor: const Color(0xFFEFF6FF),
                                  onTap: () => widget.onNavigateTab?.call(1, subIndex: 0),
                                ),
                                _buildQuickActionButton(
                                  label: 'Mitra DU/DI',
                                  icon: Icons.business_outlined,
                                  color: const Color(0xFF2563EB),
                                  bgColor: const Color(0xFFEFF6FF),
                                  onTap: () => widget.onNavigateTab?.call(1, subIndex: 2),
                                ),
                                _buildQuickActionButton(
                                  label: 'Profil',
                                  icon: Icons.person_outline_rounded,
                                  color: const Color(0xFF2563EB),
                                  bgColor: const Color(0xFFEFF6FF),
                                  onTap: () => widget.onNavigateTab?.call(3),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 4. Status Presensi Hari Ini (Matching Screenshot 1)
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
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
                                  'Status Presensi Hari Ini',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.circle, color: Color(0xFFD97706), size: 7),
                                      SizedBox(width: 5),
                                      Text(
                                        'Berjalan',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFB45309),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Batas konfirmasi masuk: 08:30 WIB',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                // Circular / Donut Progress Indicator
                                SizedBox(
                                  width: 82,
                                  height: 82,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 82,
                                        height: 82,
                                        child: CircularProgressIndicator(
                                          value: hadirPercentage / 100,
                                          strokeWidth: 9,
                                          backgroundColor: const Color(0xFFE2E8F0),
                                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                                          strokeCap: StrokeCap.round,
                                        ),
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${hadirPercentage.toInt()}%',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          const Text(
                                            'Hadir',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF64748B),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                // Legend Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildPresenceLegendRow(
                                        color: const Color(0xFFF59E0B),
                                        label: 'Belum Absen',
                                        value: '$belumAbsen Siswa',
                                      ),
                                      const SizedBox(height: 12),
                                      _buildPresenceLegendRow(
                                        color: const Color(0xFF2563EB),
                                        label: 'Terkonfirmasi Masuk',
                                        value: '$attendanceToday Siswa',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildQuickActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresenceLegendRow({
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
