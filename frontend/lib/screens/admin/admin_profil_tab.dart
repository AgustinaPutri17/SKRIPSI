import 'package:flutter/material.dart';
import '../../core/services/admin_service.dart';
import '../../core/services/auth_service.dart';
import '../../widgets/smart_pkl_header.dart';
import '../auth/login_screen.dart';
import '../common/ganti_password_screen.dart';

/// ==============================================================================
/// TAB PROFIL & PENGATURAN KREDENSIAL ADMIN
/// Sesuai Mockup Image 4: "Pengaturan & Kredensial Terpadu"
/// 
/// Interaksi Backend ('monitoring-pkl-app'):
/// 1. GET /api/admin/users?role=admin
///    -> Mengambil akun admin aktif dan total akun admin
/// 2. PUT /api/admin/users/{id}
///    -> Memperbarui data profil administrator
/// 3. POST /api/admin/users/{id}/reset-password
///    -> Reset password kredensial master admin
/// ==============================================================================
class AdminProfilTab extends StatefulWidget {
  const AdminProfilTab({super.key});

  @override
  State<AdminProfilTab> createState() => _AdminProfilTabState();
}

class _AdminProfilTabState extends State<AdminProfilTab> {
  bool _isLoading = true;
  int _totalAdminCount = 1;
  Map<String, dynamic>? _adminUser;

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  /// ============================================================================
  /// PANGGILAN API BACKEND: 4.2 Manajemen Akun Pengguna
  /// Endpoint: GET /api/admin/users?role=admin
  /// Backend File: monitoring-pkl-app/routes/api.php:38
  /// Controller: App\Http\Controllers\Api\Admin\UserController@index
  /// Deskripsi: Mengambil data pengguna ber-role 'admin' dan menghitung total akun
  /// ============================================================================
  Future<void> _fetchAdminData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final res = await AdminService.getUsers(role: 'admin');
      if (res != null && res['users'] != null) {
        final list = res['users'] as List<dynamic>;
        if (mounted) {
          setState(() {
            _totalAdminCount = list.length;
            if (list.isNotEmpty) {
              _adminUser = list.first as Map<String, dynamic>;
            }
          });
        }
      }
    } catch (_) {
      // Backend offline fallback
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Dialog edit profil admin
  void _showEditProfilDialog() {
    final nameCtrl = TextEditingController(text: _adminUser?['name'] ?? 'Administrator');
    final usernameCtrl = TextEditingController(text: _adminUser?['username'] ?? 'admin');
    final emailCtrl = TextEditingController(text: _adminUser?['email'] ?? 'admin@smk.sch.id');
    final adminId = _adminUser?['id'] ?? 1;

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text('Edit Profil Administrator', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const Divider(),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Lengkap'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: usernameCtrl,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  // ========================================================================
                  // PANGGILAN API BACKEND: 4.2 Update Pengguna Admin
                  // Endpoint: PUT /api/admin/users/{id}
                  // Controller: App\Http\Controllers\Api\Admin\UserController@update
                  // ========================================================================
                  final res = await AdminService.updateUser(
                    id: adminId,
                    name: nameCtrl.text,
                    username: usernameCtrl.text,
                    email: emailCtrl.text,
                  );
                  if (!mounted) return;
                  if (res['success'] == true) {
                    _fetchAdminData();
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res['message'] ?? 'Profil admin berhasil diperbarui.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminName = _adminUser?['name']?.toString() ?? 'Administrator';
    final adminUsername = _adminUser?['username']?.toString() ?? 'admin';

    final initial = adminName.isNotEmpty
        ? adminName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase()
        : 'AD';

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
                onRefresh: _fetchAdminData,
                color: const Color(0xFF2563EB),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Card 1: Avatar Inisial & Nama Admin (Gaya Profil Guru) ──
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
                                    adminName,
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
                                    child: const Text(
                                      'Administrator Sistem',
                                      style: TextStyle(
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
                        label: 'NAMA ADMINISTRATOR',
                        value: adminName,
                      ),
                      const SizedBox(height: 10),

                      // ── Item 2: USERNAME ──
                      _buildInfoCard(
                        icon: Icons.account_circle_outlined,
                        label: 'USERNAME',
                        value: '@$adminUsername',
                      ),
                      const SizedBox(height: 10),

                      // ── Item 4: HAK AKSES SISTEM ──
                      _buildInfoCard(
                        icon: Icons.security_rounded,
                        label: 'HAK AKSES SISTEM',
                        value: 'Super Administrator (Akses Penuh)',
                      ),
                      const SizedBox(height: 10),

                      // ── Item 5: TOTAL ADMIN ──
                      _buildInfoCard(
                        icon: Icons.people_outline_rounded,
                        label: 'TOTAL ADMIN TERDAFTAR',
                        value: '$_totalAdminCount Akun Administrator Aktif',
                      ),
                      const SizedBox(height: 10),

                      // ── Item 6: EDIT PROFIL ADMIN ──
                      InkWell(
                        onTap: _showEditProfilDialog,
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
                                child: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF2563EB)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'IDENTITAS AKUN',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF94A3B8),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Edit Profil Admin',
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
                      const SizedBox(height: 10),

                      // ── Item 7: GANTI PASSWORD ──
                      InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => GantiPasswordScreen(
                                userRole: 'Administrator',
                                username: adminUsername,
                              ),
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
                                      'Ubah Password akun Admin',
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
                              'Akun Administrator memiliki hak akses penuh untuk mengelola pengguna, DUDI, dan penempatan PKL.',
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
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Konfirmasi Keluar', style: TextStyle(fontWeight: FontWeight.w700)),
                                content: const Text('Apakah Anda yakin ingin keluar dari akun administrator?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB91C1C), foregroundColor: Colors.white),
                                    child: const Text('Keluar'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await AuthService.logout();
                              if (context.mounted) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                  (route) => false,
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
                          label: const Text(
                            'Logout / Keluar Aplikasi',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB91C1C),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
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
