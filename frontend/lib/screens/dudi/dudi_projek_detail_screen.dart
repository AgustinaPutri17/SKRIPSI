import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/smart_pkl_header.dart';

/// ==============================================================================
/// VERIFIKASI PROJEK SISWA
/// Sesuai Mockup Gambar Ketiga (Verifikasi Projek Siswa):
/// - Header: SMART PKL Projek + Avatar
/// - Card Siswa: MF (M. Farel Ardiansyah) • SMK Negeri 1 Cimahi • Rekayasa Perangkat Lunak
/// - Tanggal (24 Oktober 2024)
/// - Nama (Nama dan deskripsi projek siswa)
/// - Perencanaan Kegiatan (Dokumen perancangan)
/// - Pelaksanaan Kegiatan / Hasil Karya (Proses kerja dan foto hasil siswa)
/// - Catatan Instruktur (Tulis masukan atau hal yang perlu diperbaiki)
/// - Tombol Aksi [✕ Tolak] dan [✓ Setujui]
/// ==============================================================================
class DudiProjekDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? studentData;

  const DudiProjekDetailScreen({
    super.key,
    this.studentData,
  });

  @override
  State<DudiProjekDetailScreen> createState() => _DudiProjekDetailScreenState();
}

class _DudiProjekDetailScreenState extends State<DudiProjekDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _handleAction(bool isApprove) {
    if (!isApprove && _commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catatan Instruktur wajib diisi saat menolak/meminta revisi projek.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isApprove
                ? 'Projek siswa berhasil disetujui (ACC).'
                : 'Projek siswa ditolak dengan catatan evaluasi.',
          ),
          backgroundColor: isApprove ? const Color(0xFF16A34A) : const Color(0xFFEA580C),
        ),
      );
      Navigator.of(context).maybePop(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final studentName = widget.studentData?['name']?.toString() ?? 'M. Farel Ardiansyah';
    final studentClass = widget.studentData?['class']?.toString() ?? 'SMK Negeri 1 Cimahi';
    final studentMajor = widget.studentData?['major']?.toString() ?? 'Rekayasa Perangkat Lunak';

    final initials = studentName.isNotEmpty
        ? studentName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'MF';

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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sub Header Titling Sesuai Mockup
                    const Text(
                      'Verifikasi Projek Siswa',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Icon(Icons.business_rounded, size: 14, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text(
                          'PT Solusi Teknologi Mandiri',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
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
                                            '$studentClass\n$studentMajor',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  '24 Oktober 2024',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Section 1: Nama Projek
                    _buildSectionCard(
                      'Nama',
                      'Aplikasi Monitoring PKL SMK Berbasis Flutter & Laravel REST API.\nDilengkapi fitur presensi GPS Geofencing radius dan verifikasi jurnal berkala.',
                    ),
                    const SizedBox(height: 12),

                    // Section 2: Perencanaan Kegiatan
                    _buildSectionCard(
                      'Perencanaan Kegiatan',
                      'Dokumen analisis kebutuhan sistem, rancangan ERD database MySQL, wireframe mockup UI, serta timeline pengerjaan sprint 1 hingga sprint 4.',
                    ),
                    const SizedBox(height: 12),

                    // Section 3: Pelaksanaan Kegiatan / Hasil Karya
                    _buildSectionCard(
                      'Pelaksanaan Kegiatan / Hasil Karya',
                      'Selesai mengimplementasikan modul autentikasi JWT multi-role, sinkronisasi geolocation perangkat native, serta endpoint verifikasi logbook DUDI.',
                    ),
                    const SizedBox(height: 12),

                    // Section 4: Catatan Instruktur Box
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
                            'Catatan Instruktur',
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
                                hintText: 'Tulis masukan atau hal yang perlu diperbaiki oleh siswa...',
                                hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Tombol Tolak dan Setujui
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
                                    'Tolak',
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
                                    'Setujui',
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
