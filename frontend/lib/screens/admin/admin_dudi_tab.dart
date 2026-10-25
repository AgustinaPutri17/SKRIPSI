import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/smart_pkl_header.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/custom_button.dart';

class AdminDudiTab extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const AdminDudiTab({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<AdminDudiTab> createState() => _AdminDudiTabState();
}

class _AdminDudiTabState extends State<AdminDudiTab> {
  bool _showAddModal = false;
  final TextEditingController _namaDudiController = TextEditingController();
  final TextEditingController _bidangController = TextEditingController();
  final TextEditingController _kuotaController = TextEditingController(text: '4');

  @override
  void dispose() {
    _namaDudiController.dispose();
    _bidangController.dispose();
    _kuotaController.dispose();
    super.dispose();
  }

  void _handleSimpanDudi() {
    setState(() {
      _showAddModal = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mitra Industri Baru berhasil didaftarkan ke sistem PKL!'),
        backgroundColor: Color(0xFF16A34A),
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
              title: 'Mitra DUDI',
              subtitle: '35 Mitra',
              onProfileTap: () => widget.onNavigateTab?.call(3),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search & Add Button
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.cardBorder, width: 1),
                            ),
                            child: const TextField(
                              decoration: InputDecoration(
                                hintText: 'Cari nama perusahaan atau kota...',
                                hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                icon: Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _showAddModal = !_showAddModal;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          ),
                          child: const Icon(Icons.add_business_rounded, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (_showAddModal) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF93C5FD), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pendaftaran Perusahaan DUDI Baru',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 12),
                            const Text('Nama Perusahaan / PT / CV', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _namaDudiController,
                              decoration: const InputDecoration(
                                hintText: 'Contoh: PT Bank Mandiri Digital Hub',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text('Bidang Industri & Keahlian', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _bidangController,
                              decoration: const InputDecoration(
                                hintText: 'Contoh: Fintech, Frontend, Cloud Computing',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text('Kuota Siswa Magang', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _kuotaController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: 'Jumlah kuota penempatan',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                            const SizedBox(height: 14),
                            CustomButton(
                              text: 'Simpan Mitra DUDI',
                              icon: Icons.check,
                              onPressed: _handleSimpanDudi,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // DUDI List (Written directly in widgets)
                    _buildDudiCard(
                      nama: 'PT Telkom Digital Solutions',
                      bidang: 'Software Engineering, Mobile Apps & Web',
                      lokasi: 'Jl. Telekomunikasi No. 1, Bandung',
                      kuota: '6 Siswa Terisi Penuh',
                      radius: '50 Meter (Geofence Aktif)',
                      pic: 'Hendra Wijaya, S.T. (Lead Engineer)',
                      isFull: true,
                    ),
                    const SizedBox(height: 12),

                    _buildDudiCard(
                      nama: 'PT Astra Graphia IT Division',
                      bidang: 'Network Infrastructure & Hardware',
                      lokasi: 'Jl. Kramat Raya No. 43, Jakarta Pusat',
                      kuota: '4 dari 5 Kuota Terisi (Sisa 1)',
                      radius: '75 Meter (Geofence Aktif)',
                      pic: 'Bambang Sudibyo, S.Kom (IT Manager)',
                      isFull: false,
                    ),
                    const SizedBox(height: 12),

                    _buildDudiCard(
                      nama: 'PT GoTo Gojek Tokopedia',
                      bidang: 'Product Design & Mobile Development',
                      lokasi: 'Gedung Pasaraya Blok M, Jakarta Selatan',
                      kuota: '4 Siswa Terisi Penuh',
                      radius: '100 Meter (Geofence Aktif)',
                      pic: 'Kevin Sanjaya, M.T. (Senior Dev)',
                      isFull: true,
                    ),
                    const SizedBox(height: 12),

                    _buildDudiCard(
                      nama: 'CV Sinergi Mediatech',
                      bidang: 'Multimedia, UI/UX & Web Developer',
                      lokasi: 'Jl. Riau No. 88, Bandung',
                      kuota: '2 dari 3 Kuota Terisi (Sisa 1)',
                      radius: '40 Meter (Geofence Aktif)',
                      pic: 'Ahmad Faisal, S.T. (Direktur)',
                      isFull: false,
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

  Widget _buildDudiCard({
    required String nama,
    required String bidang,
    required String lokasi,
    required String kuota,
    required String radius,
    required String pic,
    required bool isFull,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  nama,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(
                text: isFull ? 'Kuota Penuh' : 'Tersedia Kuota',
                style: isFull ? PillStyle.neutral : PillStyle.success,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            bidang,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(lokasi, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.person_pin_circle_outlined, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text('PIC: $pic', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.group_outlined, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(kuota, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.gps_fixed_rounded, size: 13, color: Color(0xFF16A34A)),
                    const SizedBox(width: 4),
                    Text(radius, style: const TextStyle(fontSize: 10, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
