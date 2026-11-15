import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';

/// ==============================================================================
/// PDF VIEWER & DOWNLOADER SCREEN (Semua Role: DU/DI, Guru, Siswa, Admin)
/// Membaca, memperbesar (pinch zoom), mencetak, dan mengunduh berkas PDF
/// langsung di dalam aplikasi secara aman & responsif.
/// ==============================================================================
class PdfViewerScreen extends StatefulWidget {
  final String title;
  final int? projectId;
  final String? documentUrl;
  final Uint8List? initialBytes;

  const PdfViewerScreen({
    super.key,
    required this.title,
    this.projectId,
    this.documentUrl,
    this.initialBytes,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  Uint8List? _bytes;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialBytes != null) {
      _bytes = widget.initialBytes;
      _isLoading = false;
    } else {
      _fetchPdfBytes();
    }
  }

  Future<void> _fetchPdfBytes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await AuthService.getToken();
      final headers = <String, String>{
        'Accept': 'application/pdf',
      };
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      // 1. Coba endpoint langsung /api/projects/{id}/document
      if (widget.projectId != null) {
        final uri = Uri.parse('${AuthService.baseUrl}/projects/${widget.projectId}/document');
        final res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));
        if (res.statusCode >= 200 && res.statusCode < 300 && res.bodyBytes.isNotEmpty) {
          if (mounted) {
            setState(() {
              _bytes = res.bodyBytes;
              _isLoading = false;
            });
            return;
          }
        }
      }

      // 2. Coba documentUrl jika ada
      if (widget.documentUrl != null && widget.documentUrl!.isNotEmpty) {
        String url = widget.documentUrl!;
        if (url.contains('localhost:8000') || url.contains('127.0.0.1:8000')) {
          final activeHost = AuthService.baseUrl.replaceAll('/api', '');
          url = url
              .replaceAll('http://localhost:8000', activeHost)
              .replaceAll('http://127.0.0.1:8000', activeHost);
        }
        final res = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 15));
        if (res.statusCode >= 200 && res.statusCode < 300 && res.bodyBytes.isNotEmpty) {
          if (mounted) {
            setState(() {
              _bytes = res.bodyBytes;
              _isLoading = false;
            });
            return;
          }
        }
      }

      throw Exception('Gagal mengunduh atau membaca berkas PDF dari server.');
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Tidak dapat menampilkan dokumen: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          if (_bytes != null)
            IconButton(
              icon: const Icon(Icons.share_rounded, size: 20, color: Color(0xFF2563EB)),
              tooltip: 'Bagikan / Unduh PDF',
              onPressed: () => Printing.sharePdf(bytes: _bytes!, filename: widget.title),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF2563EB)),
                  SizedBox(height: 14),
                  Text('Memuat Berkas Dokumen PDF...', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFDC2626)),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _fetchPdfBytes,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Coba Lagi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : PdfPreview(
                  build: (format) => _bytes!,
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                  canDebug: false,
                  dynamicLayout: false,
                  allowPrinting: true,
                  allowSharing: true,
                  pdfFileName: widget.title,
                ),
    );
  }
}
