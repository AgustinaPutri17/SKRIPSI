import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'siswa_beranda_tab.dart';
import 'siswa_presensi_tab.dart';
import 'siswa_logbook_tab.dart';
import 'siswa_projek_tab.dart';
import 'siswa_profil_tab.dart';

class SiswaMainScreen extends StatefulWidget {
  final int initialIndex;

  const SiswaMainScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<SiswaMainScreen> createState() => _SiswaMainScreenState();
}

class _SiswaMainScreenState extends State<SiswaMainScreen> {
  late int _currentIndex;
  int _presensiSubTab = 0;
  Key _presensiKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index, [int? subTab]) {
    setState(() {
      _currentIndex = index.clamp(0, 4);
      if (subTab != null) {
        _presensiSubTab = subTab;
        _presensiKey = UniqueKey();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      SiswaBerandaTab(onNavigateTab: _onTabTapped),
      SiswaPresensiTab(
        key: _presensiKey,
        initialSubTab: _presensiSubTab,
        onNavigateTab: _onTabTapped,
      ),
      SiswaLogbookTab(onNavigateTab: _onTabTapped),
      SiswaProjekTab(onNavigateTab: _onTabTapped),
      const SiswaProfilTab(),
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
          onTap: _onTabTapped,
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: const Color(0xFF64748B),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          items: const [
            // Exact 5 items matching the screenshots
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.grid_view_rounded, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.grid_view_rounded, size: 22, color: AppColors.primary),
              ),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.how_to_reg_rounded, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.how_to_reg_rounded, size: 22, color: AppColors.primary),
              ),
              label: 'Presensi',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.fact_check_outlined, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.fact_check_rounded, size: 22, color: AppColors.primary),
              ),
              label: 'Logbook',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.assignment_outlined, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.assignment_rounded, size: 22, color: AppColors.primary),
              ),
              label: 'Projek',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.person_outline_rounded, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.person_rounded, size: 22, color: AppColors.primary),
              ),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
