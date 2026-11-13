import 'package:flutter/material.dart';
import 'guru_beranda_tab.dart';
import 'guru_rekap_tab.dart';
import 'guru_verifikasi_tab.dart';
import 'guru_profil_tab.dart';

class GuruMainScreen extends StatefulWidget {
  final int initialIndex;

  const GuruMainScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<GuruMainScreen> createState() => _GuruMainScreenState();
}

class _GuruMainScreenState extends State<GuruMainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index.clamp(0, 3);
    });
  }

  @override
  Widget build(BuildContext context) {
    // 4 Tab Navigasi Guru Pembimbing:
    // 0: Dashboard (Beranda)
    // 1: Izin & Sakit (Pengajuan Izin / Sakit Siswa Bimbingan)
    // 2: Logbook (Verifikasi Logbook Harian Siswa)
    // 3: Profil
    final List<Widget> pages = [
      GuruBerandaTab(onNavigateTab: _onTabTapped),
      GuruRekapTab(onNavigateTab: _onTabTapped),
      GuruVerifikasiTab(onNavigateTab: _onTabTapped),
      const GuruProfilTab(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
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
          selectedItemColor: const Color(0xFF2563EB), // Blue primary accent matching mockup
          unselectedItemColor: const Color(0xFF64748B),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          items: const [
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
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.medical_services_outlined, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.medical_services_rounded, size: 22),
              ),
              label: 'Izin & Sakit',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.fact_check_outlined, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.fact_check_rounded, size: 22),
              ),
              label: 'Logbook',
            ),
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
