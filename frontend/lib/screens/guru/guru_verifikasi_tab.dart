import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/teacher_service.dart';
import '../../widgets/smart_pkl_header.dart';
import 'guru_logbook_detail_screen.dart';

/// ==============================================================================
/// TAB VERIFIKASI LOGBOOK GURU PEMBIMBING (SMART PKL)
///
/// Halaman khusus untuk memantau dan memberikan verifikasi (ACC & Catatan)
/// terhadap jurnal logbook harian seluruh siswa bimbingan PKL.
/// ==============================================================================
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
  bool _isLoading = true;
  List<Map<String, dynamic>> _logbooks = [];
  String _filterStatus = 'all'; // 'all', 'unreviewed', 'reviewed', 'submitted', 'approved'
  final Map<int, String> _localTeacherNotes = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final results = await TeacherService.getLogbooksList();
      if (mounted) {
        setState(() {
          _logbooks = results;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _hasTeacherReview(Map<String, dynamic> j) {
    final jId = j['id'] is int ? j['id'] as int : int.tryParse(j['id']?.toString() ?? '0') ?? 0;
    if (_localTeacherNotes.containsKey(jId)) {
      final local = _localTeacherNotes[jId]?.trim() ?? '';
      if (local.isNotEmpty) return true;
    }
    final note = j['teacher_note']?.toString().trim() ?? '';
    final hasFlag = j['has_teacher_note'] == true;
    return hasFlag || note.isNotEmpty;
  }

  List<Map<String, dynamic>> get _filteredLogbooks {
    if (_filterStatus == 'unreviewed') {
      return _logbooks.where((j) => !_hasTeacherReview(j)).toList();
    } else if (_filterStatus == 'reviewed') {
      return _logbooks.where((j) => _hasTeacherReview(j)).toList();
    } else if (_filterStatus == 'submitted') {
      return _logbooks.where((j) => (j['status'] ?? '').toString().toLowerCase() == 'submitted').toList();
    } else if (_filterStatus == 'approved') {
      return _logbooks.where((j) => (j['status'] ?? '').toString().toLowerCase() == 'approved').toList();
    }
    return _logbooks;
  }

  int get _unreviewedCount => _logbooks.where((j) => !_hasTeacherReview(j)).length;

  int get _reviewedCount => _logbooks.where((j) => _hasTeacherReview(j)).length;

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
            // Header SMART PKL (Konsisten font 18pt bold)
            SmartPklHeader(
              title: 'Verifikasi Logbook',
              onProfileTap: () => widget.onNavigateTab?.call(3),
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
                      // Filter Pills for Logbooks
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildFilterChip('all', 'Semua (${_logbooks.length})'),
                            const SizedBox(width: 8),
                            _buildFilterChip('unreviewed', 'Belum Diulas ($_unreviewedCount)'),
                            const SizedBox(width: 8),
                            _buildFilterChip('reviewed', 'Sudah Diulas ($_reviewedCount)'),
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
                          final journalId = logbook['id'] is int
                              ? logbook['id'] as int
                              : int.tryParse(logbook['id']?.toString() ?? '0') ?? 0;

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
                          final dudiVerifierName = logbook['dudi_name']?.toString() ??
                              verifier?['name']?.toString();
                          final dudiComment = logbook['dudi_note']?.toString() ??
                              logbook['verification_comment']?.toString() ??
                              logbook['verification_note']?.toString();

                          final teacherComment = _localTeacherNotes[journalId] ??
                              logbook['teacher_note']?.toString();
                          final teacherName = logbook['teacher_name']?.toString();
                          final hasTeacherComment = _hasTeacherReview(logbook);

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
                              verifierName: dudiVerifierName,
                              verificationComment: dudiComment,
                              teacherName: teacherName,
                              teacherNote: teacherComment,
                              hasTeacherNote: hasTeacherComment,
                              onDetailTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (ctx) => GuruLogbookDetailScreen(
                                      logbook: logbook,
                                      student: student,
                                    ),
                                  ),
                                );
                                _loadData();
                              },
                              onBeriCatatanTap: () => _showBeriCatatanModal(context, logbook, student),
                            ),
                          );
                        }),
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

    final studentName = student?['name']?.toString() ?? 'Siswa';
    final existingTeacherComment = _localTeacherNotes[journalId] ??
        logbook['teacher_note']?.toString() ??
        '';

    final textController = TextEditingController(text: existingTeacherComment);
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final isEditing = existingTeacherComment.trim().isNotEmpty;
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
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isEditing ? Icons.edit_note_rounded : Icons.rate_review_rounded,
                        color: const Color(0xFF2563EB),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Ubah Catatan Bimbingan Guru' : 'Beri Catatan Bimbingan Guru',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Siswa: $studentName',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: textController,
                  maxLines: 4,
                  autofocus: true,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: 'Tuliskan catatan apresiasi, saran perbaikan materi, atau evaluasi kegiatan PKL siswa...',
                    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.all(14),
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
                              if (mounted) {
                                setState(() {
                                  _localTeacherNotes[journalId] = note;
                                  logbook['teacher_note'] = note;
                                  logbook['has_teacher_note'] = true;
                                });
                              }
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(res['message'] ?? 'Catatan berhasil disimpan!'),
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
                      isSubmitting ? 'Menyimpan...' : (isEditing ? 'Simpan Perubahan Catatan' : 'Kirim Catatan Guru'),
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
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => GuruLogbookDetailScreen(
                            logbook: logbook,
                            student: student,
                          ),
                        ),
                      );
                      _loadData();
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
            fontSize: 12,
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
            _filterStatus == 'unreviewed'
                ? 'Semua logbook siswa bimbingan telah Anda berikan catatan ulasan.'
                : _filterStatus == 'reviewed'
                    ? 'Belum ada logbook yang Anda berikan catatan ulasan.'
                    : _filterStatus == 'submitted'
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
    String? teacherName,
    String? teacherNote,
    required bool hasTeacherNote,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: isApproved
                          ? const Color(0xFFDCFCE7)
                          : isRejected
                              ? const Color(0xFFFEE2E2)
                              : const Color(0xFFFEF3C7),
                      child: Icon(
                        isApproved
                            ? Icons.check_circle_rounded
                            : isRejected
                                ? Icons.cancel_rounded
                                : Icons.schedule_rounded,
                        size: 20,
                        color: isApproved
                            ? const Color(0xFF16A34A)
                            : isRejected
                                ? AppColors.error
                                : const Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            namaSiswa,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$kelas • $dudi',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: isApproved
                          ? const Color(0xFFDCFCE7)
                          : isRejected
                              ? const Color(0xFFFEE2E2)
                              : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isApproved
                          ? 'Sudah Di-ACC'
                          : isRejected
                              ? 'Ditolak'
                              : 'Perlu ACC',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isApproved
                            ? const Color(0xFF16A34A)
                            : isRejected
                                ? AppColors.error
                                : const Color(0xFFD97706),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: hasTeacherNote ? const Color(0xFFEFF6FF) : const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: hasTeacherNote ? const Color(0xFFBFDBFE) : const Color(0xFFFDE68A),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasTeacherNote ? Icons.check_circle_rounded : Icons.pending_outlined,
                          size: 11,
                          color: hasTeacherNote ? const Color(0xFF2563EB) : const Color(0xFFD97706),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hasTeacherNote ? 'Sudah Diulas' : 'Belum Diulas',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: hasTeacherNote ? const Color(0xFF1D4ED8) : const Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.event_note_rounded, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                tanggal,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            judul,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            uraian,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          // Catatan Verifikator DUDI (Kotak Hijau/Merah)
          if (verificationComment != null && verificationComment.isNotEmpty) ...[
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
                        verifierName != null ? 'Catatan Verifikator ($verifierName):' : 'Catatan Verifikasi DUDI:',
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
          // Catatan Guru Pembimbing (Kotak Biru Khusus)
          if (teacherNote != null && teacherNote.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFBFDBFE),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.school_rounded,
                        size: 13,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        teacherName != null && teacherName.isNotEmpty
                            ? 'Catatan Guru Pembimbing ($teacherName):'
                            : 'Catatan Guru Pembimbing:',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '“$teacherNote”',
                    style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF1E3A8A),
                      height: 1.35,
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
              icon: Icon(
                hasTeacherNote ? Icons.edit_note_rounded : Icons.rate_review_rounded,
                size: 16,
              ),
              label: Text(
                hasTeacherNote ? 'Ubah Catatan Guru' : 'Beri Catatan Bimbingan',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: hasTeacherNote ? const Color(0xFF1D4ED8) : AppColors.primary,
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
}
