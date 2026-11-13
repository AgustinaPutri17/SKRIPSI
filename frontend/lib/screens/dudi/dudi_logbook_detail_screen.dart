import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/kd_indicators.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/supervisor_service.dart';
import '../../widgets/smart_pkl_header.dart';
import '../../widgets/status_pill.dart';

/// ==============================================================================
/// 7.3 DETAIL VERIFIKASI LOGBOOK SISWA OLEH DUDI
/// Sesuai Mockup Gambar:
/// - Header: SMART PKL Logbook + Profile Icon
/// - Sub-navigasi: [Logbook (active)] [Projek] [Penilaian]
/// - Card Siswa: Avatar Inisial (MF), Nama Siswa (M. Farel Ardiansyah),
///   Sekolah & Jurusan, Status Pill 'Menunggu' / 'Disetujui' / 'Ditolak',
///   Badge 'Target KD 2', Tanggal 'Kamis, 24 Oktober 2024'
/// - Judul & Uraian Aktivitas Jurnal:
///   "Implementasi Mockup ke Layout UI Responsif"
/// - Bukti Kegiatan & Presensi Fisik (2 Foto Komparasi berdampingan)
/// - Box "Catatan Instruktur" (wajib diisi saat tolak/revisi, opsional saat setujui)
/// - Aksi Button: [✕ Revisi / Tolak] (Putih Outlined/Red) dan [✓ Setujui] (Biru Primer)
/// ==============================================================================
class DudiLogbookDetailScreen extends StatefulWidget {
  final Map<String, dynamic> journal;
  final VoidCallback? onVerified;

  const DudiLogbookDetailScreen({
    super.key,
    required this.journal,
    this.onVerified,
  });

  @override
  State<DudiLogbookDetailScreen> createState() => _DudiLogbookDetailScreenState();
}

class _DudiLogbookDetailScreenState extends State<DudiLogbookDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isApproving = false;
  bool _isRejecting = false;

  late Map<String, dynamic> _currentJournal;

  @override
  void initState() {
    super.initState();
    _currentJournal = Map<String, dynamic>.from(widget.journal);
    if (_currentJournal['verification_comment'] != null) {
      _commentController.text = _currentJournal['verification_comment'].toString();
    }
    _loadFullDetail();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadFullDetail() async {
    final id = _currentJournal['id'];
    final journalId = id is int ? id : int.tryParse(id?.toString() ?? '0') ?? 0;
    if (journalId > 0) {
      final detail = await SupervisorService.getLogbookDetail(journalId);
      if (detail != null && mounted) {
        setState(() {
          _currentJournal = detail;
          if (_currentJournal['verification_comment'] != null) {
            _commentController.text = _currentJournal['verification_comment'].toString();
          }
        });
      }
    }
  }

  Map<String, dynamic> _extractKdAndDescription(String rawActivity, String rawDesc) {
    final parsed = KdIndicators.extractFromActivity(rawActivity, rawDesc);
    return {
      'kdNumber': parsed.kdNumber,
      'kdName': parsed.kdName,
      'description': parsed.description,
    };
  }

  Future<void> _approveLogbook() async {
    final id = _currentJournal['id'];
    if (id == null) return;

    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catatan instruktur wajib diisi sebelum menyetujui logbook (ACC)!'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isApproving = true);

    final res = await SupervisorService.approveLogbook(
      id: id as int,
      comment: comment,
    );

    if (!mounted) return;
    setState(() => _isApproving = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Logbook berhasil disetujui.'),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
      if (widget.onVerified != null) widget.onVerified!();
      Navigator.of(context).maybePop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Gagal menyetujui logbook.'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _showRevisiDialog() async {
    final alasanController = TextEditingController();
    final perbaikanController = TextEditingController();

    if (_commentController.text.trim().isNotEmpty) {
      alasanController.text = _commentController.text.trim();
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: const [
            Icon(Icons.edit_note_rounded, color: Color(0xFFDC2626), size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Minta Revisi Logbook',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tuliskan alasan penolakan dan poin-poin yang harus diperbaiki oleh siswa:',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 16),

              // Field 1: Alasan Revisi
              const Text(
                'Alasan Revisi *',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: alasanController,
                maxLines: 3,
                style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: 'Misal: Foto bukti kegiatan yang dilampirkan buram & deskripsi aktivitas terlalu singkat...',
                  hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Field 2: Hal yang Perlu Diperbaiki
              const Text(
                'Hal yang Perlu Diperbaiki *',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: perbaikanController,
                maxLines: 3,
                style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: 'Misal: Unggah ulang foto layar kerja yang jelas dan lengkapi deskripsi pengerjaan minimal 100 kata...',
                  hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              if (alasanController.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Alasan revisi wajib diisi!')),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Kirim Revisi', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final alasan = alasanController.text.trim();
      final perbaikan = perbaikanController.text.trim().isNotEmpty
          ? perbaikanController.text.trim()
          : 'Silakan perbaiki deskripsi dan lampirkan foto dokumentasi yang sesuai.';
      final fullComment = 'Alasan Revisi: $alasan\nHal yang Perlu Diperbaiki: $perbaikan';
      _commentController.text = fullComment;
      await _executeRejectLogbook(fullComment);
    }
  }

  Future<void> _executeRejectLogbook(String comment) async {
    final id = _currentJournal['id'];
    if (id == null) return;

    setState(() => _isRejecting = true);

    final res = await SupervisorService.rejectLogbook(
      id: id as int,
      comment: comment,
    );

    if (!mounted) return;
    setState(() => _isRejecting = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Logbook ditolak dan dikembalikan untuk revisi siswa.'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      if (widget.onVerified != null) widget.onVerified!();
      Navigator.of(context).maybePop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Gagal menolak logbook.'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract student & journal fields
    final placement = _currentJournal['placement'] as Map<String, dynamic>?;
    final student = (_currentJournal['student'] as Map<String, dynamic>?) ?? (placement?['student'] as Map<String, dynamic>?);

    final studentName = student?['name']?.toString() ?? 'Siswa PKL';
    final studentSchool = student?['class'] != null
        ? '${student?['class']} • ${student?['major'] ?? 'Rekayasa Perangkat Lunak'}'
        : 'SMK • Rekayasa Perangkat Lunak';

    final initials = studentName.isNotEmpty
        ? studentName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'S';

    final date = _currentJournal['logbook_date']?.toString() ??
        _currentJournal['journal_date']?.toString() ??
        'Hari Ini';

    final rawActivity = _currentJournal['activity']?.toString() ?? '';
    final rawDesc = _currentJournal['description']?.toString() ?? '';
    final parsedKd = _extractKdAndDescription(rawActivity, rawDesc);
    final int kdNum = parsedKd['kdNumber'] as int;
    final String kdName = parsedKd['kdName'] as String;
    final String activityDetail = parsedKd['description'] as String;

    final status = _currentJournal['status']?.toString() ?? 'submitted';
    final bool isApproved = status == 'approved';
    final bool isRejected = status == 'rejected';
    final bool isPending = status == 'submitted' || status == 'draft';

    final photoUrl = _currentJournal['photo_url']?.toString();
    final checkInPhoto = _currentJournal['check_in_photo_url']?.toString() ??
        _currentJournal['attendance']?['check_in_photo_url']?.toString() ??
        _currentJournal['attendance']?['photo_in_url']?.toString();

    final checkOutPhoto = _currentJournal['check_out_photo_url']?.toString() ??
        _currentJournal['attendance']?['check_out_photo_url']?.toString();

    final checkInTime = _currentJournal['check_in_time']?.toString() ??
        _currentJournal['attendance']?['check_in_time']?.toString() ??
        '07:30 WIB';
    final checkOutTime = _currentJournal['check_out_time']?.toString() ??
        _currentJournal['attendance']?['check_out_time']?.toString() ??
        '17:00 WIB';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SmartPklHeader(
              title: 'Logbook',
              subtitle: 'Verifikasi Logbook Siswa',
              showBackButton: true,
              onBackTap: () => Navigator.maybePop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Verification Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Student Header Row
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFFEFF6FF),
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    fontSize: 14,
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
                                      studentSchool,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Status Badge
                              if (isApproved)
                                const StatusPill(text: 'Disetujui', style: PillStyle.success)
                              else if (isRejected)
                                const StatusPill(text: 'Ditolak / Revisi', style: PillStyle.error)
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFFFECACA)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFEF4444),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'Menunggu',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFB91C1C),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Target KD & Tanggal
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Target KD $kdNum',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    kdName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E40AF),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Tanggal & Jam Presensi
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF64748B)),
                                  const SizedBox(width: 6),
                                  Text(
                                    date,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF0D9488)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$checkInTime - $checkOutTime',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0D9488),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Logbook Activity Content
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.edit_note_rounded, size: 16, color: Color(0xFF2563EB)),
                                    SizedBox(width: 6),
                                    Text(
                                      'Rincian Aktivitas Kegiatan Siswa',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  activityDetail,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF1E293B),
                                    height: 1.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Bukti Kegiatan & Presensi Fisik
                          const Text(
                            'Bukti Kegiatan & Presensi Fisik',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),

                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                // Photo 1: Foto Bukti Aktivitas / Logbook Siswa
                                _buildDudiPhotoTile(
                                  context: context,
                                  photoUrl: photoUrl,
                                  badgeLabel: 'Logbook Siswa',
                                  titleLabel: 'Foto Kegiatan',
                                  timeLabel: 'Dokumentasi Tugas',
                                  fallbackIcon: Icons.camera_alt_rounded,
                                ),
                                const SizedBox(width: 12),

                                // Photo 2: Foto Presensi Masuk (Selfie Check-in)
                                _buildDudiPhotoTile(
                                  context: context,
                                  photoUrl: checkInPhoto,
                                  badgeLabel: 'Presensi Masuk',
                                  titleLabel: 'Selfie Check-In',
                                  timeLabel: checkInTime,
                                  fallbackIcon: Icons.badge_rounded,
                                ),
                                if (checkOutPhoto != null) ...[
                                  const SizedBox(width: 12),
                                  _buildDudiPhotoTile(
                                    context: context,
                                    photoUrl: checkOutPhoto,
                                    badgeLabel: 'Presensi Pulang',
                                    titleLabel: 'Selfie Check-Out',
                                    timeLabel: checkOutTime,
                                    fallbackIcon: Icons.exit_to_app_rounded,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Box Catatan Instruktur (Sesuai Mockup)
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Catatan Instruktur',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      isPending ? 'Wajib diisi' : 'riwayat',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isPending ? const Color(0xFFEF4444) : AppColors.textMuted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
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
                                    enabled: isPending,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      border: InputBorder.none,
                                      hintText: 'Beri catatan atau evaluasi untuk siswa (wajib diisi)...',
                                      hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Action Buttons (Revisi vs Setujui)
                                if (isPending)
                                  Row(
                                    children: [
                                      // Tombol Tolak / Revisi
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: (_isApproving || _isRejecting) ? null : _showRevisiDialog,
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: Color(0xFFEF4444)),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          icon: _isRejecting
                                              ? const SizedBox(
                                                  width: 14,
                                                  height: 14,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                )
                                              : const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 16),
                                          label: const Text(
                                            'Revisi',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFFEF4444),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Tombol Setujui
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: (_isApproving || _isRejecting) ? null : _approveLogbook,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF2563EB),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          icon: _isApproving
                                              ? const SizedBox(
                                                  width: 14,
                                                  height: 14,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                                  ),
                                                )
                                              : const Icon(Icons.check_rounded, color: Colors.white, size: 16),
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
                                  )
                                else
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isApproved ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        isApproved ? '✓ Logbook telah disetujui (ACC)' : '✕ Logbook telah ditolak',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isApproved ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
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

  Widget _buildDudiPhotoTile({
    required BuildContext context,
    required String? photoUrl,
    required String badgeLabel,
    required String titleLabel,
    required String timeLabel,
    required IconData fallbackIcon,
  }) {
    final String fullUrl = AuthService.formatImageUrl(photoUrl);
    final bool hasPhoto = fullUrl.isNotEmpty;

    return SizedBox(
      width: 145,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: hasPhoto
                ? () {
                    showDialog(
                      context: context,
                      builder: (ctx) => Dialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppBar(
                              title: Text(titleLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
                              loadingBuilder: (c, w, p) => p == null
                                  ? w
                                  : const SizedBox(
                                      height: 200,
                                      child: Center(child: CircularProgressIndicator()),
                                    ),
                              errorBuilder: (_, _, _) => const Padding(
                                padding: EdgeInsets.all(32),
                                child: Text('Gagal memuat gambar dari server.'),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                'Waktu: $timeLabel',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 115,
                width: 145,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasPhoto)
                      Image.network(
                        fullUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (c, w, p) => p == null
                            ? w
                            : const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                        errorBuilder: (_, _, _) => Center(
                          child: Icon(fallbackIcon, size: 36, color: Colors.blueGrey.shade400),
                        ),
                      )
                    else
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(fallbackIcon, size: 30, color: const Color(0xFF94A3B8)),
                            const SizedBox(height: 4),
                            const Text(
                              'Belum ada foto',
                              style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badgeLabel,
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
                    if (hasPhoto)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 14),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            titleLabel,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            timeLabel,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

