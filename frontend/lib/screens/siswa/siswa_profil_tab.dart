import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/student_service.dart';
import '../../widgets/smart_pkl_header.dart';
import '../auth/login_screen.dart';
import '../common/ganti_password_screen.dart';

class SiswaProfilTab extends StatefulWidget {
  const SiswaProfilTab({super.key});

  @override
  State<SiswaProfilTab> createState() => _SiswaProfilTabState();
}

class _SiswaProfilTabState extends State<SiswaProfilTab> {
  bool _isLoading = true;
  String _name = 'Siswa PKL';
  String _nis = '-';
  String _className = '-';
  String _major = 'Rekayasa Perangkat Lunak';
  String _username = '';
  String _companyName = 'Belum Ditempatkan';
  String _periodName = '-';
  String _teacherName = '-';
  String _spvName = '-';
  final String _roleName = 'Siswa PKL';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Ambil data sesi akun login dari SharedPreferences
      final cachedUser = await AuthService.getUser();
      if (cachedUser != null) {
        if (cachedUser['name'] != null) _name = cachedUser['name'].toString();
        if (cachedUser['username'] != null) _username = cachedUser['username'].toString();
      }

      // 2. Ambil detail profil siswa (NIS, Kelas, Jurusan) dari API backend GET /api/student/profile
      final profile = await StudentService.getProfile();
      if (profile != null) {
        _name = profile['name']?.toString() ?? _name;
        _nis = profile['nis']?.toString() ?? '-';
        _className = profile['class']?.toString() ?? '-';
        _major = profile['major']?.toString() ?? _major;

        final user = profile['user'] as Map<String, dynamic>?;
        if (user != null) {
          _username = user['username']?.toString() ?? _username;
        }
      }

      // 3. Ambil data penempatan DUDI & pembimbing dari API backend GET /api/student/placement
      final placement = await StudentService.getPlacement();
      if (placement != null) {
        final loc = placement['location'] as Map<String, dynamic>?;
        final per = placement['period'] as Map<String, dynamic>?;
        final tch = placement['teacher'] as Map<String, dynamic>?;
        final spv = placement['field_supervisor'] as Map<String, dynamic>?;

        _companyName = loc?['name']?.toString() ?? 'Belum ada lokasi';
        _periodName = per?['name']?.toString() ?? '-';
        _teacherName = tch?['name']?.toString() ?? '-';
        _spvName = spv?['name']?.toString() ?? '-';
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Buat 2 huruf inisial avatar
    final initial = _name.isNotEmpty
        ? _name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase()
        : 'S';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            const SmartPklHeader(
              title: 'Profil',
            ),
            if (_isLoading)
              const LinearProgressIndicator(
                minHeight: 2,
                color: Color(0xFF2563EB),
                backgroundColor: Color(0xFFEFF6FF),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadProfileData,
                color: const Color(0xFF2563EB),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Card 1: Avatar Inisial & Nama Siswa (Gaya Profil Guru) ──
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: const Color(0xFFDBEAFE),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1D4ED8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _roleName,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Section Title: Informasi Akun ──
                      const Text(
                        'Informasi Akun',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Item 1: NAMA ──
                      _buildInfoCard(
                        icon: Icons.badge_outlined,
                        label: 'NAMA',
                        value: _name,
                      ),
                      const SizedBox(height: 10),

                      // ── Item 2: NIS & KELAS ──
                      _buildInfoCard(
                        icon: Icons.school_outlined,
                        label: 'NIS & KELAS',
                        value: '$_nis • $_className',
                      ),
                      const SizedBox(height: 10),

                      // ── Item 3: JURUSAN ──
                      _buildInfoCard(
                        icon: Icons.auto_awesome_mosaic_outlined,
                        label: 'JURUSAN',
                        value: _major,
                      ),
                      const SizedBox(height: 10),

                      // ── Item 4: TEMPAT PKL / DUDI ──
                      _buildInfoCard(
                        icon: Icons.business_rounded,
                        label: 'TEMPAT PKL / DUDI',
                        value: _periodName != '-' ? '$_companyName ($_periodName)' : _companyName,
                      ),
                      const SizedBox(height: 10),

                      // ── Item 5: GURU PEMBIMBING ──
                      _buildInfoCard(
                        icon: Icons.assignment_ind_outlined,
                        label: 'GURU PEMBIMBING',
                        value: _teacherName,
                      ),
                      const SizedBox(height: 10),

                      // ── Item 6: PEMBIMBING LAPANGAN (DUDI) ──
                      _buildInfoCard(
                        icon: Icons.person_outline_rounded,
                        label: 'PEMBIMBING LAPANGAN (DUDI)',
                        value: _spvName,
                      ),
                      const SizedBox(height: 10),


                      // ── Item 8: GANTI PASSWORD ──
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const GantiPasswordScreen(userRole: 'student'),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.lock_reset_rounded, size: 20, color: Color(0xFF2563EB)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'GANTI PASSWORD',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF94A3B8),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Ubah Password akun',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 22),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Info note
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF64748B)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Untuk perubahan identitas atau informasi akun, hubungi administrator sekolah.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Tombol Logout Merah
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.white),
                          label: const Text(
                            'Logout / Keluar Aplikasi',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB91C1C),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF2563EB)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
