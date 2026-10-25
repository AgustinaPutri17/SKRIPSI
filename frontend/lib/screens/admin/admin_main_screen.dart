import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'admin_dashboard_tab.dart';
import 'admin_master_tab.dart';
import 'admin_rekap_tab.dart';
import 'admin_profil_tab.dart';

/// Halaman Navigasi Utama Portal Administrator (SMART PKL)
/// Menggunakan 4 Navigasi Bar Utama Sesuai Mockup Desain Mobile:
/// 1. Beranda (Dashboard Statistik Real-time 4.1)
/// 2. Master (Master Data Siswa 4.3, Guru Pembimbing 4.4, & Mitra DU/DI)
/// 3. Nilai (Rekap Penilaian & KKM PKL)
/// 4. Profil (Pengaturan Kredensial Admin & Manajemen User 4.2)
class AdminMainScreen extends StatefulWidget {
  final int initialIndex;

  const AdminMainScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  late int _currentIndex;
  final GlobalKey<AdminMasterTabState> _masterTabKey = GlobalKey<AdminMasterTabState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index, {int? subIndex}) {
    final safeIndex = index.clamp(0, 3);
    setState(() {
      _currentIndex = safeIndex;
    });
    if (safeIndex == 1 && subIndex != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _masterTabKey.currentState?.setSubTab(subIndex);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      AdminDashboardTab(onNavigateTab: _onTabTapped),
      AdminMasterTab(key: _masterTabKey, onNavigateTab: _onTabTapped),
      AdminRekapTab(onNavigateTab: (idx) => _onTabTapped(idx)),
      const AdminProfilTab(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.cardBorder.withValues(alpha: 0.8), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (idx) => _onTabTapped(idx),
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF2563EB), // Primary Blue
          unselectedItemColor: const Color(0xFF64748B),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          items: const [
            // 1. Beranda (Dashboard 4.1)
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.grid_view_outlined, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.grid_view_rounded, size: 22),
              ),
              label: 'Beranda',
            ),
            // 2. Data Master (Siswa 4.3 & Guru 4.4)
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.folder_open_outlined, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.folder_rounded, size: 22),
              ),
              label: 'Master',
            ),
            // 3. Nilai PKL
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.fact_check_outlined, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.fact_check_rounded, size: 22),
              ),
              label: 'Nilai',
            ),
            // 4. Profil & Pengaturan Kredensial 4.2
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.person_outline_rounded, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.person_rounded, size: 22),
              ),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
