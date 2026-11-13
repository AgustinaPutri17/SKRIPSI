import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/admin_service.dart';
import '../../widgets/smart_pkl_header.dart';

class AdminMasterTab extends StatefulWidget {
  final int initialSubIndex;
  final Function(int tabIndex, {int? subIndex})? onNavigateTab;

  const AdminMasterTab({
    super.key,
    this.initialSubIndex = 0,
    this.onNavigateTab,
  });

  @override
  State<AdminMasterTab> createState() => AdminMasterTabState();
}

class AdminMasterTabState extends State<AdminMasterTab> {
  late int _activeSubTab; // 0: Siswa, 1: Guru, 2: Mitra DU/DI, 3: Penempatan PKL
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;

  List<dynamic> _students = [];
  List<dynamic> _teachers = [];
  List<dynamic> _locations = [];
  List<dynamic> _placements = [];
  List<dynamic> _periods = [];
  List<dynamic> _fieldSupervisors = [];
  String _placementFilterStatus = 'all'; // 'all', 'active', 'completed', 'inactive'
  final Map<dynamic, int> _placementCountMap = {};

  // Initial demo fallback data matching screenshot & database seeders
  final List<Map<String, dynamic>> _demoStudents = [
    {
      'id': 1,
      'name': 'M. Farel Ardiansyah',
      'nis': '92031',
      'class': 'XII RPL 1',
      'major': 'Rekayasa Perangkat Lunak',
      'teacher_name': 'Drs. Budi Santoso, M.Pd',
      'dudi_name': 'PT Solusi Teknologi Mandiri',
      'username': 'farel_ardiansyah',
      'is_active': true,
      'user_id': 101,
    },
    {
      'id': 2,
      'name': 'Nadia Putri Rahmadani',
      'nis': '92045',
      'class': 'XII RPL 2',
      'major': 'Rekayasa Perangkat Lunak',
      'teacher_name': 'Drs. Budi Santoso, M.Pd',
      'dudi_name': 'PT Telkom Witel Lampung',
      'username': 'nadia_putri',
      'is_active': true,
      'user_id': 102,
    },
    {
      'id': 3,
      'name': 'Rizky Pratama',
      'nis': '92050',
      'class': 'XII TKJ 1',
      'major': 'Teknik Komputer & Jaringan',
      'teacher_name': 'Sudirman',
      'dudi_name': 'CV Media Inovasi Digital',
      'username': 'rizky_pratama',
      'is_active': true,
      'user_id': 103,
    },
  ];

  final List<Map<String, dynamic>> _demoTeachers = [
    {
      'id': 1,
      'name': 'Drs. Budi Santoso, M.Pd',
      'teacher_code': 'GT001',
      'department': 'Rekayasa Perangkat Lunak',
      'username': 'budi_santoso',
      'student_count': 8,
      'is_active': true,
      'user_id': 201,
    },
    {
      'id': 2,
      'name': 'Sudirman',
      'teacher_code': 'GT002',
      'department': 'Rekayasa Perangkat Lunak',
      'username': 'bambang_sujarwo',
      'student_count': 5,
      'is_active': true,
      'user_id': 202,
    },
    {
      'id': 3,
      'name': 'Siti Rahayu, S.Kom',
      'teacher_code': 'GT003',
      'department': 'Teknik Komputer & Jaringan',
      'username': 'siti_rahayu',
      'student_count': 3,
      'is_active': true,
      'user_id': 203,
    },
  ];

  final List<Map<String, dynamic>> _demoLocations = [
    {
      'id': 1,
      'name': 'PT Solusi Teknologi Mandiri',
      'address': 'Jl. ZA. Pagar Alam No. 42, Gedong Meneng, Bandar Lampung',
      'latitude': -5.378921,
      'longitude': 105.251412,
      'radius': 100,
      'student_count': 4,
      'is_active': true,
    },
    {
      'id': 2,
      'name': 'PT Telkom Witel Lampung',
      'address': 'Jl. Majapahit No. 1, Enggal, Bandar Lampung',
      'latitude': -5.421034,
      'longitude': 105.263841,
      'radius': 100,
      'student_count': 5,
      'is_active': true,
    },
    {
      'id': 3,
      'name': 'Bengkel Auto 2000 Rajabasa',
      'address': 'Jl. Raya Haji Mena No. 88, Natar / Rajabasa',
      'latitude': -5.352410,
      'longitude': 105.234120,
      'radius': 100,
      'student_count': 3,
      'is_active': true,
    },
  ];

  final List<Map<String, dynamic>> _demoPlacements = [
    {
      'id': 1,
      'student_id': 1,
      'location_id': 1,
      'period_id': 1,
      'teacher_id': 1,
      'field_supervisor_id': 1,
      'start_date': '2025-01-06',
      'end_date': '2025-03-31',
      'status': 'active',
      'student': {
        'id': 1,
        'name': 'M. Farel Ardiansyah',
        'nis': '92031',
        'class': 'XII RPL 1',
        'major': 'Rekayasa Perangkat Lunak',
      },
      'location': {
        'id': 1,
        'name': 'PT Solusi Teknologi Mandiri',
        'address': 'Jl. ZA. Pagar Alam No. 42, Gedong Meneng, Bandar Lampung',
        'radius': 100,
      },
      'teacher': {
        'id': 1,
        'name': 'Drs. Budi Santoso, M.Pd',
        'teacher_code': 'GT001',
      },
      'field_supervisor': {
        'id': 1,
        'name': 'Hendra Wijaya, S.Kom',
        'organization': 'PT Solusi Teknologi Mandiri',
      },
      'period': {
        'id': 1,
        'name': 'Periode PKL Genap 2024/2025',
      },
    },
    {
      'id': 2,
      'student_id': 2,
      'location_id': 2,
      'period_id': 1,
      'teacher_id': 1,
      'field_supervisor_id': null,
      'start_date': '2025-01-06',
      'end_date': '2025-03-31',
      'status': 'active',
      'student': {
        'id': 2,
        'name': 'Nadia Putri Rahmadani',
        'nis': '92045',
        'class': 'XII RPL 2',
        'major': 'Rekayasa Perangkat Lunak',
      },
      'location': {
        'id': 2,
        'name': 'PT Telkom Witel Lampung',
        'address': 'Jl. Majapahit No. 1, Enggal, Bandar Lampung',
        'radius': 100,
      },
      'teacher': {
        'id': 1,
        'name': 'Drs. Budi Santoso, M.Pd',
        'teacher_code': 'GT001',
      },
      'field_supervisor': null,
      'period': {
        'id': 1,
        'name': 'Periode PKL Genap 2024/2025',
      },
    },
  ];

  final List<Map<String, dynamic>> _demoPeriods = [
    {
      'id': 1,
      'name': 'PKL Semester Ganjil 2024/2025',
      'start_date': '2024-07-01',
      'end_date': '2024-09-30',
      'status': 'inactive',
    },
    {
      'id': 2,
      'name': 'PKL Semester Genap 2024/2025',
      'start_date': '2025-01-06',
      'end_date': '2025-03-31',
      'status': 'active',
    },
    {
      'id': 3,
      'name': 'PKL Semester Ganjil 2025/2026',
      'start_date': '2025-07-01',
      'end_date': '2025-09-30',
      'status': 'inactive',
    },
  ];

  @override
  void initState() {
    super.initState();
    _activeSubTab = widget.initialSubIndex;
    _fetchData();
  }

  void setSubTab(int index) {
    setState(() {
      _activeSubTab = index;
    });
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // ========================================================================
      // PANGGILAN API BACKEND: 4.3 Master Data Siswa
      // Endpoint: GET /api/admin/students
      // Backend File: monitoring-pkl-app/routes/api.php:41
      // Controller: App\Http\Controllers\Api\Admin\StudentController@index
      // Query: search, per_page
      // Deskripsi: Menampilkan daftar siswa real dari database beserta akun pengguna
      // ========================================================================
      final studentRes = await AdminService.getStudents(search: _searchController.text);
      if (studentRes != null && studentRes['students'] != null) {
        _students = studentRes['students'] as List<dynamic>;
      } else {
        _students = _demoStudents;
      }

      // ========================================================================
      // PANGGILAN API BACKEND: 4.4 Master Data Guru Pembimbing
      // Endpoint: GET /api/admin/teachers
      // Backend File: monitoring-pkl-app/routes/api.php:44
      // Controller: App\Http\Controllers\Api\Admin\TeacherController@index
      // Query: search, per_page
      // Deskripsi: Menampilkan daftar guru pembimbing real dari database beserta akun
      // ========================================================================
      final teacherRes = await AdminService.getTeachers(search: _searchController.text);
      if (teacherRes != null && teacherRes['teachers'] != null) {
        _teachers = teacherRes['teachers'] as List<dynamic>;
      } else {
        _teachers = _demoTeachers;
      }

      // ========================================================================
      // PANGGILAN API BACKEND: 4.x Master Data Mitra DU/DI (locations)
      // Endpoint: GET /api/admin/locations
      // Backend File: monitoring-pkl-app/routes/api.php:50
      // Controller: App\Http\Controllers\Api\Admin\LocationController@index
      // Query Params:
      //   - search: String (Filter pencarian nama atau alamat mitra DU/DI)
      //   - per_page: Integer (Jumlah data per halaman, default: 15)
      //   - is_active: Boolean (Filter status aktif mitra)
      // Deskripsi: Menampilkan daftar lokasi mitra industri DU/DI dari database
      // ========================================================================
      final locRes = await AdminService.getLocations(search: _searchController.text);
      if (locRes != null && locRes['locations'] != null) {
        _locations = locRes['locations'] as List<dynamic>;
      } else {
        _locations = _demoLocations;
      }

      // ========================================================================
      // PANGGILAN API BACKEND: 4.8 Master Data Penempatan Siswa (placements)
      // Endpoint: GET /api/admin/placements
      // Backend File: monitoring-pkl-app/routes/api.php:56
      // Controller: App\Http\Controllers\Api\Admin\PlacementController@index
      // Query Params: per_page=100
      // Deskripsi: Menampilkan daftar penempatan siswa beserta relasi lengkap (siswa, DUDI, guru, pembimbing lapangan, periode)
      // ========================================================================
      try {
        final placements = await AdminService.getPlacements(perPage: 100);
        if (placements != null && placements.isNotEmpty) {
          _placements = placements;
        } else {
          _placements = _demoPlacements;
        }
        _placementCountMap.clear();
        for (final p in _placements) {
          final locId = p['location_id'] ?? (p['location'] != null ? p['location']['id'] : null);
          if (locId != null) {
            _placementCountMap[locId] = (_placementCountMap[locId] ?? 0) + 1;
          }
        }
      } catch (_) {
        _placements = _demoPlacements;
      }

      // ========================================================================
      // PANGGILAN API BACKEND: 4.7 Master Data Periode PKL (periods)
      // Endpoint: GET /api/admin/periods
      // Backend File: monitoring-pkl-app/routes/api.php:53
      // Controller: App\Http\Controllers\Api\Admin\PeriodController@index
      // Deskripsi: Mengambil daftar periode PKL untuk pilihan penempatan siswa
      // ========================================================================
      try {
        final periodRes = await AdminService.getPeriods(perPage: 100);
        if (periodRes != null && periodRes['periods'] != null && (periodRes['periods'] as List).isNotEmpty) {
          _periods = periodRes['periods'] as List<dynamic>;
        } else {
          _periods = _demoPeriods;
        }
      } catch (_) {
        _periods = _demoPeriods;
      }

      // ========================================================================
      // PANGGILAN API BACKEND: 4.5 Master Data Pembimbing Lapangan DU/DI
      // Endpoint: GET /api/admin/field-supervisors
      // Backend File: monitoring-pkl-app/routes/api.php:47
      // Controller: App\Http\Controllers\Api\Admin\FieldSupervisorController@index
      // Deskripsi: Mengambil daftar pembimbing DU/DI untuk penugasan penempatan
      // ========================================================================
      try {
        final supRes = await AdminService.getFieldSupervisors();
        if (supRes != null && supRes['field_supervisors'] != null) {
          _fieldSupervisors = supRes['field_supervisors'] as List<dynamic>;
        }
      } catch (_) {}
    } catch (_) {
      _students = _demoStudents;
      _teachers = _demoTeachers;
      _locations = _demoLocations;
      _placements = _demoPlacements;
      _periods = _demoPeriods;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int countSiswa = _students.length;
    final int countGuru = _teachers.length;
    final int countDudi = _locations.length;
    final int countPenempatan = _placements.length;
    final int countPeriode = _periods.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            SmartPklHeader(
              title: 'Data Master',
              onProfileTap: () => widget.onNavigateTab?.call(3),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchData,
                color: const Color(0xFF2563EB),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: "Data Master" + "+ Tambah ▾" button (Matching Screenshot 2 & 3)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Data Master',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildTambahDropdownButton(),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Segmented Pill Tabs (Matching Screenshot 2 & 3 + Penempatan PKL + Periode PKL)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildPillTab(
                              index: 0,
                              icon: Icons.school_outlined,
                              label: 'Siswa ($countSiswa)',
                            ),
                            const SizedBox(width: 8),
                            _buildPillTab(
                              index: 1,
                              icon: Icons.badge_outlined,
                              label: 'Guru Pembimbing ($countGuru)',
                            ),
                            const SizedBox(width: 8),
                            _buildPillTab(
                              index: 2,
                              icon: Icons.layers_rounded,
                              label: 'DU/DI ($countDudi)',
                            ),
                            const SizedBox(width: 8),
                            _buildPillTab(
                              index: 3,
                              icon: Icons.assignment_outlined,
                              label: 'Penempatan ($countPenempatan)',
                            ),
                            const SizedBox(width: 8),
                            _buildPillTab(
                              index: 4,
                              icon: Icons.date_range_rounded,
                              label: 'Periode PKL ($countPeriode)',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Search Bar with Filter Icon (Matching Screenshot 2 & 3)
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (val) {
                                  setState(() {});
                                },
                                onSubmitted: (_) => _fetchData(),
                                style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                                decoration: InputDecoration(
                                  hintText: _activeSubTab == 1
                                      ? 'Cari nama, NIP, atau jurusan...'
                                      : _activeSubTab == 2
                                          ? 'Cari nama mitra industri atau alamat...'
                                          : _activeSubTab == 3
                                              ? 'Cari siswa, mitra DU/DI, atau guru...'
                                              : _activeSubTab == 4
                                                  ? 'Cari nama periode atau tahun ajaran...'
                                                  : 'Cari nama, NIS, atau mitra DUDI...',
                                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF94A3B8)),
                                          onPressed: () {
                                            _searchController.clear();
                                            _fetchData();
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              _showFilterBottomSheet();
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: const Icon(Icons.tune_rounded, size: 20, color: Color(0xFF64748B)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Content List based on active tab
                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                          ),
                        )
                      else if (_activeSubTab == 0)
                        _buildSiswaList()
                      else if (_activeSubTab == 1)
                        _buildGuruList()
                      else if (_activeSubTab == 2)
                        _buildDudiList()
                      else if (_activeSubTab == 3)
                        _buildPenempatanList()
                      else
                        _buildPeriodeList(),

                      const SizedBox(height: 30),
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

  // ── DROPDOWN "+ Tambah ▾" BUTTON ──
  Widget _buildTambahDropdownButton() {
    return PopupMenuButton<int>(
      onSelected: (val) {
        if (val == 0) {
          _showTambahSiswaModal();
        } else if (val == 1) {
          _showTambahGuruModal();
        } else if (val == 2) {
          _showTambahDudiModal();
        } else if (val == 3) {
          _showTambahPenempatanModal();
        } else if (val == 4) {
          _showTambahPeriodeModal();
        }
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      offset: const Offset(0, 42),
      itemBuilder: (ctx) => [
        const PopupMenuItem(
          value: 0,
          child: Row(
            children: [
              Icon(Icons.school_outlined, size: 18, color: Color(0xFF2563EB)),
              SizedBox(width: 10),
              Text('Tambah Siswa', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 1,
          child: Row(
            children: [
              Icon(Icons.supervised_user_circle_outlined, size: 18, color: Color(0xFF4F46E5)),
              SizedBox(width: 10),
              Text('Tambah Guru Pembimbing', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 2,
          child: Row(
            children: [
              Icon(Icons.business_rounded, size: 18, color: Color(0xFF0284C7)),
              SizedBox(width: 10),
              Text('Tambah Mitra DU/DI', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 3,
          child: Row(
            children: [
              Icon(Icons.assignment_ind_outlined, size: 18, color: Color(0xFF0D9488)),
              SizedBox(width: 10),
              Text('Tambah Penempatan PKL', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 4,
          child: Row(
            children: [
              Icon(Icons.date_range_rounded, size: 18, color: Color(0xFFEA580C)),
              SizedBox(width: 10),
              Text('Tambah Periode PKL', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_add_alt_1_rounded, size: 16, color: Colors.white),
            SizedBox(width: 6),
            Text(
              '+ Tambah',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.white),
          ],
        ),
      ),
    );
  }

  // ── SEGMENTED PILL TAB ──
  Widget _buildPillTab({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isActive = _activeSubTab == index;

    return InkWell(
      onTap: () {
        setState(() {
          _activeSubTab = index;
        });
      },
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                color: isActive ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 1. SISWA LIST & CARD (Matching Screenshot 2) ──
  Widget _buildSiswaList() {
    final query = _searchController.text.toLowerCase();
    final filtered = _students.where((item) {
      final name = (item['name'] ?? '').toString().toLowerCase();
      final nis = (item['nis'] ?? '').toString().toLowerCase();
      final dudi = (item['dudi_name'] ?? '').toString().toLowerCase();
      return name.contains(query) || nis.contains(query) || dudi.contains(query);
    }).toList();

    if (filtered.isEmpty) {
      return _buildEmptyState(
        title: 'Belum ada data siswa',
        subtitle: 'Data siswa di database kosong atau tidak cocok dengan pencarian.',
        btnText: '+ Tambah Siswa Baru',
        onAdd: _showTambahSiswaModal,
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final item = filtered[i];
        final id = item['id'] ?? 0;
        final name = item['name'] ?? 'Siswa';
        final nis = item['nis'] ?? '-';
        final kelas = item['class'] ?? '-';
        final username = item['username'] ?? (item['user']?['username'] ?? name);
        final userId = item['user_id'] ?? (item['user']?['id'] ?? id);

        return Container(
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
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Avatar & Name/NIS
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Center(
                      child: Icon(Icons.person_rounded, size: 24, color: Color(0xFF2563EB)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'NIS: $nis',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Info Box (Username Akun, Kelas, Password)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.school_outlined, size: 16, color: Color(0xFF2563EB)),
                        const SizedBox(width: 8),
                        const Text(
                          'Kelas: ',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                        Expanded(
                          child: Text(
                            kelas,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.alternate_email_rounded, size: 16, color: Color(0xFF2563EB)),
                        const SizedBox(width: 8),
                        const Text(
                          'Username Akun: ',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                        Expanded(
                          child: Text(
                            username,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.lock_outline_rounded, size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        const Text(
                          'Password: ********',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _showResetPasswordDialog(userId, name),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock_reset_rounded, size: 11, color: Color(0xFF2563EB)),
                                SizedBox(width: 3),
                                Text(
                                  'hashing',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Action Buttons Row (Diselaraskan dengan tombol Data Master lainnya)
              _buildCardActionButtons(
                onDelete: () => _confirmDeleteSiswa(id, name),
                onEdit: () => _showEditSiswaModal(item),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Helper seragam untuk tombol Aksi Kartu (Hapus Outline Merah + Edit Biru Solid)
  Widget _buildCardActionButtons({
    required VoidCallback onDelete,
    required VoidCallback onEdit,
  }) {
    return Row(
      children: [
        // Hapus Button (Red Outline)
        Expanded(
          child: InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                  SizedBox(width: 6),
                  Text(
                    'Hapus',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Edit Button (Solid Blue Button)
        Expanded(
          child: InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_note_rounded, size: 18, color: Colors.white),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── 2. GURU PEMBIMBING LIST & CARD (Matching Screenshot 3) ──
  Widget _buildGuruList() {
    final query = _searchController.text.toLowerCase();
    final filtered = _teachers.where((item) {
      final name = (item['name'] ?? '').toString().toLowerCase();
      final code = (item['teacher_code'] ?? '').toString().toLowerCase();
      final dept = (item['department'] ?? '').toString().toLowerCase();
      return name.contains(query) || code.contains(query) || dept.contains(query);
    }).toList();

    if (filtered.isEmpty) {
      return _buildEmptyState(
        title: 'Belum ada data guru pembimbing',
        subtitle: 'Data guru pembimbing di database kosong.',
        btnText: '+ Tambah Guru Baru',
        onAdd: _showTambahGuruModal,
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final item = filtered[i];
        final id = item['id'] ?? 0;
        final name = item['name'] ?? 'Guru';
        final department = item['department'] ?? 'Rekayasa Perangkat Lunak';
        final username = item['username'] ?? (item['user']?['username'] ?? 'budi_santoso');
        final studentCount = item['student_count'] ?? 8;
        final userId = item['user_id'] ?? (item['user']?['id'] ?? id);

        return Container(
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
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Avatar with green active dot (Matching Screenshot 3)
              Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFC7D2FE)),
                        ),
                        child: const Center(
                          child: Icon(Icons.assignment_ind_rounded, size: 24, color: Color(0xFF4F46E5)),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          department,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Info Box (Matching Screenshot 3)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.alternate_email_rounded, size: 14, color: Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Text(
                              'Akun Login\n@$username',
                              style: const TextStyle(
                                fontSize: 11,
                                height: 1.3,
                                color: Color(0xFF334155),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.people_alt_rounded, size: 14, color: Color(0xFF2563EB)),
                            const SizedBox(width: 6),
                            Text(
                              'Beban Bimbingan\n$studentCount Siswa',
                              style: const TextStyle(
                                fontSize: 11,
                                height: 1.3,
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.lock_outline_rounded, size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        const Text(
                          'Password: ********',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _showResetPasswordDialog(userId, name),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock_reset_rounded, size: 11, color: Color(0xFF2563EB)),
                                SizedBox(width: 3),
                                Text(
                                  'hashing',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Action Buttons Row (Diselaraskan dengan tombol Data Master lainnya)
              _buildCardActionButtons(
                onDelete: () => _confirmDeleteGuru(id, name),
                onEdit: () => _showEditGuruModal(item),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── 3. MITRA DU/DI LIST & CARD (Matching Mockup Data Master DUDI) ──
  Widget _buildDudiList() {
    final query = _searchController.text.toLowerCase().trim();
    final filtered = _locations.where((item) {
      final name = (item['name'] ?? '').toString().toLowerCase();
      final address = (item['address'] ?? '').toString().toLowerCase();
      return name.contains(query) || address.contains(query);
    }).toList();

    if (filtered.isEmpty) {
      return _buildEmptyState(
        title: 'Belum ada data mitra DU/DI',
        subtitle: 'Data lokasi mitra industri di database kosong atau tidak ditemukan.',
        btnText: '+ Tambah Mitra DU/DI',
        onAdd: _showTambahDudiModal,
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (ctx, i) {
        final item = filtered[i];
        final id = item['id'] ?? 0;
        final name = (item['name'] ?? 'Mitra Industri').toString();
        final address = (item['address'] ?? 'Lampung').toString();
        final double? lat = (item['latitude'] != null)
            ? double.tryParse(item['latitude'].toString())
            : null;
        final double? lng = (item['longitude'] != null)
            ? double.tryParse(item['longitude'].toString())
            : null;
        final bool hasCoordinates = lat != null && lng != null;
        final int radius = (item['radius'] != null)
            ? int.tryParse(item['radius'].toString()) ?? 100
            : 100;

        // Dynamic student count calculation: Placements API with fallback to dummy/seed count
        final int studentCount = _placementCountMap[id] ?? item['student_count'] ?? 0;

        // Determine icon based on company name category (matching mockup: Tech, Telkom, Bengkel)
        IconData companyIcon = Icons.developer_board_rounded;
        final lowerName = name.toLowerCase();
        if (lowerName.contains('bengkel') || lowerName.contains('auto') || lowerName.contains('motor') || lowerName.contains('mobil')) {
          companyIcon = Icons.directions_car_rounded;
        } else if (lowerName.contains('telkom') || lowerName.contains('witel') || lowerName.contains('jaringan') || lowerName.contains('media') || lowerName.contains('inovasi')) {
          companyIcon = Icons.hub_rounded;
        } else if (lowerName.contains('solusi') || lowerName.contains('teknologi') || lowerName.contains('software') || lowerName.contains('digital')) {
          companyIcon = Icons.developer_board_rounded;
        } else {
          companyIcon = Icons.domain_rounded;
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Row: Company Icon, Company Name, and "X Siswa PKL" Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDBEAFE)),
                    ),
                    child: Center(
                      child: Icon(companyIcon, size: 24, color: const Color(0xFF2563EB)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        height: 1.25,
                      ),
                    ),
                  ),
                  if (studentCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$studentCount Siswa PKL',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),

              // 2. Address Row with Location Pin Icon
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1.5),
                    child: Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      address,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Pembimbing Lapangan & Akun Login DUDI (Endpoint 4.5 & Relasi)
              Builder(
                builder: (_) {
                  dynamic supervisor;
                  final rawSupervisors = (item['field_supervisors'] as List<dynamic>?) ??
                      (item['fieldSupervisors'] as List<dynamic>?);
                  if (rawSupervisors != null && rawSupervisors.isNotEmpty) {
                    supervisor = rawSupervisors.first;
                  } else {
                    try {
                      supervisor = _fieldSupervisors.firstWhere(
                        (s) {
                          final org = (s['organization'] ?? '').toString().toLowerCase().trim();
                          final locName = name.toLowerCase().trim();
                          return org.isNotEmpty && (org == locName || locName.contains(org) || org.contains(locName));
                        },
                        orElse: () => null,
                      );
                    } catch (_) {}
                  }

                  if (supervisor != null) {
                    if (supervisor['user'] == null && _fieldSupervisors.isNotEmpty) {
                      final supId = supervisor['id'];
                      final found = _fieldSupervisors.firstWhere(
                        (s) => s['id'] == supId,
                        orElse: () => null,
                      );
                      if (found != null && found['user'] != null) {
                        supervisor = found;
                      }
                    }

                    final spvName = (supervisor['name'] ?? 'Pembimbing Lapangan').toString();
                    final userObj = supervisor['user'] as Map<String, dynamic>?;
                    final username = (userObj?['username'] ?? supervisor['username'] ?? supervisor['account']?['username'] ?? '-').toString();
                    final userId = int.tryParse((userObj?['id'] ?? supervisor['user_id'] ?? supervisor['id'] ?? 0).toString()) ?? 0;
                    final phone = (supervisor['phone'] ?? '').toString();

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.person_pin_rounded, size: 16, color: Color(0xFF2563EB)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      spvName,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                    ),
                                    const Text(
                                      'PIC / Pembimbing DU/DI Terhubung',
                                      style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                ),
                                child: const Text(
                                  'Akun DUDI',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.alternate_email_rounded, size: 14, color: Color(0xFF64748B)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Akun Login\n@$username',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      height: 1.3,
                                      color: Color(0xFF334155),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              if (phone.isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF64748B)),
                                    const SizedBox(width: 4),
                                    Text(
                                      phone,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.lock_outline_rounded, size: 16, color: Color(0xFF64748B)),
                              const SizedBox(width: 8),
                              const Text(
                                'Password: ********',
                                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(width: 8),
                              if (userId > 0)
                                InkWell(
                                  onTap: () => _showResetPasswordDialog(userId, spvName),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFFBFDBFE)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.lock_reset_rounded, size: 11, color: Color(0xFF2563EB)),
                                        SizedBox(width: 3),
                                        Text(
                                          'hashing',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF2563EB),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              InkWell(
                                onTap: () => _confirmUnlinkOrDeleteSupervisor(supervisor, item),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.person_remove_rounded, size: 13, color: Color(0xFFDC2626)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Hapus Akun Pembimbing',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFDC2626),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFEF3C7)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFD97706)),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Belum ada akun pembimbing yang terhubung',
                            style: TextStyle(fontSize: 11, color: Color(0xFFB45309), fontWeight: FontWeight.w600),
                          ),
                        ),
                        InkWell(
                          onTap: () => _showEditDudiModal(item),
                          child: const Text(
                            'Hubungkan',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // 3. Geofence & GPS Info Box (Matching Mockup)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  children: [
                    // GPS Coordinate Row with "Ubah ✎"
                    Row(
                      children: [
                        Icon(
                          hasCoordinates ? Icons.near_me_outlined : Icons.location_searching_rounded,
                          size: 16,
                          color: hasCoordinates ? const Color(0xFF0284C7) : const Color(0xFFD97706),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: hasCoordinates
                              ? RichText(
                                  text: TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: 'GPS: ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF475569),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF0F172A),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFFDE68A)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.gps_off_rounded, size: 12, color: Color(0xFFD97706)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Menunggu GPS dari DU/DI',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFFB45309),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Radius Presensi Row with Pill Badge (Fixed 100m)
                    Row(
                      children: [
                        const Text(
                          'Radius Presensi:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFDBEAFE)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2563EB),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                radius == 100 ? '100 Meter (Standar)' : '$radius Meter',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E40AF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 4. Action Buttons Row (Hapus & Edit)
              _buildCardActionButtons(
                onDelete: () => _confirmDeleteDudi(id, name),
                onEdit: () => _showEditDudiModal(item),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── EMPTY STATE ──
  Widget _buildEmptyState({
    required String title,
    required String subtitle,
    required String btnText,
    required VoidCallback onAdd,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.folder_open_rounded, size: 36, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: Text(btnText),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ── MODALS: TAMBAH / EDIT SISWA ──
  void _showTambahSiswaModal() {
    final nameCtrl = TextEditingController();
    final nisCtrl = TextEditingController();
    final classCtrl = TextEditingController(text: 'XII RPL 1');
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: 'password');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text('Tambah Siswa Baru', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(),
              _buildFormInput('Nama Lengkap', nameCtrl, 'Contoh: M. Farel Ardiansyah'),
              _buildFormInput('NIS', nisCtrl, 'Contoh: 92031'),
              _buildFormInput('Kelas', classCtrl, 'Contoh: XII RPL 1'),
              _buildFormInput('Username Akun', userCtrl, 'Contoh: farel_ardiansyah'),
              _buildFormInput('Password Akun', passCtrl, 'Minimal 8 karakter', isPassword: true),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty || nisCtrl.text.isEmpty || userCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Harap lengkapi semua bidang wajib!')),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    // ========================================================================
                    // PANGGILAN API BACKEND: 4.3 Master Data Siswa (POST)
                    // Endpoint: POST /api/admin/students
                    // Controller: App\Http\Controllers\Api\Admin\StudentController@store
                    // Body: nis, name, class, major, phone, username, email, password
                    // Deskripsi: Membuat akun pengguna role student dan profil siswa
                    // ========================================================================
                    final res = await AdminService.createStudent(
                      name: nameCtrl.text,
                      nis: nisCtrl.text,
                      className: classCtrl.text,
                      username: userCtrl.text,
                      password: passCtrl.text,
                    );
                    if (!mounted) return;
                    if (res['success'] == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(res['message'] ?? 'Siswa berhasil ditambahkan!'), backgroundColor: Colors.green),
                      );
                      await _fetchData();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res['message'] ?? 'Gagal menambahkan siswa.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Simpan Siswa', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditSiswaModal(dynamic item) {
    final nameCtrl = TextEditingController(text: item['name'] ?? '');
    final nisCtrl = TextEditingController(text: item['nis'] ?? '');
    final classCtrl = TextEditingController(text: item['class'] ?? 'XII RPL 1');
    final id = item['id'] ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text('Edit Data Siswa', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(),
              _buildFormInput('Nama Lengkap', nameCtrl, ''),
              _buildFormInput('NIS', nisCtrl, ''),
              _buildFormInput('Kelas', classCtrl, ''),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    // ========================================================================
                    // PANGGILAN API BACKEND: 4.3 Master Data Siswa (PUT)
                    // Endpoint: PUT /api/admin/students/{id}
                    // Controller: App\Http\Controllers\Api\Admin\StudentController@update
                    // Body: nis, name, class, major, phone
                    // Deskripsi: Memperbarui profil siswa dan sinkronisasi nama ke akun user
                    // ========================================================================
                    await AdminService.updateStudent(
                      id: id,
                      name: nameCtrl.text,
                      nis: nisCtrl.text,
                      className: classCtrl.text,
                    );
                    if (!mounted) return;
                    setState(() {
                      item['name'] = nameCtrl.text;
                      item['nis'] = nisCtrl.text;
                      item['class'] = classCtrl.text;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Data siswa berhasil diperbarui!'), backgroundColor: Colors.green),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Perbarui Data', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteSiswa(int id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Akun Siswa', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Apakah Anda yakin ingin menghapus akun siswa "$name"? Seluruh data akun siswa ini akan dihapus permanen dari sistem.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final res = await AdminService.deleteStudent(id);
              if (!mounted) return;
              if (res['success'] == true) {
                await _fetchData();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(res['message'] ?? 'Akun siswa berhasil dihapus!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(res['message'] ?? 'Gagal menghapus akun siswa.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // ── MODALS: TAMBAH / EDIT GURU ──
  void _showTambahGuruModal() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: 'password');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text('Tambah Guru Pembimbing', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(),
              _buildFormInput('Nama Lengkap & Gelar', nameCtrl, 'Contoh: Drs. Budi Santoso, M.Pd'),
              _buildFormInput('Kode Guru / NIP', codeCtrl, 'Contoh: GT001'),
              _buildFormInput('Username Akun', userCtrl, 'Contoh: budi_santoso'),
              _buildFormInput('Password Akun', passCtrl, 'Minimal 8 karakter', isPassword: true),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty || codeCtrl.text.isEmpty || userCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Harap lengkapi semua bidang wajib!')),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    // ========================================================================
                    // PANGGILAN API BACKEND: 4.4 Master Data Guru Pembimbing (POST)
                    // Endpoint: POST /api/admin/teachers
                    // Controller: App\Http\Controllers\Api\Admin\TeacherController@store
                    // Body: teacher_code, name, phone, username, email, password
                    // Deskripsi: Membuat akun pengguna role teacher dan data guru pembimbing
                    // ========================================================================
                    final res = await AdminService.createTeacher(
                      name: nameCtrl.text,
                      teacherCode: codeCtrl.text,
                      username: userCtrl.text,
                      password: passCtrl.text,
                    );
                    if (!mounted) return;
                    if (res['success'] == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(res['message'] ?? 'Guru berhasil ditambahkan!'), backgroundColor: Colors.green),
                      );
                      await _fetchData();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res['message'] ?? 'Gagal menambahkan guru.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Simpan Guru', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditGuruModal(dynamic item) {
    final nameCtrl = TextEditingController(text: item['name'] ?? '');
    final codeCtrl = TextEditingController(text: item['teacher_code'] ?? '');
    final id = item['id'] ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text('Edit Data Guru', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(),
              _buildFormInput('Nama Lengkap', nameCtrl, ''),
              _buildFormInput('Kode Guru / NIP', codeCtrl, ''),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    // ========================================================================
                    // PANGGILAN API BACKEND: 4.4 Master Data Guru Pembimbing (PUT)
                    // Endpoint: PUT /api/admin/teachers/{id}
                    // Controller: App\Http\Controllers\Api\Admin\TeacherController@update
                    // Body: teacher_code, name, phone
                    // Deskripsi: Memperbarui profil guru pembimbing
                    // ========================================================================
                    await AdminService.updateTeacher(id: id, name: nameCtrl.text, teacherCode: codeCtrl.text);
                    if (!mounted) return;
                    setState(() {
                      item['name'] = nameCtrl.text;
                      item['teacher_code'] = codeCtrl.text;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Data guru berhasil diperbarui!'), backgroundColor: Colors.green),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Perbarui Data', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteGuru(int id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Akun Guru', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Apakah Anda yakin ingin menghapus akun guru "$name"? Seluruh data akun guru ini akan dihapus permanen dari sistem.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final res = await AdminService.deleteTeacher(id);
              if (!mounted) return;
              if (res['success'] == true) {
                await _fetchData();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(res['message'] ?? 'Akun guru berhasil dihapus!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(res['message'] ?? 'Gagal menghapus akun guru.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // ── MODALS: TAMBAH MITRA DU/DI (locations) ──
  // ── MODALS: TAMBAH MITRA DU/DI & AKUN PEMBIMBING (Endpoint 4.5 & 4.6 Saling Terhubung) ──
  void _showTambahDudiModal() {
    // 1. Controller Informasi Mitra & Lokasi PKL (4.6)
    final nameCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final latCtrl = TextEditingController();
    final lngCtrl = TextEditingController();
    const int lockedRadius = 100; // Radius tetap 100m sesuai permintaan

    // 2. Controller Akun Pembimbing Lapangan DU/DI (4.5)
    final spvNameCtrl = TextEditingController();
    final spvPhoneCtrl = TextEditingController();
    final spvUsernameCtrl = TextEditingController();
    final spvPasswordCtrl = TextEditingController(text: 'dudi12345');
    final spvEmailCtrl = TextEditingController();

    bool obscurePassword = true;
    bool isSubmitting = false;

    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 20,
            ),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.9,
            ),
            child: SingleChildScrollView(
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
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.add_business_rounded, size: 20, color: Color(0xFF2563EB)),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tambah Mitra DU/DI & Akun',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              'Daftarkan instansi dan buat akun login pembimbing',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                        onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // ── BAGIAN 1: INFORMASI MITRA & LOKASI PKL (Endpoint 4.6) ──
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.apartment_rounded, size: 16, color: Color(0xFF2563EB)),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '1. INFORMASI MITRA & LOKASI PKL',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF1E40AF), letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFormInput(
                    'Nama Mitra Industri / Perusahaan *',
                    nameCtrl,
                    'Contoh: PT Solusi Teknologi Mandiri',
                  ),
                  _buildFormInput(
                    'Alamat Lengkap Perusahaan *',
                    addrCtrl,
                    'Contoh: Jl. ZA. Pagar Alam No. 42, Bandar Lampung',
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFormInput(
                          'Latitude GPS (Opsional)',
                          latCtrl,
                          'Bisa dikosongkan',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFormInput(
                          'Longitude GPS (Opsional)',
                          lngCtrl,
                          'Bisa dikosongkan',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        ),
                      ),
                    ],
                  ),

                  // Radius 100m Terstandar (Tanpa Pilihan Sesuai Permintaan)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.radar_rounded, size: 18, color: Color(0xFF2563EB)),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Radius Geofencing Presensi',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Ditetapkan 100 Meter untuk presensi akurat siswa di lokasi',
                                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '100 Meter',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── BAGIAN 2: AKUN PEMBIMBING DU/DI (Endpoint 4.5) ──
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.person_pin_rounded, size: 16, color: Color(0xFF2563EB)),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '2. AKUN PEMBIMBING LAPANGAN / DUDI (LOGIN)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF1E40AF), letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Akun ini otomatis dibuat di sistem agar pembimbing DU/DI dapat login ke aplikasi SMART PKL pada tab DUDI.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
                  ),
                  const SizedBox(height: 12),
                  _buildFormInput(
                    'Nama Pembimbing / PIC Lapangan *',
                    spvNameCtrl,
                    'Contoh: Hendra Gunawan',
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFormInput(
                          'No. HP / WhatsApp PIC *',
                          spvPhoneCtrl,
                          'Contoh: 081234567890',
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFormInput(
                          'Email PIC (Opsional)',
                          spvEmailCtrl,
                          'pic@perusahaan.com',
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                    ],
                  ),

                  // Username Field dengan tombol Buat Otomatis
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Username Login DU/DI *',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                            InkWell(
                              onTap: () {
                                if (spvNameCtrl.text.trim().isNotEmpty) {
                                  final clean = spvNameCtrl.text
                                      .trim()
                                      .toLowerCase()
                                      .replaceAll(RegExp(r'[^a-z0-9]'), '_');
                                  setModalState(() {
                                    spvUsernameCtrl.text = 'dudi_$clean';
                                  });
                                }
                              },
                              child: const Text(
                                'Buat Otomatis',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: spvUsernameCtrl,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Contoh: dudi_hendra',
                            hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            prefixIcon: const Icon(Icons.alternate_email_rounded, size: 18, color: Color(0xFF64748B)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
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

                  // Password Field dengan Toggle Visibility
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Password Akun DU/DI (Min. 8 Karakter) *',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: spvPasswordCtrl,
                          obscureText: obscurePassword,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Minimal 8 karakter',
                            hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF64748B)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                size: 18,
                                color: const Color(0xFF64748B),
                              ),
                              onPressed: () {
                                setModalState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
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

                  // Tombol Simpan Terhubung (4.5 & 4.6)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final companyName = nameCtrl.text.trim();
                              final companyAddr = addrCtrl.text.trim();
                              final supervisorName = spvNameCtrl.text.trim();
                              final supervisorPhone = spvPhoneCtrl.text.trim();
                              final username = spvUsernameCtrl.text.trim();
                              final password = spvPasswordCtrl.text.trim();
                              final email = spvEmailCtrl.text.trim();

                              if (companyName.isEmpty || companyAddr.isEmpty) {
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('Harap lengkapi nama industri dan alamat lengkap!')),
                                );
                                return;
                              }

                              if (supervisorName.isEmpty) {
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('Harap masukkan nama pembimbing lapangan / PIC!')),
                                );
                                return;
                              }

                              if (username.isEmpty || password.length < 8) {
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('Username wajib diisi dan password minimal 8 karakter!')),
                                );
                                return;
                              }

                              setModalState(() {
                                isSubmitting = true;
                              });

                              final lat = latCtrl.text.trim().isNotEmpty ? double.tryParse(latCtrl.text.trim()) : null;
                              final lng = lngCtrl.text.trim().isNotEmpty ? double.tryParse(lngCtrl.text.trim()) : null;

                              // Langkah 1: Buat Akun Pembimbing Lapangan DU/DI (POST /api/admin/field-supervisors)
                              final supervisorRes = await AdminService.createFieldSupervisor(
                                name: supervisorName,
                                organization: companyName,
                                phone: supervisorPhone,
                                username: username,
                                email: email.isNotEmpty ? email : '$username@dudi.id',
                                password: password,
                              );

                              if (supervisorRes['success'] != true) {
                                setModalState(() {
                                  isSubmitting = false;
                                });
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(supervisorRes['message'] ?? 'Gagal membuat akun pembimbing DU/DI.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              // Ambil ID supervisor yang baru dibuat
                              int? newSupervisorId;
                              final spvData = supervisorRes['data'];
                              if (spvData != null) {
                                if (spvData['id'] != null) {
                                  newSupervisorId = int.tryParse(spvData['id'].toString());
                                } else if (spvData['supervisor'] != null && spvData['supervisor']['id'] != null) {
                                  newSupervisorId = int.tryParse(spvData['supervisor']['id'].toString());
                                }
                              }

                              // Langkah 2: Buat Master Lokasi PKL dan Hubungkan Pembimbing (POST /api/admin/locations)
                              final locRes = await AdminService.createLocation(
                                name: companyName,
                                address: companyAddr,
                                latitude: lat,
                                longitude: lng,
                                radius: lockedRadius,
                                fieldSupervisorIds: newSupervisorId != null ? [newSupervisorId] : null,
                              );

                              if (!mounted) return;
                              if (ctx.mounted) Navigator.pop(ctx);

                              if (locRes['success'] == true) {
                                await _fetchData();
                                // Langkah 3: Munculkan Dialog Kredensial Aku DU/DI untuk diserahkan ke user
                                _showKredensialDudiDialog(
                                  companyName: companyName,
                                  supervisorName: supervisorName,
                                  username: username,
                                  password: password,
                                  phone: supervisorPhone,
                                );
                              } else {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(locRes['message'] ?? 'Lokasi gagal dibuat, akun pembimbing sudah terdaftar.'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                await _fetchData();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: isSubmitting
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                ),
                                SizedBox(width: 10),
                                Text('Mendaftarkan Mitra & Akun DU/DI...', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              ],
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('Simpan Mitra & Buat Akun DU/DI', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── DIALOG KREDENSIAL AKUN DU/DI BARU ──
  void _showKredensialDudiDialog({
    required String companyName,
    required String supervisorName,
    required String username,
    required String password,
    String? phone,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_user_rounded, color: Color(0xFF2563EB), size: 36),
            ),
            const SizedBox(height: 14),
            const Text(
              'Mitra & Akun DU/DI Siap!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Berikan kredensial login berikut kepada pihak pembimbing DU/DI agar dapat login ke aplikasi SMART PKL pada tab DUDI.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
            ),
            const SizedBox(height: 16),

            // Card Kredensial
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
                  _buildCredentialRow('Perusahaan / Mitra', companyName, Icons.apartment_rounded),
                  const Divider(height: 16),
                  _buildCredentialRow('Pembimbing / PIC', supervisorName, Icons.person_rounded),
                  const Divider(height: 16),
                  _buildCopyableCredentialRow('Username Login', username, Icons.alternate_email_rounded),
                  const Divider(height: 16),
                  _buildCopyableCredentialRow('Password Login', password, Icons.lock_outline_rounded),
                  const Divider(height: 16),
                  _buildCredentialRow('Role Aplikasi', 'DUDI (Field Supervisor)', Icons.badge_outlined, valueColor: const Color(0xFF2563EB)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Tutup & Selesai', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor ?? const Color(0xFF0F172A),
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildCopyableCredentialRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: 0.5),
            textAlign: TextAlign.end,
          ),
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$label berhasil disalin!'),
                duration: const Duration(seconds: 2),
                backgroundColor: const Color(0xFF16A34A),
              ),
            );
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF2563EB)),
          ),
        ),
      ],
    );
  }

  // ── MODAL: EDIT DATA MITRA DU/DI (locations) ──
  void _showEditDudiModal(dynamic item) {
    final id = item['id'] ?? 0;
    final nameCtrl = TextEditingController(text: (item['name'] ?? '').toString());
    final addrCtrl = TextEditingController(text: (item['address'] ?? '').toString());
    final double? initialLat = (item['latitude'] != null)
        ? double.tryParse(item['latitude'].toString())
        : null;
    final double? initialLng = (item['longitude'] != null)
        ? double.tryParse(item['longitude'].toString())
        : null;

    final latCtrl = TextEditingController(text: initialLat != null ? initialLat.toStringAsFixed(6) : '');
    final lngCtrl = TextEditingController(text: initialLng != null ? initialLng.toStringAsFixed(6) : '');
    const int lockedRadius = 100;

    // Supervisor yang sedang terhubung saat ini
    int? selectedSupervisorId;
    final rawSupervisors = (item['field_supervisors'] as List<dynamic>?) ??
        (item['fieldSupervisors'] as List<dynamic>?);
    if (rawSupervisors != null && rawSupervisors.isNotEmpty) {
      selectedSupervisorId = int.tryParse(rawSupervisors.first['id'].toString());
    }

    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
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
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.edit_note_rounded, size: 20, color: Color(0xFF2563EB)),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Data Mitra DU/DI',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              'Perbarui profil industri dan pembimbing lapangan',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildFormInput('Nama Mitra Industri / Perusahaan', nameCtrl, ''),
                  _buildFormInput('Alamat Lengkap Perusahaan', addrCtrl, ''),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFormInput(
                          'Latitude GPS',
                          latCtrl,
                          '-5.378921',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFormInput(
                          'Longitude GPS',
                          lngCtrl,
                          '105.251412',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        ),
                      ),
                    ],
                  ),

                  // Hubungkan Pembimbing Lapangan DU/DI
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tugaskan Pembimbing Lapangan DU/DI',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              isExpanded: true,
                              value: selectedSupervisorId,
                              hint: const Text('Pilih Pembimbing Lapangan', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                              items: _fieldSupervisors.map((spv) {
                                final spvId = int.tryParse(spv['id'].toString()) ?? 0;
                                final spvName = spv['name'] ?? 'Pembimbing';
                                final spvUser = spv['user']?['username'] ?? spv['username'] ?? '';
                                return DropdownMenuItem<int>(
                                  value: spvId,
                                  child: Text(
                                    '$spvName (@$spvUser)',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setModalState(() {
                                  selectedSupervisorId = val;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Radius 100 Meter Terstandar (Tanpa Pilihan Sesuai Permintaan)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.radar_rounded, size: 18, color: Color(0xFF2563EB)),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Radius Geofence: 100 Meter (Standar Presensi)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: const Text('100m', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final lat = latCtrl.text.trim().isNotEmpty ? double.tryParse(latCtrl.text.trim()) : null;
                        final lng = lngCtrl.text.trim().isNotEmpty ? double.tryParse(lngCtrl.text.trim()) : null;

                        Navigator.pop(ctx);

                        final res = await AdminService.updateLocation(
                          id: id,
                          name: nameCtrl.text.trim(),
                          address: addrCtrl.text.trim(),
                          latitude: lat,
                          longitude: lng,
                          radius: lockedRadius,
                          fieldSupervisorIds: selectedSupervisorId != null ? [selectedSupervisorId!] : null,
                        );

                        if (!mounted) return;
                        await _fetchData();

                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(res['message'] ?? 'Data mitra berhasil diperbarui!'),
                            backgroundColor: res['success'] == true ? Colors.green : Colors.blueGrey,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Perbarui Data Mitra', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }



  // ── CONFIRM DELETE / DEACTIVATE MITRA DU/DI (locations) ──
  void _confirmDeleteDudi(int id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('Hapus Mitra DU/DI', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
                children: [
                  const TextSpan(text: 'Apakah Anda yakin ingin menghapus data mitra '),
                  TextSpan(
                    text: '"$name"',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
                  const TextSpan(text: '?'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sesuai ketentuan backend, jika mitra memiliki riwayat penempatan siswa PKL, status lokasi akan otomatis dinonaktifkan (is_active = false) agar riwayat penempatan tetap terjaga rapi.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF991B1B), height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final res = await AdminService.deleteLocation(id);

              if (!mounted) return;
              if (res['success'] == true) {
                await _fetchData();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(res['message'] ?? 'Data mitra berhasil dihapus.'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(res['message'] ?? 'Gagal menghapus mitra.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Hapus Mitra', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── DIALOG HAPUS AKUN PEMBIMBING DU/DI ──
  void _confirmUnlinkOrDeleteSupervisor(dynamic supervisor, dynamic location) {
    final spvName = supervisor['name'] ?? 'Pembimbing DU/DI';
    final locName = location['name'] ?? 'Mitra DU/DI';
    final spvId = int.tryParse(supervisor['id']?.toString() ?? '0') ?? 0;
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 22),
            SizedBox(width: 8),
            Text('Hapus Akun Pembimbing', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus akun pembimbing "$spvName" pada mitra "$locName"? Tindakan ini akan menghapus akun secara permanen.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (spvId > 0) {
                final res = await AdminService.deleteFieldSupervisor(spvId);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(res['message']?.toString() ?? 'Akun pembimbing berhasil dihapus.'),
                    backgroundColor: res['success'] == true ? const Color(0xFF16A34A) : Colors.red,
                  ),
                );
                _fetchData();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus Akun'),
          ),
        ],
      ),
    );
  }

  // ── RESET PASSWORD MODAL (Connected to [hashing] badge) ──
  void _showResetPasswordDialog(int userId, String name) {
    final passCtrl = TextEditingController(text: 'password123');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.lock_reset_rounded, color: Color(0xFF2563EB)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Reset Password: $name',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Password akun dienkripsi menggunakan hashing Bcrypt yang aman di database. Administrator dapat mereset password baru untuk pengguna ini.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: passCtrl,
              decoration: InputDecoration(
                labelText: 'Password Baru',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await AdminService.resetPassword(userId: userId, newPassword: passCtrl.text);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(res['message'] ?? 'Password berhasil direset!'),
                  backgroundColor: res['success'] == true ? Colors.green : Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset Password'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormInput(
    String label,
    TextEditingController ctrl,
    String hint, {
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            obscureText: isPassword,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. PENEMPATAN SISWA LIST & CARD ──
  Widget _buildPenempatanList() {
    final query = _searchController.text.toLowerCase();
    final filtered = _placements.where((p) {
      final student = p['student'] as Map<String, dynamic>? ?? {};
      final loc = p['location'] as Map<String, dynamic>? ?? {};
      final teacher = p['teacher'] as Map<String, dynamic>? ?? {};
      final status = (p['status'] ?? 'active').toString().toLowerCase();

      // Filter Status (Hanya Aktif dan Nonaktif)
      if (_placementFilterStatus == 'active' && status != 'active') {
        return false;
      }
      if (_placementFilterStatus == 'inactive' && status == 'active') {
        return false;
      }

      // Filter Search
      if (query.isNotEmpty) {
        final sName = (student['name'] ?? '').toString().toLowerCase();
        final sNis = (student['nis'] ?? '').toString().toLowerCase();
        final lName = (loc['name'] ?? '').toString().toLowerCase();
        final tName = (teacher['name'] ?? '').toString().toLowerCase();
        return sName.contains(query) || sNis.contains(query) || lName.contains(query) || tName.contains(query);
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status Filter Chips (Hanya Aktif dan Nonaktif)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildPlacementFilterChip('all', 'Semua Status'),
              const SizedBox(width: 8),
              _buildPlacementFilterChip('active', 'Aktif'),
              const SizedBox(width: 8),
              _buildPlacementFilterChip('inactive', 'Nonaktif'),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (filtered.isEmpty)
          _buildEmptyState(
            title: 'Belum ada data penempatan',
            subtitle: 'Data penempatan PKL belum tersedia atau tidak cocok dengan filter pencarian.',
            btnText: '+ Buat Penempatan Baru',
            onAdd: _showTambahPenempatanModal,
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) {
              final item = filtered[i];
              return _buildPlacementCard(item);
            },
          ),
      ],
    );
  }

  Widget _buildPlacementFilterChip(String statusKey, String label) {
    final isSelected = _placementFilterStatus == statusKey;
    return InkWell(
      onTap: () {
        setState(() {
          _placementFilterStatus = statusKey;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D9488) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0D9488) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildPlacementCard(dynamic item) {
    final id = item['id'] ?? 0;
    final student = item['student'] as Map<String, dynamic>? ?? {};
    final loc = item['location'] as Map<String, dynamic>? ?? {};
    final teacher = item['teacher'] as Map<String, dynamic>? ?? {};
    final supervisor = item['field_supervisor'] as Map<String, dynamic>?;
    final period = item['period'] as Map<String, dynamic>? ?? {};

    final studentName = (student['name'] ?? 'Siswa').toString();
    final studentNis = (student['nis'] ?? '-').toString();
    final studentClass = (student['class'] ?? 'XII RPL').toString();
    final locName = (loc['name'] ?? 'Mitra DU/DI').toString();
    final locAddress = (loc['address'] ?? 'Alamat mitra industri').toString();
    final teacherName = (teacher['name'] ?? 'Guru Pembimbing').toString();
    final teacherCode = (teacher['teacher_code'] ?? '').toString();
    final supervisorName = supervisor != null ? (supervisor['name'] ?? 'Pembimbing Lapangan').toString() : 'Belum Ditugaskan';
    final supervisorOrg = supervisor != null ? (supervisor['organization'] ?? '').toString() : '';
    final periodName = (period['name'] ?? 'Periode PKL').toString();
    final startDate = (item['start_date'] ?? '-').toString();
    final endDate = (item['end_date'] ?? '-').toString();
    final status = (item['status'] ?? 'active').toString();

    // Status visual colors: hanya Aktif dan Nonaktif
    final bool isActive = status == 'active';
    final Color statusBgColor = isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9);
    final Color statusTextColor = isActive ? const Color(0xFF166534) : const Color(0xFF64748B);
    final String statusLabel = isActive ? 'Aktif' : 'Nonaktif';

    return Container(
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
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Student Avatar, Name, NIS, Status Badge
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF99F6E4)),
                ),
                child: const Center(
                  child: Icon(Icons.person_pin_circle_rounded, size: 24, color: Color(0xFF0D9488)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'NIS: $studentNis • $studentClass',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusTextColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Detail Container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Mitra DU/DI
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.business_rounded, size: 16, color: Color(0xFF0284C7)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            locName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            locAddress,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                ),

                // 2. Guru Pembimbing & Pembimbing DU/DI
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.school_outlined, size: 14, color: Color(0xFF4F46E5)),
                              SizedBox(width: 4),
                              Text(
                                'Guru Pembimbing:',
                                style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            teacherName,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (teacherCode.isNotEmpty)
                            Text('Kode: $teacherCode', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 36, color: const Color(0xFFE2E8F0)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.assignment_ind_outlined, size: 14, color: Color(0xFF0D9488)),
                              SizedBox(width: 4),
                              Text(
                                'Pembimbing DU/DI:',
                                style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            supervisorName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: supervisor != null ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (supervisorOrg.isNotEmpty)
                            Text(supervisorOrg, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                ),

                // 3. Periode & Tanggal
                Row(
                  children: [
                    const Icon(Icons.date_range_rounded, size: 14, color: Color(0xFFD97706)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '$periodName • $startDate s/d $endDate',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Actions: Toggle Aktif / Nonaktif & Edit Penempatan
          Row(
            children: [
              if (isActive)
                InkWell(
                  onTap: () => _confirmDeletePenempatan(id, studentName, locName),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.block_rounded, size: 15, color: Color(0xFFDC2626)),
                        SizedBox(width: 4),
                        Text(
                          'Nonaktifkan',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                InkWell(
                  onTap: () => _handleToggleStatusPenempatan(id, false),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 15, color: Color(0xFF16A34A)),
                        SizedBox(width: 4),
                        Text(
                          'Aktifkan Kembali',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
                        ),
                      ],
                    ),
                  ),
                ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showEditPenempatanModal(item),
                icon: const Icon(Icons.edit_note_rounded, size: 16),
                label: const Text('Edit Penempatan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── MODAL: TAMBAH PENEMPATAN SISWA (placements) ──
  void _showTambahPenempatanModal() {
    int? selectedStudentId = _students.isNotEmpty ? _students.first['id'] as int? : null;
    int? selectedLocationId = _locations.isNotEmpty ? _locations.first['id'] as int? : null;
    int? selectedTeacherId = _teachers.isNotEmpty ? _teachers.first['id'] as int? : null;
    int? selectedSupervisorId;
    int? selectedPeriodId = _periods.isNotEmpty ? _periods.first['id'] as int? : null;

    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 90));
    String status = 'active';

    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setModalState) {
          final startStr = "${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
          final endStr = "${endDate.year.toString().padLeft(4, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCCFBF1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.assignment_ind_rounded, size: 20, color: Color(0xFF0D9488)),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tambah Penempatan PKL',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              'Tempatkan siswa ke mitra DU/DI & guru pembimbing',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // 1. Pilih Siswa
                  const Text('Pilih Siswa PKL *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        value: selectedStudentId,
                        hint: const Text('Pilih Siswa', style: TextStyle(fontSize: 13)),
                        items: _students.map<DropdownMenuItem<int>>((s) {
                          final id = s['id'] as int;
                          final name = (s['name'] ?? 'Siswa').toString();
                          final nis = (s['nis'] ?? '-').toString();
                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text('$name ($nis)', style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setModalState(() => selectedStudentId = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Pilih Mitra DU/DI
                  const Text('Pilih Mitra DU/DI (Lokasi PKL) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        value: selectedLocationId,
                        hint: const Text('Pilih Mitra DU/DI', style: TextStyle(fontSize: 13)),
                        items: _locations.map<DropdownMenuItem<int>>((l) {
                          final id = l['id'] as int;
                          final name = (l['name'] ?? 'Lokasi').toString();
                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text(name, style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setModalState(() {
                            selectedLocationId = val;
                            if (val != null) {
                              final loc = _locations.firstWhere((item) => item['id'] == val, orElse: () => null);
                              if (loc != null && loc['field_supervisors'] is List && (loc['field_supervisors'] as List).isNotEmpty) {
                                final spv = (loc['field_supervisors'] as List).first;
                                selectedSupervisorId = int.tryParse(spv['id']?.toString() ?? '');
                              }
                            }
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. Pilih Guru Pembimbing
                  const Text('Pilih Guru Pembimbing Sekolah *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        value: selectedTeacherId,
                        hint: const Text('Pilih Guru Pembimbing', style: TextStyle(fontSize: 13)),
                        items: _teachers.map<DropdownMenuItem<int>>((t) {
                          final id = t['id'] as int;
                          final name = (t['name'] ?? 'Guru').toString();
                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text(name, style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setModalState(() => selectedTeacherId = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4. Pilih Pembimbing Lapangan DU/DI (Opsional)
                  const Text('Pilih Pembimbing Lapangan DU/DI (Opsional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        isExpanded: true,
                        value: selectedSupervisorId,
                        hint: const Text('Tanpa Pembimbing Lapangan', style: TextStyle(fontSize: 13)),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('-- Belum Ditugaskan --', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                          ),
                          ..._fieldSupervisors.map<DropdownMenuItem<int?>>((fs) {
                            final id = fs['id'] as int;
                            final name = (fs['name'] ?? 'Pembimbing').toString();
                            final org = (fs['organization'] ?? '').toString();
                            return DropdownMenuItem<int?>(
                              value: id,
                              child: Text(org.isNotEmpty ? '$name ($org)' : name, style: const TextStyle(fontSize: 13)),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          setModalState(() => selectedSupervisorId = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 5. Periode PKL
                  const Text('Pilih Periode PKL *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        value: selectedPeriodId ?? (_periods.isNotEmpty ? _periods.first['id'] as int? : 1),
                        hint: const Text('Pilih Periode', style: TextStyle(fontSize: 13)),
                        items: _periods.isNotEmpty
                            ? _periods.map<DropdownMenuItem<int>>((p) {
                                final id = p['id'] as int;
                                final name = (p['name'] ?? 'Periode PKL').toString();
                                return DropdownMenuItem<int>(
                                  value: id,
                                  child: Text(name, style: const TextStyle(fontSize: 13)),
                                );
                              }).toList()
                            : [
                                const DropdownMenuItem<int>(
                                  value: 1,
                                  child: Text('Periode PKL Genap 2024/2025', style: TextStyle(fontSize: 13)),
                                ),
                              ],
                        onChanged: (val) {
                          setModalState(() => selectedPeriodId = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 6. Tanggal Mulai & Tanggal Selesai
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tanggal Mulai *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: startDate,
                                  firstDate: DateTime(2023),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  setModalState(() => startDate = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF2563EB)),
                                    const SizedBox(width: 8),
                                    Text(startStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tanggal Selesai *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: endDate.isAfter(startDate) ? endDate : startDate.add(const Duration(days: 1)),
                                  firstDate: startDate,
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  setModalState(() => endDate = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF0D9488)),
                                    const SizedBox(width: 8),
                                    Text(endStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 7. Status Penempatan
                  const Text('Status Penempatan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: status,
                        items: const [
                          DropdownMenuItem(value: 'active', child: Text('Aktif (Sedang Berjalan)')),
                          DropdownMenuItem(value: 'inactive', child: Text('Nonaktif')),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => status = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (selectedStudentId == null || selectedLocationId == null || selectedTeacherId == null) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Harap pilih Siswa, Mitra DU/DI, dan Guru Pembimbing!')),
                          );
                          return;
                        }

                        Navigator.pop(ctx);

                        // ========================================================================
                        // PANGGILAN API BACKEND: 4.8 Master Data Penempatan Siswa (POST)
                        // Endpoint: POST /api/admin/placements
                        // Controller: App\Http\Controllers\Api\Admin\PlacementController@store
                        // Body: student_id, location_id, period_id, teacher_id, field_supervisor_id, start_date, end_date, status
                        // Deskripsi: Menempatkan siswa pada lokasi PKL dengan validasi agar siswa tidak memiliki lebih dari 1 penempatan aktif
                        // ========================================================================
                        final res = await AdminService.createPlacement(
                          studentId: selectedStudentId!,
                          locationId: selectedLocationId!,
                          periodId: selectedPeriodId ?? 1,
                          teacherId: selectedTeacherId!,
                          fieldSupervisorId: selectedSupervisorId,
                          startDate: startStr,
                          endDate: endStr,
                          status: status,
                        );

                        if (!mounted) return;
                        if (res['success'] == true) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(res['message'] ?? 'Penempatan siswa berhasil disimpan!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          await _fetchData();
                        } else {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(res['message'] ?? 'Gagal membuat penempatan.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_turned_in_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Simpan Penempatan Siswa', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── MODAL: EDIT DATA PENEMPATAN SISWA (placements) ──
  void _showEditPenempatanModal(dynamic item) {
    final id = item['id'] as int? ?? 0;
    int? selectedLocationId = item['location_id'] ?? item['location']?['id'];
    int? selectedTeacherId = item['teacher_id'] ?? item['teacher']?['id'];
    int? selectedSupervisorId = item['field_supervisor_id'] ?? item['field_supervisor']?['id'];
    String status = (item['status'] ?? 'active').toString();

    DateTime startDate = DateTime.tryParse((item['start_date'] ?? '').toString()) ?? DateTime.now();
    DateTime endDate = DateTime.tryParse((item['end_date'] ?? '').toString()) ?? DateTime.now().add(const Duration(days: 90));

    final student = item['student'] as Map<String, dynamic>? ?? {};
    final studentName = (student['name'] ?? 'Siswa').toString();
    final studentNis = (student['nis'] ?? '-').toString();
    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setModalState) {
          final startStr = "${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
          final endStr = "${endDate.year.toString().padLeft(4, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Edit Penempatan Siswa',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              '$studentName (NIS: $studentNis)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Mitra DU/DI
                  const Text('Mitra DU/DI (Lokasi PKL)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        value: selectedLocationId,
                        items: _locations.map<DropdownMenuItem<int>>((l) {
                          final lId = l['id'] as int;
                          final name = (l['name'] ?? 'Lokasi').toString();
                          return DropdownMenuItem<int>(
                            value: lId,
                            child: Text(name, style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (val) => setModalState(() => selectedLocationId = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Guru Pembimbing
                  const Text('Guru Pembimbing Sekolah', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        value: selectedTeacherId,
                        items: _teachers.map<DropdownMenuItem<int>>((t) {
                          final tId = t['id'] as int;
                          final name = (t['name'] ?? 'Guru').toString();
                          return DropdownMenuItem<int>(
                            value: tId,
                            child: Text(name, style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (val) => setModalState(() => selectedTeacherId = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Pembimbing Lapangan DU/DI
                  const Text('Pembimbing Lapangan DU/DI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        isExpanded: true,
                        value: selectedSupervisorId,
                        hint: const Text('Tanpa Pembimbing Lapangan', style: TextStyle(fontSize: 13)),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('-- Belum Ditugaskan --', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                          ),
                          ..._fieldSupervisors.map<DropdownMenuItem<int?>>((fs) {
                            final fsId = fs['id'] as int;
                            final name = (fs['name'] ?? 'Pembimbing').toString();
                            return DropdownMenuItem<int?>(
                              value: fsId,
                              child: Text(name, style: const TextStyle(fontSize: 13)),
                            );
                          }),
                        ],
                        onChanged: (val) => setModalState(() => selectedSupervisorId = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Tanggal
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tanggal Mulai', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: startDate,
                                  firstDate: DateTime(2023),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  setModalState(() => startDate = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF2563EB)),
                                    const SizedBox(width: 8),
                                    Text(startStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tanggal Selesai', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: endDate,
                                  firstDate: startDate,
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  setModalState(() => endDate = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFF0D9488)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF0D9488)),
                                    const SizedBox(width: 8),
                                    Text(endStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Status
                  const Text('Status Penempatan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: status,
                        items: const [
                          DropdownMenuItem(value: 'active', child: Text('Aktif (Sedang Berjalan)')),
                          DropdownMenuItem(value: 'inactive', child: Text('Nonaktif')),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => status = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Update Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        // ========================================================================
                        // PANGGILAN API BACKEND: 4.8 Master Data Penempatan Siswa (PUT)
                        // Endpoint: PUT /api/admin/placements/{id}
                        // Controller: App\Http\Controllers\Api\Admin\PlacementController@update
                        // Body: location_id, teacher_id, field_supervisor_id, start_date, end_date, status
                        // Deskripsi: Memperbarui data penempatan siswa
                        // ========================================================================
                        final res = await AdminService.updatePlacement(
                          id: id,
                          locationId: selectedLocationId,
                          teacherId: selectedTeacherId,
                          fieldSupervisorId: selectedSupervisorId,
                          startDate: startStr,
                          endDate: endStr,
                          status: status,
                        );

                        if (!mounted) return;
                        if (res['success'] == true) {
                          messenger.showSnackBar(
                            SnackBar(content: Text(res['message'] ?? 'Penempatan berhasil diperbarui!'), backgroundColor: Colors.green),
                          );
                          await _fetchData();
                        } else {
                          messenger.showSnackBar(
                            SnackBar(content: Text(res['message'] ?? 'Gagal memperbarui penempatan.'), backgroundColor: Colors.red),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Perbarui Penempatan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── KONFIRMASI NONAKTIFKAN PENEMPATAN ──
  void _confirmDeletePenempatan(int id, String studentName, String dudiName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Nonaktifkan', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          'Apakah Anda yakin ingin menonaktifkan penempatan siswa "$studentName" di "$dudiName"? Status akan diubah menjadi nonaktif tanpa menghapus data logbook dan presensi siswa.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // ========================================================================
              // PANGGILAN API BACKEND: 4.8 Master Data Penempatan Siswa (DELETE)
              // Endpoint: DELETE /api/admin/placements/{id}
              // Controller: App\Http\Controllers\Api\Admin\PlacementController@destroy
              // Deskripsi: Menonaktifkan penempatan dengan mengubah status menjadi 'inactive'
              // ========================================================================
              final res = await AdminService.deletePlacement(id);
              if (!mounted) return;
              if (res['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(res['message'] ?? 'Penempatan berhasil dinonaktifkan!'), backgroundColor: Colors.orange),
                );
                await _fetchData();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(res['message'] ?? 'Gagal menonaktifkan penempatan.'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Nonaktifkan'),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter Data Master', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            ListTile(
              leading: const Icon(Icons.school_outlined, color: Color(0xFF2563EB)),
              title: const Text('Siswa (Semua Jurusan)'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _activeSubTab = 0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.supervised_user_circle_outlined, color: Color(0xFF4F46E5)),
              title: const Text('Guru Pembimbing Aktif'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _activeSubTab = 1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.business_rounded, color: Color(0xFF0284C7)),
              title: const Text('Mitra DU/DI Terverifikasi'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _activeSubTab = 2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_ind_outlined, color: Color(0xFF0D9488)),
              title: const Text('Penempatan Siswa PKL'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _activeSubTab = 3);
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range_rounded, color: Color(0xFFEA580C)),
              title: const Text('Periode PKL (Tahun Ajaran)'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _activeSubTab = 4);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── TOGGLE STATUS PENEMPATAN (Aktif / Nonaktif) ──
  Future<void> _handleToggleStatusPenempatan(int id, bool currentIsActive) async {
    final messenger = ScaffoldMessenger.of(context);
    final res = await AdminService.togglePlacementStatus(id);
    if (!mounted) return;
    if (res['success'] == true) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Status penempatan berhasil diperbarui!'),
          backgroundColor: currentIsActive ? Colors.orange : const Color(0xFF16A34A),
        ),
      );
      await _fetchData();
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Gagal mengubah status penempatan.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── 5. PERIODE PKL LIST & CARD ──
  Widget _buildPeriodeList() {
    final query = _searchController.text.toLowerCase();
    final filtered = _periods.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      if (query.isNotEmpty) {
        return name.contains(query);
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (filtered.isEmpty)
          _buildEmptyState(
            title: 'Belum ada data periode PKL',
            subtitle: 'Periode PKL belum dibuat atau tidak ditemukan dari hasil pencarian.',
            btnText: '+ Tambah Periode Baru',
            onAdd: _showTambahPeriodeModal,
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) {
              final item = filtered[i];
              return _buildPeriodeCard(item);
            },
          ),
      ],
    );
  }

  Widget _buildPeriodeCard(dynamic item) {
    final id = item['id'] ?? 0;
    final name = (item['name'] ?? 'Periode PKL').toString();
    final startDate = (item['start_date'] ?? '-').toString();
    final endDate = (item['end_date'] ?? '-').toString();
    final status = (item['status'] ?? 'inactive').toString();
    final bool isActive = status == 'active';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive ? const Color(0xFF22C55E).withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.date_range_rounded,
                  size: 24,
                  color: isActive ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 12),
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
                    const SizedBox(height: 3),
                    Text(
                      'Rentang: $startDate  s/d  $endDate',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isActive ? 'Aktif' : 'Nonaktif',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isActive ? const Color(0xFF166534) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            children: [
              if (isActive) ...[
                const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF16A34A)),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Periode ini tampil di Beranda & Dashboard Utama',
                    style: TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
              ] else ...[
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _confirmActivatePeriode(id, name),
                  icon: const Icon(Icons.stars_rounded, size: 16),
                  label: const Text('Jadikan Periode Aktif'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _confirmDeletePeriode(id, name, isActive),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDeletePeriode(int id, String periodName, bool isActive) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Periode PKL', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          isActive
              ? 'PERINGATAN: "$periodName" adalah periode yang sedang AKTIF!\n\nApakah Anda yakin ingin menghapusnya? Seluruh data penempatan dan logbook pada periode ini akan ikut terhapus permanen dari sistem.'
              : 'Apakah Anda yakin ingin menghapus periode PKL "$periodName"? Seluruh data penempatan pada periode ini akan dihapus permanen dari sistem.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final res = await AdminService.deletePeriod(id);
              if (!mounted) return;
              if (res['success'] == true) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(res['message'] ?? 'Periode PKL berhasil dihapus!'),
                    backgroundColor: const Color(0xFF16A34A),
                  ),
                );
                await _fetchData();
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(res['message'] ?? 'Gagal menghapus periode PKL.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );
  }

  void _confirmActivatePeriode(int id, String periodName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aktifkan Periode PKL', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          'Apakah Anda ingin mengaktifkan "$periodName" sebagai periode aktif berjalan? Periode ini akan langsung tampil di Beranda Admin dan seluruh sistem SMART PKL.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final res = await AdminService.activatePeriod(id);
              if (!mounted) return;
              if (res['success'] == true) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(res['message'] ?? 'Periode berhasil diaktifkan!'),
                    backgroundColor: const Color(0xFF16A34A),
                  ),
                );
                await _fetchData();
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(res['message'] ?? 'Gagal mengaktifkan periode.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Aktifkan'),
          ),
        ],
      ),
    );
  }

  void _showTambahPeriodeModal() {
    final nameCtrl = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 90));
    String status = 'active';

    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setModalState) {
          final startStr = "${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
          final endStr = "${endDate.year.toString().padLeft(4, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEDD5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.date_range_rounded, size: 20, color: Color(0xFFEA580C)),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tambah Periode PKL Baru',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              'Tahun ajaran & masa pelaksanaan magang siswa',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  _buildFormInput(
                    'Nama Periode PKL *',
                    nameCtrl,
                    'Contoh: PKL Semester Ganjil 2025/2026',
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tanggal Mulai *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: startDate,
                                  firstDate: DateTime(2023),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  setModalState(() => startDate = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF2563EB)),
                                    const SizedBox(width: 8),
                                    Text(startStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tanggal Selesai *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: endDate.isAfter(startDate) ? endDate : startDate.add(const Duration(days: 1)),
                                  firstDate: startDate,
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  setModalState(() => endDate = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFF0D9488)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF0D9488)),
                                    const SizedBox(width: 8),
                                    Text(endStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  const Text('Status Periode', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: status,
                        items: const [
                          DropdownMenuItem(value: 'active', child: Text('Aktif (Jadikan Periode Berjalan)')),
                          DropdownMenuItem(value: 'inactive', child: Text('Nonaktif (Arsip/Mendatang)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => status = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Harap masukkan Nama Periode PKL!')),
                          );
                          return;
                        }

                        Navigator.pop(ctx);
                        final res = await AdminService.createPeriod(
                          name: nameCtrl.text.trim(),
                          startDate: startStr,
                          endDate: endStr,
                          status: status,
                        );

                        if (!mounted) return;
                        if (res['success'] == true) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(res['message'] ?? 'Periode PKL berhasil ditambahkan!'),
                              backgroundColor: const Color(0xFF16A34A),
                            ),
                          );
                          await _fetchData();
                        } else {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(res['message'] ?? 'Gagal membuat periode PKL.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      child: const Text('Simpan Periode PKL'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
