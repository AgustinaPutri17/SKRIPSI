import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/teacher_service.dart';
import '../../widgets/smart_pkl_header.dart';
import 'guru_projek_detail_screen.dart';

/// ==============================================================================
/// TAB PROJEK SISWA GURU PEMBIMBING (SMART PKL)
///
/// Halaman khusus bagi guru pembimbing untuk memantau pengajuan projek siswa
/// yang telah diverifikasi oleh DU/DI, membaca berkas laporan/hasil karya,
/// serta memberikan catatan dan arahan bimbingan kepada siswa.
/// ==============================================================================
class GuruProjekTab extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const GuruProjekTab({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<GuruProjekTab> createState() => _GuruProjekTabState();
}

class _GuruProjekTabState extends State<GuruProjekTab> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _projects = [];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final results = await TeacherService.getProjects();
      if (mounted) {
        setState(() {
          _projects = results;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _hasTeacherReview(Map<String, dynamic> proj) {
    final reviews = proj['reviews'] as List<dynamic>? ?? [];
    return reviews.any((r) => r['reviewer_role'] == 'teacher');
  }

  bool _isVerifiedByDudi(Map<String, dynamic> proj) {
    final status = (proj['status'] ?? '').toString().toLowerCase();
    if (status == 'approved') return true;
    final reviews = proj['reviews'] as List<dynamic>? ?? [];
    return reviews.any((r) => r['reviewer_role'] == 'dudi' && r['decision'] == 'approved');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SmartPklHeader(
              title: 'Projek',
              onProfileTap: () => widget.onNavigateTab?.call(4),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadProjects,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Loading State
                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
                        )
                      else if (_projects.isEmpty)
                        _buildEmptyState()
                      else
                        ..._projects.map((project) => _buildProjectCard(project)),

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

  Widget _buildProjectCard(Map<String, dynamic> project) {
    final student = project['student'] as Map<String, dynamic>? ?? {};
    final studentName = student['name']?.toString() ?? 'Siswa PKL';
    final studentClass = student['class']?.toString() ?? 'XII RPL';
    final major = student['major']?.toString() ?? 'Rekayasa Perangkat Lunak';
    final dudiLocation = student['location']?.toString() ?? 'DUDI Mitra';

    final initials = studentName.isNotEmpty
        ? studentName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase()
        : 'SW';

    final title = project['title']?.toString() ?? 'Projek Siswa';
    final plan = project['plan']?.toString() ?? '';
    final result = project['result']?.toString() ?? '';
    final docName = project['document_name']?.toString();
    final docSize = project['document_size'] as int? ?? 0;
    final status = (project['status'] ?? 'pending').toString().toLowerCase();

    final isVerifiedDudi = _isVerifiedByDudi(project);
    final hasTeacherNote = _hasTeacherReview(project);

    final reviews = project['reviews'] as List<dynamic>? ?? [];
    final dudiReview = reviews.firstWhere(
      (r) => r['reviewer_role'] == 'dudi',
      orElse: () => null,
    );
    final teacherReview = reviews.firstWhere(
      (r) => r['reviewer_role'] == 'teacher',
      orElse: () => null,
    );

    Color statusBadgeBg;
    Color statusBadgeColor;
    String statusBadgeText;
    IconData statusBadgeIcon;

    if (status == 'approved' || isVerifiedDudi) {
      statusBadgeBg = const Color(0xFFDCFCE7);
      statusBadgeColor = const Color(0xFF16A34A);
      statusBadgeText = 'Disetujui';
      statusBadgeIcon = Icons.check_circle_rounded;
    } else if (status == 'revision') {
      statusBadgeBg = const Color(0xFFFEE2E2);
      statusBadgeColor = const Color(0xFFDC2626);
      statusBadgeText = 'Perlu Revisi';
      statusBadgeIcon = Icons.warning_amber_rounded;
    } else {
      statusBadgeBg = const Color(0xFFFEF3C7);
      statusBadgeColor = const Color(0xFFD97706);
      statusBadgeText = 'Menunggu';
      statusBadgeIcon = Icons.hourglass_top_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
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
          // Header: Avatar, Nama Siswa & Status DU/DI
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFEFF6FF),
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2563EB),
                    fontSize: 12,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$studentClass • $major',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBadgeBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusBadgeColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusBadgeIcon, size: 12, color: statusBadgeColor),
                    const SizedBox(width: 4),
                    Text(
                      statusBadgeText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusBadgeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Judul Projek & Lokasi
          Row(
            children: [
              const Icon(Icons.business_rounded, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  dudiLocation,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
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

          // Dokumen PDF Terlampir
          if (docName != null && docName.isNotEmpty) ...[
            const SizedBox(height: 10),
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

          // Catatan DU/DI jika ada
          if (dudiReview != null && dudiReview['note'] != null && dudiReview['note'].toString().trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.rate_review_rounded, size: 13, color: Color(0xFF16A34A)),
                      const SizedBox(width: 5),
                      Text(
                        'Catatan DU/DI (${dudiReview['reviewer_name'] ?? 'Instruktur'}):',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    dudiReview['note'].toString(),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF166534)),
                  ),
                ],
              ),
            ),
          ],

          // Catatan Guru jika sudah ada
          if (teacherReview != null && teacherReview['note'] != null && teacherReview['note'].toString().trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
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
                      const Icon(Icons.school_rounded, size: 13, color: Color(0xFF2563EB)),
                      const SizedBox(width: 5),
                      const Text(
                        'Catatan Bimbingan Anda (Guru):',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    teacherReview['note'].toString(),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF1E40AF)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Tombol Buka & Beri Catatan
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GuruProjekDetailScreen(
                      projectId: project['id'] as int?,
                      studentData: student,
                    ),
                  ),
                ).then((_) => _loadProjects());
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
              icon: Icon(
                hasTeacherNote ? Icons.assignment_turned_in_rounded : Icons.edit_note_rounded,
                size: 16,
              ),
              label: Text(
                hasTeacherNote ? 'Buka & Perbarui Catatan Bimbingan' : 'Buka & Beri Catatan Bimbingan',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Icon(Icons.folder_open_rounded, size: 48, color: Color(0xFF94A3B8)),
          SizedBox(height: 12),
          Text(
            'Tidak Ada Projek Siswa',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Belum ada pengajuan projek siswa pada kategori filter yang dipilih.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
