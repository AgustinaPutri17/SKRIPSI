import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/supervisor_service.dart';

class DudiPenilaianScreen extends StatefulWidget {
  final Map<String, dynamic> student;
  final String? companyName;

  const DudiPenilaianScreen({
    super.key,
    required this.student,
    this.companyName,
  });

  @override
  State<DudiPenilaianScreen> createState() => _DudiPenilaianScreenState();
}

class _SubIndicatorItem {
  final String code;
  String title;
  double score;

  _SubIndicatorItem({
    required this.code,
    required this.title,
    this.score = 85.0,
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'title': title,
        'score': score,
      };

  factory _SubIndicatorItem.fromJson(Map<String, dynamic> json) => _SubIndicatorItem(
        code: json['code']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        score: (json['score'] as num?)?.toDouble() ?? 85.0,
      );
}

class _DudiPenilaianScreenState extends State<DudiPenilaianScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  // Controllers for descriptions
  late TextEditingController _desc1Controller;
  late TextEditingController _desc2Controller;
  late TextEditingController _desc3Controller;
  late TextEditingController _desc4Controller;
  late TextEditingController _generalNotesController;

  // 1. Soft skills (1.1 - 1.6)
  late List<_SubIndicatorItem> _softSkills;

  // 2. Norma, POS & K3LH (2.1 - 2.2)
  late List<_SubIndicatorItem> _k3lhItems;

  // 3. Kompetensi Teknis (3.1 - 3.x)
  late List<_SubIndicatorItem> _technicalItems;

  // 4. Alur Bisnis (4.1)
  late List<_SubIndicatorItem> _businessItems;

  @override
  void initState() {
    super.initState();
    _initDefaults();
    _loadExistingAssessment();
  }

  void _initDefaults() {
    _desc1Controller = TextEditingController(
      text: 'Peserta didik sudah memiliki soft skills sesuai harapan dalam berkomunikasi dan beretika kerja, disiplin dan kerjasama tim baik.',
    );
    _desc2Controller = TextEditingController(
      text: 'Peserta didik tertib menggunakan atribut/APD dan konsisten mematuhi POS yang berlaku di tempat kerja.',
    );
    _desc3Controller = TextEditingController(
      text: 'Peserta didik mampu menerapkan kompetensi teknis kejuruan dengan baik dan dapat menyelesaikan instruksi tugas industri.',
    );
    _desc4Controller = TextEditingController(
      text: 'Peserta didik telah mampu memahami alur bisnis pada tempat PKL dan memiliki pemahaman alur kerja operasional.',
    );
    _generalNotesController = TextEditingController(
      text: 'Pertahankan kedisiplinan dan terus kembangkan kemampuan teknis di industri.',
    );

    _softSkills = [
      _SubIndicatorItem(code: '1.1', title: 'Melaksanakan komunikasi telepon & koordinasi sesuai kaidah', score: 85.0),
      _SubIndicatorItem(code: '1.2', title: 'Menunjukkan integritas (jujur, disiplin, komitmen, tanggung jawab)', score: 88.0),
      _SubIndicatorItem(code: '1.3', title: 'Memiliki etos kerja tinggi dan dedikasi', score: 86.0),
      _SubIndicatorItem(code: '1.4', title: 'Menunjukkan kemandirian dalam bekerja', score: 84.0),
      _SubIndicatorItem(code: '1.5', title: 'Menunjukkan kerjasama tim yang solid', score: 87.0),
      _SubIndicatorItem(code: '1.6', title: 'Menunjukkan kepedulian sosial & kelestarian lingkungan kerja', score: 85.0),
    ];

    _k3lhItems = [
      _SubIndicatorItem(code: '2.1', title: 'Menggunakan Baju Kerja / APD dengan tertib dan benar', score: 88.0),
      _SubIndicatorItem(code: '2.2', title: 'Melaksanakan pekerjaan sesuai Prosedur Operasional Standar (POS)', score: 86.0),
    ];

    _technicalItems = [
      _SubIndicatorItem(code: '3.1', title: 'Perancangan Sistem & Basis Data (Mockup / ERD)', score: 88.0),
      _SubIndicatorItem(code: '3.2', title: 'Implementasi & Pemrograman Web / Aplikasi', score: 87.0),
      _SubIndicatorItem(code: '3.3', title: 'Pengujian, Debugging & Optimasi Kode', score: 85.0),
      _SubIndicatorItem(code: '3.4', title: 'Penggunaan Alat (Tools) & Framework Industri', score: 86.0),
      _SubIndicatorItem(code: '3.5', title: 'Dokumentasi Teknis & Pelaporan Proyek', score: 85.0),
    ];

    _businessItems = [
      _SubIndicatorItem(code: '4.1', title: 'Memahami alur proses bisnis tempat PKL & wawasan wirausaha', score: 86.0),
    ];
  }

  @override
  void dispose() {
    _desc1Controller.dispose();
    _desc2Controller.dispose();
    _desc3Controller.dispose();
    _desc4Controller.dispose();
    _generalNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingAssessment() async {
    final studentId = widget.student['id'] as int?;
    if (studentId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final res = await SupervisorService.getAssessment(studentId);
      if (res != null && res['assessment'] != null) {
        final asm = res['assessment'] as Map<String, dynamic>;
        final comps = asm['dudi_components'] as Map<String, dynamic>?;

        if (comps != null) {
          if (comps['indicator_1'] != null) {
            final ind1 = comps['indicator_1'] as Map<String, dynamic>;
            final items = (ind1['items'] as List?)?.map((e) => _SubIndicatorItem.fromJson(Map<String, dynamic>.from(e))).toList();
            if (items != null && items.isNotEmpty) _softSkills = items;
            if (ind1['description'] != null) _desc1Controller.text = ind1['description'].toString();
          }

          if (comps['indicator_2'] != null) {
            final ind2 = comps['indicator_2'] as Map<String, dynamic>;
            final items = (ind2['items'] as List?)?.map((e) => _SubIndicatorItem.fromJson(Map<String, dynamic>.from(e))).toList();
            if (items != null && items.isNotEmpty) _k3lhItems = items;
            if (ind2['description'] != null) _desc2Controller.text = ind2['description'].toString();
          }

          if (comps['indicator_3'] != null) {
            final ind3 = comps['indicator_3'] as Map<String, dynamic>;
            final items = (ind3['items'] as List?)?.map((e) => _SubIndicatorItem.fromJson(Map<String, dynamic>.from(e))).toList();
            if (items != null && items.isNotEmpty) _technicalItems = items;
            if (ind3['description'] != null) _desc3Controller.text = ind3['description'].toString();
          }

          if (comps['indicator_4'] != null) {
            final ind4 = comps['indicator_4'] as Map<String, dynamic>;
            final items = (ind4['items'] as List?)?.map((e) => _SubIndicatorItem.fromJson(Map<String, dynamic>.from(e))).toList();
            if (items != null && items.isNotEmpty) _businessItems = items;
            if (ind4['description'] != null) _desc4Controller.text = ind4['description'].toString();
          }
        }

        if (asm['dudi_notes'] != null && asm['dudi_notes'].toString().isNotEmpty) {
          _generalNotesController.text = asm['dudi_notes'].toString();
        }
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
  }

  // --- Calculations ---
  double get _score1 {
    if (_softSkills.isEmpty) return 0.0;
    final sum = _softSkills.fold<double>(0.0, (acc, item) => acc + item.score);
    return sum / _softSkills.length;
  }

  double get _score2 {
    if (_k3lhItems.isEmpty) return 0.0;
    final sum = _k3lhItems.fold<double>(0.0, (acc, item) => acc + item.score);
    return sum / _k3lhItems.length;
  }

  double get _score3 {
    if (_technicalItems.isEmpty) return 0.0;
    final sum = _technicalItems.fold<double>(0.0, (acc, item) => acc + item.score);
    return sum / _technicalItems.length;
  }

  double get _score4 {
    if (_businessItems.isEmpty) return 0.0;
    final sum = _businessItems.fold<double>(0.0, (acc, item) => acc + item.score);
    return sum / _businessItems.length;
  }

  /// Total Skor PKL = (Skor 1 + Skor 2 + Skor 3 + Skor 4) / 4
  double get _totalDudiScore {
    return (_score1 + _score2 + _score3 + _score4) / 4.0;
  }

  String _getGrade(double score) {
    if (score >= 90) return 'A';
    if (score >= 80) return 'B';
    if (score >= 70) return 'C';
    if (score >= 60) return 'D';
    return 'E';
  }

  String _getPredikatText(double score) {
    if (score >= 90) return 'Sangat Baik';
    if (score >= 80) return 'Baik';
    if (score >= 70) return 'Cukup';
    return 'Kurang';
  }

  Color _getGradeColor(double score) {
    if (score >= 85) return const Color(0xFF16A34A);
    if (score >= 75) return const Color(0xFF2563EB);
    if (score >= 65) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  Future<void> _saveAssessment() async {
    final studentId = widget.student['id'] as int?;
    if (studentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID Siswa tidak valid')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final payload = {
      'formula': 'Skor PKL = (Skor 1 + Skor 2 + Skor 3 + Skor 4) / 4',
      'total_score': double.parse(_totalDudiScore.toStringAsFixed(2)),
      'grade': _getGrade(_totalDudiScore),
      'predikat': _getPredikatText(_totalDudiScore),
      'indicator_1': {
        'title': 'Menerapkan soft skills yang dibutuhkan dalam dunia kerja',
        'score': double.parse(_score1.toStringAsFixed(2)),
        'description': _desc1Controller.text.trim(),
        'items': _softSkills.map((e) => e.toJson()).toList(),
      },
      'indicator_2': {
        'title': 'Menerapkan norma, POS dan K3LH yang ada pada dunia kerja',
        'score': double.parse(_score2.toStringAsFixed(2)),
        'description': _desc2Controller.text.trim(),
        'items': _k3lhItems.map((e) => e.toJson()).toList(),
      },
      'indicator_3': {
        'title': 'Menerapkan kompetensi teknis yang sudah/baru dipelajari pada dunia kerja',
        'score': double.parse(_score3.toStringAsFixed(2)),
        'description': _desc3Controller.text.trim(),
        'items': _technicalItems.map((e) => e.toJson()).toList(),
      },
      'indicator_4': {
        'title': 'Memahami alur bisnis dunia kerja tempat PKL dan wawasan wirausaha',
        'score': double.parse(_score4.toStringAsFixed(2)),
        'description': _desc4Controller.text.trim(),
        'items': _businessItems.map((e) => e.toJson()).toList(),
      },
    };

    final result = await SupervisorService.saveAssessment(
      studentId: studentId,
      dudiScore: _totalDudiScore,
      components: payload,
      notes: _generalNotesController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Nilai PKL berhasil disimpan! Total Skor: ${_totalDudiScore.toStringAsFixed(2)} (${_getGrade(_totalDudiScore)})',
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, _totalDudiScore);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal menyimpan penilaian.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAddTechnicalItemDialog() {
    final titleController = TextEditingController();
    double initialVal = 85.0;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Tambah Indikator Teknis (No. 3)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nama Kompetensi Teknis:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'Contoh: Konfigurasi Jaringan & Server',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Nilai Awal:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      Text(initialVal.toStringAsFixed(0), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF2563EB))),
                    ],
                  ),
                  Slider(
                    value: initialVal,
                    min: 50,
                    max: 100,
                    divisions: 50,
                    activeColor: const Color(0xFF2563EB),
                    onChanged: (v) => setDlgState(() => initialVal = v),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final t = titleController.text.trim();
                    if (t.isNotEmpty) {
                      setState(() {
                        final nextCode = '3.${_technicalItems.length + 1}';
                        _technicalItems.add(_SubIndicatorItem(code: nextCode, title: t, score: initialVal));
                      });
                      Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Tambahkan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentName = widget.student['name']?.toString() ?? 'Siswa PKL';
    final nis = widget.student['nis']?.toString() ?? '-';
    final studentClass = widget.student['class']?.toString() ?? 'XII RPL';
    final major = widget.student['major']?.toString() ?? 'Rekayasa Perangkat Lunak';
    final company = widget.companyName ?? 'Tempat PKL DU/DI';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Form Penilaian PKL (DU/DI)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            Text(
              'Form. 07 Lembar Observasi Kegiatan PKL',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Header Identitas Siswa & DU/DI ---
                        _buildStudentIdentityCard(studentName, nis, studentClass, major, company),
                        const SizedBox(height: 16),

                        // --- Total Skor PKL (Formula card) ---
                        _buildTotalScoreHeroCard(),
                        const SizedBox(height: 20),

                        // --- Section 1: Soft Skills ---
                        _buildSectionCard(
                          number: '1',
                          title: 'Menerapkan Soft Skills yang Dibutuhkan Dunia Kerja',
                          subtitle: 'Komunikasi, integritas, etos kerja, kemandirian, kerjasama, kepedulian sosial',
                          sectionScore: _score1,
                          items: _softSkills,
                          descController: _desc1Controller,
                          formulaLabel: 'Skor 1 = Jumlah : 6',
                        ),
                        const SizedBox(height: 16),

                        // --- Section 2: Norma, POS & K3LH ---
                        _buildSectionCard(
                          number: '2',
                          title: 'Menerapkan Norma, POS, dan K3LH di Dunia Kerja',
                          subtitle: 'Baju kerja/APD tertib & benar, serta melaksanakan pekerjaan sesuai POS',
                          sectionScore: _score2,
                          items: _k3lhItems,
                          descController: _desc2Controller,
                          formulaLabel: 'Skor 2 = Jumlah : 2',
                        ),
                        const SizedBox(height: 16),

                        // --- Section 3: Kompetensi Teknis Kejuruan ---
                        _buildSectionCard(
                          number: '3',
                          title: 'Menerapkan Kompetensi Teknis Kejuruan',
                          subtitle: 'Kompetensi teknis yang dipelajari di sekolah & dunia industri',
                          sectionScore: _score3,
                          items: _technicalItems,
                          descController: _desc3Controller,
                          formulaLabel: 'Skor 3 = Jumlah : ${_technicalItems.length}',
                          onAddItem: _showAddTechnicalItemDialog,
                        ),
                        const SizedBox(height: 16),

                        // --- Section 4: Alur Bisnis & Wirausaha ---
                        _buildSectionCard(
                          number: '4',
                          title: 'Memahami Alur Bisnis & Wawasan Wirausaha',
                          subtitle: 'Pemahaman alur operasional bisnis perusahaan & budaya industri',
                          sectionScore: _score4,
                          items: _businessItems,
                          descController: _desc4Controller,
                          formulaLabel: 'Skor 4 = Jumlah : 1',
                        ),
                        const SizedBox(height: 16),

                        // --- Catatan / Rekomendasi Umum ---
                        _buildGeneralNotesCard(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),

                // --- Bottom Save Bar ---
                _buildBottomActionBar(),
              ],
            ),
    );
  }

  Widget _buildStudentIdentityCard(String name, String nis, String sClass, String major, String company) {
    return Container(
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
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFEFF6FF),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'S',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF2563EB)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'NIS: $nis  •  $sClass',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              const Icon(Icons.business_rounded, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  company,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Penilai: Pembimbing DU/DI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalScoreHeroCard() {
    final grade = _getGrade(_totalDudiScore);
    final predikat = _getPredikatText(_totalDudiScore);
    final gradeColor = _getGradeColor(_totalDudiScore);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.3),
            blurRadius: 12,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOTAL SKOR PKL (DU/DI)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFBFDBFE),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _totalDudiScore.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '/ 100',
                        style: TextStyle(fontSize: 14, color: Color(0xFF93C5FD), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Grade $grade',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: gradeColor,
                      ),
                    ),
                    Text(
                      predikat,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.functions_rounded, color: Color(0xFF93C5FD), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Rumus Form. 07: Skor PKL = (Skor 1 + Skor 2 + Skor 3 + Skor 4) : 4',
                    style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 4 Sub-score indicators preview
          Row(
            children: [
              _buildMiniScorePill('No.1 Soft Skills', _score1),
              const SizedBox(width: 6),
              _buildMiniScorePill('No.2 K3LH/POS', _score2),
              const SizedBox(width: 6),
              _buildMiniScorePill('No.3 Teknis', _score3),
              const SizedBox(width: 6),
              _buildMiniScorePill('No.4 Bisnis', _score4),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniScorePill(String label, double val) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 9, color: Color(0xFFDBEAFE), fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              val.toStringAsFixed(1),
              style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String number,
    required String title,
    required String subtitle,
    required double sectionScore,
    required List<_SubIndicatorItem> items,
    required TextEditingController descController,
    required String formulaLabel,
    VoidCallback? onAddItem,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          // Section Title Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    number,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Skor Indikator', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                    Text(
                      sectionScore.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: _getGradeColor(sectionScore),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Sub-indicator items list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                ...items.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  return _buildSubIndicatorRow(item, idx, items.length);
                }),
                if (onAddItem != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onAddItem,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Tambah Indikator Teknis'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        side: const BorderSide(color: Color(0xFF93C5FD)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // Formula info banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calculate_outlined, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Text(
                        formulaLabel,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Deskripsi / Catatan per indikator
                const Text(
                  'Deskripsi Ketercapaian / Catatan:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Tuliskan deskripsi capaian siswa...',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubIndicatorRow(_SubIndicatorItem item, int index, int total) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.code,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 8),
              // Direct numeric display & tap to edit
              GestureDetector(
                onTap: () => _showQuickEditScoreDialog(item),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        item.score.toStringAsFixed(0),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF2563EB)),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit, size: 12, color: Color(0xFF94A3B8)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Interactive Slider
          Row(
            children: [
              const Text('50', style: TextStyle(fontSize: 10, color: Colors.grey)),
              Expanded(
                child: Slider(
                  value: item.score,
                  min: 50,
                  max: 100,
                  divisions: 50,
                  activeColor: const Color(0xFF2563EB),
                  inactiveColor: const Color(0xFFE2E8F0),
                  onChanged: (val) {
                    setState(() {
                      item.score = val;
                    });
                  },
                ),
              ),
              const Text('100', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  void _showQuickEditScoreDialog(_SubIndicatorItem item) {
    final c = TextEditingController(text: item.score.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Nilai ${item.code}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              TextField(
                controller: c,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Masukkan Skor (0 - 100)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                final v = double.tryParse(c.text.trim());
                if (v != null) {
                  setState(() {
                    item.score = v.clamp(0.0, 100.0);
                  });
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGeneralNotesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notes_rounded, size: 20, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text(
                'Catatan & Evaluasi Pembimbing Industri (DU/DI)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Beri ulasan, masukan, atau apresiasi untuk perkembangan kompetensi siswa.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _generalNotesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Tuliskan catatan evaluasi untuk siswa...',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 14,
        bottom: MediaQuery.of(context).padding.bottom + 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Skor Akhir DU/DI:',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
                Row(
                  children: [
                    Text(
                      _totalDudiScore.toStringAsFixed(2),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF2563EB)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Grade ${_getGrade(_totalDudiScore)}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF1D4ED8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveAssessment,
            icon: _isSaving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_rounded, size: 20),
            label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Nilai PKL'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
