import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/services/student_service.dart';
import '../../widgets/smart_pkl_header.dart';
import '../common/pdf_viewer_screen.dart';

/// ==============================================================================
/// HALAMAN PROJEK SISWA
/// ==============================================================================
/// Fitur:
/// 1. Riwayat Projek Siswa (Daftar projek yang diajukan beserta status verifikasi & catatan DU/DI)
/// 2. Formulir Input Projek Baru (1. Nama Pekerjaan, 2. Perencanaan, 3. Pelaksanaan, 4. Dokumen PDF)
/// 3. Diteruskan ke DU/DI untuk verifikasi & catatan, serta guru pembimbing untuk pemantauan.
/// ==============================================================================
class SiswaProjekTab extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const SiswaProjekTab({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<SiswaProjekTab> createState() => _SiswaProjekTabState();
}

class _SiswaProjekTabState extends State<SiswaProjekTab> {
  // Mode tampilan: false = Riwayat Projek, true = Formulir Input Projek Baru/Edit
  bool _isCreating = false;
  int? _editingProjectId;

  // Controller formulir projek (4 bagian utama)
  final TextEditingController _namaDescController = TextEditingController();
  final TextEditingController _planningController = TextEditingController();
  final TextEditingController _pelaksanaanController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;

  // Lampiran berkas PDF
  String? _selectedFilePath;
  String? _selectedFileName;
  int _selectedFileSize = 0; // Bytes

  // Daftar riwayat projek siswa
  List<Map<String, dynamic>> _projects = [];

  @override
  void initState() {
    super.initState();
    _loadProjectsData();
  }

  @override
  void dispose() {
    _namaDescController.dispose();
    _planningController.dispose();
    _pelaksanaanController.dispose();
    super.dispose();
  }

  /// Memuat daftar seluruh projek siswa dari backend
  Future<void> _loadProjectsData() async {
    setState(() => _isLoading = true);

    try {
      final res = await StudentService.getProjectSubmission();
      if (res != null && mounted) {
        List<Map<String, dynamic>> loadedProjects = [];

        if (res['projects'] is List) {
          final list = res['projects'] as List;
          loadedProjects = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        } else if (res['id'] != null || res['title'] != null) {
          // Format single submission
          loadedProjects = [Map<String, dynamic>.from(res)];
        } else if (res['submission'] is Map) {
          loadedProjects = [Map<String, dynamic>.from(res['submission'] as Map)];
        }

        setState(() {
          _projects = loadedProjects;
        });
      }
    } catch (_) {
      // Backend error / timeout
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Membuka formulir pengajuan projek baru (bersih & kosong)
  void _openCreateForm() {
    setState(() {
      _editingProjectId = null;
      _namaDescController.clear();
      _planningController.clear();
      _pelaksanaanController.clear();
      _selectedFilePath = null;
      _selectedFileName = null;
      _selectedFileSize = 0;
      _isCreating = true;
    });
  }

  /// Mengedit projek yang perlu revisi / draf
  void _openEditForm(Map<String, dynamic> proj) {
    final title = proj['title']?.toString() ?? '';
    final desc = proj['description']?.toString() ?? '';
    String namaDesc = title;
    if (desc.isNotEmpty && desc != title) {
      namaDesc = '$title\n$desc';
    }

    setState(() {
      _editingProjectId = proj['id'] is int ? proj['id'] as int : int.tryParse(proj['id']?.toString() ?? '0');
      _namaDescController.text = namaDesc;
      _planningController.text = proj['plan']?.toString() ?? '';
      _pelaksanaanController.text = proj['result']?.toString() ?? '';
      _selectedFilePath = null;
      _selectedFileName = proj['document_name']?.toString();
      _selectedFileSize = proj['document_size'] as int? ?? 0;
      _isCreating = true;
    });
  }

  /// Membuka file picker asli untuk memilih dokumen PDF (Maks. 15 MB)
  Future<void> _pickPdfFile() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (files.isNotEmpty) {
        final file = files.first;
        final fileSize = file.lengthSync() ?? (await file.length()) ?? 0;
        if (fileSize > 15 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ukuran file maksimal adalah 15 MB.'),
                backgroundColor: Color(0xFFDC2626),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedFilePath = file.path;
          _selectedFileName = file.name;
          _selectedFileSize = fileSize;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Berkas "${file.name}" berhasil dipilih!'),
              backgroundColor: const Color(0xFF2563EB),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih file: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Submit pengajuan projek ke backend
  Future<void> _handleSubmit() async {
    final namaDesc = _namaDescController.text.trim();
    final plan = _planningController.text.trim();
    final result = _pelaksanaanController.text.trim();

    if (namaDesc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan masukkan 1. Nama & Deskripsi Pekerjaan projek terlebih dahulu.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final lines = namaDesc.split('\n');
      final title = lines.first.trim();
      final description = lines.length > 1 ? lines.sublist(1).join('\n').trim() : namaDesc;

      final response = await StudentService.saveProjectSubmission(
        id: _editingProjectId,
        title: title,
        description: description.isNotEmpty ? description : title,
        plan: plan,
        result: result,
        filePath: _selectedFilePath,
        documentName: _selectedFileName,
        documentSize: _selectedFileSize,
        submitImmediately: true,
      );

      if (mounted) {
        if (response['success'] == true) {
          final returnedData = response['data'];
          setState(() {
            _isCreating = false;
            _editingProjectId = null;
            _namaDescController.clear();
            _planningController.clear();
            _pelaksanaanController.clear();
            _selectedFilePath = null;
            _selectedFileName = null;

            if (returnedData is Map) {
              final projMap = Map<String, dynamic>.from(returnedData);
              final pId = projMap['id'];
              final idx = _projects.indexWhere((p) => p['id'] == pId);
              if (idx >= 0) {
                _projects[idx] = projMap;
              } else {
                _projects.insert(0, projMap);
              }
            }
          });

          await _loadProjectsData();

          if (!mounted) return;
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 28),
                  SizedBox(width: 10),
                  Text('Projek Terkirim!', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                ],
              ),
              content: Text(
                response['message']?.toString() ??
                    'Projek dan berkas PDF berhasil diajukan dan sedang menunggu verifikasi serta catatan dari Pembimbing DU/DI!',
                style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message']?.toString() ?? 'Gagal mengajukan projek.'),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan saat mengajukan projek: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
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
            // Header SMART PKL - Projek + Avatar Profil
            SmartPklHeader(
              title: 'Projek',
              onProfileTap: () => widget.onNavigateTab?.call(4),
            ),

            if (_isLoading)
              const LinearProgressIndicator(
                minHeight: 2,
                color: Color(0xFF2563EB),
                backgroundColor: Color(0xFFEFF6FF),
              ),

            Expanded(
              child: _isCreating ? _buildFormView() : _buildHistoryView(),
            ),
          ],
        ),
      ),
    );
  }

  // ── VIEW 1: RIWAYAT PROJEK SISWA ─────────────────────────────────────────────
  Widget _buildHistoryView() {
    return RefreshIndicator(
      color: const Color(0xFF2563EB),
      onRefresh: _loadProjectsData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bar Navigasi & Tombol Tambah Projek Baru
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Riwayat Projek Siswa',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Total: ${_projects.length} Projek Terdaftar',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _openCreateForm,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Isi Projek Baru'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Daftar Projek atau Empty State
            if (_projects.isEmpty)
              _buildEmptyState()
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _projects.length,
                itemBuilder: (ctx, index) => _buildProjectCard(_projects[index]),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Empty state jika siswa belum mengajukan projek
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_outlined,
              size: 44,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum Ada Projek Diajukan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Anda belum memasukkan laporan hasil projek PKL. Silakan klik tombol di bawah untuk mengisi formulir projek baru.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _openCreateForm,
            icon: const Icon(Icons.edit_note_rounded, size: 20),
            label: const Text('Mulai Isi Projek Sekarang'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  /// Kartu tampilan riwayat projek
  Widget _buildProjectCard(Map<String, dynamic> proj) {
    final title = proj['title']?.toString() ?? 'Projek Siswa';
    final desc = proj['description']?.toString() ?? '';
    final plan = proj['plan']?.toString() ?? '';
    final result = proj['result']?.toString() ?? '';
    final docName = proj['document_name']?.toString();
    final status = proj['status']?.toString() ?? 'draft';
    final submittedAt = proj['submitted_at']?.toString() ?? proj['created_at']?.toString() ?? '';
    final reviews = proj['reviews'] as List<dynamic>? ?? [];

    // Konfigurasi Status Badge
    Color badgeColor;
    Color badgeBg;
    IconData badgeIcon;
    String badgeLabel;

    if (status == 'approved') {
      badgeColor = const Color(0xFF16A34A);
      badgeBg = const Color(0xFFDCFCE7);
      badgeIcon = Icons.check_circle_rounded;
      badgeLabel = 'Disetujui';
    } else if (status == 'revision') {
      badgeColor = const Color(0xFFDC2626);
      badgeBg = const Color(0xFFFEE2E2);
      badgeIcon = Icons.warning_amber_rounded;
      badgeLabel = 'Perlu Revisi';
    } else if (status == 'pending' || status == 'submitted') {
      badgeColor = const Color(0xFF2563EB);
      badgeBg = const Color(0xFFEFF6FF);
      badgeIcon = Icons.hourglass_top_rounded;
      badgeLabel = 'Menunggu Verifikasi';
    } else {
      badgeColor = const Color(0xFF64748B);
      badgeBg = const Color(0xFFF1F5F9);
      badgeIcon = Icons.edit_note_rounded;
      badgeLabel = 'Draf Projek';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Header Card: Judul & Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 13, color: badgeColor),
                    const SizedBox(width: 4),
                    Text(
                      badgeLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (submittedAt.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Diajukan: ${submittedAt.length >= 10 ? submittedAt.substring(0, 10) : submittedAt}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],

          const Divider(height: 20),

          // 1. Rincian Deskripsi
          if (desc.isNotEmpty && desc != title) ...[
            const Text(
              'Deskripsi Pekerjaan:',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
          ],

          // 2. Perencanaan
          if (plan.isNotEmpty) ...[
            const Text(
              'Perencanaan Kegiatan (Planning):',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 2),
            Text(
              plan,
              style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
          ],

          // 3. Pelaksanaan
          if (result.isNotEmpty) ...[
            const Text(
              'Pelaksanaan Kegiatan / Hasil Karya:',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 2),
            Text(
              result,
              style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
          ],

          // 4. Dokumen PDF Terlampir
          if (docName != null && docName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  final pId = proj['id'] is int
                      ? proj['id'] as int
                      : int.tryParse(proj['id']?.toString() ?? '');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PdfViewerScreen(
                        title: docName,
                        projectId: pId,
                        documentUrl: proj['document_url']?.toString(),
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          docName,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility_rounded, size: 14, color: Color(0xFF2563EB)),
                          SizedBox(width: 4),
                          Text('Lihat PDF', style: TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // Catatan & Evaluasi Pembimbing Industri (DU/DI)
          if (reviews.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...reviews.map((rev) {
              final isTeacher = rev['reviewer_role'] == 'teacher';
              final isApp = rev['decision'] == 'approved';
              final note = rev['note']?.toString() ?? '-';
              final revName = rev['reviewer_name']?.toString() ?? (isTeacher ? 'Guru Pembimbing' : 'Pembimbing DU/DI');
              final revDate = rev['created_at']?.toString() ?? '';

              final Color cardBg = isTeacher
                  ? const Color(0xFFEFF6FF)
                  : (isApp ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2));
              final Color cardBorder = isTeacher
                  ? const Color(0xFFBFDBFE)
                  : (isApp ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA));
              final Color titleColor = isTeacher
                  ? const Color(0xFF1E40AF)
                  : (isApp ? const Color(0xFF166534) : const Color(0xFF991B1B));
              final IconData titleIcon = isTeacher
                  ? Icons.school_rounded
                  : (isApp ? Icons.verified_rounded : Icons.feedback_rounded);
              final String titleText = isTeacher
                  ? 'Catatan Bimbingan Guru ($revName)'
                  : 'Catatan Evaluasi DU/DI ($revName)';

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          titleIcon,
                          size: 15,
                          color: titleColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            titleText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                            ),
                          ),
                        ),
                        if (revDate.isNotEmpty)
                          Text(
                            revDate.length >= 10 ? revDate.substring(0, 10) : revDate,
                            style: TextStyle(
                              fontSize: 10,
                              color: titleColor.withValues(alpha: 0.8),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      note,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4),
                    ),
                  ],
                ),
              );
            }),
          ],

          // Tombol Ubah / Revisi jika status perlu revisi atau draf
          if (status == 'revision' || status == 'draft') ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () => _openEditForm(proj),
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: Text(status == 'revision' ? 'Perbaiki & Ajukan Ulang' : 'Lanjutkan Edit Draf'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  side: const BorderSide(color: Color(0xFF2563EB)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── VIEW 2: FORMULIR INPUT PROJEK BARU / EDIT ────────────────────────────────
  Widget _buildFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tombol Kembali ke Riwayat
          InkWell(
            onTap: () {
              setState(() => _isCreating = false);
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_rounded, size: 18, color: Color(0xFF2563EB)),
                  SizedBox(width: 6),
                  Text(
                    'Kembali ke Riwayat Projek',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Card 1: 1. Nama & Deskripsi Pekerjaan
          _buildSectionCard(
            title: '1. Nama & Deskripsi Pekerjaan',
            hintText: 'Contoh: Pengembangan Fitur Presensi GPS\nMasukkan nama pekerjaan serta deskripsi ringkas projek...',
            controller: _namaDescController,
            minLines: 3,
          ),
          const SizedBox(height: 14),

          // Card 2: 2. Perencanaan Kegiatan (Planning)
          _buildSectionCard(
            title: '2. Perencanaan Kegiatan (Planning)',
            hintText: 'Contoh:\n1. Analisis kebutuhan sistem\n2. Perancangan database & mockup\n3. Implementasi kode program',
            controller: _planningController,
            minLines: 4,
          ),
          const SizedBox(height: 14),

          // Card 3: 3. Pelaksanaan Kegiatan / Hasil Karya
          _buildSectionCard(
            title: '3. Pelaksanaan Kegiatan / Hasil Karya',
            hintText: 'Masukkan uraian hasil pengerjaan projek, implementasi fitur, atau capaian pekerjaan yang dilakukan...',
            controller: _pelaksanaanController,
            minLines: 4,
          ),
          const SizedBox(height: 14),

          // Card 4: 4. Dokumen / Berkas Pendukung Projek (PDF Maks. 15 MB)
          _buildPdfUploadCard(),

          const SizedBox(height: 20),

          // Tombol Aksi Utama: Simpan & Ajukan Verifikasi Projek
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                disabledBackgroundColor: const Color(0xFF93C5FD),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Simpan & Ajukan Verifikasi Projek',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Komponen Kartu Input Formulir
  Widget _buildSectionCard({
    required String title,
    required String hintText,
    required TextEditingController controller,
    int minLines = 4,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            ),
            child: TextField(
              controller: controller,
              minLines: minLines,
              maxLines: null,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF0F172A),
                height: 1.4,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                  height: 1.4,
                ),
                contentPadding: const EdgeInsets.all(14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Komponen Bagian 4: Dokumen / Berkas Pendukung Projek (PDF Maks. 15 MB)
  Widget _buildPdfUploadCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
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
          const Text(
            '4. Dokumen / Berkas Pendukung Projek (PDF)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),

          // Tombol Pilih / Ganti Berkas PDF
          Material(
            color: const Color(0xFFF0F7FF),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: _pickPdfFile,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
                ),
                child: Center(
                  child: Text(
                    _selectedFileName != null
                        ? 'Ganti Berkas PDF (Maks. 15 MB)'
                        : 'Pilih Berkas PDF (Maks. 15 MB)',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),

          // Kotak Detail Berkas PDF yang Terlampir
          if (_selectedFileName != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: Color(0xFFDC2626),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedFileName!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Text(
                              '• Terlampir',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                            if (_selectedFileSize > 0) ...[
                              const SizedBox(width: 8),
                              Text(
                                '(${(_selectedFileSize / (1024 * 1024)).toStringAsFixed(2)} MB)',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                    onPressed: () {
                      setState(() {
                        _selectedFilePath = null;
                        _selectedFileName = null;
                        _selectedFileSize = 0;
                      });
                    },
                    tooltip: 'Hapus Lampiran',
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
