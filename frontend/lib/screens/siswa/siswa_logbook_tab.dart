import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/student_service.dart';
import '../../widgets/smart_pkl_header.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/custom_button.dart';

class SiswaLogbookTab extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const SiswaLogbookTab({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<SiswaLogbookTab> createState() => _SiswaLogbookTabState();
}

class _SiswaLogbookTabState extends State<SiswaLogbookTab> {
  int _selectedFilterIndex = 0; // 0: Semua, 1: Disetujui, 2: Menunggu, 3: Revisi, 4: Draft
  bool _isCreatingJournal = false;
  bool _isLoading = true;
  bool _isSubmitting = false;

  Map<String, dynamic>? _selectedDetailJournal;
  Map<String, dynamic>? _selectedRevisionJournal;
  int? _editingJournalId;
  String? _existingPhotoUrl;

  final ImagePicker _picker = ImagePicker();
  XFile? _activityPhoto;

  int _selectedKD = 1;
  final TextEditingController _deskripsiController = TextEditingController();

  List<dynamic> _allJournals = [];

  static Map<String, String> _parseRevisionNotes(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return {
        'alasan': 'Foto bukti kegiatan yang dilampirkan buram atau deskripsi pengerjaan masih terlalu singkat.',
        'perbaikan': 'Harap perbaiki dan lengkapi rincian aktivitas serta unggah ulang foto dokumentasi yang jelas.',
      };
    }
    final text = raw.trim();
    if (text.contains('Alasan Revisi:') && text.contains('Hal yang Perlu Diperbaiki:')) {
      final parts = text.split('Hal yang Perlu Diperbaiki:');
      final alasanPart = parts[0].replaceAll('Alasan Revisi:', '').trim();
      final perbaikanPart = parts.length > 1 ? parts[1].trim() : '';
      return {
        'alasan': alasanPart.isNotEmpty ? alasanPart : text,
        'perbaikan': perbaikanPart.isNotEmpty ? perbaikanPart : 'Silakan sesuaikan isi logbook sesuai arahan pembimbing.',
      };
    } else if (text.contains('[Alasan Revisi]') && text.contains('[Hal yang Perlu Diperbaiki]')) {
      final parts = text.split('[Hal yang Perlu Diperbaiki]');
      final alasanPart = parts[0].replaceAll('[Alasan Revisi]', '').trim();
      final perbaikanPart = parts.length > 1 ? parts[1].trim() : '';
      return {
        'alasan': alasanPart.isNotEmpty ? alasanPart : text,
        'perbaikan': perbaikanPart.isNotEmpty ? perbaikanPart : 'Silakan sesuaikan isi logbook sesuai arahan pembimbing.',
      };
    }
    return {
      'alasan': text,
      'perbaikan': 'Harap perbaiki dan lengkapi rincian aktivitas serta unggah ulang foto dokumentasi yang sesuai.',
    };
  }

  int _matchKdFromActivity(String activity) {
    for (int i = 1; i <= 7; i++) {
      if (activity.contains('KD $i') || activity.contains('KD$i')) {
        return i;
      }
    }
    return 1;
  }

  void _openRevisionDetail(Map<String, dynamic> journal) {
    setState(() {
      _selectedRevisionJournal = journal;
      _selectedDetailJournal = null;
    });
  }

  void _openApprovedDetail(Map<String, dynamic> journal) {
    setState(() {
      _selectedDetailJournal = journal;
      _selectedRevisionJournal = null;
    });
  }

  void _startEditingJournal(Map<String, dynamic> journal) {
    final int id = journal['id'] is int
        ? journal['id'] as int
        : int.tryParse(journal['id']?.toString() ?? '0') ?? 0;
    final activity = journal['activity']?.toString() ?? '';
    final desc = journal['description']?.toString() ?? activity;

    String cleanDesc = desc;
    if (cleanDesc.startsWith('[') && cleanDesc.contains(']')) {
      cleanDesc = cleanDesc.substring(cleanDesc.indexOf(']') + 1).trim();
    }

    setState(() {
      _selectedRevisionJournal = null;
      _selectedDetailJournal = null;
      _editingJournalId = id;
      _existingPhotoUrl = journal['photo_url']?.toString();
      _activityPhoto = null;
      _selectedKD = _matchKdFromActivity(activity);
      _deskripsiController.text = cleanDesc;
      _isCreatingJournal = true;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchJournals();
  }

  // 1. Ambil riwayat seluruh logbook siswa dari API backend GET /api/student/logbooks
  Future<void> _fetchJournals() async {
    setState(() => _isLoading = true);
    try {
      final res = await StudentService.getLogbooks();
      if (res != null && res['journals'] != null) {
        if (mounted) {
          setState(() {
            _allJournals = res['journals'] as List<dynamic>;
          });
        }
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _pickActivityPhoto(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (photo != null && mounted) {
        setState(() {
          _activityPhoto = photo;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengakses kamera/galeri: $e')),
      );
    }
  }

  void _showPhotoSourceBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              const Text(
                'Pilih Sumber Foto Kegiatan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Dokumentasikan aktivitas tugas atau hasil pekerjaan PKL hari ini.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF2563EB)),
                ),
                title: const Text('Kamera', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: const Text('Ambil foto langsung dengan kamera', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickActivityPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF2563EB)),
                ),
                title: const Text('Galeri Foto', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: const Text('Pilih dari file foto galeri HP', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickActivityPhoto(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleKirimJurnal() async {
    if (_deskripsiController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi deskripsi kegiatan terlebih dahulu!')),
      );
      return;
    }

    final kdTexts = [
      'Membuat mockup aplikasi sesuai dengan rancangan',
      'Mengimplementasi mockup ke dalam layout user interface',
      'Mengkonfigurasi script web aplikasi',
      'Membuat diagram ERD dan perancangan database',
      'Menampilkan hasil pengujian aplikasi',
      'Melakukan debugging kode program',
      'Kegiatan industri lainnya',
    ];
    final selectedKdTitle = kdTexts[(_selectedKD - 1).clamp(0, kdTexts.length - 1)];

    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    setState(() => _isSubmitting = true);

    if (_editingJournalId != null) {
      // 1. Perbarui data logbook
      final res = await StudentService.updateLogbook(
        id: _editingJournalId!,
        activity: '[$selectedKdTitle] ${_deskripsiController.text.trim()}',
        description: _deskripsiController.text.trim(),
        logbookDate: todayStr,
        photo: _activityPhoto,
      );

      if (res['success'] == true) {
        // 2. Submit ulang ke DUDI agar status beralih dari 'rejected' ke 'submitted'
        await StudentService.submitLogbook(_editingJournalId!);

        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
          _isCreatingJournal = false;
          _editingJournalId = null;
          _existingPhotoUrl = null;
          _activityPhoto = null;
          _deskripsiController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logbook berhasil diperbaiki dan diajukan ulang ke DUDI!'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
        _fetchJournals();
      } else {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Gagal memperbarui logbook.'), backgroundColor: Colors.red),
        );
      }
    } else {
      // 2. Simpan draft logbook baru ke API backend POST /api/student/logbooks dengan foto kegiatan terpisah
      final res = await StudentService.createLogbook(
        logbookDate: todayStr,
        activity: '[$selectedKdTitle] ${_deskripsiController.text.trim()}',
        description: _deskripsiController.text.trim(),
        photo: _activityPhoto,
      );

      if (!mounted) return;

      setState(() => _isSubmitting = false);

      if (res['success'] == true) {
        setState(() {
          _isCreatingJournal = false;
          _activityPhoto = null;
          _deskripsiController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jurnal kegiatan berhasil disimpan!'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchJournals();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Gagal menyimpan jurnal.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showBack = _selectedDetailJournal != null || _selectedRevisionJournal != null || _isCreatingJournal;
    final String pageTitle = _selectedDetailJournal != null
        ? 'Detail Logbook & Bimbingan'
        : (_selectedRevisionJournal != null
            ? 'Form Logbook'
            : (_isCreatingJournal
                ? (_editingJournalId != null ? 'Isi Logbook (Revisi)' : 'Isi Logbook')
                : 'Logbook Kegiatan'));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SmartPklHeader(
              title: pageTitle,
              showBackButton: showBack,
              onBackTap: () {
                setState(() {
                  if (_selectedDetailJournal != null) {
                    _selectedDetailJournal = null;
                  } else if (_selectedRevisionJournal != null) {
                    _selectedRevisionJournal = null;
                  } else if (_isCreatingJournal) {
                    _isCreatingJournal = false;
                    _editingJournalId = null;
                    _existingPhotoUrl = null;
                    _activityPhoto = null;
                    _deskripsiController.clear();
                  }
                });
              },
              onProfileTap: () => widget.onNavigateTab?.call(4),
            ),
            if (_isLoading)
              const LinearProgressIndicator(
                minHeight: 2,
                color: Color(0xFF2563EB),
                backgroundColor: Color(0xFFEFF6FF),
              ),
            Expanded(
              child: _selectedDetailJournal != null
                  ? _buildDetailApprovedView(_selectedDetailJournal!)
                  : (_selectedRevisionJournal != null
                      ? _buildRevisionDetailView(_selectedRevisionJournal!)
                      : (_isCreatingJournal ? _buildTargetKDFormView() : _buildLogbookListView())),
            ),
          ],
        ),
      ),
      floatingActionButton: (!_isCreatingJournal && _selectedDetailJournal == null && _selectedRevisionJournal == null)
          ? FloatingActionButton.extended(
              onPressed: () {
                setState(() {
                  _editingJournalId = null;
                  _existingPhotoUrl = null;
                  _activityPhoto = null;
                  _deskripsiController.clear();
                  _isCreatingJournal = true;
                });
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
              label: const Text(
                'Isi Jurnal Baru',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            )
          : null,
    );
  }

  Widget _buildLogbookListView() {
    final int total = _allJournals.length;
    final int approved = _allJournals.where((j) => j['status'] == 'approved').length;
    final int submitted = _allJournals.where((j) => j['status'] == 'submitted').length;
    final int rejected = _allJournals.where((j) => j['status'] == 'rejected').length;
    final int draft = _allJournals.where((j) => j['status'] == 'draft').length;

    final double progress = total > 0 ? (approved / total) : 0.0;

    List<dynamic> filtered = _allJournals;
    if (_selectedFilterIndex == 1) {
      filtered = _allJournals.where((j) => j['status'] == 'approved').toList();
    } else if (_selectedFilterIndex == 2) {
      filtered = _allJournals.where((j) => j['status'] == 'submitted').toList();
    } else if (_selectedFilterIndex == 3) {
      filtered = _allJournals.where((j) => j['status'] == 'rejected').toList();
    } else if (_selectedFilterIndex == 4) {
      filtered = _allJournals.where((j) => j['status'] == 'draft').toList();
    }

    return RefreshIndicator(
      onRefresh: _fetchJournals,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progres Jurnal Banner Card
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
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progres: $approved/$total Disetujui',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 7,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterPill(0, 'Semua ($total)'),
                  const SizedBox(width: 8),
                  _buildFilterPill(1, 'Disetujui ($approved)'),
                  const SizedBox(width: 8),
                  _buildFilterPill(2, 'Menunggu ($submitted)'),
                  const SizedBox(width: 8),
                  _buildFilterPill(3, 'Revisi ($rejected)'),
                  const SizedBox(width: 8),
                  _buildFilterPill(4, 'Draft ($draft)'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // List of Journals or Empty State
            if (filtered.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.note_alt_outlined, size: 44, color: Color(0xFF94A3B8)),
                    const SizedBox(height: 12),
                    const Text(
                      'Belum ada catatan logbook',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tulis aktivitas harian PKL Anda sekarang untuk direview oleh Pembimbing.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() => _isCreatingJournal = true);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Tulis Jurnal Hari Ini'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final j = filtered[i];
                  final id = j['id'] ?? 0;
                  final date = j['logbook_date']?.toString() ?? '-';
                  final activity = j['activity']?.toString() ?? '-';
                  final desc = j['description']?.toString() ?? '';
                  final status = j['status']?.toString() ?? 'draft';
                  final comment = j['verification_comment']?.toString();
                  final teacherNote = j['teacher_note']?.toString();
                  final teacherName = j['teacher_name']?.toString();
                  final photoUrl = j['photo_url']?.toString();

                  final bool isApproved = status == 'approved';
                  final bool isRejected = status == 'rejected';

                  return InkWell(
                    onTap: () {
                      if (isRejected) {
                        _openRevisionDetail(j);
                      } else if (isApproved) {
                        _openApprovedDetail(j);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isRejected
                              ? const Color(0xFFFECACA)
                              : (isApproved ? const Color(0xFFBBF7D0) : AppColors.cardBorder),
                          width: isRejected || isApproved ? 1.4 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                date,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                              _buildStatusBadge(status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            activity,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (desc.isNotEmpty && desc != activity) ...[
                            const SizedBox(height: 4),
                            Text(
                              desc,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
                            ),
                          ],
                          if (photoUrl != null && photoUrl.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                AuthService.formatImageUrl(photoUrl),
                                height: 130,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const SizedBox(),
                              ),
                            ),
                          ],
                          if (isRejected) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFECACA)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(Icons.error_outline_rounded, size: 14, color: Color(0xFFDC2626)),
                                      SizedBox(width: 6),
                                      Text(
                                        'Catatan Pembimbing (Perlu Revisi):',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFDC2626),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '“${_parseRevisionNotes(comment)['alasan']}”',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                      color: Color(0xFF991B1B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _openRevisionDetail(j),
                                icon: const Icon(Icons.edit_note_rounded, size: 16),
                                label: const Text('Perbaiki Logbook', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ] else if (isApproved) ...[
                            if (comment != null && comment.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Catatan Pembimbing: "$comment"',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => _openApprovedDetail(j),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: const [
                                    Text(
                                      'Detail Logbook & Tanggapan Pembimbing',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF2563EB)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          if (teacherNote != null && teacherNote.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.school_rounded, size: 14, color: Color(0xFF2563EB)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Catatan Guru Pembimbing${teacherName != null ? ' ($teacherName)' : ''}:',
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '“$teacherNote”',
                                          style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        if (status == 'draft') ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () async {
                                  // 3. Hapus draft logbook dari API backend DELETE /api/student/logbooks/{id}
                                  await StudentService.deleteLogbook(id);
                                  _fetchJournals();
                                },
                                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                                label: const Text('Hapus', style: TextStyle(color: Colors.red, fontSize: 12)),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  // 4. Ajukan logbook ke pembimbing via API backend POST /api/student/logbooks/{id}/submit
                                  await StudentService.submitLogbook(id);
                                  _fetchJournals();
                                },
                                icon: const Icon(Icons.send_rounded, size: 14),
                                label: const Text('Submit'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    if (status == 'approved') {
      return const StatusPill(text: 'Disetujui', style: PillStyle.success);
    } else if (status == 'submitted') {
      return const StatusPill(text: 'Menunggu', style: PillStyle.warning);
    } else if (status == 'rejected') {
      return const StatusPill(text: 'Revisi', style: PillStyle.error);
    }
    return const StatusPill(text: 'Draft', style: PillStyle.neutral);
  }

  Widget _buildFilterPill(int index, String label) {
    final bool isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilterIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTargetKDFormView() {
    final now = DateTime.now();
    final dateDisplay = '${now.day} / ${now.month} / ${now.year}';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tanggal Jurnal', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(
                      dateDisplay,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.verified_outlined, color: AppColors.primary, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Target Kompetensi Dasar (KD)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pilih salah satu kompetensi dasar kegiatan hari ini:',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                _buildKdOption(1, 'KD 1', '1. Membuat mockup aplikasi sesuai dengan rancangan'),
                const SizedBox(height: 8),
                _buildKdOption(2, 'KD 2', '2. Mengimplementasi mockup ke dalam layout UI'),
                const SizedBox(height: 8),
                _buildKdOption(3, 'KD 3', '3. Mengkonfigurasi script web / backend aplikasi'),
                const SizedBox(height: 8),
                _buildKdOption(4, 'KD 4', '4. Manajemen basis data & relasi entitas'),
                const SizedBox(height: 8),
                _buildKdOption(5, 'KD 5', '5. Pengujian & validasi modul aplikasi'),
                const SizedBox(height: 8),
                _buildKdOption(6, 'KD 6', '6. Bug fixing & perbaikan performa sistem'),
                const SizedBox(height: 8),
                _buildKdOption(7, 'KD 7', '7. Kegiatan operasional industri lainnya'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rincian Aktivitas Kegiatan *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                TextField(
                  controller: _deskripsiController,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Jelaskan tugas, tools, dan hasil pekerjaan yang Anda selesaikan hari ini...',
                    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Card 4: Ambil / Masukkan Foto Kegiatan (Terpisah dari Presensi) ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.camera_alt_outlined, size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'Dokumentasi Foto Kegiatan',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Foto Aktivitas',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Ambil foto hasil tugas, layar pekerjaan, atau kegiatan PKL Anda (berbeda dari selfie presensi).',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),

                // Preview Foto Kegiatan jika sudah dipilih/difoto
                if (_activityPhoto != null) ...[
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          kIsWeb
                              ? Image.network(_activityPhoto!.path, fit: BoxFit.cover)
                              : Image.file(File(_activityPhoto!.path), fit: BoxFit.cover),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    'Foto Kegiatan Siap',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showPhotoSourceBottomSheet,
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Ganti Foto', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2563EB),
                            side: const BorderSide(color: Color(0xFFBFDBFE)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _activityPhoto = null),
                        icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                        label: const Text('Hapus', style: TextStyle(fontSize: 12, color: Color(0xFFEF4444))),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFECACA)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ] else if (_existingPhotoUrl != null && _existingPhotoUrl!.isNotEmpty) ...[
                  // Preview Foto Kegiatan Sebelumnya jika sedang dalam mode revisi/edit
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            AuthService.formatImageUrl(_existingPhotoUrl!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Center(
                              child: Icon(Icons.broken_image_rounded, size: 36, color: Color(0xFF94A3B8)),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.photo_rounded, color: Color(0xFF60A5FA), size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    'Foto Sebelumnya',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _showPhotoSourceBottomSheet,
                    icon: const Icon(Icons.camera_alt_outlined, size: 16),
                    label: const Text('Ganti / Unggah Foto Baru', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ] else ...[
                  // Tombol Ambil / Pilih Foto
                  InkWell(
                    onTap: _showPhotoSourceBottomSheet,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEFF6FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_a_photo_outlined,
                              color: Color(0xFF2563EB),
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Ambil atau Unggah Foto Kegiatan',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Buka Kamera atau Pilih dari Galeri HP',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          CustomButton(
            text: _isSubmitting
                ? 'Mengirim Jurnal...'
                : (_editingJournalId != null ? 'Kirim Perbaikan Logbook' : 'Kirim Jurnal Kegiatan'),
            icon: Icons.send_rounded,
            onPressed: _isSubmitting ? () {} : _handleKirimJurnal,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildKdOption(int kdNumber, String badge, String text) {
    final bool isSelected = _selectedKD == kdNumber;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedKD = kdNumber;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              size: 18,
              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? const Color(0xFF1E40AF) : const Color(0xFF334155),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── SCREEN 3: Detail Alasan Revisi Logbook (Figma Mockup) ───────────────────
  Widget _buildRevisionDetailView(Map<String, dynamic> journal) {
    final placement = journal['placement'] as Map<String, dynamic>?;
    final location = (journal['location'] as Map<String, dynamic>?) ?? (placement?['location'] as Map<String, dynamic>?);
    final dudiName = location?['name']?.toString() ?? 'PT Solusi Teknologi Mandiri';

    final comment = journal['verification_comment']?.toString() ?? journal['verification_note']?.toString();
    final parsed = _parseRevisionNotes(comment);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card 1: Mitra DUDI
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.business_rounded, color: Color(0xFF2563EB), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              dudiName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded, color: Color(0xFF2563EB), size: 16),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Mitra DUDI / Industri',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'DUDI',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Card 2: Catatan DUDI
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
                    Icon(Icons.comment_outlined, size: 16, color: Color(0xFF64748B)),
                    SizedBox(width: 8),
                    Text(
                      'Catatan DUDI',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Alasan Revisi (Merah)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Alasan Revisi:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        parsed['alasan']!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7F1D1D),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Hal yang Perlu Diperbaiki (Biru / Hijau Lembut)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hal yang Perlu Diperbaiki:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF15803D),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        parsed['perbaikan']!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF14532D),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tombol Mulai Perbaiki (Edit) ->
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => _startEditingJournal(journal),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_note_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Mulai Perbaiki (Edit)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ── SCREEN 2: Detail Logbook & Bimbingan (Figma Mockup) ─────────────────────
  Widget _buildDetailApprovedView(Map<String, dynamic> journal) {
    final placement = journal['placement'] as Map<String, dynamic>?;
    final location = (journal['location'] as Map<String, dynamic>?) ?? (placement?['location'] as Map<String, dynamic>?);
    final companyName = location?['name']?.toString() ?? 'PT Solusi Teknologi';

    final verifier = journal['verifier'] as Map<String, dynamic>?;
    final instrukturName = verifier?['name']?.toString() ?? 
        journal['instruktur_name']?.toString() ?? 
        placement?['fieldSupervisor']?['name']?.toString() ?? 
        'Hendra Kurniawan, S.Kom';

    final teacherName = journal['teacher_name']?.toString() ??
        placement?['teacher']?['name']?.toString() ??
        'Drs. Budi Santoso, M.Pd';

    final teacherNote = journal['teacher_note']?.toString() ??
        'Dokumentasikan kendala responsive breakpoint di laporan mingguan untuk bahan seminar magang.';

    final dudiNote = journal['dudi_note']?.toString() ??
        journal['verification_comment']?.toString() ??
        journal['verification_note']?.toString() ??
        'Pekerjaan rapi sesuai standar industri. PR sudah teruji di staging server.';

    final tanggal = journal['logbook_date']?.toString() ?? journal['journal_date']?.toString() ?? 'Kamis, 24 Okt 2024';
    final activity = journal['activity']?.toString() ?? 'Slicing UI Dashboard Admin Siswa';
    final desc = journal['description']?.toString() ?? activity;
    final kdNum = _matchKdFromActivity(activity);

    final photoUrl = journal['photo_url']?.toString();
    final checkInPhoto = journal['check_in_photo_url']?.toString();
    final checkOutPhoto = journal['check_out_photo_url']?.toString();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subheader Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(
                      '$tanggal • Target KD $kdNum',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF16A34A)),
                    SizedBox(width: 4),
                    Text('Selesai', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF166534))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Card 1: AKTIVITAS MANDIRI
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
                const Text(
                  'AKTIVITAS MANDIRI',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2563EB),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  activity,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Bukti Kerja:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (photoUrl != null && photoUrl.isNotEmpty) ...[
                        SizedBox(
                          width: 130,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  AuthService.formatImageUrl(photoUrl),
                                  height: 95,
                                  width: 130,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported_rounded),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text('Foto Kegiatan', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (checkInPhoto != null && checkInPhoto.isNotEmpty) ...[
                        SizedBox(
                          width: 130,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  AuthService.formatImageUrl(checkInPhoto),
                                  height: 95,
                                  width: 130,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported_rounded),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text('Presensi Masuk', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF16A34A))),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (checkOutPhoto != null && checkOutPhoto.isNotEmpty) ...[
                        SizedBox(
                          width: 130,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  AuthService.formatImageUrl(checkOutPhoto),
                                  height: 95,
                                  width: 130,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported_rounded),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text('Presensi Pulang', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF2563EB))),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Card 2: Validasi Industri (DUDI)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Row(
                      children: [
                        Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF16A34A)),
                        SizedBox(width: 8),
                        Text(
                          'Validasi Industri (DUDI)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    Text('24 Okt • 17:00', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded, size: 18, color: Color(0xFF16A34A)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Disetujui Mitra Industri',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF166534)),
                            ),
                            Text(
                              '$instrukturName • $companyName',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF15803D)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '“$dudiNote”',
                  style: const TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF334155),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Card 3: Bimbingan Guru SMK
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Row(
                      children: [
                        Icon(Icons.school_rounded, size: 16, color: Color(0xFF2563EB)),
                        SizedBox(width: 8),
                        Text(
                          'Bimbingan Guru SMK',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    Text('24 Okt • 17:30', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFFEFF6FF),
                      child: Text(
                        teacherName.isNotEmpty ? teacherName.substring(0, 2).toUpperCase() : 'BS',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            teacherName,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                          const Text(
                            'Guru Pembimbing • SMK Bimbingan',
                            style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ARAHAN TINDAK LANJUT',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF2563EB), letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '“$teacherNote”',
                        style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF334155), height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Footer Badge: Logbook Selesai & Tervalidasi Penuh
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF2563EB)),
                SizedBox(width: 8),
                Text(
                  'Logbook Selesai & Tervalidasi Penuh',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E40AF)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Bottom Button: <- Kembali ke Riwayat
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() => _selectedDetailJournal = null);
              },
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Kembali ke Riwayat', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
