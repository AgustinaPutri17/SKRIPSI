import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/teacher_service.dart';
import '../../widgets/smart_pkl_header.dart';
import 'guru_logbook_detail_screen.dart';

class GuruBerandaTab extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const GuruBerandaTab({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<GuruBerandaTab> createState() => _GuruBerandaTabState();
}

class _GuruBerandaTabState extends State<GuruBerandaTab> {
  bool _isLoading = true;

  // Header State
  String _teacherName = 'Guru Pembimbing';
  String _schoolName = 'SMKN 2 Bandar Lampung';

  // Statistics from /api/teacher/dashboard
  int _totalStudents = 24;
  int _attendanceToday = 22;
  int _journalsPending = 8;

  // Real logbooks from backend
  List<Map<String, dynamic>> _recentLogbooks = [];

  @override
  void initState() {
    super.initState();
    _loadAllDashboardData();
  }

  /// Memanggil endpoint backend untuk Modul Guru Pembimbing:
  /// 1. GET /api/teacher/dashboard
  /// 2. GET /api/teacher/attendances
  /// 3. GET /api/teacher/logbooks
  Future<void> _loadAllDashboardData() async {
    setState(() => _isLoading = true);

    try {
      // 0. Profil Guru dari cache login SharedPreferences
      final cachedUser = await AuthService.getUser();
      if (cachedUser != null && cachedUser['name'] != null) {
        if (mounted) {
          setState(() {
            _teacherName = cachedUser['name'].toString();
            final profile = cachedUser['profile'] ?? cachedUser['teacher'];
            if (profile != null && profile['school_name'] != null && profile['school_name'].toString().trim().isNotEmpty) {
              _schoolName = profile['school_name'].toString().trim();
            }
          });
        }
      }

      // 1. Dashboard API
      final dashboardData = await TeacherService.getDashboard();
      if (dashboardData != null && mounted) {
        setState(() {
          _totalStudents = dashboardData['total_students'] ?? _totalStudents;
          _attendanceToday = dashboardData['attendance_today'] ?? _attendanceToday;
          _journalsPending = dashboardData['journals_pending'] ?? _journalsPending;
        });
      }

      // 2. Attendances API
      await TeacherService.getAttendances();

      // 3. Logbooks API (ambil logbook riil dari database)
      final logbooksList = await TeacherService.getLogbooksList();
      if (mounted) {
        setState(() {
          _recentLogbooks = logbooksList;
          if (logbooksList.isNotEmpty) {
            final pending = logbooksList
                .where((j) => (j['status'] ?? '').toString().toLowerCase() == 'submitted')
                .length;
            _journalsPending = pending;
          }
        });
      }
    } catch (_) {
      // Fallback tetap responsif jika offline
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
            // Header SMART PKL Beranda Guru
            SmartPklHeader(
              title: 'Beranda',
              onProfileTap: () => widget.onNavigateTab?.call(3),
            ),

            if (_isLoading)
              const LinearProgressIndicator(
                minHeight: 2,
                color: Color(0xFF2563EB),
                backgroundColor: Color(0xFFEFF6FF),
              ),

            // Konten Beranda Scrollable
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadAllDashboardData,
                color: const Color(0xFF2563EB),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting & Teacher Info (Konsisten dengan DUDI & Siswa)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Halo, $_teacherName 👋',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Guru Pembimbing • $_schoolName',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // 3 Quick Navigation Action Cards (Izin & Sakit, Logbook, Profil)
                      Row(
                        children: [
                          Expanded(
                            child: _buildHeaderActionTile(
                              icon: Icons.medical_services_outlined,
                              label: 'Izin & Sakit',
                              onTap: () => widget.onNavigateTab?.call(1), // Tab Izin & Sakit
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildHeaderActionTile(
                              icon: Icons.fact_check_outlined,
                              label: 'Logbook ($_journalsPending)',
                              onTap: () => widget.onNavigateTab?.call(2), // Tab Logbook
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildHeaderActionTile(
                              icon: Icons.person_outline_rounded,
                              label: 'Profil',
                              onTap: () => widget.onNavigateTab?.call(3), // Tab Profil
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Section Title: "Daftar Presensi & Aktivitas" + "Sinkron otomatis"
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Daftar Presensi & Aktivitas',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          InkWell(
                            onTap: () => widget.onNavigateTab?.call(2),
                            child: Row(
                              children: const [
                                Text(
                                  'Lihat Semua',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                                SizedBox(width: 2),
                                Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF2563EB)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // DYNAMIC LOGBOOK FEED
                      if (_recentLogbooks.isNotEmpty) ...[
                        ..._recentLogbooks.map((logbook) {
                          final student = logbook['student'] ?? logbook['placement']?['student'];
                          final studentName = student?['name']?.toString() ?? 'Siswa';
                          final studentClass = student?['class']?.toString() ?? 'XII';

                          final location = logbook['location'] ?? logbook['placement']?['location'];
                          final dudiName = location?['name']?.toString() ?? 'DUDI Mitra';

                          final tanggal = logbook['logbook_date']?.toString() ??
                              logbook['journal_date']?.toString() ??
                              'Hari Ini';

                          final judul = logbook['activity']?.toString() ?? 'Aktivitas PKL';
                          final uraian = logbook['description']?.toString() ?? '-';

                          final status = (logbook['status'] ?? '').toString().toLowerCase();
                          final isApproved = status == 'approved';
                          final isRejected = status == 'rejected';

                          final verifier = logbook['verifier'];
                          final verifierName = verifier?['name']?.toString() ?? 'Pembimbing';
                          final verificationNotes = logbook['verification_comment']?.toString() ??
                              logbook['verification_note']?.toString() ??
                              (isRejected ? '“Perlu revisi pada data logbook.”' : (isApproved ? '“Pekerjaan rapi sesuai standar industri.”' : '“Menunggu verifikasi.”'));

                          final initial = studentName.isNotEmpty
                              ? studentName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
                              : 'S';

                          final avatarUrl = student?['avatar']?.toString() ??
                              student?['avatar_url']?.toString() ??
                              student?['photo']?.toString() ??
                              student?['user']?['avatar_url']?.toString() ??
                              '';

                          final checkIn = logbook['check_in_time']?.toString() ??
                              logbook['start_time']?.toString() ??
                              '07:30 WIB';
                          final checkOut = logbook['check_out_time']?.toString() ??
                              logbook['end_time']?.toString() ??
                              '16:00 WIB';

                          final fotoMasuk = logbook['check_in_photo_url']?.toString() ??
                              logbook['attendance']?['check_in_photo_url']?.toString();
                          final fotoKeluar = logbook['check_out_photo_url']?.toString() ??
                              logbook['attendance']?['check_out_photo_url']?.toString();
                          final fotoAktivitas = logbook['photo_url']?.toString();

                          final teacherComment = logbook['teacher_note']?.toString();
                          final hasTeacherComment = (teacherComment != null && teacherComment.trim().isNotEmpty) ||
                              (logbook['has_teacher_note'] == true);
                          final teacherAuthor = logbook['teacher_name']?.toString() ?? _teacherName;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _buildMonitoringCard(
                              context: context,
                              name: studentName,
                              initial: initial,
                              dudi: '$dudiName • $studentClass',
                              avatarUrl: avatarUrl,
                              checkIn: checkIn,
                              checkOut: checkOut,
                              fotoMasuk: fotoMasuk,
                              fotoKeluar: fotoKeluar,
                              fotoAktivitas: fotoAktivitas,
                              logbookTitle: 'LOGBOOK • $tanggal',
                              logbookDesc: '$judul\n$uraian',
                              statusDudi: isRejected ? 'Perlu Revisi (DUDI)' : (isApproved ? 'Disetujui (ACC)' : 'Menunggu Review'),
                              isApproved: isApproved,
                              isRejected: isRejected,
                              instrukturName: verifierName,
                              dudiNotes: '“$verificationNotes”',
                              teacherNotes: teacherComment,
                              hasTeacherNotes: hasTeacherComment,
                              teacherName: teacherAuthor,
                              showUlasanButton: true,
                              onUlasanTap: () => _showBeriCatatanModal(context, logbook, student),
                              onCardTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GuruLogbookDetailScreen(
                                      logbook: logbook,
                                      student: student,
                                    ),
                                  ),
                                );
                                _loadAllDashboardData();
                              },
                            ),
                          );
                        }),
                      ] else ...[
                        // Empty state jika belum ada data logbook
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: const [
                              Icon(Icons.assignment_outlined, size: 38, color: Color(0xFF94A3B8)),
                              SizedBox(height: 10),
                              Text(
                                'Belum Ada Presensi & Aktivitas Siswa',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Daftar presensi dan catatan aktivitas siswa bimbingan Anda akan tampil di sini.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      const SizedBox(height: 20),
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
    final studentName = student?['name']?.toString() ?? logbook['student_name']?.toString() ?? 'Siswa';
    final logbookDate = logbook['logbook_date']?.toString() ?? logbook['journal_date']?.toString() ?? 'Hari Ini';
    final activity = logbook['activity']?.toString() ?? logbook['description']?.toString() ?? 'Aktivitas Logbook';
    final initialNote = logbook['teacher_note']?.toString() ?? '';

    final TextEditingController textController = TextEditingController(text: initialNote);
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
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
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.rate_review_rounded, color: Color(0xFF2563EB), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Beri Catatan Bimbingan',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$studentName • $logbookDate',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.assignment_outlined, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          activity,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Catatan / Arahan Bimbingan Guru:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: TextField(
                    controller: textController,
                    maxLines: 4,
                    autofocus: true,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                    decoration: const InputDecoration(
                      hintText: 'Tuliskan catatan, evaluasi, atau masukan bimbingan untuk siswa...',
                      hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(12),
                    ),
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
                                  backgroundColor: Color(0xFFEF4444),
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
                                  logbook['teacher_note'] = note;
                                  logbook['has_teacher_note'] = true;
                                });
                              }
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(res['message'] ?? 'Catatan berhasil dikirim ke siswa!'),
                                    backgroundColor: const Color(0xFF16A34A),
                                  ),
                                );
                                _loadAllDashboardData();
                              }
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(res['message'] ?? 'Gagal mengirim catatan.'),
                                    backgroundColor: const Color(0xFFEF4444),
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
                      isSubmitting ? 'Mengirim...' : (initialNote.isNotEmpty ? 'Simpan Catatan' : 'Kirim Catatan'),
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
                          builder: (context) => GuruLogbookDetailScreen(
                            logbook: logbook,
                            student: student,
                          ),
                        ),
                      );
                      _loadAllDashboardData();
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

  // Widget Header Action Button persis UI Mockup (Ujian, Rekap, Profil)
  Widget _buildHeaderActionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF334155), size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget Thumbnail Gambar
  Widget _buildThumbnailItem({
    required String? imageUrl,
    required String label,
    required IconData fallbackIcon,
    required Color iconColor,
  }) {
    final bool hasImage = imageUrl != null && imageUrl.isNotEmpty && !imageUrl.contains('unsplash.com');
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: hasImage
                ? Image.network(
                    AuthService.formatImageUrl(imageUrl),
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(fallbackIcon, size: 20, color: iconColor),
                    ),
                  )
                : Center(
                    child: Icon(fallbackIcon, size: 20, color: iconColor),
                  ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 8,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // Widget Kartu Siswa Hadir & Logbook
  Widget _buildMonitoringCard({
    required BuildContext context,
    required String name,
    required String initial,
    required String dudi,
    required String avatarUrl,
    required String checkIn,
    required String checkOut,
    String? fotoMasuk,
    String? fotoKeluar,
    String? fotoAktivitas,
    required String logbookTitle,
    required String logbookDesc,
    required String statusDudi,
    bool isApproved = false,
    bool isRejected = false,
    required String instrukturName,
    required String dudiNotes,
    String? teacherNotes,
    bool hasTeacherNotes = false,
    String teacherName = '',
    required bool showUlasanButton,
    required VoidCallback onUlasanTap,
    VoidCallback? onCardTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Siswa Info
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: (avatarUrl.isNotEmpty && !avatarUrl.contains('unsplash.com'))
                        ? NetworkImage(AuthService.formatImageUrl(avatarUrl))
                        : null,
                    backgroundColor: const Color(0xFFEFF6FF),
                    child: (avatarUrl.isEmpty || avatarUrl.contains('unsplash.com'))
                        ? Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2563EB),
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dudi,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: hasTeacherNotes ? const Color(0xFFEFF6FF) : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: hasTeacherNotes ? const Color(0xFFBFDBFE) : const Color(0xFFFDE68A),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasTeacherNotes ? Icons.check_circle_rounded : Icons.pending_outlined,
                      size: 11,
                      color: hasTeacherNotes ? const Color(0xFF2563EB) : const Color(0xFFD97706),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasTeacherNotes ? 'Sudah Diulas' : 'Belum Diulas',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: hasTeacherNotes ? const Color(0xFF1D4ED8) : const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Jam Masuk & Pulang Badges
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.login_rounded, size: 14, color: Color(0xFF059669)),
                      const SizedBox(width: 4),
                      Text(
                        'Masuk: $checkIn',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout_rounded, size: 14, color: Color(0xFF2563EB)),
                      const SizedBox(width: 4),
                      Text(
                        'Pulang: $checkOut',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Box Logbook Harian + 3 Thumbnails (Masuk, Pulang, Aktivitas)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Thumbnail Presensi Masuk
                _buildThumbnailItem(
                  imageUrl: fotoMasuk,
                  label: 'Masuk',
                  fallbackIcon: Icons.how_to_reg_rounded,
                  iconColor: const Color(0xFF16A34A),
                ),
                const SizedBox(width: 6),

                // 2. Thumbnail Presensi Pulang
                _buildThumbnailItem(
                  imageUrl: fotoKeluar,
                  label: 'Pulang',
                  fallbackIcon: Icons.exit_to_app_rounded,
                  iconColor: const Color(0xFF2563EB),
                ),
                const SizedBox(width: 6),

                // 3. Thumbnail Foto Aktivitas
                _buildThumbnailItem(
                  imageUrl: fotoAktivitas,
                  label: 'Aktivitas',
                  fallbackIcon: Icons.camera_alt_rounded,
                  iconColor: const Color(0xFF9333EA),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        logbookTitle,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        logbookDesc,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Validasi DUDI Subcard
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isRejected
                  ? const Color(0xFFFEF2F2)
                  : (isApproved ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isRejected
                    ? const Color(0xFFFECACA)
                    : (isApproved ? const Color(0xFFDCFCE7) : const Color(0xFFFDE68A)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isRejected
                            ? const Color(0xFFFEE2E2)
                            : (isApproved ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isRejected
                                ? Icons.cancel_rounded
                                : (isApproved ? Icons.check_circle_rounded : Icons.hourglass_top_rounded),
                            size: 12,
                            color: isRejected
                                ? const Color(0xFFDC2626)
                                : (isApproved ? const Color(0xFF16A34A) : const Color(0xFFD97706)),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            statusDudi,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: isRejected
                                  ? const Color(0xFF991B1B)
                                  : (isApproved ? const Color(0xFF166534) : const Color(0xFF92400E)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Instruktur: $instrukturName',
                      style: TextStyle(
                        fontSize: 9,
                        color: isRejected
                            ? const Color(0xFFDC2626)
                            : (isApproved ? const Color(0xFF15803D) : const Color(0xFFB45309)),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  dudiNotes,
                  style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: isRejected
                        ? const Color(0xFF991B1B)
                        : (isApproved ? const Color(0xFF166534) : const Color(0xFF78350F)),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Catatan Guru Pembimbing Subcard (Biru)
          if (teacherNotes != null && teacherNotes.isNotEmpty) ...[
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
                      const Icon(Icons.school_rounded, size: 12, color: Color(0xFF2563EB)),
                      const SizedBox(width: 4),
                      Text(
                        teacherName.isNotEmpty ? 'Catatan Guru Pembimbing ($teacherName):' : 'Catatan Guru Pembimbing:',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '“$teacherNotes”',
                    style: const TextStyle(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF1E3A8A),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Tombol Beri Catatan / Ubah Catatan Guru (Biru)
          if (showUlasanButton)
            SizedBox(
              height: 36,
              child: ElevatedButton.icon(
                onPressed: onUlasanTap,
                icon: Icon(
                  hasTeacherNotes ? Icons.edit_note_rounded : Icons.rate_review_rounded,
                  size: 14,
                  color: Colors.white,
                ),
                label: Text(
                  hasTeacherNotes ? 'Ubah Catatan Guru' : 'Beri Catatan',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasTeacherNotes ? const Color(0xFF1D4ED8) : const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

}
