import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../admin/admin_main_screen.dart';
import '../dudi/dudi_main_screen.dart';
import '../guru/guru_main_screen.dart';
import '../siswa/siswa_main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  int _selectedRoleIndex = 0; // 0: Siswa, 1: Guru, 2: DUDI, 3: Admin

  final List<Map<String, dynamic>> _roles = [
    {
      'label': 'Siswa',
      'icon': Icons.person_outline_rounded,
      'hint': 'Masukkan username atau NIS siswa',
      'roleCode': 'student',
    },
    {
      'label': 'Guru',
      'icon': Icons.menu_book_outlined,
      'hint': 'Masukkan username atau Kode Guru',
      'roleCode': 'teacher',
    },
    {
      'label': 'DUDI',
      'icon': Icons.apartment_rounded,
      'hint': 'Masukkan username pembimbing DUDI',
      'roleCode': 'field_supervisor',
    },
    {
      'label': 'Admin',
      'icon': Icons.shield_outlined,
      'hint': 'Masukkan username Administrator',
      'roleCode': 'admin',
    },
  ];

  void _selectRole(int index) {
    setState(() {
      _selectedRoleIndex = index;
    });
  }

  void _navigateToRoleScreen(String roleCode) {
    Widget targetScreen;
    switch (roleCode) {
      case 'student':
        targetScreen = const SiswaMainScreen();
        break;
      case 'teacher':
        targetScreen = const GuruMainScreen();
        break;
      case 'field_supervisor':
        targetScreen = const DudiMainScreen();
        break;
      case 'admin':
      default:
        targetScreen = const AdminMainScreen();
        break;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => targetScreen),
    );
  }

  Future<void> _handleLogin() async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    // Koreksi otomatis jika pengguna mengetik nama variabel
    if (username.toLowerCase() == 'adminusername') {
      username = 'admin';
      _usernameController.text = 'admin';
    }
    if (password.toLowerCase() == 'adminpassword') {
      password = 'password';
      _passwordController.text = 'password';
    }

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan masukkan username dan password.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final selectedRole = _roles[_selectedRoleIndex];
    final selectedRoleCode = selectedRole['roleCode'] as String;

    try {
      final result = await AuthService.login(
        username: username,
        password: password,
        role: selectedRoleCode,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final user = result['user'] as Map<String, dynamic>?;
        final actualRole = user?['role']?.toString() ?? selectedRoleCode;

        // Validasi ganda jika peran yang didapat dari akun tidak sesuai dengan tab yang dipilih
        if (actualRole != selectedRoleCode) {
          await AuthService.logout();
          if (!mounted) return;
          const roleLabels = {
            'student': 'Siswa',
            'teacher': 'Guru',
            'field_supervisor': 'DUDI',
            'admin': 'Admin',
          };
          final actualLabel = roleLabels[actualRole] ?? actualRole;
          final expectedLabel = roleLabels[selectedRoleCode] ?? selectedRoleCode;
          final targetIdx = _roles.indexWhere((r) => r['roleCode'] == actualRole);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Akun ini bukan akun $expectedLabel. Akun ini terdaftar sebagai $actualLabel. Silakan pilih peran $actualLabel untuk masuk.',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFFEF4444),
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
              action: targetIdx != -1
                  ? SnackBarAction(
                      label: 'Pilih $actualLabel',
                      textColor: const Color(0xFFFDE047),
                      onPressed: () => _selectRole(targetIdx),
                    )
                  : null,
            ),
          );
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Login berhasil! Selamat datang, ${user?['name'] ?? username}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );

        _navigateToRoleScreen(actualRole);
      } else {
        final detectedRole = result['detectedRole']?.toString();
        SnackBarAction? action;
        if (result['isConnectionError'] == true) {
          action = SnackBarAction(
            label: 'Atur Server',
            textColor: const Color(0xFFFDE047),
            onPressed: _showServerConfigDialog,
          );
        } else if (detectedRole != null) {
          final targetIdx = _roles.indexWhere((r) => r['roleCode'] == detectedRole);
          if (targetIdx != -1) {
            final targetLabel = _roles[targetIdx]['label'];
            action = SnackBarAction(
              label: 'Pilih $targetLabel',
              textColor: const Color(0xFFFDE047),
              onPressed: () {
                _selectRole(targetIdx);
              },
            );
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    result['message'] ?? 'Login gagal. Periksa username dan password Anda.',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            action: action,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showServerConfigDialog() async {
    final urlController = TextEditingController(text: AuthService.baseUrl);
    bool isTesting = false;
    String? testResult;
    bool? testSuccess;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.cloud_sync_rounded, color: Color(0xFF2563EB), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Pengaturan Server API',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Masukkan alamat URL Cloudflare Tunnel atau server backend:',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: urlController,
                      decoration: InputDecoration(
                        labelText: 'URL Server Backend',
                        hintText: 'https://skripsi-production-ce547be8.up.railway.app/api',
                        prefixIcon: const Icon(Icons.link_rounded, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: isTesting
                              ? null
                              : () async {
                                  setDialogState(() {
                                    isTesting = true;
                                    testResult = null;
                                  });
                                  final ok = await AuthService.testConnection(urlController.text.trim());
                                  setDialogState(() {
                                    isTesting = false;
                                    testSuccess = ok;
                                    testResult = ok
                                        ? 'Terhubung! Server aktif & merespons.'
                                        : 'Gagal terhubung ke URL ini.';
                                  });
                                },
                          icon: isTesting
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.wifi_tethering_rounded, size: 16),
                          label: Text(isTesting ? 'Menguji...' : 'Tes Koneksi'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            urlController.text = AuthService.defaultBaseUrl;
                            setDialogState(() {
                              testResult = null;
                            });
                          },
                          child: const Text('Reset Default', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    if (testResult != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (testSuccess ?? false) ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (testSuccess ?? false) ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              (testSuccess ?? false) ? Icons.check_circle_rounded : Icons.cancel_rounded,
                              size: 18,
                              color: (testSuccess ?? false) ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                testResult!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: (testSuccess ?? false) ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final target = urlController.text.trim();
                    if (target.isNotEmpty) {
                      await AuthService.setBaseUrl(target);
                    }
                    if (context.mounted) {
                      Navigator.of(ctx).pop();
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Alamat server berhasil diperbarui!'),
                          backgroundColor: Color(0xFF16A34A),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedRole = _roles[_selectedRoleIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),
                  // App Icon / Logo
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.18),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/app_icon.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Image.asset(
                          'assets/images/logo_smart_pkl.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.school_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Brand Greeting Header
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Selamat Datang di ',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        TextSpan(
                          text: 'SMART PKL',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2563EB),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Sistem Monitoring Praktek Kerja Lapangan SMK',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Main Login Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 24,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Masuk ke Akun',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Pilih peran dan masukkan kredensial yang telah didaftarkan.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Section Header: PERAN
                        const Text(
                          'PERAN',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // 2x2 Grid Role Selector
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  _buildRoleGridItem(0),
                                  const SizedBox(width: 5),
                                  _buildRoleGridItem(1),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  _buildRoleGridItem(2),
                                  const SizedBox(width: 5),
                                  _buildRoleGridItem(3),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),


                        // Label Username
                        Row(
                          children: const [
                            Text(
                              'Username',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              ' *',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Username Input Field
                        TextField(
                          controller: _usernameController,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: selectedRole['hint'] as String,
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF94A3B8),
                            ),
                            prefixIcon: Icon(
                              selectedRole['icon'] as IconData,
                              color: const Color(0xFF2563EB),
                              size: 20,
                            ),
                            suffixIcon: _usernameController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                                    onPressed: () {
                                      setState(() {
                                        _usernameController.clear();
                                      });
                                    },
                                  )
                                : null,
                            fillColor: const Color(0xFFF8FAFC),
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFF2563EB),
                                width: 1.5,
                              ),
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 18),

                        // Label Password *
                        Row(
                          children: const [
                            Text(
                              'Password',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              ' *',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Password Input Field
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Masukkan password',
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF94A3B8),
                            ),
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: Color(0xFF2563EB),
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF94A3B8),
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            fillColor: const Color(0xFFF8FAFC),
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFF2563EB),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              shadowColor: const Color(0xFF2563EB).withValues(alpha: 0.35),
                            ),
                            child: _isLoading
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Menghubungkan...',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Text(
                                        'Masuk',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Bottom Help Info Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFDBEAFE),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.help_outline_rounded,
                            color: Color(0xFF2563EB),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kendala Akses Akun?',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Hubungi Admin PKL sekolah untuk reset password atau sinkronisasi data siswa & pembimbing.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF475569),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleGridItem(int index) {
    final role = _roles[index];
    final bool isSelected = _selectedRoleIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _selectRole(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                role['icon'] as IconData,
                size: 17,
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Text(
                role['label'] as String,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
