<?php

namespace App\Helpers;

class ProjectPdfGenerator
{
    /**
     * Generate a fully-compliant PDF 1.4 document containing the project submission details.
     */
    public static function generatePdf($project): string
    {
        try {
            $title = !empty($project->title) ? (string)$project->title : 'Projek Siswa';
            $docName = !empty($project->document_name) ? (string)$project->document_name : 'Dokumen_Projek.pdf';
            $studentName = $project->placement?->student?->name ?? 'Siswa PKL';
            $nis = $project->placement?->student?->nis ?? '-';
            $dudiName = $project->placement?->location?->name ?? 'Mitra DU/DI';
            $plan = !empty($project->plan) ? (string)$project->plan : '-';
            $result = !empty($project->result) ? (string)$project->result : '-';
            $desc = !empty($project->description) ? (string)$project->description : '-';
            $statusRaw = strtolower((string)($project->status ?? 'submitted'));
            $statusLabel = match($statusRaw) {
                'approved' => 'Disetujui',
                'revision', 'rejected' => 'Direvisi',
                default => 'Menunggu',
            };

            $date = date('d F Y');
            if (!empty($project->submitted_at)) {
                $ts = strtotime((string)$project->submitted_at);
                if ($ts) $date = date('d F Y', $ts);
            } elseif (!empty($project->created_at)) {
                $ts = strtotime((string)$project->created_at);
                if ($ts) $date = date('d F Y', $ts);
            }

            $esc = function (string $text): string {
                $clean = preg_replace('/[^\x20-\x7E]/', ' ', $text);
                return str_replace(['\\', '(', ')'], ['\\\\', '\\(', '\\)'], $clean);
            };

            $wrapText = function (string $text, int $maxLen = 75) use ($esc): array {
                $words = explode(' ', $text);
                $lines = [];
                $currentLine = '';
                foreach ($words as $w) {
                    if (strlen($currentLine . ' ' . $w) <= $maxLen) {
                        $currentLine = ($currentLine === '') ? $w : $currentLine . ' ' . $w;
                    } else {
                        if ($currentLine !== '') $lines[] = $currentLine;
                        $currentLine = $w;
                    }
                }
                if ($currentLine !== '') $lines[] = $currentLine;
                if (empty($lines)) $lines[] = '-';
                return array_map($esc, $lines);
            };

            $pdfLines = [];
            $y = 800;

            // Header
            $pdfLines[] = "BT /F1 15 Tf 50 $y Td (" . $esc("SMART PKL - DOKUMEN PROJEK SISWA") . ") Tj ET";
            $y -= 18;
            $pdfLines[] = "BT /F2 9 Tf 50 $y Td (" . $esc("Sistem Informasi Monitoring Praktik Kerja Lapangan Terintegrasi") . ") Tj ET";
            $y -= 8;
            $pdfLines[] = "0.75 0.75 0.75 RG 1.5 w 50 $y m 545 $y l S";
            $y -= 25;

            // Metadata Box
            $pdfLines[] = "0.96 0.97 0.99 rg 50 " . ($y - 75) . " 495 85 re f";
            $pdfLines[] = "0.85 0.90 0.98 RG 1 w 50 " . ($y - 75) . " 495 85 re S";
            $boxY = $y - 14;
            $pdfLines[] = "BT /F1 12 Tf 65 $boxY Td (" . $esc($title) . ") Tj ET";
            $boxY -= 17;
            $pdfLines[] = "BT /F2 9.5 Tf 65 $boxY Td (" . $esc("Siswa: $studentName (NIS: $nis) | Lokasi PKL: $dudiName") . ") Tj ET";
            $boxY -= 15;
            $pdfLines[] = "BT /F2 9 Tf 65 $boxY Td (" . $esc("Status Berkas: $statusLabel | Tanggal: $date") . ") Tj ET";
            $boxY -= 14;
            $pdfLines[] = "BT /F2 8.5 Tf 65 $boxY Td (" . $esc("Nama Berkas Asli: $docName") . ") Tj ET";

            $y -= 95;

            // Section 1: Perencanaan (Planning)
            $pdfLines[] = "BT /F1 10.5 Tf 50 $y Td (" . $esc("1. Perencanaan Kegiatan (Planning)") . ") Tj ET";
            $y -= 14;
            $planLines = $wrapText($plan, 78);
            foreach ($planLines as $line) {
                $pdfLines[] = "BT /F2 9.5 Tf 58 $y Td ($line) Tj ET";
                $y -= 13;
            }
            $y -= 10;

            // Section 2: Pelaksanaan / Hasil Karya
            $pdfLines[] = "BT /F1 10.5 Tf 50 $y Td (" . $esc("2. Pelaksanaan Kegiatan / Hasil Karya") . ") Tj ET";
            $y -= 14;
            $resLines = $wrapText($result, 78);
            foreach ($resLines as $line) {
                $pdfLines[] = "BT /F2 9.5 Tf 58 $y Td ($line) Tj ET";
                $y -= 13;
            }
            $y -= 10;

            // Section 3: Deskripsi / Catatan Tambahan
            if ($desc !== '-' && $desc !== '') {
                $pdfLines[] = "BT /F1 10.5 Tf 50 $y Td (" . $esc("3. Deskripsi Singkat") . ") Tj ET";
                $y -= 14;
                $descLines = $wrapText($desc, 78);
                foreach ($descLines as $line) {
                    $pdfLines[] = "BT /F2 9.5 Tf 58 $y Td ($line) Tj ET";
                    $y -= 13;
                }
                $y -= 10;
            }

            // Reviews / Catatan Pembimbing
            $reviews = !empty($project->reviews) ? $project->reviews : [];
            if (!empty($reviews)) {
                $pdfLines[] = "BT /F1 10.5 Tf 50 $y Td (" . $esc("Catatan Evaluasi & Bimbingan") . ") Tj ET";
                $y -= 14;
                foreach ($reviews as $rev) {
                    $reviewer = $rev->reviewer?->name ?? 'Pembimbing';
                    $note = $rev->note ?? '-';
                    $decision = $rev->decision ?? '-';
                    $revText = "• $reviewer ($decision): $note";
                    foreach ($wrapText($revText, 76) as $rline) {
                        $pdfLines[] = "BT /F2 9 Tf 58 $y Td ($rline) Tj ET";
                        $y -= 12;
                    }
                }
                $y -= 10;
            }

            // Footer
            $pdfLines[] = "0.85 0.85 0.85 RG 0.5 w 50 50 m 545 50 l S";
            $pdfLines[] = "BT /F2 8 Tf 50 38 Td (" . $esc("Dokumen ini disinkronkan & disajikan resmi melalui Sistem SMART PKL SMK.") . ") Tj ET";

            $streamContent = implode("\n", $pdfLines);
            $streamLength = strlen($streamContent);

            $objects = [];
            $objects[1] = "<< /Type /Catalog /Pages 2 0 R >>";
            $objects[2] = "<< /Type /Pages /Kids [3 0 R] /Count 1 >>";
            $objects[3] = "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595.28 841.89] /Contents 4 0 R /Resources << /Font << /F1 5 0 R /F2 6 0 R >> >> >>";
            $objects[4] = "<< /Length $streamLength >>\nstream\n$streamContent\nendstream";
            $objects[5] = "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>";
            $objects[6] = "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>";

            $pdf = "%PDF-1.4\n";
            $offsets = [];
            foreach ($objects as $num => $obj) {
                $offsets[$num] = strlen($pdf);
                $pdf .= "$num 0 obj\n$obj\nendobj\n";
            }

            $xrefOffset = strlen($pdf);
            $pdf .= "xref\n0 " . (count($objects) + 1) . "\n";
            $pdf .= "0000000000 65535 f \n";
            for ($i = 1; $i <= count($objects); $i++) {
                $pdf .= sprintf("%010d 00000 n \n", $offsets[$i]);
            }

            $pdf .= "trailer\n<< /Size " . (count($objects) + 1) . " /Root 1 0 R >>\n";
            $pdf .= "startxref\n$xrefOffset\n%%EOF\n";

            return $pdf;
        } catch (\Throwable $e) {
            // Absolute minimal valid PDF fallback
            $stream = "BT /F1 12 Tf 50 750 Td (SMART PKL - Dokumen Projek) Tj ET";
            $len = strlen($stream);
            return "%PDF-1.4\n1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>\nendobj\n4 0 obj\n<< /Length $len >>\nstream\n$stream\nendstream\nendobj\n5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\nxref\n0 6\n0000000000 65535 f \n0000000009 00000 n \n0000000058 00000 n \n0000000115 00000 n \n0000000224 00000 n \n0000000305 00000 n \ntrailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n382\n%%EOF\n";
        }
    }
}
