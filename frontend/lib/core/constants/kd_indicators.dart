/// Daftar resmi 7 indikator Kompetensi Dasar (KD) Logbook PKL.
class KdIndicators {
  KdIndicators._();

  static const List<String> list = [
    'Membuat Mockup aplikasi sesuai dengan rancangan',
    'Mengimplementasikan Mockup ke dalam layout User Interface',
    'Mengonfigurasi skrip web dari aplikasi perhitungan diskon',
    'Membuat diagram ERD serta identifikasi alur pemrograman dan algoritma',
    'Menampilkan hasil aplikasi perhitungan diskon',
    'Melakukan pengujian / debug setiap kode program',
    'Kegiatan operasional industri lainnya',
  ];

  /// Mengembalikan teks indikator KD untuk nomor 1..7.
  static String titleFor(int kdNumber) {
    final idx = (kdNumber - 1).clamp(0, list.length - 1);
    return list[idx];
  }

  /// Mencocokkan nomor KD (1..7) dari teks aktivitas atau nama KD.
  static int matchNumber(String rawText, {int fallback = 1}) {
    final lower = rawText.toLowerCase().trim();
    if (lower.isEmpty) return fallback;

    for (int i = 0; i < list.length; i++) {
      final candidate = list[i].toLowerCase();
      if (lower.contains(candidate) ||
          (lower.length >= 6 && candidate.contains(lower)) ||
          lower.contains('kd ${i + 1}') ||
          lower.contains('kd${i + 1}')) {
        return i + 1;
      }
    }

    // Fallback untuk data lama / penulisan singkat; KD 2 dicek sebelum KD 1 karena sama-sama memuat kata "mockup".
    if (lower.contains('mengimplementasi') ||
        lower.contains('layout') ||
        lower.contains('user interface') ||
        lower.contains('slicing') ||
        RegExp(r'\bui\b').hasMatch(lower)) {
      return 2;
    }
    if (lower.contains('mockup') || lower.contains('rancang')) {
      return 1;
    }
    if (lower.contains('skrip') ||
        lower.contains('script') ||
        lower.contains('konfigurasi') ||
        lower.contains('backend') ||
        RegExp(r'\bapi\b').hasMatch(lower)) {
      return 3;
    }
    if (lower.contains('erd') ||
        lower.contains('algoritma') ||
        lower.contains('alur pemrograman') ||
        lower.contains('database') ||
        lower.contains('basis data')) {
      return 4;
    }
    if (lower.contains('menampilkan hasil') ||
        lower.contains('perhitungan diskon')) {
      return 5;
    }
    if (lower.contains('pengujian') ||
        lower.contains('debug') ||
        lower.contains('bug') ||
        lower.contains('uji') ||
        lower.contains('test') ||
        lower.contains('validasi')) {
      return 6;
    }
    if (lower.contains('operasional') || lower.contains('industri')) {
      return 7;
    }
    return fallback;
  }

  /// Memisahkan `[Nama KD]` dari deskripsi kegiatan logbook.
  static ({int kdNumber, String kdName, String description}) extractFromActivity(
    String rawActivity,
    String rawDesc,
  ) {
    String kdName = '';
    String cleanDescription = rawDesc.trim();

    if (rawActivity.startsWith('[') && rawActivity.contains(']')) {
      final endIdx = rawActivity.indexOf(']');
      kdName = rawActivity.substring(1, endIdx).trim();
      if (cleanDescription.isEmpty || cleanDescription == rawActivity) {
        cleanDescription = rawActivity.substring(endIdx + 1).trim();
      }
    } else {
      kdName = rawActivity;
    }

    final int kdNumber = matchNumber(kdName, fallback: 7);

    if (cleanDescription.isEmpty) {
      cleanDescription = rawActivity.replaceAll('[$kdName]', '').trim();
      if (cleanDescription.isEmpty) cleanDescription = rawActivity;
    }

    return (
      kdNumber: kdNumber,
      kdName: kdName.isNotEmpty ? kdName : 'Kompetensi Dasar Terpenuhi',
      description: cleanDescription,
    );
  }
}

