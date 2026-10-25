import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/smart_pkl_header.dart';
import '../../widgets/custom_button.dart';

class AdminRekapTab extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const AdminRekapTab({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<AdminRekapTab> createState() => _AdminRekapTabState();
}

class _AdminRekapTabState extends State<AdminRekapTab> {
  int _selectedJurusan = 0; // 0: RPL, 1: TKJ, 2: Multimedia

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SmartPklHeader(
              title: 'Rekapitulasi',
              subtitle: 'Laporan PKL',
              onProfileTap: () => widget.onNavigateTab?.call(3),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Jurusan Selector Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildJurusanChip(0, 'Rekayasa Perangkat Lunak (RPL)'),
                          const SizedBox(width: 8),
                          _buildJurusanChip(1, 'Teknik Komputer Jaringan (TKJ)'),
                          const SizedBox(width: 8),
                          _buildJurusanChip(2, 'Multimedia (MM)'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Rekap Card Summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ringkasan Kehadiran & Nilai PKL (RPL)',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem('Rata-rata Hadir', '94.8%', const Color(0xFF16A34A)),
                              Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
                              _buildStatItem('Logbook Terisi', '92.4%', AppColors.primary),
                              Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
                              _buildStatItem('Rata-rata Nilai', '87.5', const Color(0xFF7C3AED)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Table Rekap Per Kelas (Written directly in widgets)
                    const Text(
                      'Tabel Rekapitulasi Siswa',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder, width: 1),
                      ),
                      child: Column(
                        children: [
                          // Table Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
                            ),
                            child: const Row(
                              children: [
                                Expanded(flex: 3, child: Text('Nama Siswa', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                Expanded(flex: 2, child: Text('DUDI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                Expanded(flex: 1, child: Text('Hadir', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                Expanded(flex: 1, child: Text('Nilai', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                              ],
                            ),
                          ),
                          _buildTableRow('Ananda Putri', 'PT Telkom', '96%', '88 (A)'),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          _buildTableRow('Rizky Pratama', 'PT Astra', '92%', '85 (A-)'),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          _buildTableRow('Siti Nurhaliza', 'PT GoTo', '98%', '92 (A)'),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          _buildTableRow('Dimas Anggara', 'CV Sinergi', '84%', '78 (B)'),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          _buildTableRow('Maya Puspita', 'PT Telkom', '95%', '86 (A-)'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Export Buttons
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Cetak Rekap PDF',
                            icon: Icons.picture_as_pdf_rounded,
                            color: const Color(0xFFEF4444),
                            fontSize: 12,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Laporan Rekapitulasi PKL berhasil diekspor ke PDF')),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CustomButton(
                            text: 'Ekspor Excel (.xlsx)',
                            icon: Icons.table_view_rounded,
                            color: const Color(0xFF16A34A),
                            fontSize: 12,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Data Rekapitulasi PKL berhasil diekspor ke Excel')),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
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

  Widget _buildJurusanChip(int index, String title) {
    final bool isSelected = _selectedJurusan == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedJurusan = index;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7C3AED) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF7C3AED) : AppColors.cardBorder,
            width: 1,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildTableRow(String nama, String dudi, String hadir, String nilai) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(nama, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
          Expanded(flex: 2, child: Text(dudi, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
          Expanded(flex: 1, child: Text(hadir, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)))),
          Expanded(flex: 1, child: Text(nilai, textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary))),
        ],
      ),
    );
  }
}
