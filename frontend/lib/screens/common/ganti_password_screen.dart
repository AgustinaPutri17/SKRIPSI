import 'package:flutter/material.dart';
import '../../core/services/admin_service.dart';
import '../../core/services/auth_service.dart';
import '../../widgets/custom_button.dart';

class GantiPasswordScreen extends StatefulWidget {
  final String? userRole;
  final String? username;
  final int? userId;

  const GantiPasswordScreen({
    super.key,
    this.userRole,
    this.username,
    this.userId,
  });

  @override
  State<GantiPasswordScreen> createState() => _GantiPasswordScreenState();
}

class _GantiPasswordScreenState extends State<GantiPasswordScreen> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  bool _hasMin8Chars = false;
  bool _hasMixedCaseAndNumber = false;
  bool _isPasswordMatch = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _validatePasswordRequirements();
    _newPasswordController.addListener(_validatePasswordRequirements);
    _confirmPasswordController.addListener(_validatePasswordRequirements);
  }


  void _validatePasswordRequirements() {
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    final hasMin8 = newPass.length >= 8;
    final hasUpper = newPass.contains(RegExp(r'[A-Z]'));
    final hasLower = newPass.contains(RegExp(r'[a-z]'));
    final hasDigit = newPass.contains(RegExp(r'[0-9]'));
    final hasMixed = hasUpper && hasLower && hasDigit;

    final isMatch = newPass.isNotEmpty && newPass == confirmPass;

    setState(() {
      _hasMin8Chars = hasMin8;
      _hasMixedCaseAndNumber = hasMixed;
      _isPasswordMatch = isMatch;
    });
  }

  Future<void> _handleSavePassword() async {
    final currentPass = _currentPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (currentPass.isEmpty) {
      _showSnackBar('Masukkan password saat ini terlebih dahulu.', isError: true);
      return;
    }

    if (!_hasMin8Chars || !_hasMixedCaseAndNumber) {
      _showSnackBar(
        'Password baru harus memenuhi minimal 8 karakter serta kombinasi huruf besar, huruf kecil, dan angka.',
        isError: true,
      );
      return;
    }

    if (newPass != confirmPass) {
      _showSnackBar('Konfirmasi password tidak cocok dengan password baru.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> res;

      // Jika admin sedang me-reset akun orang lain berdasarkan userId
      if (widget.userId != null && widget.userRole == 'admin') {
        res = await AdminService.resetPassword(
          userId: widget.userId!,
          newPassword: newPass,
          passwordConfirmation: confirmPass,
        );
      } else {
        // Ganti password mandiri untuk user aktif (Siswa, Guru, DUDI, Admin)
        res = await AuthService.changePassword(
          currentPassword: currentPass,
          newPassword: newPass,
          confirmPassword: confirmPass,
        );
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (res['success'] == true) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 24),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Password Berhasil Diubah',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            content: Text(
              res['message'] ?? 'Password baru Anda telah berhasil disimpan. Silakan gunakan password baru ini untuk masuk.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.maybePop(context);
                },
                child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
      } else {
        _showSnackBar(res['message'] ?? 'Gagal mengubah password.', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Terjadi kesalahan: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF16A34A),
      ),
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A), size: 22),
                    onPressed: () => Navigator.of(context).maybePop(),
                    tooltip: 'Kembali',
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Ganti Password',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  // Avatar profile icon matching screenshot
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notice Card: "Lindungi Akun Anda" matching screenshot
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.gpp_good_outlined,
                            color: Color(0xFF2563EB),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lindungi Akun Anda',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Gunakan password baru yang kuat dan berbeda dari password saat ini.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Main Form Card matching screenshot
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Field 1: Password Saat Ini
                        const Text(
                          'Password Saat Ini',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildPasswordField(
                          controller: _currentPasswordController,
                          hint: 'Masukkan password saat ini',
                          isObscure: _obscureCurrentPassword,
                          onToggleObscure: () {
                            setState(() {
                              _obscureCurrentPassword = !_obscureCurrentPassword;
                            });
                          },
                          isFocused: false,
                        ),
                        const SizedBox(height: 18),

                        // Field 2: Password Baru
                        const Text(
                          'Password Baru',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildPasswordField(
                          controller: _newPasswordController,
                          hint: 'Masukkan password baru',
                          isObscure: _obscureNewPassword,
                          onToggleObscure: () {
                            setState(() {
                              _obscureNewPassword = !_obscureNewPassword;
                            });
                          },
                          isFocused: true, // Matching highlighted blue border in screenshot
                        ),
                        const SizedBox(height: 12),

                        // Password Requirements Indicators matching screenshot
                        const Text(
                          'Password baru harus memiliki:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildRequirementItem(
                          'Minimal 8 karakter',
                          _hasMin8Chars,
                        ),
                        const SizedBox(height: 4),
                        _buildRequirementItem(
                          'Huruf besar, huruf kecil, dan angka',
                          _hasMixedCaseAndNumber,
                        ),
                        const SizedBox(height: 18),

                        // Field 3: Konfirmasi Password Baru
                        const Text(
                          'Konfirmasi Password Baru',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildPasswordField(
                          controller: _confirmPasswordController,
                          hint: 'Ulangi password baru',
                          isObscure: _obscureConfirmPassword,
                          onToggleObscure: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                          isFocused: false,
                        ),
                        const SizedBox(height: 8),

                        // Confirmation Status matching screenshot
                        if (_confirmPasswordController.text.isNotEmpty)
                          _buildConfirmationStatus(
                            _isPasswordMatch,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Button: "Simpan Password Baru" matching screenshot
                  CustomButton(
                    text: 'Simpan Password Baru',
                    icon: Icons.save_outlined,
                    color: const Color(0xFF2563EB),
                    height: 50,
                    borderRadius: 14,
                    isLoading: _isLoading,
                    onPressed: _isLoading ? () {} : _handleSavePassword,
                  ),
                  const SizedBox(height: 12),

                  // Bottom Notice with info icon matching screenshot
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Setelah disimpan, gunakan password baru untuk masuk kembali ke akun Anda.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool isObscure,
    required VoidCallback onToggleObscure,
    required bool isFocused,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          width: isFocused ? 1.6 : 1.0,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F172A),
          letterSpacing: 2.0, // For clean bullet appearance
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontSize: 13,
            color: Color(0xFF94A3B8),
            letterSpacing: 0,
            fontWeight: FontWeight.normal,
          ),
          prefixIcon: const Icon(
            Icons.lock_outline_rounded,
            color: Color(0xFF64748B),
            size: 20,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: const Color(0xFF64748B),
              size: 20,
            ),
            onPressed: onToggleObscure,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildRequirementItem(String text, bool isMet) {
    final color = isMet ? const Color(0xFF16A34A) : const Color(0xFF94A3B8);
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle_outline_rounded : Icons.radio_button_unchecked_rounded,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isMet ? FontWeight.w600 : FontWeight.w500,
            color: isMet ? const Color(0xFF16A34A) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationStatus(bool isMatch) {
    if (isMatch) {
      return Row(
        children: const [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 16,
            color: Color(0xFF16A34A),
          ),
          SizedBox(width: 6),
          Text(
            'Konfirmasi password sudah sesuai.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF16A34A),
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: const [
          Icon(
            Icons.cancel_outlined,
            size: 16,
            color: Color(0xFFEF4444),
          ),
          SizedBox(width: 6),
          Text(
            'Konfirmasi password belum sesuai.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFFEF4444),
            ),
          ),
        ],
      );
    }
  }
}
