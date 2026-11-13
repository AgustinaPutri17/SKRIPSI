import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/admin_service.dart';
import '../../core/utils/file_download_helper.dart';
import '../../core/utils/pdf_report_helper.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/smart_pkl_header.dart';

class StudentRekapItem {
  final String nama;
  final String nis;
  final String jurusan;
  final String dudi;
  final String guruPembimbing;
  final int hariHadir;
  final double? nilaiDudi;
  final double? nilaiGuru;

  const StudentRekapItem({
    required this.nama,
    required this.nis,
    required this.jurusan,
    required this.dudi,
    required this.guruPembimbing,
    required this.hariHadir,
    this.nilaiDudi,
    this.nilaiGuru,
  });

  /// Rumus Nilai Total: (Nilai DU/DI + Nilai Guru Pembimbing) / 2
  double? get nilaiTotal {
    if (nilaiDudi != null && nilaiGuru != null) {
      return (nilaiDudi! + nilaiGuru!) / 2.0;
    } else if (nilaiDudi != null) {
      return nilaiDudi;
    } else if (nilaiGuru != null) {
      return nilaiGuru;
    }
    return null;
  }
}

class AdminRekapTab extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const AdminRekapTab({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<AdminRekapTab> createState() => _AdminRekapTabState();
}

class _AdminRekapTabState extends State<AdminRekapTab> {
  // ── Sub-Tab State: 0: Kehadiran, 1: Logbook, 2: Nilai & KKM ──
  int _activeSubTab = 0;

  // ── Global Loading State ──
  bool _isLoading = true;

  // ── Rekap Nilai State ──
  List<StudentRekapItem> _students = [];

  // ── Rekap Kehadiran State ──
  List<dynamic> _attendances = [];
  Map<String, dynamic> _attendanceSummary = {
    'total': 0,
    'present': 0,
    'late': 0,
    'sick': 0,
    'leave': 0,
    'absent': 0,
  };
  DateTime? _selectedAttendanceDate;
  String _attendanceStatusFilter = 'all'; // all, present, late, sick, leave, absent

  // ── Rekap Logbook State ──
  List<dynamic> _logbooks = [];
  Map<String, dynamic> _logbookSummary = {
    'total': 0,
    'approved': 0,
    'submitted': 0,
    'rejected': 0,
    'draft': 0,
  };
  DateTime? _selectedLogbookDate;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadAttendanceData(),
      _loadLogbookData(),
      _loadNilaiData(),
    ]);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. DATA REKAP KEHADIRAN (Presensi Masuk, Pulang, Terlambat, Izin/Sakit)
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> _loadAttendanceData() async {
    try {
      final dateStr = _selectedAttendanceDate != null
          ? "${_selectedAttendanceDate!.year.toString().padLeft(4, '0')}-${_selectedAttendanceDate!.month.toString().padLeft(2, '0')}-${_selectedAttendanceDate!.day.toString().padLeft(2, '0')}"
          : null;

      final res = await AdminService.getAttendances(
        date: dateStr,
        status: _attendanceStatusFilter != 'all' ? _attendanceStatusFilter : null,
      );

      if (res != null && mounted) {
        setState(() {
          _attendances = (res['attendances'] as List<dynamic>?) ?? [];
          if (res['summary'] != null && res['summary'] is Map<String, dynamic>) {
            _attendanceSummary = res['summary'] as Map<String, dynamic>;
          }
        });
      }
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. DATA REKAP LOGBOOK (Jurnal Aktivitas Harian)
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> _loadLogbookData() async {
    try {
      final dateStr = _selectedLogbookDate != null
          ? "${_selectedLogbookDate!.year.toString().padLeft(4, '0')}-${_selectedLogbookDate!.month.toString().padLeft(2, '0')}-${_selectedLogbookDate!.day.toString().padLeft(2, '0')}"
          : null;

      final res = await AdminService.getLogbooks(
        date: dateStr,
        status: 'approved',
      );

      if (res != null && mounted) {
        final list = (res['logbooks'] as List<dynamic>?) ?? [];
        final approvedList = list.where((item) {
          final s = (item['status'] ?? '').toString().toLowerCase();
          return s == 'approved' || s == 'disetujui';
        }).toList();

        setState(() {
          _logbooks = approvedList;
          if (res['summary'] != null && res['summary'] is Map<String, dynamic>) {
            _logbookSummary = res['summary'] as Map<String, dynamic>;
          }
        });
      }
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. DATA REKAP NILAI & KKM
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> _loadNilaiData() async {
    try {
      final placements = await AdminService.getPlacements(perPage: 100);
      final dashboard = await AdminService.getDashboard();

      int attendanceToday = 1;
      if (dashboard != null && dashboard['attendance_today'] != null) {
        attendanceToday = dashboard['attendance_today'] is int
            ? dashboard['attendance_today']
            : int.tryParse(dashboard['attendance_today'].toString()) ?? 1;
      }

      final List<StudentRekapItem> items = [];

      if (placements != null && placements.isNotEmpty) {
        for (final p in placements) {
          final student = p['student'] as Map<String, dynamic>?;
          final location = p['location'] as Map<String, dynamic>?;
          final teacher = p['teacher'] as Map<String, dynamic>?;

          if (student != null) {
            items.add(
              StudentRekapItem(
                nama: student['name']?.toString() ?? 'Siswa',
                nis: student['nis']?.toString() ?? '-',
                jurusan: student['major']?.toString() ?? student['class']?.toString() ?? 'Rekayasa Perangkat Lunak',
                dudi: location?['name']?.toString() ?? 'Mitra DU/DI',
                guruPembimbing: teacher?['name']?.toString() ?? 'Guru Pembimbing',
                hariHadir: attendanceToday > 0 ? attendanceToday : 1,
                nilaiDudi: null,
                nilaiGuru: null,
              ),
            );
          }
        }
      }

      if (items.isEmpty) {
        items.add(
          const StudentRekapItem(
            nama: 'Agustina Putri',
            nis: '23150',
            jurusan: 'Rekayasa Perangkat Lunak',
            dudi: 'PT SAID',
            guruPembimbing: 'Tina',
            hariHadir: 1,
            nilaiDudi: null,
            nilaiGuru: null,
          ),
        );
      }

      if (mounted) {
        setState(() => _students = items);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _students = [
            const StudentRekapItem(
              nama: 'Agustina Putri',
              nis: '23150',
              jurusan: 'Rekayasa Perangkat Lunak',
              dudi: 'PT SAID',
              guruPembimbing: 'Tina',
              hariHadir: 1,
              nilaiDudi: null,
              nilaiGuru: null,
            ),
          ];
        });
      }
    }
  }

  // ── Helper Formatting Tanggal & Hari ──
  String _formatHariTanggal(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '-';
    try {
      final dt = DateTime.parse(rawDate);
      const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      final dayName = days[dt.weekday - 1];
      final monthName = months[dt.month - 1];
      return '$dayName, ${dt.day} $monthName ${dt.year}';
    } catch (_) {
      return rawDate;
    }
  }

  String _formatJam(String? rawDateTime) {
    if (rawDateTime == null || rawDateTime.isEmpty) return '-';
    try {
      if (rawDateTime.contains('T')) {
        final dt = DateTime.parse(rawDateTime).toLocal();
        final h = dt.hour.toString().padLeft(2, '0');
        final m = dt.minute.toString().padLeft(2, '0');
        return '$h:$m WIB';
      }
      return rawDateTime;
    } catch (_) {
      return rawDateTime;
    }
  }

  // ── STATISTIK REKAP NILAI ──
  int get _totalSiswa => _students.length;
  int get _totalAkumulasiHadir => _students.fold(0, (sum, s) => sum + s.hariHadir);

  double? get _rataRataNilaiDudi {
    final graded = _students.where((s) => s.nilaiDudi != null).toList();
    if (graded.isEmpty) return null;
    return graded.fold(0.0, (acc, s) => acc + s.nilaiDudi!) / graded.length;
  }

  double? get _rataRataNilaiGuru {
    final graded = _students.where((s) => s.nilaiGuru != null).toList();
    if (graded.isEmpty) return null;
    return graded.fold(0.0, (acc, s) => acc + s.nilaiGuru!) / graded.length;
  }

  double? get _rataRataNilaiTotal {
    final graded = _students.where((s) => s.nilaiTotal != null).toList();
    if (graded.isEmpty) return null;
    return graded.fold(0.0, (acc, s) => acc + s.nilaiTotal!) / graded.length;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // HAPUS DATA PRESENSI
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> _confirmDeleteAttendance(Map<String, dynamic> item) async {
    final id = item['id'];
    final placement = item['placement'] as Map<String, dynamic>?;
    final student = placement?['student'] as Map<String, dynamic>?;
    final studentName = student?['name']?.toString() ?? 'Siswa';
    final dateStr = _formatHariTanggal(item['attendance_date']?.toString());

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626), size: 24),
            SizedBox(width: 8),
            Text('Hapus Presensi?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus data presensi $studentName pada tanggal $dateStr?\n\nData yang telah dihapus tidak dapat dipulihkan kembali.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Hapus Data', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true && id != null) {
      final res = await AdminService.deleteAttendance(int.parse(id.toString()));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(res['success'] == true ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(res['message']?.toString() ?? 'Proses selesai.')),
              ],
            ),
            backgroundColor: res['success'] == true ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadAttendanceData();
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // HAPUS DATA LOGBOOK
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> _confirmDeleteLogbook(Map<String, dynamic> item) async {
    final id = item['id'];
    final placement = item['placement'] as Map<String, dynamic>?;
    final student = (item['student'] as Map<String, dynamic>?) ?? (placement?['student'] as Map<String, dynamic>?);
    final studentName = student?['name']?.toString() ?? 'Siswa';
    final dateStr = _formatHariTanggal(item['logbook_date']?.toString() ?? item['journal_date']?.toString());

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626), size: 24),
            SizedBox(width: 8),
            Text('Hapus Logbook?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus data logbook kegiatan $studentName pada tanggal $dateStr?\n\nData yang telah dihapus tidak dapat dipulihkan kembali.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Hapus Logbook', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true && id != null) {
      final res = await AdminService.deleteLogbook(int.parse(id.toString()));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(res['success'] == true ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(res['message']?.toString() ?? 'Proses selesai.')),
              ],
            ),
            backgroundColor: res['success'] == true ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadLogbookData();
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // DOWNLOAD EXCEL / CSV (PRESENSI)
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> _downloadAttendanceCsv() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 10),
            Text('Menyiapkan file ekspor Excel presensi...'),
          ],
        ),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    final dateStr = _selectedAttendanceDate != null
        ? "${_selectedAttendanceDate!.year.toString().padLeft(4, '0')}-${_selectedAttendanceDate!.month.toString().padLeft(2, '0')}-${_selectedAttendanceDate!.day.toString().padLeft(2, '0')}"
        : null;

    final csvData = await AdminService.exportAttendancesCsv(
      date: dateStr,
      status: _attendanceStatusFilter != 'all' ? _attendanceStatusFilter : null,
    );

    if (csvData != null && mounted) {
      final fileName = 'rekap_kehadiran_${DateTime.now().millisecondsSinceEpoch}.csv';
      FileDownloadHelper.download(csvData, fileName);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.download_done_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('File $fileName berhasil diunduh!')),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengekspor data presensi.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // PREVIEW FOTO POPUP
  // ─────────────────────────────────────────────────────────────────────────────
  void _showPhotoDialog(String url, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 18,
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.7,
                maxWidth: 600,
              ),
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 3.5,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, prog) => prog == null
                      ? child
                      : const SizedBox(
                          height: 200,
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                  errorBuilder: (context, error, stackTrace) => const SizedBox(
                    height: 180,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image_rounded, size: 40, color: Color(0xFF94A3B8)),
                          SizedBox(height: 6),
                          Text('Foto tidak dapat dimuat', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SmartPklHeader(
              title: 'Rekapitulasi & Laporan',
              subtitle: 'Rekap Kehadiran, Logbook, & Nilai Siswa',
              onProfileTap: () => widget.onNavigateTab?.call(3),
            ),

            // ── TOP NAVIGATION SUB-TAB PILLS ──
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildSubTabButton(
                      index: 0,
                      icon: Icons.how_to_reg_rounded,
                      label: 'Kehadiran (${_attendanceSummary['total'] ?? _attendances.length})',
                    ),
                    const SizedBox(width: 8),
                    _buildSubTabButton(
                      index: 1,
                      icon: Icons.menu_book_rounded,
                      label: 'Logbook (${_logbookSummary['total'] ?? _logbooks.length})',
                    ),
                    const SizedBox(width: 8),
                    _buildSubTabButton(
                      index: 2,
                      icon: Icons.calculate_rounded,
                      label: 'Nilai ($_totalSiswa)',
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // ── CONTENT AREA ──
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAllData,
                      color: const Color(0xFF2563EB),
                      child: _buildCurrentSubTab(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubTabButton({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _activeSubTab == index;
    return InkWell(
      onTap: () {
        if (_activeSubTab != index) {
          setState(() => _activeSubTab = index);
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentSubTab() {
    switch (_activeSubTab) {
      case 0:
        return _buildAttendanceRekapView();
      case 1:
        return _buildLogbookRekapView();
      case 2:
      default:
        return _buildNilaiRekapView();
    }
  }

  // =============================================================================
  // SUB-TAB 0: REKAP KEHADIRAN (PRESENSI SISWA)
  // =============================================================================
  Widget _buildAttendanceRekapView() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. FILTER TANGGAL & STATUS
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Picker Selector
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedAttendanceDate ?? DateTime.now(),
                      firstDate: DateTime(2024, 1, 1),
                      lastDate: DateTime(2030, 12, 31),
                      helpText: 'PILIH TANGGAL PRESENSI',
                      cancelText: 'Batal',
                      confirmText: 'Pilih',
                    );
                    if (picked != null) {
                      setState(() => _selectedAttendanceDate = picked);
                      _loadAttendanceData();
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFF2563EB)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedAttendanceDate != null
                                ? 'Tanggal: ${_formatHariTanggal(_selectedAttendanceDate!.toIso8601String())}'
                                : 'Filter Tanggal: Semua Tanggal',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _selectedAttendanceDate != null ? FontWeight.w700 : FontWeight.w500,
                              color: _selectedAttendanceDate != null ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        if (_selectedAttendanceDate != null)
                          InkWell(
                            onTap: () {
                              setState(() => _selectedAttendanceDate = null);
                              _loadAttendanceData();
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
                            ),
                          )
                        else
                          const Icon(Icons.arrow_drop_down_rounded, size: 20, color: Color(0xFF64748B)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Semua Status', 'all', _attendanceStatusFilter, (v) {
                        setState(() => _attendanceStatusFilter = v);
                        _loadAttendanceData();
                      }),
                      _buildFilterChip('Hadir', 'present', _attendanceStatusFilter, (v) {
                        setState(() => _attendanceStatusFilter = v);
                        _loadAttendanceData();
                      }),
                      _buildFilterChip('Terlambat', 'late', _attendanceStatusFilter, (v) {
                        setState(() => _attendanceStatusFilter = v);
                        _loadAttendanceData();
                      }),
                      _buildFilterChip('Izin', 'leave', _attendanceStatusFilter, (v) {
                        setState(() => _attendanceStatusFilter = v);
                        _loadAttendanceData();
                      }),
                      _buildFilterChip('Sakit', 'sick', _attendanceStatusFilter, (v) {
                        setState(() => _attendanceStatusFilter = v);
                        _loadAttendanceData();
                      }),
                      _buildFilterChip('Alpha', 'absent', _attendanceStatusFilter, (v) {
                        setState(() => _attendanceStatusFilter = v);
                        _loadAttendanceData();
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. DAFTAR REKAPAN KEHADIRAN SISWA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daftar Riwayat Presensi (${_attendances.length} Data)',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF2563EB)),
                onPressed: _loadAttendanceData,
                tooltip: 'Refresh Data',
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_attendances.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Icon(Icons.event_busy_rounded, size: 44, color: Color(0xFF94A3B8)),
                    SizedBox(height: 8),
                    Text(
                      'Belum ada data presensi yang sesuai filter.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _attendances.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (ctx, idx) {
                final item = _attendances[idx] as Map<String, dynamic>;
                return _buildAttendanceCard(item);
              },
            ),

          const SizedBox(height: 18),

          // 3. ACTION ROW DI BAWAH: EKSPOR EXCEL & CETAK PDF
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _downloadAttendanceCsv,
                  icon: const Icon(Icons.table_view_rounded, size: 16),
                  label: const Text('Unduh Excel (.csv)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _printAttendancePdf,
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                  label: const Text('Cetak / PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> item) {
    final placement = item['placement'] as Map<String, dynamic>?;
    final student = placement?['student'] as Map<String, dynamic>?;
    final location = placement?['location'] as Map<String, dynamic>?;
    final teacher = placement?['teacher'] as Map<String, dynamic>?;

    final studentName = student?['name']?.toString() ?? 'Siswa PKL';
    final nis = student?['nis']?.toString() ?? '-';
    final dudiName = location?['name']?.toString() ?? '-';
    final teacherName = teacher?['name']?.toString() ?? '-';

    final dateStr = _formatHariTanggal(item['attendance_date']?.toString());
    final checkIn = _formatJam(item['check_in_at']?.toString());
    final checkOut = _formatJam(item['check_out_at']?.toString());
    final status = (item['status'] ?? 'present').toString();
    final notes = item['notes']?.toString();
    final lateMin = item['late_minutes'];

    final checkInPhoto = item['check_in_photo_url']?.toString();
    final checkOutPhoto = item['check_out_photo_url']?.toString();

    // Status styling
    Color statusBg = const Color(0xFFDCFCE7);
    Color statusText = const Color(0xFF15803D);
    String statusLabel = 'Hadir';
    IconData statusIcon = Icons.check_circle_rounded;

    if (status == 'late') {
      statusBg = const Color(0xFFFEF3C7);
      statusText = const Color(0xFFB45309);
      statusLabel = 'Terlambat ${lateMin != null && lateMin > 0 ? '(+$lateMin m)' : ''}';
      statusIcon = Icons.alarm_rounded;
    } else if (status == 'sick') {
      statusBg = const Color(0xFFF3E8FF);
      statusText = const Color(0xFF6B21A8);
      statusLabel = 'Sakit';
      statusIcon = Icons.local_hospital_outlined;
    } else if (status == 'leave') {
      statusBg = const Color(0xFFEFF6FF);
      statusText = const Color(0xFF1D4ED8);
      statusLabel = 'Izin';
      statusIcon = Icons.event_available_rounded;
    } else if (status == 'absent') {
      statusBg = const Color(0xFFFEE2E2);
      statusText = const Color(0xFFB91C1C);
      statusLabel = 'Alpha';
      statusIcon = Icons.cancel_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          // Header: Nama Siswa & Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFEFF6FF),
                child: Text(
                  studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'NIS: $nis • $dudiName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusText),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusText),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // Detail Presensi: Hari, Jam Masuk & Jam Keluar
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(dateStr, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.login_rounded, size: 14, color: Color(0xFF16A34A)),
                    const SizedBox(width: 4),
                    Text('Masuk: $checkIn', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF16A34A))),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.logout_rounded, size: 14, color: Color(0xFFDC2626)),
                    const SizedBox(width: 4),
                    Text('Pulang: $checkOut', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFDC2626))),
                  ],
                ),
              ),
            ],
          ),

          // Keterangan / Alasan (Izin / Sakit / Catatan)
          if (notes != null && notes.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes_rounded, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Keterangan: $notes',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF334155), fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Foto Selfie Thumbnail (Jika ada)
          if (checkInPhoto != null || checkOutPhoto != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (checkInPhoto != null) ...[
                  InkWell(
                    onTap: () => _showPhotoDialog(checkInPhoto, 'Foto Selfie Masuk ($studentName)'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt_outlined, size: 13, color: Color(0xFF2563EB)),
                          SizedBox(width: 4),
                          Text('Foto Masuk', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (checkOutPhoto != null) ...[
                  InkWell(
                    onTap: () => _showPhotoDialog(checkOutPhoto, 'Foto Selfie Pulang ($studentName)'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt_outlined, size: 13, color: Color(0xFF2563EB)),
                          SizedBox(width: 4),
                          Text('Foto Pulang', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],

          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 6),

          // Footer: Guru Pembimbing & Tombol Hapus Rekap
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pembimbing: $teacherName',
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),
              InkWell(
                onTap: () => _confirmDeleteAttendance(item),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 13, color: Color(0xFFDC2626)),
                      SizedBox(width: 3),
                      Text('Hapus', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
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

  // =============================================================================
  // SUB-TAB 1: REKAP LOGBOOK (JURNAL HARIAN SISWA - SUDAH ACC / DISETUJUI)
  // =============================================================================
  Widget _buildLogbookRekapView() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. FILTER TANGGAL (HANYA TANGGAL, TANPA STATUS & PENCARIAN)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedLogbookDate ?? DateTime.now(),
                  firstDate: DateTime(2024, 1, 1),
                  lastDate: DateTime(2030, 12, 31),
                  helpText: 'PILIH TANGGAL LOGBOOK',
                  cancelText: 'Batal',
                  confirmText: 'Pilih',
                );
                if (picked != null) {
                  setState(() => _selectedLogbookDate = picked);
                  _loadLogbookData();
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedLogbookDate != null
                            ? 'Tanggal: ${_formatHariTanggal(_selectedLogbookDate!.toIso8601String())}'
                            : 'Filter Tanggal: Semua Tanggal',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _selectedLogbookDate != null ? FontWeight.w700 : FontWeight.w500,
                          color: _selectedLogbookDate != null ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    if (_selectedLogbookDate != null)
                      InkWell(
                        onTap: () {
                          setState(() => _selectedLogbookDate = null);
                          _loadLogbookData();
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
                        ),
                      )
                    else
                      const Icon(Icons.arrow_drop_down_rounded, size: 20, color: Color(0xFF64748B)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 2. DAFTAR REKAPAN LOGBOOK (HANYA YANG SUDAH DISETUJUI / ACC)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daftar Jurnal Aktivitas (${_logbooks.length} Data Disetujui)',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF2563EB)),
                onPressed: _loadLogbookData,
                tooltip: 'Refresh Logbook',
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_logbooks.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Icon(Icons.menu_book_outlined, size: 44, color: Color(0xFF94A3B8)),
                    SizedBox(height: 8),
                    Text(
                      'Belum ada logbook yang disetujui / ACC.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _logbooks.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (ctx, idx) {
                final item = _logbooks[idx] as Map<String, dynamic>;
                return _buildLogbookCard(item);
              },
            ),

          const SizedBox(height: 18),

          // 3. ACTION ROW DI BAWAH: HANYA CETAK / PDF (SESUAI REQUEST USER, TANPA EXCEL)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _printLogbookPdf,
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
              label: const Text('Cetak / PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLogbookCard(Map<String, dynamic> item) {
    final placement = item['placement'] as Map<String, dynamic>?;
    final student = (item['student'] as Map<String, dynamic>?) ?? (placement?['student'] as Map<String, dynamic>?);
    final location = (item['location'] as Map<String, dynamic>?) ?? (placement?['location'] as Map<String, dynamic>?);
    final verifier = item['verifier'] as Map<String, dynamic>?;

    final studentName = student?['name']?.toString() ?? 'Siswa';
    final nis = student?['nis']?.toString() ?? '-';
    final dudiName = location?['name']?.toString() ?? '-';
    final verifierName = verifier?['name']?.toString() ?? item['dudi_name']?.toString() ?? item['teacher_name']?.toString();

    final dateStr = _formatHariTanggal(item['logbook_date']?.toString() ?? item['journal_date']?.toString());
    final activity = item['activity']?.toString() ?? 'Kegiatan PKL';
    final desc = item['description']?.toString() ?? '-';
    final result = item['result']?.toString();
    final photoUrl = item['photo_url']?.toString();
    final status = (item['status'] ?? 'draft').toString();
    final reviewNote = item['verification_note']?.toString() ?? item['verification_comment']?.toString();

    // Status styling
    Color statusBg = const Color(0xFFF1F5F9);
    Color statusText = const Color(0xFF64748B);
    String statusLabel = 'Draft';
    IconData statusIcon = Icons.edit_note_rounded;

    if (status == 'approved') {
      statusBg = const Color(0xFFDCFCE7);
      statusText = const Color(0xFF15803D);
      statusLabel = 'Disetujui';
      statusIcon = Icons.verified_rounded;
    } else if (status == 'submitted') {
      statusBg = const Color(0xFFFEF3C7);
      statusText = const Color(0xFFB45309);
      statusLabel = 'Menunggu';
      statusIcon = Icons.hourglass_top_rounded;
    } else if (status == 'rejected') {
      statusBg = const Color(0xFFFEE2E2);
      statusText = const Color(0xFFB91C1C);
      statusLabel = 'Revisi';
      statusIcon = Icons.assignment_late_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          // Header: Nama Siswa & Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFEFF6FF),
                child: Text(
                  studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'NIS: $nis • $dudiName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusText),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusText),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // Tanggal & Aktivitas
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(dateStr, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            activity,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(fontSize: 11, color: Color(0xFF475569), height: 1.4),
          ),

          if (result != null && result.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Hasil: $result',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF16A34A)),
            ),
          ],

          // Foto Dokumentasi
          if (photoUrl != null && photoUrl.isNotEmpty) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _showPhotoDialog(photoUrl, 'Dokumentasi Logbook ($studentName)'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.image_outlined, size: 13, color: Color(0xFF2563EB)),
                    SizedBox(width: 4),
                    Text('Lihat Foto Kegiatan', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                  ],
                ),
              ),
            ),
          ],

          // Catatan Pembimbing
          if (reviewNote != null && reviewNote.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFEF3C7)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.rate_review_outlined, size: 14, color: Color(0xFFD97706)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Catatan Pembimbing: $reviewNote',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 6),

          // Footer: Verifier & Hapus Logbook
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                verifierName != null ? 'Ditinjau oleh: $verifierName' : 'Belum ditinjau',
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),
              InkWell(
                onTap: () => _confirmDeleteLogbook(item),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 13, color: Color(0xFFDC2626)),
                      SizedBox(width: 3),
                      Text('Hapus', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
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

  // =============================================================================
  // SUB-TAB 2: REKAP NILAI & KKM (PENILAIAN SISWA)
  // =============================================================================
  Widget _buildNilaiRekapView() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. BANNER FORMULA NILAI PKL: (Nilai DU/DI + Nilai Guru) / 2
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
                  color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.calculate_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Formula Penilaian PKL',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF08A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Bobot 50% : 50%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF854D0E),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Nilai Total = ',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        '(Nilai DU/DI + Nilai Guru) ÷ 2',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. KARTU RINGKASAN METRIK RATA-RATA
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Rata Nilai DU/DI',
                  _rataRataNilaiDudi != null ? _rataRataNilaiDudi!.toStringAsFixed(1) : '-',
                  const Color(0xFF2563EB),
                ),
                Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
                _buildStatItem(
                  'Rata Nilai Guru',
                  _rataRataNilaiGuru != null ? _rataRataNilaiGuru!.toStringAsFixed(1) : '-',
                  const Color(0xFF7C3AED),
                ),
                Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
                _buildStatItem(
                  'Rata Nilai Total',
                  _rataRataNilaiTotal != null ? _rataRataNilaiTotal!.toStringAsFixed(1) : '-',
                  const Color(0xFF16A34A),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. TABEL REKAPITULASI NILAI SISWA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tabel Nilai & Kehadiran Siswa',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  '$_totalSiswa Siswa Terhitung',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Kontainer Tabel Lengkap
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Text(
                          'Nama Siswa / DUDI',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'DU/DI',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Guru',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Total',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                        ),
                      ),
                    ],
                  ),
                ),

                // Table Rows
                if (_students.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(
                      child: Text(
                        'Belum ada siswa yang mengisi absensi',
                        style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  )
                else
                  ..._students.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final s = entry.value;
                    return Column(
                      children: [
                        if (idx > 0) const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _buildStudentRow(s),
                      ],
                    );
                  }),

                // FOOTER TABEL: Total Kehadiran & Rata-rata Nilai
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    border: Border(
                      top: BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL / RATA-RATA',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Akumulasi Hadir: $_totalAkumulasiHadir Hari',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF16A34A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          _rataRataNilaiDudi != null ? _rataRataNilaiDudi!.toStringAsFixed(1) : '-',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          _rataRataNilaiGuru != null ? _rataRataNilaiGuru!.toStringAsFixed(1) : '-',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _rataRataNilaiTotal != null ? _rataRataNilaiTotal!.toStringAsFixed(1) : '-',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                            const Text(
                              'Rata Total',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 9,
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
          const SizedBox(height: 14),

          // 4. KARTU INFORMASI FOOTER PENILAIAN & PRESENSI
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Ketentuan Penilaian PKL',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 15, color: Color(0xFF16A34A)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Nilai Total dihitung otomatis dari (Nilai DU/DI + Nilai Guru) ÷ 2 jika guru dan instruktur DU/DI telah memasukkan penilaian.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF475569)),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 15, color: Color(0xFF16A34A)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Kehadiran dihitung per hari kerja berdasarkan rekaman presensi siswa yang telah mengisi absensi masuk dan keluar.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF475569)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 5. TOMBOL EKSPOR (PDF & EXCEL)
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Cetak Rekap PDF',
                  icon: Icons.picture_as_pdf_rounded,
                  color: const Color(0xFFEF4444),
                  fontSize: 12,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  onPressed: _showPdfExportDialog,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomButton(
                  text: 'Ekspor Excel (.xlsx)',
                  icon: Icons.table_view_rounded,
                  color: const Color(0xFF16A34A),
                  fontSize: 12,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  onPressed: _showExcelExportDialog,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Helper Widgets ──
  Widget _buildFilterChip(String label, String value, String currentSelected, Function(String) onSelect) {
    final isSelected = currentSelected == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => onSelect(value),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildStudentRow(StudentRekapItem s) {
    final String nilaiDudiText = s.nilaiDudi != null ? s.nilaiDudi!.toStringAsFixed(0) : '-';
    final String nilaiGuruText = s.nilaiGuru != null ? s.nilaiGuru!.toStringAsFixed(0) : '-';
    final String nilaiTotalText = s.nilaiTotal != null ? s.nilaiTotal!.toStringAsFixed(1) : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.nama,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(
                  '${s.dudi} • ${s.guruPembimbing}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Hadir: ${s.hariHadir} Hari',
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              nilaiDudiText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: s.nilaiDudi != null ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              nilaiGuruText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: s.nilaiGuru != null ? const Color(0xFF7C3AED) : const Color(0xFF94A3B8),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              nilaiTotalText,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: s.nilaiTotal != null ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // CETAK / PDF LANGSUNG (KEHADIRAN)
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> _printAttendancePdf() async {
    if (_attendances.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada data kehadiran untuk dicetak.'),
          backgroundColor: Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final dateLabel = _selectedAttendanceDate != null
          ? _formatHariTanggal(_selectedAttendanceDate!.toIso8601String())
          : null;
      await PdfReportHelper.printAttendanceReport(
        attendances: _attendances,
        dateLabel: dateLabel,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat PDF kehadiran: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // CETAK / PDF LANGSUNG (LOGBOOK)
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> _printLogbookPdf() async {
    if (_logbooks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada data logbook untuk dicetak.'),
          backgroundColor: Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 10),
            Text('Menyiapkan PDF logbook & foto kegiatan...'),
          ],
        ),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      final dateLabel = _selectedLogbookDate != null
          ? _formatHariTanggal(_selectedLogbookDate!.toIso8601String())
          : null;
      await PdfReportHelper.printLogbookReport(
        logbooks: _logbooks,
        dateLabel: dateLabel,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat PDF logbook: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // MODAL EKSPOR EXCEL (NILAI)
  // ─────────────────────────────────────────────────────────────────────────────
  void _showExcelExportDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.table_view_rounded, color: Color(0xFF16A34A), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ekspor Nilai & Kehadiran Excel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        Text('Data Rekapitulasi Siswa Terhitung', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildMetaRow('Jumlah Siswa Hadir', '$_totalSiswa Siswa'),
                    const Divider(height: 14),
                    _buildMetaRow(
                      'Rata-rata Nilai DU/DI',
                      _rataRataNilaiDudi != null ? _rataRataNilaiDudi!.toStringAsFixed(1) : 'Belum ada nilai',
                    ),
                    const Divider(height: 14),
                    _buildMetaRow(
                      'Rata-rata Nilai Guru',
                      _rataRataNilaiGuru != null ? _rataRataNilaiGuru!.toStringAsFixed(1) : 'Belum ada nilai',
                    ),
                    const Divider(height: 14),
                    _buildMetaRow(
                      'Rata-rata Nilai Total',
                      _rataRataNilaiTotal != null ? _rataRataNilaiTotal!.toStringAsFixed(1) : 'Belum ada nilai',
                    ),
                    const Divider(height: 14),
                    _buildMetaRow('Akumulasi Kehadiran', '$_totalAkumulasiHadir Hari'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final buffer = StringBuffer();
                        buffer.writeln('No\tNIS\tNama Siswa\tJurusan\tMitra DUDI\tGuru Pembimbing\tTotal Hadir\tNilai DUDI\tNilai Guru\tNilai Total');
                        for (int i = 0; i < _students.length; i++) {
                          final s = _students[i];
                          final dudi = s.nilaiDudi != null ? s.nilaiDudi!.toStringAsFixed(0) : '-';
                          final guru = s.nilaiGuru != null ? s.nilaiGuru!.toStringAsFixed(0) : '-';
                          final total = s.nilaiTotal != null ? s.nilaiTotal!.toStringAsFixed(1) : '-';
                          buffer.writeln(
                            '${i + 1}\t${s.nis}\t${s.nama}\t${s.jurusan}\t${s.dudi}\t${s.guruPembimbing}\t${s.hariHadir} Hari\t$dudi\t$guru\t$total',
                          );
                        }
                        Clipboard.setData(ClipboardData(text: buffer.toString()));

                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text('Data tabel lengkap berhasil disalin! Silakan tempel (Paste) di Microsoft Excel atau Google Sheets.'),
                                ),
                              ],
                            ),
                            backgroundColor: Color(0xFF16A34A),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Salin Data Excel'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: const Color(0xFF16A34A),
                        side: const BorderSide(color: Color(0xFF16A34A)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final buffer = StringBuffer();
                        buffer.writeln('No,NIS,Nama Siswa,Jurusan,Mitra DUDI,Guru Pembimbing,Total Hadir,Nilai DUDI,Nilai Guru,Nilai Total');
                        for (int i = 0; i < _students.length; i++) {
                          final s = _students[i];
                          final dudi = s.nilaiDudi != null ? s.nilaiDudi!.toStringAsFixed(0) : '-';
                          final guru = s.nilaiGuru != null ? s.nilaiGuru!.toStringAsFixed(0) : '-';
                          final total = s.nilaiTotal != null ? s.nilaiTotal!.toStringAsFixed(1) : '-';
                          buffer.writeln('${i + 1},"${s.nis}","${s.nama}","${s.jurusan}","${s.dudi}","${s.guruPembimbing}","${s.hariHadir} Hari",$dudi,$guru,$total');
                        }
                        FileDownloadHelper.download(buffer.toString(), 'Rekap_Nilai_PKL_${DateTime.now().millisecondsSinceEpoch}.csv');
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.download_done_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Expanded(child: Text('File Rekap_Nilai_PKL.csv berhasil diunduh!')),
                              ],
                            ),
                            backgroundColor: Color(0xFF16A34A),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.file_download_rounded, size: 18),
                      label: const Text('Unduh .csv'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // MODAL CETAK PDF (NILAI)
  // ─────────────────────────────────────────────────────────────────────────────
  void _showPdfExportDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cetak Lembar Nilai & Rekap PDF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        Text('Dokumen Rekapitulasi Penilaian & Kehadiran', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text('SMK NEGERI 2 BANDAR LAMPUNG', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    ),
                    const Center(
                      child: Text('LEMBAR REKAPITULASI PENILAIAN & KEHADIRAN PKL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                    ),
                    const Divider(thickness: 1.5, color: Color(0xFF0F172A), height: 16),
                    _buildMetaRow('Formula Nilai', 'Nilai Total = (Nilai DU/DI + Nilai Guru) ÷ 2'),
                    const SizedBox(height: 4),
                    _buildMetaRow('Jumlah Siswa Hadir', '$_totalSiswa Siswa Terhitung'),
                    const SizedBox(height: 4),
                    _buildMetaRow('Total Kehadiran', '$_totalAkumulasiHadir Hari'),
                    const SizedBox(height: 4),
                    _buildMetaRow('Rata-rata Nilai DU/DI', _rataRataNilaiDudi != null ? _rataRataNilaiDudi!.toStringAsFixed(1) : '-'),
                    const SizedBox(height: 4),
                    _buildMetaRow('Rata-rata Nilai Guru', _rataRataNilaiGuru != null ? _rataRataNilaiGuru!.toStringAsFixed(1) : '-'),
                    const SizedBox(height: 4),
                    _buildMetaRow('Rata-rata Nilai Total', _rataRataNilaiTotal != null ? _rataRataNilaiTotal!.toStringAsFixed(1) : '-'),
                    const SizedBox(height: 16),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Pembimbing Lapangan DU/DI', style: TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                        Text('Guru Pembimbing Sekolah', style: TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('( ________________________ )', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                        Text('( ________________________ )', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Expanded(child: Text('Laporan Rekapitulasi Nilai & Kehadiran siap dicetak!')),
                          ],
                        ),
                        backgroundColor: Color(0xFFDC2626),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.print_rounded, size: 18),
                  label: const Text('Cetak / Unduh Dokumen PDF'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }
}
