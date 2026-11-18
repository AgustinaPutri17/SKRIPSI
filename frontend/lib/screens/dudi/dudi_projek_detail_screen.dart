import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/supervisor_service.dart';
import '../../widgets/smart_pkl_header.dart';
import '../../widgets/status_pill.dart';
import '../common/pdf_viewer_screen.dart';

/// ==============================================================================
/// VERIFIKASI PROJEK SISWA OLEH DU/DI
/// Terhubung langsung dengan backend API:
/// - GET /api/supervisor/projects/{id}
/// - POST /api/supervisor/projects/{id}/verify
/// ==============================================================================
class DudiProjekDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? studentData;
  final int? projectId;

  const DudiProjekDetailScreen({
    super.key,
    this.studentData,
    this.projectId,
  });

  @override
  State<DudiProjekDetailScreen> createState() => _DudiProjekDetailScreenState();
}

class _DudiProjekDetailScreenState extends State<DudiProjekDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = true;
  bool _isSubmitting = false;

  Map<String, dynamic>? _project;
  List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadProjectData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadProjectData() async {
    setState(() => _isLoading = true);

    try {
      int? targetId = widget.projectId;

      // Jika projectId belum diberikan langsung, cari dari daftar projek siswa
      if (targetId == null) {
        final projects = await SupervisorService.getProjects();
        final studentId = widget.studentData?['id']?.toString() ?? widget.studentData?['student_id']?.toString();

        if (studentId != null) {
          final match = projects.firstWhere(
            (p) =>
                p['student']?['id']?.toString() == studentId ||
                p['placement_id']?.toString() == widget.studentData?['placement_id']?.toString(),
            orElse: () => {},
          );
          if (match.isNotEmpty) {
            targetId = match['id'] as int?;
          }
        }
      }

      if (targetId != null) {
        final detail = await SupervisorService.getProjectDetail(targetId);
        if (detail != null && mounted) {
          setState(() {
            _project = detail;
            final rawReviews = detail['reviews'] as List<dynamic>? ?? [];
            _reviews = rawReviews.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          });
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAction(bool isApprove) async {
    final note = _commentController.text.trim();
    if (!isApprove && note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catatan Instruktur wajib diisi saat meminta revisi projek.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final projectId = _project?['id'] ?? widget.projectId;
    if (projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data projek siswa belum tersedia untuk diverifikasi.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final res = await SupervisorService.verifyProject(
        id: projectId as int,
        decision: isApprove ? 'approved' : 'revision',
        note: note,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isApprove
                  ? 'Projek siswa berhasil disetujui (ACC).'
                  : 'Projek siswa dikembalikan untuk revisi beserta catatan evaluasi.',
            ),
            backgroundColor: isApprove ? const Color(0xFF16A34A) : const Color(0xFFEA580C),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).maybePop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Gagal memproses verifikasi projek.'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildStatusPill(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const StatusPill(text: 'Disetujui', style: PillStyle.success);
      case 'revision':
        return const StatusPill(text: 'Direvisi', style: PillStyle.error);
      case 'pending':
      case 'submitted':
        return const StatusPill(text: 'Menunggu', style: PillStyle.warning);
      default:
        return const StatusPill(text: 'Draf', style: PillStyle.neutral);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentName = _project?['student']?['name']?.toString() ??
        widget.studentData?['name']?.toString() ??
        'Nama Siswa';
    final studentClass = _project?['student']?['class']?.toString() ??
        widget.studentData?['class']?.toString() ??
        widget.studentData?['school']?.toString() ??
        'SMK';
    final studentMajor = _project?['student']?['major']?.toString() ??
        widget.studentData?['major']?.toString() ??
        '';

    final initials = studentName.isNotEmpty
        ? studentName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'SW';

    final projectTitle = _project?['title']?.toString() ?? '';
    final projectDesc = _project?['description']?.toString() ?? '';
    final projectPlan = _project?['plan']?.toString() ?? '';
    final projectResult = _project?['result']?.toString() ?? '';
    final docName = _project?['document_name']?.toString();
    final docSize = _project?['document_size'] as int? ?? 0;
    final status = _project?['status']?.toString() ?? 'pending';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SmartPklHeader(
              title: 'Projek',
              subtitle: 'Verifikasi Projek Siswa',
              showBackButton: true,
              onBackTap: () => Navigator.maybePop(context),
            ),
            if (_isLoading)
              const LinearProgressIndicator(
                minHeight: 2,
                color: Color(0xFF2563EB),
                backgroundColor: Color(0xFFEFF6FF),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sub Header
                    const Text(
                      'Verifikasi Projek Siswa',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Siswa Profile Card (Top Blue Accent Line)
                    Container(
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
                          Container(
                            height: 4,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2563EB),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: const Color(0xFFEFF6FF),
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
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
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        studentMajor.isNotEmpty ? '$studentClass • $studentMajor' : studentClass,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _buildStatusPill(status),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (_project == null && !_isLoading)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.folder_open_rounded, size: 48, color: Color(0xFF94A3B8)),
                            SizedBox(height: 12),
                            Text(
                              'Siswa Belum Mengajukan Projek',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Data pekerjaan projek magang dan dokumen laporan siswa akan tampil di sini setelah diajukan oleh siswa.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      // Section 1: Nama & Deskripsi Pekerjaan
                      _buildSectionCard(
                        '1. Nama & Deskripsi Pekerjaan',
                        projectDesc.isNotEmpty && projectDesc != projectTitle
                            ? '$projectTitle\n\n$projectDesc'
                            : (projectTitle.isNotEmpty ? projectTitle : '-'),
                      ),
                      const SizedBox(height: 12),

                      // Section 2: Perencanaan Kegiatan (Planning)
                      _buildSectionCard(
                        '2. Perencanaan Kegiatan (Planning)',
                        projectPlan.isNotEmpty ? projectPlan : 'Tidak ada perencanaan khusus yang dicantumkan.',
                      ),
                      const SizedBox(height: 12),

                      // Section 3: Pelaksanaan Kegiatan / Hasil Karya
                      _buildSectionCard(
                        '3. Pelaksanaan Kegiatan / Hasil Karya',
                        projectResult.isNotEmpty ? projectResult : 'Tidak ada catatan hasil karya tambahan.',
                      ),
                      const SizedBox(height: 12),

                      // Section 4: Berkas Dokumen PDF Terlampir
                      if (docName != null && docName.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Berkas Dokumen Projek',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    final pId = _project?['id'] is int
                                        ? _project!['id'] as int
                                        : int.tryParse((_project?['id'] ?? widget.projectId ?? '').toString());
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PdfViewerScreen(
                                          title: docName,
                                          projectId: pId,
                                          documentUrl: _project?['document_url']?.toString(),
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEE2E2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626), size: 24),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                docName,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF1E293B),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                docSize > 0
                                                    ? '${(docSize / (1024 * 1024)).toStringAsFixed(1)} MB • Dokumen Terlampir'
                                                    : 'Dokumen PDF Terlampir',
                                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.visibility_rounded, color: Color(0xFF2563EB), size: 20),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                height: 40,
                                child: ElevatedButton(
                                  onPressed: () {
                                    final pId = _project?['id'] is int
                                        ? _project!['id'] as int
                                        : int.tryParse((_project?['id'] ?? widget.projectId ?? '').toString());
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PdfViewerScreen(
                                          title: docName,
                                          projectId: pId,
                                          documentUrl: _project?['document_url']?.toString(),
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    'Buka dan Baca Dokumen',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Riwayat Review Sebelumnya jika ada (hanya catatan DU/DI, tanpa umpan balik silang dengan guru)
                      if (_reviews.where((r) => r['reviewer_role'] != 'teacher').isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.history_rounded, size: 16, color: Color(0xFF2563EB)),
                                  SizedBox(width: 6),
                                  Text(
                                    'Catatan Evaluasi Sebelumnya',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ..._reviews.where((r) => r['reviewer_role'] != 'teacher').map((r) {
                                final isAcc = r['decision'] == 'approved';
                                final revName = r['reviewer_name']?.toString() ?? 'Instruktur DU/DI';
                                final String prefix = isAcc ? "Disetujui ($revName)" : "Perlu Revisi ($revName)";

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFBFDBFE)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$prefix: ${r['note'] ?? "-"}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1D4ED8),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Section Catatan Instruktur Box
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Catatan Instruktur DU/DI',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: TextField(
                                controller: _commentController,
                                maxLines: 3,
                                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  hintText: 'Tulis masukan atau catatan perbaikan untuk siswa...',
                                  hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Tombol Tolak / Revisi dan Setujui
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _isSubmitting ? null : () => _handleAction(false),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFFEF4444)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 16),
                                    label: const Text(
                                      'Minta Revisi',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFEF4444),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _isSubmitting ? null : () => _handleAction(true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2563EB),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                                    label: const Text(
                                      'Setujui Projek',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
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

  Widget _buildSectionCard(String label, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
