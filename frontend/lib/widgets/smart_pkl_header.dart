import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Header konsisten sesuai desain aplikasi SMART PKL
/// Menampilkan logo merek 'SMART PKL', judul halaman aktif (Beranda/Projek),
/// dan tombol aksi profil siswa di sisi kanan atas.
class SmartPklHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onProfileTap;
  final bool showBackButton;
  final VoidCallback? onBackTap;
  final String? subtitle;

  const SmartPklHeader({
    super.key,
    required this.title,
    this.onProfileTap,
    this.showBackButton = false,
    this.onBackTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (showBackButton)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  onPressed: onBackTap ?? () => Navigator.of(context).maybePop(),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.background,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ),

            // Logo & Judul Halaman
            Expanded(
              child: Row(
                children: [
                  // Logo SMART PKL murni tanpa kotak / border segi empat (sesuai contoh gambar)
                  SizedBox(
                    width: 38,
                    height: 38,
                    child: Image.asset(
                      'assets/images/logo_smart_pkl.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.settings_rounded,
                        color: Color(0xFF2563EB),
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Teks Merek SMART PKL dan Judul Halaman
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'SMART PKL',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2563EB),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tombol Avatar Profil Lingkaran Biru
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onProfileTap,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x332563EB),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
