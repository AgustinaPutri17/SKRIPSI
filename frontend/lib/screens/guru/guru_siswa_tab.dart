import 'package:flutter/material.dart';
import '../../core/services/teacher_service.dart';
import '../../widgets/smart_pkl_header.dart';
import '../../widgets/status_pill.dart';

class GuruSiswaTab extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const GuruSiswaTab({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<GuruSiswaTab> createState() => _GuruSiswaTabState();
}

class _GuruSiswaTabState extends State<GuruSiswaTab> {
  bool _isLoading = true;
  int _selectedFilter = 0; // 0: Semua, 1..n: Kelas yang dinamis dari backend
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allStudents = [];
  List<String> _distinctClasses = [];

  @override
  void initState() {
    super.initState();
    _fetchStudents();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Memanggil endpoint API: GET /api/teacher/students
  Future<void> _fetchStudents() async {
    setState(() => _isLoading = true);
    try {
      final list = await TeacherService.getStudents();
      if (mounted) {
        setState(() {
          _allStudents = list;

          // Ambil daftar kelas unik dari database
          final classes = <String>{};
          for (final s in list) {
            final cls = s['class']?.toString().trim();
            if (cls != null && cls.isNotEmpty) {
              classes.add(cls);
            }
          }
          _distinctClasses = classes.toList()..sort();
        });
      }
    } catch (_) {
      // Fallback tetap aman
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getAvatarColor(int index) {
    const colors = [
      Color(0xFF2563EB),
      Color(0xFF0D9488),
      Color(0xFF7C3AED),
      Color(0xFFF59E0B),
      Color(0xFFE11D48),
      Color(0xFF0284C7),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    // Filter dan Search Logic
    final query = _searchController.text.trim().toLowerCase();

    final filteredStudents = _allStudents.where((student) {
      final name = (student['user']?['name'] ?? student['name'] ?? '').toString().toLowerCase();
      final nis = (student['nis'] ?? student['nisn'] ?? '').toString().toLowerCase();
      final className = (student['class'] ?? '').toString();
      final placement = student['placement'] as Map<String, dynamic>?;
      final locationName = (placement?['location']?['name'] ?? '').toString().toLowerCase();

      // Cek pencarian nama, NIS/NISN, atau DUDI
      final matchesQuery = query.isEmpty ||
          name.contains(query) ||
          nis.contains(query) ||
          locationName.contains(query);

      // Cek filter tab kelas
      if (_selectedFilter == 0) return matchesQuery;
      if (_selectedFilter - 1 < _distinctClasses.length) {
        final targetClass = _distinctClasses[_selectedFilter - 1];
        return matchesQuery && className == targetClass;
      }
      return matchesQuery;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header SMART PKL (Menampilkan jumlah total siswa riil dari server)
            SmartPklHeader(
              title: 'Siswa Bimbingan',
              subtitle: '${_allStudents.length} Siswa',
              onProfileTap: () => widget.onNavigateTab?.call(4), // Tab Profil
            ),

            if (_isLoading)
              const LinearProgressIndicator(
                minHeight: 2,
                color: Color(0xFF2563EB),
                backgroundColor: Color(0xFFEFF6FF),
              ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchStudents,
                color: const Color(0xFF2563EB),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Bar Box
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                decoration: const InputDecoration(
                                  hintText: 'Cari nama siswa, NISN, atau DUDI...',
                                  hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              GestureDetector(
                                onTap: () => _searchController.clear(),
                                child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Filter Chips yang responsif (SingleChildScrollView horizontal untuk cegah yellow overflow)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildFilterPill(0, 'Semua Siswa (${_allStudents.length})'),
                            ...List.generate(_distinctClasses.length, (idx) {
                              final cls = _distinctClasses[idx];
                              final count = _allStudents.where((s) => s['class'] == cls).length;
                              return Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: _buildFilterPill(idx + 1, '$cls ($count)'),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Daftar Siswa dari Database Backend
                      if (filteredStudents.isEmpty && !_isLoading)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: const [
                              Icon(Icons.person_search_rounded, size: 48, color: Color(0xFF94A3B8)),
                              SizedBox(height: 12),
                              Text(
                                'Tidak ada siswa bimbingan ditemukan',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Coba sesuaikan kata kunci pencarian atau filter kelas.',
                                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredStudents.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (ctx, index) {
                            final student = filteredStudents[index];
                            final name = student['user']?['name']?.toString() ??
                                student['name']?.toString() ??
                                'Siswa Bimbingan';
                            final nis = student['nis']?.toString() ??
                                student['nisn']?.toString() ??
                                '-';
                            final className = student['class']?.toString() ?? '-';
                            final placement = student['placement'] as Map<String, dynamic>?;
                            final location = placement?['location'] as Map<String, dynamic>?;
                            final dudiName = location?['name']?.toString() ??
                                location?['address']?.toString() ??
                                'Belum Ditempatkan';
                            final supervisor = placement?['fieldSupervisor'] as Map<String, dynamic>?;
                            final supervisorName = supervisor?['name']?.toString() ??
                                supervisor?['user']?['name']?.toString() ??
                                'Belum Ditentukan';

                            final initial = name.trim().isNotEmpty
                                ? name
                                    .trim()
                                    .split(' ')
                                    .take(2)
                                    .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
                                    .join('')
                                : 'SW';

                            final placementStatus = placement?['status']?.toString();
                            final isAktif = placementStatus == 'active' || placement != null;

                            return _buildStudentCard(
                              nama: name,
                              initial: initial.isNotEmpty ? initial : 'SW',
                              nisn: nis,
                              kelas: className,
                              dudi: dudiName,
                              pembimbingDudi: supervisorName,
                              kehadiran: 'Hadir', // Status presensi
                              logbook: 'Terpantau',
                              status: isAktif ? 'Aktif PKL' : 'Belum Aktif',
                              statusStyle: isAktif ? PillStyle.success : PillStyle.warning,
                              avatarColor: _getAvatarColor(index),
                            );
                          },
                        ),
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

  Widget _buildFilterPill(int index, String title) {
    final bool isSelected = _selectedFilter == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = index;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard({
    required String nama,
    required String initial,
    required String nisn,
    required String kelas,
    required String dudi,
    required String pembimbingDudi,
    required String kehadiran,
    required String logbook,
    required String status,
    required PillStyle statusStyle,
    required Color avatarColor,
  }) {
    return Container(
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
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: avatarColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
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
                      nama,
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
                      'NISN: $nisn • $kelas',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(
                text: status,
                style: statusStyle,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.business_rounded, size: 14, color: Color(0xFF2563EB)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  dudi,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.person_pin_rounded, size: 14, color: Color(0xFF94A3B8)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Pembimbing: $pembimbingDudi',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('Status: ', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    Text(
                      status,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF16A34A)),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text('Logbook: ', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    Text(
                      logbook,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
