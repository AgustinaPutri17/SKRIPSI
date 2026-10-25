import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/teacher_service.dart';
import '../../widgets/smart_pkl_header.dart';
import '../../widgets/status_pill.dart';
import 'guru_logbook_detail_screen.dart';

class GuruVerifikasiTab extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const GuruVerifikasiTab({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<GuruVerifikasiTab> createState() => _GuruVerifikasiTabState();
}

class _GuruVerifikasiTabState extends State<GuruVerifikasiTab> {
  int _activeSubTab = 0; // 0: Verifikasi Logbook, 1: Verifikasi Izin / Sakit

  // State logbook & izin dari API riil
  bool _isLoading = true;
  List<Map<String, dynamic>> _logbooks = [];
  List<Map<String, dynamic>> _leaveRequests = [];
  String _filterStatus = 'all'; // 'all', 'submitted', 'approved'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        TeacherService.getLogbooksList(),
        TeacherService.getLeaveRequests(),
      ]);

      if (mounted) {
        setState(() {
          _logbooks = results[0];
          _leaveRequests = results[1];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredLogbooks {
    if (_filterStatus == 'submitted') {
      return _logbooks.where((j) => (j['status'] ?? '').toString().toLowerCase() == 'submitted').toList();
    } else if (_filterStatus == 'approved') {
      return _logbooks.where((j) => (j['status'] ?? '').toString().toLowerCase() == 'approved').toList();
    }
    return _logbooks;
  }

  int get _pendingCount =>
      _logbooks.where((j) => (j['status'] ?? '').toString().toLowerCase() == 'submitted').length;

  int get _approvedCount =>
      _logbooks.where((j) => (j['status'] ?? '').toString().toLowerCase() == 'approved').length;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SmartPklHeader(
              title: 'Verifikasi',
              subtitle: 'Guru',
              onProfileTap: () => widget.onNavigateTab?.call(4),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Segmented Sub-Tab Switcher
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorder, width: 1),
                        ),
                        child: Row(
                          children: [
                            _buildSubTabButton(
                              0,
                              'Logbook Siswa (${_logbooks.length})',
                              Icons.edit_note_rounded,
                            ),
                            _buildSubTabButton(
                              1,
                              'Izin & Sakit (${_leaveRequests.length})',
                              Icons.medical_services_rounded,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      if (_activeSubTab == 0) ...[
                        // Filter Pills for Logbooks
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip('all', 'Semua (${_logbooks.length})'),
                              const SizedBox(width: 8),
                              _buildFilterChip('submitted', 'Perlu ACC ($_pendingCount)'),
                              const SizedBox(width: 8),
                              _buildFilterChip('approved', 'Sudah Di-ACC ($_approvedCount)'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Loading State
                        if (_isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: CircularProgressIndicator(color: AppColors.primary),
                            ),
                          )
                        else if (_filteredLogbooks.isEmpty)
                          _buildEmptyState()
                        else
                          // Dynamic list of logbooks
                          ..._filteredLogbooks.map((logbook) {
                            final student = logbook['student'] ?? logbook['placement']?['student'];
                            final studentName = student?['name']?.toString() ?? 'Siswa';
                            final studentClass = student?['class']?.toString() ?? 'XII RPL 1';

                            final location = logbook['location'] ?? logbook['placement']?['location'];
                            final dudiName = location?['name']?.toString() ?? 'DUDI Mitra';

                            final tanggal = logbook['logbook_date']?.toString() ??
                                logbook['journal_date']?.toString() ??
                                '-';

                            final judul = logbook['activity']?.toString() ?? 'Aktivitas Harian';
                            final uraian = logbook['description']?.toString() ?? '-';

                            final status = (logbook['status'] ?? '').toString().toLowerCase();
                            final isApproved = status == 'approved';
                            final isRejected = status == 'rejected';

                            final verifier = logbook['verifier'];
                            final verifierName = verifier?['name']?.toString();
                            final verificationComment = logbook['verification_comment']?.toString() ??
                                logbook['verification_note']?.toString();

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _buildVerifikasiLogbookCard(
                                namaSiswa: studentName,
                                kelas: studentClass,
                                dudi: dudiName,
                                tanggal: tanggal,
                                judul: judul,
                                uraian: uraian,
                                isApproved: isApproved,
                                isRejected: isRejected,
                                verifierName: verifierName,
                                verificationComment: verificationComment,
                                onDetailTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (ctx) => GuruLogbookDetailScreen(
                                        logbook: logbook,
                                        student: student,
                                      ),
                                    ),
                                  );
                                },
                                onBeriCatatanTap: () => _showBeriCatatanModal(context, logbook, student),
                              ),
                            );
                          }),
                      ] else ...[
                        // VERIFIKASI IZIN & SAKIT VIEW (DATA REAL DARI API)
                        if (_leaveRequests.isEmpty)
                          _buildEmptyIzinState()
                        else
                          ..._leaveRequests.map((leave) {
                            final student = leave['student'] ?? leave['placement']?['student'];
                            final studentName = student?['name']?.toString() ?? 'Siswa';
                            final studentClass = student?['class']?.toString() ?? 'XII RPL 1';

                            final location = leave['location'] ?? leave['placement']?['location'];
                            final dudiName = location?['name']?.toString() ?? 'DUDI Mitra';

                            final jenisIzin = leave['type_label']?.toString() ?? 'Izin / Sakit';
                            final rentang = leave['date_range_label']?.toString() ??
                                '${leave['start_date'] ?? '-'} s/d ${leave['end_date'] ?? '-'}';
                            final alasan = leave['reason']?.toString() ?? '-';
                            final namaFile = leave['attachment_name']?.toString() ?? 'Tidak ada berkas terlampir';
                            final isApproved = leave['is_approved'] == true || leave['status'] == 'approved';
                            final isRejected = leave['is_rejected'] == true || leave['status'] == 'rejected';
                            final int leaveId = leave['id'] is int
                                ? leave['id']
                                : int.tryParse(leave['id']?.toString() ?? '0') ?? 0;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _buildVerifikasiIzinCard(
                                namaSiswa: studentName,
                                kelas: studentClass,
                                dudi: dudiName,
                                jenisIzin: jenisIzin,
                                rentang: rentang,
                                alasan: alasan,
                                namaFile: namaFile,
                                isApproved: isApproved,
                                isRejected: isRejected,
                                attachmentUrl: leave['attachment_url']?.toString(),
                                reviewerNote: leave['reviewer_note']?.toString(),
                                onApprove: () => _handleApproveIzin(leaveId, studentName),
                                onReject: () => _handleRejectIzin(leaveId, studentName),
                              ),
                            );
                          }),
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

  void _showBeriCatatanModal(BuildContext context, Map<String, dynamic> logbook, Map<String, dynamic>? student) {
    final journalId = logbook['id'] is int
        ? logbook['id'] as int
        : int.tryParse(logbook['id']?.toString() ?? '0') ?? 0;
    final studentName = student?['name']?.toString() ?? logbook['student_name']?.toString() ?? 'Siswa';
    final logbookDate = logbook['logbook_date']?.toString() ?? logbook['journal_date']?.toString() ?? 'Hari Ini';
    final activity = logbook['activity']?.toString() ?? logbook['description']?.toString() ?? 'Aktivitas Logbook';
    final initialNote = logbook['teacher_note']?.toString() ?? '';

    final TextEditingController textController = TextEditingController(text: initialNote);
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
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
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.rate_review_rounded, color: Color(0xFF2563EB), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Beri Catatan Bimbingan',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$studentName • $logbookDate',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.assignment_outlined, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          activity,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Catatan / Arahan Bimbingan Guru:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: TextField(
                    controller: textController,
                    maxLines: 4,
                    autofocus: true,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                    decoration: const InputDecoration(
                      hintText: 'Tuliskan catatan, evaluasi, atau masukan bimbingan untuk siswa...',
                      hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final note = textController.text.trim();
                            if (note.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Tuliskan catatan bimbingan terlebih dahulu'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                              return;
                            }
                            setModalState(() => isSubmitting = true);
                            final res = await TeacherService.addComment(id: journalId, comment: note);
                            setModalState(() => isSubmitting = false);
                            if (res['success'] == true) {
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(res['message'] ?? 'Catatan berhasil dikirim ke siswa!'),
                                    backgroundColor: const Color(0xFF16A34A),
                                  ),
                                );
                                _loadData();
                              }
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(res['message'] ?? 'Gagal mengirim catatan.'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                    label: Text(
                      isSubmitting ? 'Mengirim...' : 'Kirim Catatan',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => GuruLogbookDetailScreen(
                            logbook: logbook,
                            student: student,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 14, color: Color(0xFF2563EB)),
                    label: const Text(
                      'Lihat Foto Selfie & Detail Lengkap Logbook',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filterStatus == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filterStatus = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: 14),
          const Text(
            'Tidak Ada Logbook',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            _filterStatus == 'submitted'
                ? 'Semua logbook siswa bimbingan telah di-ACC.'
                : _filterStatus == 'approved'
                    ? 'Belum ada logbook yang disetujui (di-ACC).'
                    : 'Belum ada logbook yang tercatat dari siswa bimbingan.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Muat Ulang'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTabButton(int index, String title, IconData icon) {
    final bool isSelected = _activeSubTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeSubTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerifikasiLogbookCard({
    required String namaSiswa,
    required String kelas,
    required String dudi,
    required String tanggal,
    required String judul,
    required String uraian,
    required bool isApproved,
    required bool isRejected,
    String? verifierName,
    String? verificationComment,
    VoidCallback? onDetailTap,
    VoidCallback? onBeriCatatanTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isApproved
              ? const Color(0xFF86EFAC)
              : isRejected
                  ? const Color(0xFFFCA5A5)
                  : AppColors.cardBorder,
          width: 1.2,
        ),
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
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: isApproved
                          ? const Color(0xFFDCFCE7)
                          : isRejected
                              ? const Color(0xFFFEE2E2)
                              : AppColors.primarySoft,
                      child: Text(
                        namaSiswa.isNotEmpty ? namaSiswa.substring(0, 1).toUpperCase() : 'S',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isApproved
                              ? const Color(0xFF16A34A)
                              : isRejected
                                  ? AppColors.error
                                  : AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            namaSiswa,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '$kelas • $dudi',
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(
                text: isApproved
                    ? 'Sudah Di-ACC'
                    : isRejected
                        ? 'Perlu Revisi'
                        : 'Menunggu ACC',
                style: isApproved
                    ? PillStyle.success
                    : isRejected
                        ? PillStyle.error
                        : PillStyle.warning,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              tanggal,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            judul,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            uraian,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
          ),
          if (verificationComment != null && verificationComment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isApproved ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isApproved ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isApproved ? Icons.verified_user_rounded : Icons.comment_rounded,
                        size: 13,
                        color: isApproved ? const Color(0xFF16A34A) : AppColors.error,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        verifierName != null ? 'Catatan Verifikator ($verifierName):' : 'Catatan Verifikasi:',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isApproved ? const Color(0xFF15803D) : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '“$verificationComment”',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: isApproved ? const Color(0xFF166534) : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (onDetailTap != null) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: onDetailTap,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.photo_camera_front_rounded, size: 15, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'Lihat Foto Selfie Presensi & Detail Logbook',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onBeriCatatanTap ?? onDetailTap,
              icon: const Icon(Icons.rate_review_rounded, size: 16),
              label: const Text('Beri Catatan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleApproveIzin(int id, String studentName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Setujui Izin / Sakit', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Text('Apakah Anda yakin ingin menyetujui pengajuan izin/sakit siswa $studentName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Ya, Setujui'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final res = await TeacherService.verifyLeaveRequest(
      id: id,
      status: 'approved',
      note: 'Disetujui oleh Guru Pembimbing',
    );

    if (!mounted) return;
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pengajuan izin/sakit $studentName disetujui.'), backgroundColor: const Color(0xFF16A34A)),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Gagal memproses.'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _handleRejectIzin(int id, String studentName) async {
    final noteController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tolak Pengajuan Izin', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tuliskan alasan penolakan izin siswa $studentName:'),
            const SizedBox(height: 10),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                hintText: 'Contoh: Berkas surat keterangan tidak jelas...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Tolak Izin'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final res = await TeacherService.verifyLeaveRequest(
      id: id,
      status: 'rejected',
      note: noteController.text.trim().isNotEmpty ? noteController.text.trim() : 'Ditolak oleh Guru Pembimbing',
    );

    if (!mounted) return;
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pengajuan izin $studentName telah ditolak.'), backgroundColor: AppColors.error),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Gagal memproses.'), backgroundColor: AppColors.error),
      );
    }
  }

  Widget _buildEmptyIzinState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.health_and_safety_outlined,
              size: 44,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum Ada Pengajuan Izin / Sakit',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Seluruh siswa bimbingan hadir aktif di lokasi PKL dan belum ada permohonan izin atau sakit yang diajukan.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVerifikasiIzinCard({
    required String namaSiswa,
    required String kelas,
    required String dudi,
    required String jenisIzin,
    required String rentang,
    required String alasan,
    required String namaFile,
    required bool isApproved,
    bool isRejected = false,
    String? attachmentUrl,
    String? reviewerNote,
    required VoidCallback onApprove,
    required VoidCallback onReject,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isApproved
              ? const Color(0xFF86EFAC)
              : isRejected
                  ? const Color(0xFFFCA5A5)
                  : AppColors.cardBorder,
          width: 1.2,
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
                  namaSiswa,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(
                text: jenisIzin,
                style: PillStyle.error,
                icon: Icons.medical_services_rounded,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '$kelas • $dudi',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_month_outlined, size: 15, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                rentang,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Alasan: $alasan',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
          ),
          const SizedBox(height: 10),
          // Lampiran Box
          GestureDetector(
            onTap: () {
              if (attachmentUrl != null && attachmentUrl.isNotEmpty) {
                final fullUrl = AuthService.formatImageUrl(attachmentUrl);
                showDialog(
                  context: context,
                  builder: (ctx) => Dialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppBar(
                          title: const Text('Berkas Surat Keterangan', style: TextStyle(fontSize: 14)),
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0F172A),
                          elevation: 0,
                          leading: IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ),
                        Image.network(
                          fullUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('Format berkas dokumen lampiran.'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tidak ada berkas lampiran yang diunggah.')),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_file_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      namaFile,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Text(
                    'Lihat Berkas',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
          if (reviewerNote != null && reviewerNote.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isApproved ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isApproved ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
                ),
              ),
              child: Text(
                'Catatan: “$reviewerNote”',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: isApproved ? const Color(0xFF166534) : AppColors.error,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (isApproved)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  '✓ Pengajuan Izin / Sakit Telah Disetujui',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
                ),
              ),
            )
          else if (isRejected)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  '✕ Pengajuan Izin / Sakit Ditolak',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.error),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: Color(0xFFFCA5A5), width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Tolak Izin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Setujui Izin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
