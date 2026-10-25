import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/teacher_service.dart';
import '../../widgets/smart_pkl_header.dart';
import '../../widgets/status_pill.dart';

class GuruRekapTab extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const GuruRekapTab({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<GuruRekapTab> createState() => _GuruRekapTabState();
}

class _GuruRekapTabState extends State<GuruRekapTab> {
  bool _isLoading = true;
  // 0: Semua Siswa, 1: Hadir Hari Ini, 2: Pengajuan Izin, 3: Riwayat Izin
  int _selectedFilter = 0;

  // Data riil dari backend
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _attendancesToday = [];
  List<Map<String, dynamic>> _leaveRequests = [];

  // Hitungan statistik
  int _totalStudents = 0;
  int _countPresent = 0;
  int _countIzinToday = 0;
  int _countPendingIzin = 0;

  // Set proses verifikasi lokal untuk loading state pada card
  final Set<int> _processingLeaveIds = {};

  @override
  void initState() {
    super.initState();
    _loadRekapData();
  }

  /// Mengambil data terpadu dari backend Laravel:
  /// 1. GET /api/teacher/dashboard (Statistik total siswa, hadir, izin, pending)
  /// 2. GET /api/teacher/students (Daftar siswa bimbingan beserta info PKL & presensi hari ini)
  /// 3. GET /api/teacher/attendances?today=true (Presensi hadir hari ini)
  /// 4. GET /api/teacher/leave-requests (Daftar izin pending & riwayat)
  Future<void> _loadRekapData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Ambil data Dashboard statistik
      final dashboard = await TeacherService.getDashboard();
      if (dashboard != null && mounted) {
        setState(() {
          _totalStudents = dashboard['total_students'] ?? 0;
          _countPresent = dashboard['attendance_today'] ?? 0;
          _countIzinToday = dashboard['leave_today'] ?? 0;
          _countPendingIzin = dashboard['leave_pending'] ?? 0;
        });
      }

      // 2. Ambil daftar siswa bimbingan
      final studentList = await TeacherService.getStudents();
      if (mounted) {
        setState(() {
          _students = studentList;
          _totalStudents = studentList.length;
        });
      }

      // 3. Ambil daftar presensi hari ini
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final attRes = await TeacherService.getAttendances(date: todayStr);
      if (attRes != null && attRes['attendances'] != null && mounted) {
        final list = (attRes['attendances'] as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        setState(() {
          _attendancesToday = list;
          final presentList = list.where((a) {
            final st = (a['status'] ?? '').toString();
            return st == 'present' || st == 'late';
          }).toList();
          _countPresent = presentList.length;
        });
      }

      // 4. Ambil daftar pengajuan izin & sakit
      final leaveList = await TeacherService.getLeaveRequests();
      if (mounted) {
        setState(() {
          _leaveRequests = leaveList;
          _countPendingIzin = leaveList
              .where((l) => (l['status'] ?? '').toString() == 'pending')
              .length;
          if (_countIzinToday == 0) {
            _countIzinToday = _countPendingIzin;
          }
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Filter lists
  List<Map<String, dynamic>> get _presentStudents {
    // Ambil dari attendances today yang statusnya hadir atau late
    return _attendancesToday.where((a) {
      final st = (a['status'] ?? '').toString();
      return st == 'present' || st == 'late';
    }).toList();
  }

  List<Map<String, dynamic>> get _pendingLeaves {
    return _leaveRequests.where((l) => (l['status'] ?? '').toString() == 'pending').toList();
  }

  List<Map<String, dynamic>> get _historyLeaves {
    return _leaveRequests.where((l) => (l['status'] ?? '').toString() != 'pending').toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header SMART PKL
            SmartPklHeader(
              title: 'Rekap Kehadiran',
              subtitle: 'Guru Pembimbing',
              onProfileTap: () => widget.onNavigateTab?.call(4),
            ),

            if (_isLoading)
              const LinearProgressIndicator(
                minHeight: 2,
                color: Color(0xFF2563EB),
                backgroundColor: Color(0xFFEFF6FF),
              ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadRekapData,
                color: const Color(0xFF2563EB),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subtitle "Daftar Rekap & Konfirmasi"
                      const Text(
                        'Daftar Rekap & Konfirmasi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Filter Pills (Semua Siswa, Hadir Hari Ini, Pengajuan Izin, Riwayat Izin)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildFilterPill(0, 'Semua Siswa', '$_totalStudents'),
                            const SizedBox(width: 8),
                            _buildFilterPill(1, 'Hadir Hari Ini', '$_countPresent'),
                            const SizedBox(width: 8),
                            _buildFilterPill(2, 'Pengajuan Izin', '$_countPendingIzin'),
                            const SizedBox(width: 8),
                            _buildFilterPill(3, 'Riwayat Izin', '${_historyLeaves.length}'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Ringkasan Kehadiran Cepat (Bisa di-tap untuk beralih tab)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
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
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _selectedFilter = 0),
                                borderRadius: BorderRadius.circular(10),
                                child: _buildStatItem(
                                  'Total Bimbingan',
                                  '$_totalStudents',
                                  const Color(0xFF0F172A),
                                  isActive: _selectedFilter == 0,
                                ),
                              ),
                            ),
                            Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _selectedFilter = 1),
                                borderRadius: BorderRadius.circular(10),
                                child: _buildStatItem(
                                  'Hadir Hari Ini',
                                  '$_countPresent',
                                  const Color(0xFF16A34A),
                                  isActive: _selectedFilter == 1,
                                ),
                              ),
                            ),
                            Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _selectedFilter = 2),
                                borderRadius: BorderRadius.circular(10),
                                child: _buildStatItem(
                                  'Izin / Sakit',
                                  '$_countPendingIzin',
                                  const Color(0xFFE11D48),
                                  isActive: _selectedFilter == 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // KONTEN BERDASARKAN TAB AKTIF
                      if (_selectedFilter == 0) ...[
                        _buildSemuaSiswaSection(),
                      ] else if (_selectedFilter == 1) ...[
                        _buildHadirHariIniSection(),
                      ] else if (_selectedFilter == 2) ...[
                        _buildPengajuanIzinSection(),
                      ] else ...[
                        _buildRiwayatIzinSection(),
                      ],
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

  // ─────────────────────────────────────────────────────────────────────────────
  // STAT ITEM & FILTER PILL
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildStatItem(String label, String value, Color color, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.06) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              color: isActive ? color : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(int index, String title, String badgeCount) {
    final bool isSelected = _selectedFilter == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = index;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badgeCount,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // TAB 0: DAFTAR SEMUA SISWA BIMBINGAN
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildSemuaSiswaSection() {
    if (_students.isEmpty && !_isLoading) {
      return _buildEmptyState(
        'Belum ada data siswa bimbingan yang terdaftar untuk akun Anda.',
        icon: Icons.people_outline_rounded,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Daftar Siswa Bimbingan (${_students.length})',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
            const Text(
              'Status Hari Ini',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _students.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) {
            final s = _students[i];
            final name = s['name']?.toString() ?? 'Siswa';
            final nis = s['nis']?.toString() ?? s['nisn']?.toString() ?? '-';
            final cls = s['class']?.toString() ?? '-';
            final major = s['major']?.toString() ?? '';

            // Lokasi DUDI
            final location = s['location'] as Map<String, dynamic>?;
            final placement = s['placement'] as Map<String, dynamic>?;
            final dudiName = location?['name']?.toString() ??
                placement?['location']?['name']?.toString() ??
                'Belum Ada DUDI';

            // Pembimbing DUDI
            final fieldSup = s['field_supervisor'] as Map<String, dynamic>?;
            final supName = fieldSup?['name']?.toString() ??
                placement?['field_supervisor']?['name']?.toString() ??
                '';

            // Kehadiran hari ini
            final attToday = s['attendance_today'] as Map<String, dynamic>?;
            final leaveToday = s['leave_today'] as Map<String, dynamic>?;

            String statusText = 'Belum Presensi';
            PillStyle pillStyle = PillStyle.neutral;

            if (attToday != null) {
              final attStatus = (attToday['status'] ?? '').toString();
              if (attStatus == 'present') {
                statusText = 'Hadir';
                pillStyle = PillStyle.success;
              } else if (attStatus == 'late') {
                statusText = 'Terlambat';
                pillStyle = PillStyle.warning;
              } else if (attStatus == 'excused') {
                statusText = 'Izin/Sakit';
                pillStyle = PillStyle.warning;
              }
            } else if (leaveToday != null) {
              final lType = (leaveToday['type'] ?? '').toString();
              statusText = lType == 'sick' ? 'Sakit' : 'Izin';
              pillStyle = PillStyle.warning;
            }

            final initial = name.isNotEmpty
                ? name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
                : 'S';

            return InkWell(
              onTap: () => _showStudentDetailModal(s),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.015),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFEFF6FF),
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
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
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$nis • $cls ${major.isNotEmpty ? '• $major' : ''}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.business_rounded, size: 11, color: Color(0xFF2563EB)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  supName.isNotEmpty ? '$dudiName ($supName)' : dudiName,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF334155),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusPill(text: statusText, style: pillStyle),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // TAB 1: DAFTAR SISWA YANG HADIR HARI INI
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildHadirHariIniSection() {
    final presentList = _presentStudents;

    if (presentList.isEmpty && !_isLoading) {
      return _buildEmptyState(
        'Belum ada siswa bimbingan yang melakukan presensi hadir hari ini.',
        icon: Icons.event_busy_rounded,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daftar Hadir Hari Ini (${presentList.length} Siswa)',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: presentList.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (ctx, i) {
            final att = presentList[i];
            final placement = att['placement'] as Map<String, dynamic>?;
            final student = placement?['student'] as Map<String, dynamic>?;
            final location = placement?['location'] as Map<String, dynamic>?;

            final studentName = student?['name']?.toString() ??
                student?['user']?['name']?.toString() ??
                'Siswa';
            final nis = student?['nis']?.toString() ?? '-';
            final cls = student?['class']?.toString() ?? '-';
            final dudi = location?['name']?.toString() ?? 'Lokasi PKL';

            final checkInAt = att['check_in_at']?.toString() ?? '';
            final checkOutAt = att['check_out_at']?.toString() ?? '';
            final checkInPhoto = att['check_in_photo_url']?.toString();
            final checkOutPhoto = att['check_out_photo_url']?.toString();

            final inFormatted = _formatTime(checkInAt);
            final outFormatted = _formatTime(checkOutAt);

            final initial = studentName.isNotEmpty
                ? studentName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
                : 'S';

            final isLate = (att['status'] ?? '').toString() == 'late';

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Header Siswa
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFFEFF6FF),
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              studentName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$nis • $cls • $dudi',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusPill(
                        text: isLate ? 'Terlambat' : 'Hadir Tepat Waktu',
                        style: isLate ? PillStyle.warning : PillStyle.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 12),

                  // Waktu Masuk & Pulang
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFDCFCE7)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.login_rounded, size: 14, color: Color(0xFF16A34A)),
                              const SizedBox(width: 6),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Presensi Masuk',
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF166534)),
                                  ),
                                  Text(
                                    inFormatted.isNotEmpty ? inFormatted : '-',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF14532D)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: outFormatted.isNotEmpty ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: outFormatted.isNotEmpty ? const Color(0xFFDBEAFE) : const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.logout_rounded,
                                size: 14,
                                color: outFormatted.isNotEmpty ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 6),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Presensi Pulang',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: outFormatted.isNotEmpty ? const Color(0xFF1E40AF) : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                  Text(
                                    outFormatted.isNotEmpty ? outFormatted : 'Belum Pulang',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: outFormatted.isNotEmpty ? const Color(0xFF1E3A8A) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Foto Selfie Presensi (Jika tersedia)
                  if ((checkInPhoto != null && checkInPhoto.isNotEmpty) ||
                      (checkOutPhoto != null && checkOutPhoto.isNotEmpty)) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (checkInPhoto != null && checkInPhoto.isNotEmpty)
                          Expanded(
                            child: _buildPhotoThumbnail(
                              label: 'Foto Masuk',
                              photoUrl: checkInPhoto,
                              accentColor: const Color(0xFF16A34A),
                            ),
                          ),
                        if (checkInPhoto != null && checkInPhoto.isNotEmpty && checkOutPhoto != null && checkOutPhoto.isNotEmpty)
                          const SizedBox(width: 10),
                        if (checkOutPhoto != null && checkOutPhoto.isNotEmpty)
                          Expanded(
                            child: _buildPhotoThumbnail(
                              label: 'Foto Pulang',
                              photoUrl: checkOutPhoto,
                              accentColor: const Color(0xFF2563EB),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPhotoThumbnail({
    required String label,
    required String photoUrl,
    required Color accentColor,
  }) {
    final formattedUrl = AuthService.formatImageUrl(photoUrl);
    return InkWell(
      onTap: () => _showFullImageDialog(label, formattedUrl),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                formattedUrl,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 36,
                  height: 36,
                  color: const Color(0xFFE2E8F0),
                  child: const Icon(Icons.person, size: 18, color: Color(0xFF94A3B8)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                  const Text(
                    'Lihat Bukti Foto',
                    style: TextStyle(fontSize: 9, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new_rounded, size: 13, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // TAB 2: PENGAJUAN IZIN & SAKIT (PENDING)
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildPengajuanIzinSection() {
    final pendingList = _pendingLeaves;

    if (pendingList.isEmpty && !_isLoading) {
      return _buildEmptyState(
        'Tidak ada pengajuan izin atau surat sakit yang menunggu konfirmasi.',
        icon: Icons.check_circle_outline_rounded,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Menunggu Review & Konfirmasi (${pendingList.length})',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: pendingList.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (ctx, i) {
            final leave = pendingList[i];
            final leaveId = leave['id'] as int? ?? 0;
            final student = leave['student'] as Map<String, dynamic>? ??
                leave['placement']?['student'] as Map<String, dynamic>?;
            final location = leave['location'] as Map<String, dynamic>? ??
                leave['placement']?['location'] as Map<String, dynamic>?;

            final studentName = student?['name']?.toString() ??
                student?['user']?['name']?.toString() ??
                'Siswa';
            final nisn = student?['nisn']?.toString() ?? student?['nis']?.toString() ?? '-';
            final kelas = student?['class']?.toString() ?? 'XII';
            final dudi = location?['name']?.toString() ?? 'DUDI Mitra';

            final fieldSup = leave['placement']?['field_supervisor'] as Map<String, dynamic>?;
            final instruktur = fieldSup?['name']?.toString() ?? 'Pembimbing Lapangan';

            final type = (leave['type'] ?? 'permission').toString().toLowerCase();
            final isSick = type == 'sick' || type == 'sakit';
            final kategori = isSick ? 'Sakit / Medis' : 'Izin Mendesak';
            final kategoriIcon = isSick ? Icons.medical_services_rounded : Icons.groups_rounded;
            final kategoriColor = isSick ? const Color(0xFFE11D48) : const Color(0xFF4F46E5);

            final dateRangeLabel = leave['date_range_label']?.toString() ??
                '${leave['start_date'] ?? '-'} s/d ${leave['end_date'] ?? '-'}';
            final alasan = leave['reason']?.toString() ?? '-';
            final attachmentUrl = leave['attachment_url']?.toString() ?? '';
            final attachmentName = leave['attachment_name']?.toString() ??
                (attachmentUrl.isNotEmpty ? attachmentUrl.split('/').last : 'Surat_Keterangan.pdf');

            final isProcessing = _processingLeaveIds.contains(leaveId);

            return Container(
              padding: const EdgeInsets.all(16),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profil Siswa + Status Menunggu Review
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFFEFF6FF),
                        child: Text(
                          studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              studentName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'NISN: $nisn • $kelas',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFEF3C7)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.hourglass_top_rounded, size: 12, color: Color(0xFFB45309)),
                            SizedBox(width: 4),
                            Text(
                              'Menunggu Review',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Subcard DUDI
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.business_rounded, size: 14, color: Color(0xFF2563EB)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            dudi,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          'Instruktur: $instruktur',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Kategori & Durasi
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kategori Presensi',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(kategoriIcon, size: 13, color: kategoriColor),
                                const SizedBox(width: 4),
                                Text(
                                  kategori,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: kategoriColor),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Rentang Durasi',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF2563EB)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    dateRangeLabel,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Alasan Pengajuan
                  const Text(
                    'Alasan Pengajuan:',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '“$alasan”',
                      style: const TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF334155),
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // File Attachment Box
                  if (attachmentUrl.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              attachmentName.toLowerCase().endsWith('.pdf')
                                  ? Icons.picture_as_pdf_rounded
                                  : Icons.image_rounded,
                              size: 18,
                              color: const Color(0xFFE11D48),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  attachmentName,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Dokumen Surat Resmi Siswa',
                                  style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.visibility_rounded, color: Color(0xFF2563EB), size: 18),
                            onPressed: () => _previewAttachment(studentName, attachmentUrl, attachmentName),
                            tooltip: 'Tinjau Dokumen',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Tombol Verifikasi & Tolak
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 42,
                          child: ElevatedButton.icon(
                            onPressed: isProcessing
                                ? null
                                : () => _confirmVerifikasiIzin(leaveId, studentName, 'approved'),
                            icon: isProcessing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.verified_user_rounded, size: 16, color: Colors.white),
                            label: Text(
                              isProcessing ? 'Memproses...' : 'Verifikasi & Tinjau Surat',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFFEF4444)),
                          onPressed: isProcessing
                              ? null
                              : () => _showRejectDialog(leaveId, studentName),
                          tooltip: 'Tolak Permohonan',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // TAB 3: RIWAYAT IZIN & SAKIT
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildRiwayatIzinSection() {
    final historyList = _historyLeaves;

    if (historyList.isEmpty && !_isLoading) {
      return _buildEmptyState(
        'Belum ada riwayat perizinan siswa yang selesai diproses.',
        icon: Icons.history_rounded,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Riwayat Perizinan Selesai (${historyList.length})',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: historyList.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) {
            final leave = historyList[i];
            final student = leave['student'] as Map<String, dynamic>? ??
                leave['placement']?['student'] as Map<String, dynamic>?;
            final location = leave['location'] as Map<String, dynamic>? ??
                leave['placement']?['location'] as Map<String, dynamic>?;

            final studentName = student?['name']?.toString() ??
                student?['user']?['name']?.toString() ??
                'Siswa';
            final nis = student?['nis']?.toString() ?? '-';
            final cls = student?['class']?.toString() ?? 'XII';
            final dudi = location?['name']?.toString() ?? 'Lokasi PKL';

            final status = (leave['status'] ?? '').toString();
            final isApproved = status == 'approved';
            final type = (leave['type'] ?? '').toString().toLowerCase();
            final typeLabel = type == 'sick' || type == 'sakit' ? 'Sakit' : 'Izin';

            final reviewerNote = leave['reviewer_note']?.toString();
            final dateLabel = leave['date_range_label']?.toString() ??
                '${leave['start_date'] ?? '-'} s/d ${leave['end_date'] ?? '-'}';
            final attachmentUrl = leave['attachment_url']?.toString() ?? '';

            final initial = studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S';

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFFEFF6FF),
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              studentName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              '$nis • $cls • $dudi',
                              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusPill(
                        text: isApproved ? 'Disetujui' : 'Ditolak',
                        style: isApproved ? PillStyle.success : PillStyle.error,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jenis: $typeLabel • Rentang: $dateLabel',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
                        if (leave['reason'] != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Alasan: “${leave['reason']}”',
                            style: const TextStyle(
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                        if (reviewerNote != null && reviewerNote.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Catatan Guru: $reviewerNote',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isApproved ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (attachmentUrl.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _previewAttachment(studentName, attachmentUrl, 'Lampiran'),
                        icon: const Icon(Icons.attachment_rounded, size: 14),
                        label: const Text('Lihat Lampiran', style: TextStyle(fontSize: 11)),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // MODAL & AKSI VERIFIKASI / TOLAK IZIN KE BACKEND
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> _confirmVerifikasiIzin(int leaveId, String studentName, String status) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Verifikasi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        content: Text('Apakah Anda yakin ingin menyetujui (ACC) pengajuan izin/sakit dari $studentName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Setujui'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _processingLeaveIds.add(leaveId));

    final res = await TeacherService.verifyLeaveRequest(
      id: leaveId,
      status: 'approved',
      note: 'Disetujui oleh Guru Pembimbing',
    );

    if (mounted) {
      setState(() => _processingLeaveIds.remove(leaveId));
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Pengajuan izin berhasil disetujui.'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
        _loadRekapData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Gagal memproses verifikasi izin.'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _showRejectDialog(int leaveId, String studentName) async {
    final noteController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tolak Pengajuan Izin', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Masukkan alasan penolakan untuk $studentName:'),
            const SizedBox(height: 10),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Contoh: Berkas surat dokter kurang jelas / tidak terlampir.',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() => _processingLeaveIds.add(leaveId));

      final note = noteController.text.trim().isNotEmpty
          ? noteController.text.trim()
          : 'Pengajuan ditolak oleh guru pembimbing.';

      final res = await TeacherService.verifyLeaveRequest(
        id: leaveId,
        status: 'rejected',
        note: note,
      );

      if (mounted) {
        setState(() => _processingLeaveIds.remove(leaveId));
        if (res['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Pengajuan izin telah ditolak.'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
          _loadRekapData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Gagal menolak izin.'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    }
  }

  void _showStudentDetailModal(Map<String, dynamic> student) {
    final name = student['name']?.toString() ?? 'Siswa';
    final nis = student['nis']?.toString() ?? '-';
    final cls = student['class']?.toString() ?? '-';
    final major = student['major']?.toString() ?? '-';
    final phone = student['phone']?.toString() ?? '-';

    final location = student['location'] as Map<String, dynamic>?;
    final dudiName = location?['name']?.toString() ?? 'Belum Ditentukan';
    final dudiAddress = location?['address']?.toString() ?? '-';

    final fieldSup = student['field_supervisor'] as Map<String, dynamic>?;
    final supName = fieldSup?['name']?.toString() ?? '-';
    final supPhone = fieldSup?['phone']?.toString() ?? '-';

    final attToday = student['attendance_today'] as Map<String, dynamic>?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            Text(
              'NIS: $nis • Kelas: $cls',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 10),
            _buildDetailRow('Jurusan', major),
            _buildDetailRow('Kontak Siswa', phone),
            _buildDetailRow('Tempat PKL / DUDI', dudiName),
            _buildDetailRow('Alamat DUDI', dudiAddress),
            _buildDetailRow('Pembimbing Industri', supName),
            _buildDetailRow('Kontak Pembimbing', supPhone),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10),
            const Text(
              'Kehadiran Hari Ini:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            if (attToday != null) ...[
              _buildDetailRow('Status', (attToday['status'] ?? '-').toString().toUpperCase()),
              _buildDetailRow('Jam Masuk', _formatTime(attToday['check_in_at']?.toString() ?? '')),
              _buildDetailRow('Jam Pulang', _formatTime(attToday['check_out_at']?.toString() ?? '')),
            ] else ...[
              const Text('Belum ada data presensi hari ini.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }

  void _previewAttachment(String studentName, String url, String fileName) {
    final formattedUrl = AuthService.formatImageUrl(url);
    final isPdf = fileName.toLowerCase().endsWith('.pdf');

    if (!isPdf) {
      _showFullImageDialog(studentName, formattedUrl);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(fileName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nama Siswa: $studentName'),
            const SizedBox(height: 6),
            const Text('Status Lampiran: Dokumen Resmi Siswa'),
            const SizedBox(height: 12),
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.picture_as_pdf_rounded, size: 48, color: Color(0xFFE11D48)),
                  SizedBox(height: 6),
                  Text('Dokumen PDF Terverifikasi', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showFullImageDialog(String title, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Container(
                  height: 180,
                  color: const Color(0xFFF1F5F9),
                  child: const Center(
                    child: Text('Gagal memuat gambar', style: TextStyle(color: Color(0xFF64748B))),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, {IconData icon = Icons.info_outline_rounded}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: const Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String raw) {
    if (raw.isEmpty) return '';
    try {
      if (raw.contains('T')) {
        final parsed = DateTime.parse(raw).toLocal();
        final hh = parsed.hour.toString().padLeft(2, '0');
        final mm = parsed.minute.toString().padLeft(2, '0');
        return '$hh:$mm WIB';
      }
      final parts = raw.split(' ');
      if (parts.length > 1) {
        final timePart = parts[1];
        final sub = timePart.split(':');
        if (sub.length >= 2) return '${sub[0]}:${sub[1]} WIB';
      }
    } catch (_) {}
    return raw;
  }
}
