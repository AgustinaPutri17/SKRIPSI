import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/teacher_service.dart';
import '../../widgets/smart_pkl_header.dart';
import '../../widgets/status_pill.dart';
import '../common/pdf_viewer_screen.dart';

/// ==============================================================================
/// DETAIL BIMBINGAN & PEMANTAUAN PROJEK SISWA OLEH GURU PEMBIMBING
/// Guru pembimbing dapat memantau projek dan memberikan catatan bimbingan
/// yang akan langsung terkirim dan terbaca oleh siswa di riwayat projeknya.
/// ==============================================================================
class GuruProjekDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? studentData;
  final int? projectId;

  const GuruProjekDetailScreen({
    super.key,
    this.studentData,
    this.projectId,
  });

  @override
  State<GuruProjekDetailScreen> createState() => _GuruProjekDetailScreenState();
}

class _GuruProjekDetailScreenState extends State<GuruProjekDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _project;
  List<Map<String, dynamic>> _reviews = [];

  final TextEditingController _noteController = TextEditingController();
  bool _isSubmittingNote = false;

  @override
  void initState() {
    super.initState();
    _loadProjectData();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadProjectData() async {
    setState(() => _isLoading = true);

    try {
      int? targetId = widget.projectId;

      if (targetId == null) {
        final list = await TeacherService.getProjects();
        final studentId = widget.studentData?['id']?.toString() ??
            widget.studentData?['student_id']?.toString();

        if (studentId != null) {
          final match = list.firstWhere(
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
        final detail = await TeacherService.getProjectDetail(targetId);
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

  Future<void> _submitTeacherNote() async {
    final note = _noteController.text.trim();
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tuliskan catatan arahan atau bimbingan terlebih dahulu.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final projectId = _project?['id'] as int? ?? widget.projectId;
    if (projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID projek tidak ditemukan.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmittingNote = true);
    final res = await TeacherService.addProjectNote(
      projectId: projectId,
      note: note,
    );

    if (!mounted) return;
    setState(() => _isSubmittingNote = false);

    if (res['success'] == true) {
      _noteController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  res['message'] ?? 'Catatan bimbingan berhasil dikirim ke siswa!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadProjectData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Gagal mengirim catatan bimbingan.'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
        'SMK';
    final studentMajor = _project?['student']?['major']?.toString() ??
        widget.studentData?['major']?.toString() ??
        '';
    final locationName = _project?['student']?['location']?.toString() ??
        widget.studentData?['placement']?['location']?['name']?.toString() ??
        'Instansi DU/DI';

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
              title: 'Projek Siswa',
              subtitle: 'Bimbingan & Pemantauan Guru',
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
                    // Siswa Profile Card
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
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        locationName,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2563EB),
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
                              'Data pengerjaan projek magang siswa akan muncul di sini setelah siswa mengisikan form projek.',
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
                                        : int.tryParse(_project?['id']?.toString() ?? '');
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
                                        : int.tryParse(_project?['id']?.toString() ?? '');
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

                      // FORM INPUT CATATAN GURU PEMBIMBING
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.school_rounded, size: 20, color: Color(0xFF2563EB)),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Beri Catatan Bimbingan (Guru Sekolah)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Catatan ini akan dikirimkan dan langsung dapat dibaca oleh siswa pada halaman projeknya.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _noteController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Tuliskan catatan arahan, bimbingan, atau masukan untuk siswa...',
                                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.all(12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isSubmittingNote ? null : _submitTeacherNote,
                                icon: _isSubmittingNote
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.send_rounded, size: 18),
                                label: Text(
                                  _isSubmittingNote ? 'Mengirim Catatan...' : 'Kirim Catatan Bimbingan ke Siswa',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Section Catatan & Riwayat Verifikasi (DU/DI & Guru)
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
                            const SizedBox(height: 10),
                            if (_reviews.where((r) => r['reviewer_role'] == 'teacher').isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Belum ada catatan evaluasi untuk projek ini.',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              )
                            else
                              ..._reviews.where((r) => r['reviewer_role'] == 'teacher').map((r) {
                                final revName = r['reviewer_name']?.toString() ?? 'Guru Pembimbing';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFBFDBFE)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.school_rounded, size: 15, color: Color(0xFF1D4ED8)),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Catatan Guru ($revName)',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF1D4ED8),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (r['note'] != null && r['note'].toString().isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          'Catatan: "${r['note']}"',
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF1E3A8A), height: 1.4),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }),
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
