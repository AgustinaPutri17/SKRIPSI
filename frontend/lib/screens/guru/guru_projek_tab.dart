import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/smart_pkl_header.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/custom_button.dart';

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
  bool _isGraded = false;
  final TextEditingController _nilaiController = TextEditingController(text: '88');
  final TextEditingController _catatanController = TextEditingController(
    text: 'Implementasi rancangan sangat rapi dan memenuhi standar industri. Siap maju sidang presentasi PKL.',
  );

  @override
  void dispose() {
    _nilaiController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  void _handleSimpanNilai() {
    setState(() {
      _isGraded = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Penilaian dan persetujuan sidang projek Ananda Putri berhasil disimpan!'),
        backgroundColor: Color(0xFF16A34A),
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
              title: 'Sidang Projek',
              subtitle: 'Guru',
              onProfileTap: () => widget.onNavigateTab?.call(4),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder, width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.assignment_turned_in_rounded, color: AppColors.primary, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Verifikasi Laporan Akhir PKL',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '5 Siswa telah mengajukan draft laporan & siap sidang.',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Detail Submission Projek: Ananda Putri (Matching what Ananda submitted)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isGraded ? const Color(0xFF86EFAC) : const Color(0xFFBFDBFE),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Ananda Putri',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'XII RPL 1 • PT Telkom Digital Solutions',
                                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              StatusPill(
                                text: _isGraded ? 'ACC Sidang (88/A)' : 'Menunggu Review',
                                style: _isGraded ? PillStyle.success : PillStyle.warning,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(color: Color(0xFFF1F5F9), height: 1),
                          const SizedBox(height: 14),

                          // Section 1
                          const Text(
                            '1. Nama & Deskripsi Pekerjaan',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Pengembangan Modul E-Commerce & Dashboard Monitoring PKL Berbasis Flutter Cross-Platform untuk integrasi data industri.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Section 2
                          const Text(
                            '2. Perencanaan Kegiatan (Planning)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Sprint 1: Desain Figma, Sprint 2: Slicing UI Siswa & Guru, Sprint 3: Pengujian Validasi Presensi GPS & Upload Dokumen.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // File Lampiran PDF Laporan
                          const Text(
                            '5. Berkas Laporan Pendukung',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFEF4444), size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Laporan_Akhir_PKL_AnandaPutri_XIIRPL1.pdf',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text('4.8 MB • Dokumen Lengkap', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.primary),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Penilaian Form Guru
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Form Evaluasi & Nilai Guru Pembimbing',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Text('Nilai Angka (0-100): ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 70,
                                      height: 36,
                                      child: TextField(
                                        controller: _nilaiController,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        decoration: InputDecoration(
                                          contentPadding: EdgeInsets.zero,
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('Grade A', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                const Text('Catatan Rekomendasi Sidang:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _catatanController,
                                  maxLines: 2,
                                  style: const TextStyle(fontSize: 12),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.all(8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                    fillColor: Colors.white,
                                    filled: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          CustomButton(
                            text: _isGraded ? 'Perbarui Nilai Sidang' : 'Simpan Nilai & Setujui Sidang PKL',
                            icon: Icons.check_circle_outline_rounded,
                            color: const Color(0xFF16A34A),
                            onPressed: _handleSimpanNilai,
                          ),
                        ],
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
}
