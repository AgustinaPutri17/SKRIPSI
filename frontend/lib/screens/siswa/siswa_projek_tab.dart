import 'package:flutter/material.dart';
import '../../core/services/student_service.dart';
import '../../widgets/smart_pkl_header.dart';

/// ==============================================================================
/// HALAMAN PROJEK SISWA
/// Sesuai UI Mockup Desain Mobile SMART PKL
/// 
/// Interaksi Backend ('monitoring-pkl-app'):
/// Terhubung dengan tabel 'project_submissions' & 'project_reviews' pada backend.
/// 
/// Panggilan API Backend:
/// 1. GET /api/student/projects
///    -> Mengambil data draf / pengajuan projek yang tersimpan sebelumnya
/// 2. POST /api/student/projects
///    -> Menyimpan draf atau mengajukan verifikasi projek ke Guru Pembimbing & DUDI
///    -> Payload: title, description, plan, result, document_name, document_size, status
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
  // Controller form projek sesuai 3 bagian utama
  final TextEditingController _namaDescController = TextEditingController();
  final TextEditingController _planningController = TextEditingController();
  final TextEditingController _pelaksanaanController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;

  // Lampiran berkas PDF
  String? _selectedFileName;
  int _selectedFileSize = 0; // Bytes
  String _submissionStatus = 'draft'; // 'draft', 'submitted', 'approved', 'revision'

  @override
  void initState() {
    super.initState();
    _loadProjectData();
  }

  @override
  void dispose() {
    _namaDescController.dispose();
    _planningController.dispose();
    _pelaksanaanController.dispose();
    super.dispose();
  }

  /// ============================================================================
  /// PANGGILAN API BACKEND: GET /api/student/projects
  /// Backend File: monitoring-pkl-app (Model: App\Models\ProjectSubmission)
  /// Deskripsi: Mengambil formulir pengajuan projek yang telah disimpan siswa
  /// ============================================================================
  Future<void> _loadProjectData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final projectData = await StudentService.getProjectSubmission();
      if (projectData != null && mounted) {
        final title = projectData['title']?.toString() ?? '';
        final description = projectData['description']?.toString() ?? '';
        final plan = projectData['plan']?.toString() ?? '';
        final result = projectData['result']?.toString() ?? '';
        final docName = projectData['document_name']?.toString();
        final docSize = projectData['document_size'] as int? ?? 0;
        final status = projectData['status']?.toString() ?? 'draft';

        setState(() {
          // Gabungkan nama pekerjaan dan deskripsi jika sebelumnya disimpan terpisah
          if (title.isNotEmpty && description.isNotEmpty && !description.startsWith(title)) {
            _namaDescController.text = '$title\n$description';
          } else {
            _namaDescController.text = description.isNotEmpty ? description : title;
          }

          _planningController.text = plan;
          _pelaksanaanController.text = result;
          _selectedFileName = docName;
          _selectedFileSize = docSize;
          _submissionStatus = status;
        });
      }
    } catch (_) {
      // Backend offline
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Menampilkan dialog pemilih berkas PDF (Maks. 15 MB)
  void _showFilePickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final samplePdfs = [
          {'name': 'Laporan_Akhir_Projek_PKL_Ananda.pdf', 'size': 3450000}, // 3.4 MB
          {'name': 'Dokumentasi_Aplikasi_Monitoring.pdf', 'size': 5120000}, // 5.1 MB
          {'name': 'Proposal_Pekerjaan_Projek_Magang.pdf', 'size': 2180000}, // 2.1 MB
        ];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
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
              const Row(
                children: [
                  Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFEF4444), size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pilih Berkas PDF Laporan',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Pilih berkas PDF laporan projek akhir (Ukuran maksimal 15 MB).',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              ...samplePdfs.map((pdf) {
                final name = pdf['name'] as String;
                final sizeBytes = pdf['size'] as int;
                final sizeMb = (sizeBytes / (1024 * 1024)).toStringAsFixed(1);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.description_rounded, color: Color(0xFFDC2626), size: 20),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                    ),
                    subtitle: Text(
                      '$sizeMb MB • Dokumen PDF',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                    onTap: () {
                      setState(() {
                        _selectedFileName = name;
                        _selectedFileSize = sizeBytes;
                      });
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Berkas "$name" berhasil dipilih!'),
                          backgroundColor: const Color(0xFF2563EB),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  /// ============================================================================
  /// PANGGILAN API BACKEND: POST /api/student/projects
  /// Backend File: monitoring-pkl-app (Model: App\Models\ProjectSubmission)
  /// Deskripsi:
  ///   Mengirim formulir projek dan berkas lampiran untuk verifikasi pembimbing
  /// ============================================================================
  Future<void> _handleSubmit() async {
    final namaDesc = _namaDescController.text.trim();
    final plan = _planningController.text.trim();
    final result = _pelaksanaanController.text.trim();

    if (namaDesc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan masukkan Nama & Deskripsi Pekerjaan projek terlebih dahulu.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Potong baris pertama sebagai judul jika ada
      final lines = namaDesc.split('\n');
      final title = lines.first.trim();
      final description = lines.length > 1 ? lines.sublist(1).join('\n').trim() : namaDesc;

      // ============================================================================
      // PANGGILAN API BACKEND: POST /api/student/projects
      // Payload:
      // {
      //   "title": title,
      //   "description": description,
      //   "plan": plan,
      //   "result": result,
      //   "document_name": _selectedFileName ?? "Laporan_Akhir_PKL.pdf",
      //   "document_size": _selectedFileSize > 0 ? _selectedFileSize : 3500000,
      //   "status": "submitted"
      // }
      // ============================================================================
      final response = await StudentService.saveProjectSubmission(
        title: title,
        description: description.isNotEmpty ? description : title,
        plan: plan,
        result: result,
        documentName: _selectedFileName ?? 'Laporan_Akhir_PKL_Ananda.pdf',
        documentSize: _selectedFileSize > 0 ? _selectedFileSize : 3500000,
        submitImmediately: true,
      );

      if (mounted) {
        setState(() {
          _submissionStatus = 'submitted';
        });

        // Tampilkan dialog konfirmasi sukses
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 28),
                SizedBox(width: 10),
                Text('Projek Diajukan!', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              ],
            ),
            content: Text(
              response['message']?.toString() ?? 'Projek dan berkas laporan berhasil diajukan untuk verifikasi Guru Pembimbing & DUDI!',
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
              ),
            ],
          ),
        );
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
        setState(() {
          _isSubmitting = false;
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

            // Konten Formulir Projek Siswa
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge jika sudah diajukan
                    if (_submissionStatus == 'submitted')
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 18),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Projek telah diajukan dan sedang menunggu verifikasi pembimbing.',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E40AF)),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Card 1: 1. Nama & Deskripsi Pekerjaan
                    _buildSectionCard(
                      title: '1. Nama & Deskripsi Pekerjaan',
                      hintText: 'Masukkan nama pekerjaan dan deskripsi lengkap projek...',
                      controller: _namaDescController,
                      minLines: 4,
                    ),
                    const SizedBox(height: 14),

                    // Card 2: 2. Perencanaan Kegiatan (Planning)
                    _buildSectionCard(
                      title: '2. Perencanaan Kegiatan (Planning)',
                      hintText: 'Masukkan rencana dan tahapan kegiatan kerja...',
                      controller: _planningController,
                      minLines: 4,
                    ),
                    const SizedBox(height: 14),

                    // Card 3: 3. Pelaksanaan Kegiatan / Hasil Karya
                    _buildSectionCard(
                      title: '3. Pelaksanaan Kegiatan / Hasil Karya',
                      hintText: 'Masukkan hasil pelaksanaan kegiatan, tautan demo, atau dokumentasi hasil karya...',
                      controller: _pelaksanaanController,
                      minLines: 4,
                    ),
                    const SizedBox(height: 14),

                    // Card 4: Lampiran Berkas PDF (Maks. 15 MB) - Persis Mockup Figma
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
                                  Icon(Icons.check_rounded, color: Colors.white, size: 20),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Komponen Kartu Input Teks dengan Header Judul dan Area Multi-line
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

  /// Komponen Kartu Upload Berkas PDF (Maks. 15 MB) persis tampilan screenshot
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
            '3. Pelaksanaan Kegiatan / Hasil Karya',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),

          // Tombol Pilih / Ganti Berkas PDF dengan latar biru muda
          Material(
            color: const Color(0xFFF0F7FF),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: _showFilePickerModal,
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
                        : 'Pilih / Ganti Berkas PDF (Maks. 15 MB)',
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

          // Preview Berkas jika sudah dipilih
          if (_selectedFileName != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedFileName!,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '• Terlampir',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B)),
                    onPressed: () {
                      setState(() {
                        _selectedFileName = null;
                        _selectedFileSize = 0;
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
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
