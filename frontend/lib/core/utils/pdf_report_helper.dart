import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/auth_service.dart';

class PdfReportHelper {
  static const List<String> _days = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static String _formatTanggal(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '-';
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final y = dt.year.toString();
      return '$d/$m/$y';
    } catch (_) {
      return rawDate;
    }
  }

  static String _formatHari(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '-';
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      return _days[dt.weekday - 1];
    } catch (_) {
      return '-';
    }
  }

  static String _formatJam(String? rawDateTime) {
    if (rawDateTime == null || rawDateTime.isEmpty) return '-';
    try {
      if (rawDateTime.contains('T')) {
        final dt = DateTime.parse(rawDateTime).toLocal();
        final h = dt.hour.toString().padLeft(2, '0');
        final m = dt.minute.toString().padLeft(2, '0');
        final s = dt.second.toString().padLeft(2, '0');
        return '$h:$m:$s';
      }
      return rawDateTime;
    } catch (_) {
      return rawDateTime;
    }
  }

  static String _cleanAttendanceStatus(String status, String rawNotes) {
    final s = status.toLowerCase();
    if (s == 'excused') {
      return rawNotes.toLowerCase().contains('(sick)') ? 'Sakit' : 'Izin';
    }
    switch (s) {
      case 'present':
        return 'Hadir Tepat Waktu';
      case 'late':
        return 'Terlambat';
      case 'sick':
        return 'Sakit';
      case 'leave':
        return 'Izin';
      case 'absent':
        return 'Alpha';
      default:
        return status.isNotEmpty
            ? '${status[0].toUpperCase()}${status.substring(1)}'
            : '-';
    }
  }

  static String _cleanAttendanceNotes(String rawNotes) {
    final trimmed = rawNotes.trim();
    if (trimmed.isEmpty) return '-';
    if (trimmed.startsWith('Terlambat ')) return '-';
    final match = RegExp(r'^Izin/Sakit\s*\([^)]+\):\s*(.+)$', caseSensitive: false)
        .firstMatch(trimmed);
    if (match != null) {
      return (match.group(1) ?? '').trim();
    }
    return trimmed;
  }

  static pw.Widget _buildHeader(String title, String subtitle) {
    final now = DateTime.now();
    final printedAt =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'SMART PKL - SISTEM MONITORING PRAKTIK KERJA LAPANGAN',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey900,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  subtitle,
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
            pw.Text(
              'Dicetak: $printedAt',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(thickness: 1.2, color: PdfColors.blue800),
        pw.SizedBox(height: 8),
      ],
    );
  }

  static Future<void> printAttendanceReport({
    required List<dynamic> attendances,
    String? dateLabel,
  }) async {
    final pdf = pw.Document();
    final subtitle = dateLabel != null
        ? 'Filter Tanggal: $dateLabel (${attendances.length} Data)'
        : 'Periode: Semua Tanggal (${attendances.length} Data)';

    final headers = [
      'No',
      'Hari / Tanggal',
      'NIS',
      'Nama Siswa',
      'Kelas / Jurusan',
      'DU/DI (Mitra)',
      'Jam Masuk',
      'Jam Pulang',
      'Status Kehadiran',
      'Keterangan',
    ];

    final rows = <List<String>>[];
    for (int i = 0; i < attendances.length; i++) {
      final item = attendances[i] as Map<String, dynamic>;
      final placement = item['placement'] as Map<String, dynamic>?;
      final student = placement?['student'] as Map<String, dynamic>?;
      final location = placement?['location'] as Map<String, dynamic>?;

      final rawDate = item['attendance_date']?.toString();
      final rawNotes = (item['notes'] ?? '').toString();
      final rawStatus = (item['status'] ?? 'present').toString();

      rows.add([
        '${i + 1}',
        '${_formatHari(rawDate)}\n${_formatTanggal(rawDate)}',
        student?['nis']?.toString() ?? '-',
        student?['name']?.toString() ?? 'Siswa',
        student?['class']?.toString() ?? student?['major']?.toString() ?? 'RPL',
        location?['name']?.toString() ?? '-',
        _formatJam(item['check_in_at']?.toString()),
        _formatJam(item['check_out_at']?.toString()),
        _cleanAttendanceStatus(rawStatus, rawNotes),
        _cleanAttendanceNotes(rawNotes),
      ]);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => _buildHeader(
          'LAPORAN REKAPITULASI KEHADIRAN SISWA PKL',
          subtitle,
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Halaman ${context.pageNumber} dari ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          if (rows.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.all(20),
              child: pw.Center(
                child: pw.Text(
                  'Belum ada data presensi pada periode ini.',
                  style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
                ),
              ),
            )
          else
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: rows,
              headerCount: 1,
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.6),
              headerStyle: pw.TextStyle(
                fontSize: 7.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              cellStyle: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey900),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
              columnWidths: {
                0: const pw.FixedColumnWidth(22), // No
                1: const pw.FixedColumnWidth(62), // Hari / Tanggal
                2: const pw.FixedColumnWidth(40), // NIS
                3: const pw.FlexColumnWidth(1.5), // Nama
                4: const pw.FlexColumnWidth(1.0), // Kelas
                5: const pw.FlexColumnWidth(1.3), // DU/DI
                6: const pw.FixedColumnWidth(46), // Masuk
                7: const pw.FixedColumnWidth(46), // Pulang
                8: const pw.FlexColumnWidth(1.1), // Status
                9: const pw.FlexColumnWidth(1.4), // Keterangan
              },
            ),
        ],
      ),
    );

    final Uint8List bytes = await pdf.save();
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'rekap_kehadiran_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static ({String kd, String deskripsi}) _extractKdAndDescription(
    String activity,
    String description,
  ) {
    final trimmedAct = activity.trim();
    final trimmedDesc = description.trim();
    String kd = '-';
    String cleanActBody = trimmedAct;

    final match = RegExp(r'^\[([^\]]+)\]\s*(.*)$', dotAll: true).firstMatch(trimmedAct);
    if (match != null) {
      kd = (match.group(1) ?? '-').trim();
      cleanActBody = (match.group(2) ?? '').trim();
    } else if (trimmedAct.isNotEmpty) {
      kd = trimmedAct;
    }

    String finalDesc = trimmedDesc.isNotEmpty ? trimmedDesc : cleanActBody;
    if (finalDesc.startsWith('[') && finalDesc.contains(']')) {
      finalDesc = finalDesc.substring(finalDesc.indexOf(']') + 1).trim();
    }
    if (finalDesc.isEmpty) {
      finalDesc = cleanActBody.isNotEmpty ? cleanActBody : '-';
    }

    return (kd: kd.isEmpty ? '-' : kd, deskripsi: finalDesc);
  }

  static bool _isSupportedRasterImage(Uint8List bytes) {
    if (bytes.length < 8) return false;
    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return true;
    // PNG: 89 50 4E 47 0D 0A 1A 0A
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true;
    }
    return false;
  }

  static Future<pw.MemoryImage?> _fetchPhotoImage(String? rawPhotoUrl) async {
    if (rawPhotoUrl == null || rawPhotoUrl.trim().isEmpty) return null;
    try {
      final formatted = AuthService.formatImageUrl(rawPhotoUrl);
      if (formatted.isEmpty) return null;
      final resp = await http
          .get(Uri.parse(formatted))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200 && _isSupportedRasterImage(resp.bodyBytes)) {
        return pw.MemoryImage(resp.bodyBytes);
      }
    } catch (_) {}
    return null;
  }

  static pw.Widget _cellText(
    String text, {
    bool bold = false,
    PdfColor color = PdfColors.grey900,
    double fontSize = 7.5,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  static Future<void> printLogbookReport({
    required List<dynamic> logbooks,
    String? dateLabel,
  }) async {
    final pdf = pw.Document();
    final subtitle = dateLabel != null
        ? 'Filter Tanggal: $dateLabel (${logbooks.length} Jurnal Disetujui)'
        : 'Periode: Semua Tanggal (${logbooks.length} Jurnal Disetujui)';

    // Ambil foto dokumentasi secara paralel sebelum menyusun halaman PDF
    final List<pw.MemoryImage?> loadedPhotos = await Future.wait(
      logbooks.map((raw) {
        final item = raw as Map<String, dynamic>;
        return _fetchPhotoImage(item['photo_url']?.toString());
      }),
    );

    final tableRows = <pw.TableRow>[
      pw.TableRow(
        repeat: true,
        decoration: const pw.BoxDecoration(color: PdfColors.blue800),
        children: [
          _cellText('No', bold: true, color: PdfColors.white, align: pw.TextAlign.center),
          _cellText('Hari / Tanggal', bold: true, color: PdfColors.white),
          _cellText('NIS', bold: true, color: PdfColors.white),
          _cellText('Nama Siswa', bold: true, color: PdfColors.white),
          _cellText('DU/DI (Mitra)', bold: true, color: PdfColors.white),
          _cellText('Kompetensi Dasar (KD)', bold: true, color: PdfColors.white),
          _cellText('Deskripsi Kegiatan', bold: true, color: PdfColors.white),
          _cellText('Foto Kegiatan', bold: true, color: PdfColors.white, align: pw.TextAlign.center),
          _cellText('Catatan Pembimbing', bold: true, color: PdfColors.white),
        ],
      ),
    ];

    for (int i = 0; i < logbooks.length; i++) {
      final item = logbooks[i] as Map<String, dynamic>;
      final placement = item['placement'] as Map<String, dynamic>?;
      final student = (item['student'] as Map<String, dynamic>?) ??
          (placement?['student'] as Map<String, dynamic>?);
      final location = (item['location'] as Map<String, dynamic>?) ??
          (placement?['location'] as Map<String, dynamic>?);
      final verifier = item['verifier'] as Map<String, dynamic>?;

      final rawDate =
          item['logbook_date']?.toString() ?? item['journal_date']?.toString();
      final tgl = _formatTanggal(rawDate);
      final hari = _formatHari(rawDate);

      final studentName = student?['name']?.toString() ?? 'Siswa';
      final nis = student?['nis']?.toString() ?? '-';
      final dudiName = location?['name']?.toString() ?? '-';

      final parsed = _extractKdAndDescription(
        item['activity']?.toString() ?? '',
        item['description']?.toString() ?? '',
      );

      final resultText = (item['result']?.toString() ?? '').trim();
      final obstaclesText = (item['obstacles']?.toString() ?? '').trim();
      final descBuffer = StringBuffer(parsed.deskripsi);
      if (resultText.isNotEmpty) {
        descBuffer.write('\nHasil: $resultText');
      }
      if (obstaclesText.isNotEmpty) {
        descBuffer.write('\nKendala: $obstaclesText');
      }

      final dudiReviewer = (item['dudi_name']?.toString() ?? '').trim();
      final fallbackReviewer = (verifier?['name']?.toString() ?? '').trim();
      final reviewer = dudiReviewer.isNotEmpty ? dudiReviewer : fallbackReviewer;

      final dudiNote = (item['dudi_note']?.toString() ?? '').trim();
      final fallbackNote = (item['verification_note']?.toString() ??
              item['verification_comment']?.toString() ??
              '')
          .trim();
      final noteRaw = (dudiNote.isNotEmpty ? dudiNote : fallbackNote)
          .replaceAll(RegExp(r'\s*\n+\s*'), ' ')
          .trim();

      final String finalNote;
      if (noteRaw.isNotEmpty && reviewer.isNotEmpty) {
        finalNote = '$noteRaw ($reviewer)';
      } else if (noteRaw.isNotEmpty) {
        finalNote = noteRaw;
      } else if (reviewer.isNotEmpty) {
        finalNote = '($reviewer)';
      } else {
        finalNote = '-';
      }

      final photoUrl = item['photo_url']?.toString() ?? '';
      final photoImg = loadedPhotos[i];

      tableRows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: i.isOdd ? PdfColors.grey100 : PdfColors.white,
          ),
          verticalAlignment: pw.TableCellVerticalAlignment.middle,
          children: [
            _cellText('${i + 1}', align: pw.TextAlign.center),
            _cellText('$hari\n$tgl'),
            _cellText(nis),
            _cellText(studentName),
            _cellText(dudiName),
            _cellText(parsed.kd),
            _cellText(descBuffer.toString()),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Center(
                child: photoImg != null
                    ? pw.Container(
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300, width: 0.6),
                        ),
                        child: pw.Image(
                          photoImg,
                          width: 64,
                          height: 46,
                          fit: pw.BoxFit.cover,
                        ),
                      )
                    : pw.Text(
                        photoUrl.trim().isNotEmpty
                            ? 'Foto terlampir'
                            : 'Tidak ada foto',
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(
                          fontSize: 7,
                          color: PdfColors.grey600,
                        ),
                      ),
              ),
            ),
            _cellText(finalNote),
          ],
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => _buildHeader(
          'LAPORAN REKAPITULASI LOGBOOK / JURNAL HARIAN PKL',
          subtitle,
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Halaman ${context.pageNumber} dari ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          if (logbooks.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.all(20),
              child: pw.Center(
                child: pw.Text(
                  'Belum ada logbook yang disetujui pada periode ini.',
                  style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
                ),
              ),
            )
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.6),
              columnWidths: {
                0: const pw.FixedColumnWidth(22), // No
                1: const pw.FixedColumnWidth(58), // Hari / Tanggal
                2: const pw.FixedColumnWidth(40), // NIS
                3: const pw.FlexColumnWidth(1.1), // Nama Siswa
                4: const pw.FlexColumnWidth(1.0), // DU/DI
                5: const pw.FlexColumnWidth(1.5), // KD
                6: const pw.FlexColumnWidth(1.5), // Deskripsi
                7: const pw.FixedColumnWidth(76), // Foto
                8: const pw.FlexColumnWidth(1.4), // Catatan Pembimbing
              },
              children: tableRows,
            ),
        ],
      ),
    );

    final Uint8List bytes = await pdf.save();
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'rekap_logbook_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }
}

