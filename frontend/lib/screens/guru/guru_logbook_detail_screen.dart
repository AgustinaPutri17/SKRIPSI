import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/kd_indicators.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/teacher_service.dart';

class GuruLogbookDetailScreen extends StatefulWidget {
  final Map<String, dynamic> logbook;
  final Map<String, dynamic>? student;

  const GuruLogbookDetailScreen({
    super.key,
    required this.logbook,
    this.student,
  });

  @override
  State<GuruLogbookDetailScreen> createState() => _GuruLogbookDetailScreenState();
}

class _GuruLogbookDetailScreenState extends State<GuruLogbookDetailScreen> {
  final TextEditingController _catatanController = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    final teacherNote = widget.logbook['teacher_note']?.toString();
    if (teacherNote != null && teacherNote.isNotEmpty) {
      _catatanController.text = teacherNote;
    }
  }

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _kirimCatatan() async {
    final note = _catatanController.text.trim();
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tuliskan komentar atau masukan bimbingan terlebih dahulu.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final journalId = widget.logbook['id'] is int
        ? widget.logbook['id'] as int
        : int.tryParse(widget.logbook['id']?.toString() ?? '0') ?? 0;

    setState(() {
      _isSending = true;
    });

    final res = await TeacherService.addComment(
      id: journalId,
      comment: note,
    );

    if (!mounted) return;
    setState(() {
      _isSending = false;
    });

    if (res['success'] == true) {
      widget.logbook['teacher_note'] = note;
      widget.logbook['has_teacher_note'] = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Catatan bimbingan berhasil disimpan dan dikirim ke siswa!'),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Gagal menyimpan catatan bimbingan.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  static Map<String, dynamic>? _safeMap(dynamic value) {
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return null;
  }

  static String _formatDateSafe(dynamic val, String fallback) {
    if (val == null) return fallback;
    final str = val.toString().trim();
    if (str.isEmpty || str == 'null') return fallback;
    if (str.length >= 10) return str.substring(0, 10);
    return str;
  }

  static String _formatServerTime(dynamic timeVal, String fallback) {
    if (timeVal == null) return fallback;
    final str = timeVal.toString().trim();
    if (str.isEmpty || str == 'null') return fallback;
    try {
      // Jika format ISO DateTime (misal "2026-10-23T07:15:00.000000Z" atau "2026-10-23 07:15:00")
      if (str.contains('T') || str.contains(' ')) {
        final dt = DateTime.parse(str).toLocal();
        final hour = dt.hour.toString().padLeft(2, '0');
        final min = dt.minute.toString().padLeft(2, '0');
        return '$hour:$min WIB';
      }
      // Jika format "HH:mm" atau "HH:mm:ss"
      if (str.contains(':')) {
        final parts = str.split(':');
        if (parts.length >= 2) {
          return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')} WIB';
        }
      }
    } catch (_) {}
    return str.endsWith('WIB') ? str : '$str WIB';
  }

  @override
  Widget build(BuildContext context) {
    // Parsing data siswa & logbook dengan proteksi tipe aman
    final logbook = _safeMap(widget.logbook) ?? {};
    final placement = _safeMap(logbook['placement']);
    final studentData = _safeMap(widget.student) ?? 
        _safeMap(placement?['student']) ?? 
        _safeMap(logbook['student']);
    final user = _safeMap(studentData?['user']);

    final studentName = user?['name']?.toString() ?? 
        studentData?['name']?.toString() ?? 
        logbook['student_name']?.toString() ?? 
        'Siswa Bimbingan';
    final nisn = studentData?['nisn']?.toString() ?? studentData?['nis']?.toString() ?? '-';
    final school = studentData?['school_name']?.toString() ?? studentData?['school']?.toString() ?? 'SMK';
    final major = studentData?['class']?.toString() ?? studentData?['major']?.toString() ?? 'Siswa PKL';

    final location = _safeMap(placement?['location']) ?? _safeMap(logbook['location']);
    final companyName = location?['name']?.toString() ?? 'DUDI Mitra';
    final verifier = _safeMap(logbook['verifier']);
    final instrukturName = verifier?['name']?.toString() ?? 
        logbook['instruktur_name']?.toString() ?? 
        _safeMap(placement?['fieldSupervisor'])?['name']?.toString() ?? 
        'Instruktur Lapangan';

    final logbookDate = logbook['logbook_date']?.toString() ?? 
        logbook['journal_date']?.toString() ?? 
        'Hari Ini';
    
    // Waktu check-in dan check-out dinamis sesuai data presensi server
    final attendance = _safeMap(logbook['attendance']);
    final rawCheckIn = logbook['check_in_time'] ?? attendance?['check_in_at'] ?? logbook['check_in_at'] ?? logbook['start_time'];
    final rawCheckOut = logbook['check_out_time'] ?? attendance?['check_out_at'] ?? logbook['check_out_at'] ?? logbook['end_time'];

    final checkInAt = _formatServerTime(rawCheckIn, '07:30 WIB');
    final checkOutAt = _formatServerTime(rawCheckOut, '16:00 WIB');

    // FOTO KEGIATAN / DOKUMENTASI AKTIVITAS ASLI SISWA (Terpisah dari presensi)
    final String? activityPhoto = logbook['photo_url']?.toString();

    // FOTO CHECK-IN / SELFIE ASLI SISWA
    final String? checkInPhoto = logbook['check_in_photo_url']?.toString() ??
        attendance?['check_in_photo_url']?.toString();

    // FOTO CHECK-OUT / PRESENSI PULANG ASLI SISWA
    final String? checkOutPhoto = logbook['check_out_photo_url']?.toString() ??
        attendance?['check_out_photo_url']?.toString();

    final activityTitle = logbook['activity']?.toString() ?? 'Aktivitas PKL';
    final parsedKd = KdIndicators.extractFromActivity(
      activityTitle,
      logbook['description']?.toString() ?? '',
    );
    final activityDescription = logbook['description']?.toString() ??
        logbook['activity']?.toString() ??
        logbook['activities']?.toString() ??
        parsedKd.description;
    final activityResult = logbook['result']?.toString();
    final activityObstacles = logbook['obstacles']?.toString();

    final dudiFeedback = logbook['verification_comment']?.toString() ??
        logbook['dudi_feedback']?.toString() ??
        logbook['verification_note']?.toString() ??
        (logbook['status'] == 'approved' ? 'Pekerjaan rapi sesuai standar industri.' : 'Menunggu review instruktur DUDI.');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Logbook Siswa',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card 1: Identitas Siswa & Penempatan DUDI ──────────────────────
            Container(
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E7FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            studentName.isNotEmpty
                                ? studentName.split(' ').take(2).map((e) => e.isNotEmpty ? e[0] : '').join('')
                                : 'FA',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF3730A3),
                            ),
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
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'NISN: $nisn • $school',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          major,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Info DUDI Subcard
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.business_rounded, size: 16, color: Color(0xFF2563EB)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                companyName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 24),
                          child: Text(
                            'Instruktur: $instrukturName',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Text(
                              logbookDate,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEDE9FE),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'KD ${parsedKd.kdNumber} • ${KdIndicators.titleFor(parsedKd.kdNumber)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF6D28D9),
                                    ),
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
              ),
            ),
            const SizedBox(height: 16),

            // ── Card 2: Aktivitas & Log Waktu ─────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.access_time_rounded, size: 18, color: Color(0xFF2563EB)),
                      SizedBox(width: 8),
                      Text(
                        'Aktivitas & Log Waktu',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Jam Masuk & Jam Pulang Box
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Jam Masuk',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                checkInAt,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1D4ED8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Jam Pulang',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                checkOutAt,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1D4ED8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Dokumentasi Foto Kegiatan (Aktivitas Logbook)
                  if (activityPhoto != null && activityPhoto.isNotEmpty) ...[
                    const Text(
                      'Dokumentasi Foto Kegiatan (Aktivitas)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildPhotoTile(
                      context: context,
                      photoUrl: activityPhoto,
                      timeLabel: 'Foto Kegiatan',
                      titleLabel: 'Dokumentasi Tugas / Pekerjaan Siswa',
                      fallbackIcon: Icons.camera_alt_rounded,
                      height: 180,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Bukti Foto Presensi Harian (Terpisah dari Foto Kegiatan)
                  const Text(
                    'Bukti Foto Presensi Harian',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPhotoTile(
                          context: context,
                          photoUrl: checkInPhoto,
                          timeLabel: checkInAt,
                          titleLabel: 'Presensi Masuk (Selfie)',
                          fallbackIcon: Icons.face_rounded,
                          height: 120,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildPhotoTile(
                          context: context,
                          photoUrl: checkOutPhoto,
                          timeLabel: checkOutAt,
                          titleLabel: 'Presensi Pulang',
                          fallbackIcon: Icons.exit_to_app_rounded,
                          height: 120,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Uraian Pekerjaan Siswa
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'URAIAN PEKERJAAN SISWA',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (activityTitle.isNotEmpty) ...[
                          Text(
                            activityTitle,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          activityDescription,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        if (activityResult != null && activityResult.trim().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                          const SizedBox(height: 8),
                          const Text(
                            'HASIL YANG DICAPAI:',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF16A34A),
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            activityResult,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                        if (activityObstacles != null && activityObstacles.trim().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                          const SizedBox(height: 8),
                          const Text(
                            'KENDALA / TANTANGAN:',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFD97706),
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            activityObstacles,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Card 3: Validasi Industri (DUDI) ───────────────────────────────
            Builder(
              builder: (context) {
                final status = (logbook['status'] ?? '').toString().toLowerCase();
                final isApproved = status == 'approved';
                final isRejected = status == 'rejected';

                final titleIcon = isRejected
                    ? const Icon(Icons.cancel_rounded, size: 18, color: Color(0xFFDC2626))
                    : (isApproved
                        ? const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF16A34A))
                        : const Icon(Icons.hourglass_top_rounded, size: 18, color: Color(0xFFD97706)));

                final bannerBg = isRejected
                    ? const Color(0xFFFEF2F2)
                    : (isApproved ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB));
                final bannerBorder = isRejected
                    ? const Color(0xFFFECACA)
                    : (isApproved ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A));
                final bannerIcon = isRejected
                    ? const Icon(Icons.error_outline_rounded, size: 20, color: Color(0xFFDC2626))
                    : (isApproved
                        ? const Icon(Icons.verified_rounded, size: 20, color: Color(0xFF16A34A))
                        : const Icon(Icons.schedule_rounded, size: 20, color: Color(0xFFD97706)));
                final bannerTitle = isRejected
                    ? 'Perlu Revisi / Ditolak oleh DUDI'
                    : (isApproved ? 'Disetujui oleh Instruktur DUDI' : 'Menunggu Review Instruktur DUDI');
                final bannerTitleColor = isRejected
                    ? const Color(0xFF991B1B)
                    : (isApproved ? const Color(0xFF166534) : const Color(0xFF92400E));
                final bannerSubColor = isRejected
                    ? const Color(0xFFB91C1C)
                    : (isApproved ? const Color(0xFF15803D) : const Color(0xFFB45309));

                final feedbackTitle = isRejected ? 'Catatan & Alasan Revisi DUDI:' : 'Umpan Balik Instruktur Lapangan:';
                final feedbackBg = isRejected ? const Color(0xFFFFF1F2) : const Color(0xFFF8FAFC);
                final feedbackColor = isRejected ? const Color(0xFF991B1B) : const Color(0xFF334155);

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isRejected
                          ? const Color(0xFFFECACA)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          titleIcon,
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Validasi Industri (DUDI)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDateSafe(logbook['verified_at'], logbookDate),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Status Banner (Disetujui / Ditolak / Menunggu)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: bannerBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: bannerBorder),
                        ),
                        child: Row(
                          children: [
                            bannerIcon,
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bannerTitle,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: bannerTitleColor,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    instrukturName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: bannerSubColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Umpan Balik DUDI / Catatan Revisi
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: feedbackBg,
                          borderRadius: BorderRadius.circular(12),
                          border: isRejected ? Border.all(color: const Color(0xFFFECACA)) : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              feedbackTitle,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isRejected ? const Color(0xFFB91C1C) : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '“$dudiFeedback”',
                              style: TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                                color: feedbackColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // ── Card 4: Catatan & Bimbingan Guru SMK ───────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.school_rounded, size: 18, color: Color(0xFF2563EB)),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Catatan Guru Pembimbing',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (widget.logbook['teacher_note'] != null && widget.logbook['teacher_note'].toString().trim().isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBFDBFE), width: 0.8),
                          ),
                          child: const Text(
                            'Sudah Diulas',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tulis Umpan Balik Tambahan',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _catatanController,
                      maxLines: 4,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
                      decoration: const InputDecoration(
                        hintText: 'Tulis komentar atau arahan bimbingan untuk siswa...',
                        hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _isSending ? null : _kirimCatatan,
                      icon: _isSending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                      label: Text(
                        _isSending
                            ? 'Menyimpan...'
                            : (widget.logbook['teacher_note'] != null && widget.logbook['teacher_note'].toString().trim().isNotEmpty
                                ? 'Perbarui Catatan Guru'
                                : 'Kirim Catatan Guru'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoTile({
    required BuildContext context,
    required String? photoUrl,
    required String timeLabel,
    required String titleLabel,
    required IconData fallbackIcon,
    double height = 120,
  }) {
    final String fullUrl = AuthService.formatImageUrl(photoUrl);
    final bool hasPhoto = fullUrl.isNotEmpty;

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titleLabel,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
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
              child: Stack(
                children: [
                  Container(
                    height: height,
                    width: double.infinity,
                    color: const Color(0xFFF1F5F9),
                    child: hasPhoto
                        ? Image.network(
                            fullUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (c, w, p) => p == null
                                ? w
                                : const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                            errorBuilder: (_, _, _) => Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(fallbackIcon, color: const Color(0xFF94A3B8), size: 36),
                                  const SizedBox(height: 4),
                                  const Text('Gagal Memuat Foto', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                                ],
                              ),
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(fallbackIcon, color: const Color(0xFF94A3B8), size: 36),
                                const SizedBox(height: 4),
                                const Text('Foto Belum Diunggah', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                              ],
                            ),
                          ),
                  ),
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        timeLabel,
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
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
        ],
      );
  }
}
