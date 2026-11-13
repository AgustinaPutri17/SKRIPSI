import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/teacher_service.dart';
import '../../widgets/smart_pkl_header.dart';
import '../../widgets/status_pill.dart';

/// ==============================================================================
/// TAB IZIN & SAKIT GURU PEMBIMBING (SMART PKL)
///
/// Halaman khusus untuk memantau, memverifikasi, menyetujui atau menolak
/// pengajuan Izin dan Sakit seluruh siswa bimbingan PKL.
/// ==============================================================================
class GuruRekapTab extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const GuruRekapTab({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<GuruRekapTab> createState() => _GuruRekapTabState();
}

class _GuruRekapTabState extends State<GuruRekapTab> {
  bool _isLoading = true;
  String _filterStatus = 'all'; // 'all', 'pending', 'approved', 'rejected'
  List<Map<String, dynamic>> _leaveRequests = [];

  @override
  void initState() {
    super.initState();
    _loadLeaveData();
  }

  Future<void> _loadLeaveData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final list = await TeacherService.getLeaveRequests();
      if (mounted) {
        setState(() {
          _leaveRequests = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredLeaves {
    if (_filterStatus == 'pending') {
      return _leaveRequests.where((l) {
        final st = (l['status'] ?? '').toString().toLowerCase();
        final isApproved = l['is_approved'] == true || st == 'approved';
        final isRejected = l['is_rejected'] == true || st == 'rejected';
        return !isApproved && !isRejected;
      }).toList();
    } else if (_filterStatus == 'approved') {
      return _leaveRequests.where((l) {
        final st = (l['status'] ?? '').toString().toLowerCase();
        return l['is_approved'] == true || st == 'approved';
      }).toList();
    } else if (_filterStatus == 'rejected') {
      return _leaveRequests.where((l) {
        final st = (l['status'] ?? '').toString().toLowerCase();
        return l['is_rejected'] == true || st == 'rejected';
      }).toList();
    }
    return _leaveRequests;
  }

  int get _pendingCount => _leaveRequests.where((l) {
        final st = (l['status'] ?? '').toString().toLowerCase();
        final isApproved = l['is_approved'] == true || st == 'approved';
        final isRejected = l['is_rejected'] == true || st == 'rejected';
        return !isApproved && !isRejected;
      }).length;

  int get _approvedCount => _leaveRequests.where((l) {
        final st = (l['status'] ?? '').toString().toLowerCase();
        return l['is_approved'] == true || st == 'approved';
      }).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header SMART PKL (Konsisten font 18pt bold)
            SmartPklHeader(
              title: 'Izin & Sakit',
              onProfileTap: () => widget.onNavigateTab?.call(3),
            ),

            if (_isLoading)
              const LinearProgressIndicator(
                minHeight: 2,
                color: Color(0xFF2563EB),
                backgroundColor: Color(0xFFEFF6FF),
              ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadLeaveData,
                color: const Color(0xFF2563EB),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul Section
                      const Text(
                        'Daftar Pengajuan Izin & Sakit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Ringkasan Statistik
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _filterStatus = 'all'),
                                borderRadius: BorderRadius.circular(10),
                                child: _buildStatItem(
                                  'Total Pengajuan',
                                  '${_leaveRequests.length}',
                                  const Color(0xFF0F172A),
                                  isActive: _filterStatus == 'all',
                                ),
                              ),
                            ),
                            Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _filterStatus = 'pending'),
                                borderRadius: BorderRadius.circular(10),
                                child: _buildStatItem(
                                  'Menunggu ACC',
                                  '$_pendingCount',
                                  const Color(0xFFD97706),
                                  isActive: _filterStatus == 'pending',
                                ),
                              ),
                            ),
                            Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _filterStatus = 'approved'),
                                borderRadius: BorderRadius.circular(10),
                                child: _buildStatItem(
                                  'Disetujui',
                                  '$_approvedCount',
                                  const Color(0xFF16A34A),
                                  isActive: _filterStatus == 'approved',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // List Pengajuan Izin / Sakit
                      if (_isLoading && _leaveRequests.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                          ),
                        )
                      else if (_filteredLeaves.isEmpty)
                        _buildEmptyIzinState()
                      else
                        ..._filteredLeaves.map((leave) => _buildLeaveCard(leave)),

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

  Widget _buildStatItem(String label, String value, Color color, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.06) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              color: isActive ? color : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyIzinState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.health_and_safety_outlined,
              size: 44,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum Ada Pengajuan Izin / Sakit',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            _filterStatus == 'pending'
                ? 'Tidak ada permohonan izin/sakit yang menunggu konfirmasi saat ini.'
                : _filterStatus == 'approved'
                    ? 'Belum ada pengajuan izin/sakit yang disetujui.'
                    : _filterStatus == 'rejected'
                        ? 'Belum ada pengajuan izin/sakit yang ditolak.'
                        : 'Seluruh siswa bimbingan hadir aktif di lokasi PKL dan belum ada permohonan izin atau sakit yang diajukan.',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _loadLeaveData,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Muat Ulang'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveCard(Map<String, dynamic> leave) {
    final student = leave['student'] ?? leave['placement']?['student'];
    final studentName = student?['name']?.toString() ?? 'Siswa';
    final studentClass = student?['class']?.toString() ?? 'XII RPL';

    final location = leave['location'] ?? leave['placement']?['location'];
    final dudiName = location?['name']?.toString() ?? 'DUDI Mitra';

    final jenisIzin = leave['type_label']?.toString() ?? (leave['type'] == 'sick' ? 'Sakit / Medis' : 'Izin Keperluan');
    final rentang = leave['date_range_label']?.toString() ??
        '${leave['start_date'] ?? '-'} s/d ${leave['end_date'] ?? '-'}';
    final alasan = leave['reason']?.toString() ?? '-';
    final namaFile = leave['attachment_name']?.toString() ?? 'Berkas Surat Keterangan';
    final isApproved = leave['is_approved'] == true || leave['status'] == 'approved';
    final isRejected = leave['is_rejected'] == true || leave['status'] == 'rejected';

    final int leaveId = leave['id'] is int
        ? leave['id']
        : int.tryParse(leave['id']?.toString() ?? '0') ?? 0;

    final attachmentUrl = leave['attachment_url']?.toString();
    final reviewerNote = leave['reviewer_note']?.toString();

    final initials = studentName.isNotEmpty
        ? studentName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'S';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isApproved
              ? const Color(0xFF86EFAC)
              : isRejected
                  ? const Color(0xFFFCA5A5)
                  : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
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
          // 1. Header Kartu: Avatar, Nama Siswa, Kelas & Badge Jenis Izin
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFEFF6FF),
                child: Text(
                  initials,
                  style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2563EB), fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$studentClass • $dudiName',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(
                text: jenisIzin,
                style: jenisIzin.toLowerCase().contains('sakit') ? PillStyle.error : PillStyle.warning,
                icon: Icons.medical_services_rounded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // 2. Rentang Tanggal Izin
          Row(
            children: [
              const Icon(Icons.calendar_month_outlined, size: 16, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rentang,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 3. Alasan
          Text(
            'Alasan: $alasan',
            style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.35),
          ),
          const SizedBox(height: 12),

          // 4. Lampiran Box (Surat Keterangan Dokter/Orang Tua)
          GestureDetector(
            onTap: () {
              if (attachmentUrl != null && attachmentUrl.isNotEmpty) {
                final fullUrl = AuthService.formatImageUrl(attachmentUrl);
                showDialog(
                  context: context,
                  builder: (ctx) => Dialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppBar(
                          title: const Text('Berkas Surat Keterangan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
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
                          errorBuilder: (context, error, stackTrace) => const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('Format berkas dokumen lampiran.'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tidak ada berkas lampiran yang diunggah.')),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_file_rounded, color: Color(0xFF2563EB), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      namaFile,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Text(
                    'Lihat Berkas',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                  ),
                ],
              ),
            ),
          ),

          // 5. Catatan Reviewer (Jika sudah diverifikasi)
          if (reviewerNote != null && reviewerNote.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isApproved ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isApproved ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
                ),
              ),
              child: Text(
                'Catatan: “$reviewerNote”',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: isApproved ? const Color(0xFF166534) : const Color(0xFFDC2626),
                ),
              ),
            ),
          ],

          const SizedBox(height: 14),

          // 6. Action Buttons atau Banner Status
          if (isApproved)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Pengajuan Izin / Sakit Telah Disetujui',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                  ),
                ],
              ),
            )
          else if (isRejected)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cancel_rounded, color: Color(0xFFDC2626), size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Pengajuan Izin / Sakit Telah Ditolak',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFB91C1C)),
                  ),
                ],
              ),
            )
          else
            // Tombol Aksi Verifikasi: [Tolak] [Setujui]
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleRejectIzin(leaveId, studentName),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Tolak', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleApproveIzin(leaveId, studentName),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Setujui', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _handleApproveIzin(int id, String studentName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Setujui Izin / Sakit', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Text('Apakah Anda yakin ingin menyetujui pengajuan izin/sakit siswa $studentName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Ya, Setujui'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final res = await TeacherService.verifyLeaveRequest(
      id: id,
      status: 'approved',
      note: 'Disetujui oleh Guru Pembimbing',
    );

    if (!mounted) return;
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pengajuan izin/sakit $studentName disetujui.'), backgroundColor: const Color(0xFF16A34A)),
      );
      _loadLeaveData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Gagal memproses.'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _handleRejectIzin(int id, String studentName) async {
    final noteController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tolak Pengajuan Izin', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tuliskan alasan penolakan izin siswa $studentName:'),
            const SizedBox(height: 10),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                hintText: 'Contoh: Berkas surat keterangan tidak jelas...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Tolak Izin'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final res = await TeacherService.verifyLeaveRequest(
      id: id,
      status: 'rejected',
      note: noteController.text.trim().isNotEmpty ? noteController.text.trim() : 'Ditolak oleh Guru Pembimbing',
    );

    if (!mounted) return;
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pengajuan izin $studentName telah ditolak.'), backgroundColor: const Color(0xFFDC2626)),
      );
      _loadLeaveData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Gagal memproses.'), backgroundColor: AppColors.error),
      );
    }
  }
}
