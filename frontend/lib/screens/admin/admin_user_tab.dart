import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/smart_pkl_header.dart';
import '../../widgets/custom_button.dart';

class AdminUserTab extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const AdminUserTab({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<AdminUserTab> createState() => _AdminUserTabState();
}

class _AdminUserTabState extends State<AdminUserTab> {
  int _selectedFilter = 0; // 0: Semua (144), 1: Siswa (128), 2: Guru (16)
  bool _showCreateForm = false;

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController(text: 'pkl@2024');
  String _selectedRole = 'Siswa';

  @override
  void dispose() {
    _namaController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSimpanAkun() {
    setState(() {
      _showCreateForm = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Akun kredensial baru ($_selectedRole: ${_usernameController.text}) berhasil diterapkan oleh Admin!'),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SmartPklHeader(
              title: 'Kelola Akun',
              subtitle: 'Admin',
              onProfileTap: () => widget.onNavigateTab?.call(3),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Banner about Admin-applied credentials
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Administrator menetapkan username & password bagi seluruh Siswa dan Guru Pembimbing sebelum memulai masa PKL.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF), height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Add Account Button
                    CustomButton(
                      text: _showCreateForm ? 'Tutup Formulir Pendaftaran' : '+ Terapkan Akun Baru',
                      icon: _showCreateForm ? Icons.close : Icons.person_add_alt_1_rounded,
                      color: _showCreateForm ? const Color(0xFF64748B) : const Color(0xFF7C3AED),
                      onPressed: () {
                        setState(() {
                          _showCreateForm = !_showCreateForm;
                        });
                      },
                    ),
                    const SizedBox(height: 14),

                    // Inline Create Account Form
                    if (_showCreateForm) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFDDD6FE), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.key_rounded, color: Color(0xFF7C3AED), size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Formulir Pembuatan Kredensial Login',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Role Selection
                            const Text('Peran Akun', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _buildRoleChoice('Siswa'),
                                const SizedBox(width: 12),
                                _buildRoleChoice('Guru Pembimbing'),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Nama Lengkap
                            const Text('Nama Lengkap', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _namaController,
                              decoration: const InputDecoration(
                                hintText: 'Contoh: Ahmad Fadilah / Rina Wati, M.Pd',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Username
                            const Text('Username Login', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                hintText: 'Contoh: ahmad.fadilah atau NISN 0067829108',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Password Default
                            const Text('Password Default yang Diterapkan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _passwordController,
                              decoration: const InputDecoration(
                                hintText: 'Password awal (contoh: pkl@2024)',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                            const SizedBox(height: 16),

                            CustomButton(
                              text: 'Terapkan & Simpan Kredensial',
                              icon: Icons.check,
                              color: const Color(0xFF7C3AED),
                              onPressed: _handleSimpanAkun,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Filter Selector
                    Row(
                      children: [
                        _buildFilterPill(0, 'Semua Akun (144)'),
                        const SizedBox(width: 8),
                        _buildFilterPill(1, 'Siswa (128)'),
                        const SizedBox(width: 8),
                        _buildFilterPill(2, 'Guru (16)'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Account List Cards (Directly written in widget, no model)
                    if (_selectedFilter == 0 || _selectedFilter == 1) ...[
                      _buildAccountItem(
                        nama: 'Ananda Putri',
                        username: 'ananda.putri',
                        role: 'Siswa (XII RPL 1)',
                        dudi: 'PT Telkom Digital Solutions',
                        status: 'Aktif',
                        roleColor: AppColors.primary,
                        icon: Icons.school_rounded,
                      ),
                      const SizedBox(height: 10),

                      _buildAccountItem(
                        nama: 'Rizky Pratama',
                        username: 'rizky.pratama',
                        role: 'Siswa (XII RPL 1)',
                        dudi: 'PT Astra Graphia IT Division',
                        status: 'Aktif',
                        roleColor: AppColors.primary,
                        icon: Icons.school_rounded,
                      ),
                      const SizedBox(height: 10),

                      _buildAccountItem(
                        nama: 'Siti Nurhaliza',
                        username: 'siti.nurhaliza',
                        role: 'Siswa (XII RPL 2)',
                        dudi: 'PT GoTo Gojek Tokopedia',
                        status: 'Aktif',
                        roleColor: AppColors.primary,
                        icon: Icons.school_rounded,
                      ),
                      const SizedBox(height: 10),
                    ],

                    if (_selectedFilter == 0 || _selectedFilter == 2) ...[
                      _buildAccountItem(
                        nama: 'Budi Santoso, M.Kom',
                        username: 'budi.santoso',
                        role: 'Guru Pembimbing (NIP: 19850312)',
                        dudi: 'Membimbing 24 Siswa',
                        status: 'Aktif',
                        roleColor: const Color(0xFF0D9488),
                        icon: Icons.supervised_user_circle_rounded,
                      ),
                      const SizedBox(height: 10),

                      _buildAccountItem(
                        nama: 'Dewi Lestari, S.Pd',
                        username: 'dewi.lestari',
                        role: 'Guru Pembimbing (NIP: 19890415)',
                        dudi: 'Membimbing 20 Siswa',
                        status: 'Aktif',
                        roleColor: const Color(0xFF0D9488),
                        icon: Icons.supervised_user_circle_rounded,
                      ),
                      const SizedBox(height: 10),
                    ],
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

  Widget _buildRoleChoice(String role) {
    final bool isSelected = _selectedRole == role;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: isSelected ? const Color(0xFF7C3AED) : AppColors.textMuted,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            role,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? const Color(0xFF7C3AED) : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(int index, String label) {
    final bool isSelected = _selectedFilter == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = index;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7C3AED) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF7C3AED) : AppColors.cardBorder,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildAccountItem({
    required String nama,
    required String username,
    required String role,
    required String dudi,
    required String status,
    required Color roleColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: roleColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      nama,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Aktif', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Text('Username: ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    Text(
                      username,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ],
                ),
                Text(
                  '$role • $dudi',
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          // Action Reset Password
          IconButton(
            icon: const Icon(Icons.lock_reset_rounded, size: 20, color: AppColors.textSecondary),
            tooltip: 'Reset Password',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Password untuk akun "$username" di-reset ke "pkl@2024"'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
