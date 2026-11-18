<?php

namespace App\Helpers;

class ProjectPdfGenerator
{
    /**
     * Generate a fully-compliant PDF 1.4 document containing the project submission details.
     */
    public static function generatePdf($project): string
    {
        $title = $project->title ?? 'Projek Siswa';
        $docName = $project->document_name ?? 'Dokumen_Projek.pdf';
        $studentName = $project->placement?->student?->name ?? 'Siswa PKL';
        $nis = $project->placement?->student?->nis ?? '-';
        $dudiName = $project->placement?->location?->name ?? 'Mitra DU/DI';
        $plan = $project->plan ?? '-';
        $result = $project->result ?? '-';
        $desc = $project->description ?? '-';
        $statusRaw = strtolower($project->status ?? 'submitted');
        $statusLabel = match($statusRaw) {
            'approved' => 'Disetujui',
            'revision', 'rejected' => 'Direvisi',
            default => 'Menunggu',
        };
        $date = $project->submitted_at
            ? date('d F Y', strtotime($project->submitted_at))
            : ($project->created_at ? $project->created_at->format('d F Y') : date('d F Y'));

        $esc = function (string $text): string {
            $clean = preg_replace('/[^\x20-\x7E]/', ' ', $text);
            return str_replace(['\\', '(', ')'], ['\\\\', '\\(', '\\)'], $clean);
        };

        // Split text into lines of max characters
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
        $pdfLines[] = "0.75 w 50 $y m 545 $y l S";
        $y -= 20;

        // Section 1: Identitas
        $pdfLines[] = "BT /F1 11 Tf 50 $y Td (" . $esc("1. Informasi Siswa & Penempatan") . ") Tj ET";
        $y -= 16;
        $pdfLines[] = "BT /F2 9.5 Tf 65 $y Td (" . $esc("Nama Siswa        : $studentName (NIS: $nis)") . ") Tj ET";
        $y -= 14;
        $pdfLines[] = "BT /F2 9.5 Tf 65 $y Td (" . $esc("Mitra DU/DI       : $dudiName") . ") Tj ET";
        $y -= 14;
        $pdfLines[] = "BT /F2 9.5 Tf 65 $y Td (" . $esc("Lampiran Berkas   : $docName") . ") Tj ET";
        $y -= 14;
        $pdfLines[] = "BT /F2 9.5 Tf 65 $y Td (" . $esc("Status Verifikasi : $statusLabel") . ") Tj ET";
        $y -= 14;
        $pdfLines[] = "BT /F2 9.5 Tf 65 $y Td (" . $esc("Tanggal Diajukan  : $date") . ") Tj ET";
        $y -= 20;

        // Section 2: Judul & Deskripsi
        $pdfLines[] = "BT /F1 11 Tf 50 $y Td (" . $esc("2. Nama & Deskripsi Pekerjaan") . ") Tj ET";
        $y -= 16;
        $pdfLines[] = "BT /F1 9.5 Tf 65 $y Td (" . $esc("Judul : " . substr($title, 0, 70)) . ") Tj ET";
        $y -= 14;
        $descLines = $wrapText("Deskripsi : " . $desc, 70);
        foreach ($descLines as $dl) {
            $pdfLines[] = "BT /F2 9.5 Tf 65 $y Td ($dl) Tj ET";
            $y -= 14;
        }
        $y -= 6;

        // Section 3: Perencanaan (Planning)
        $pdfLines[] = "BT /F1 11 Tf 50 $y Td (" . $esc("3. Perencanaan Kegiatan (Planning)") . ") Tj ET";
        $y -= 16;
        $planLines = $wrapText($plan, 72);
        foreach ($planLines as $pl) {
            $pdfLines[] = "BT /F2 9.5 Tf 65 $y Td ($pl) Tj ET";
            $y -= 14;
        }
        $y -= 6;

        // Section 4: Pelaksanaan Kegiatan / Hasil Karya
        $pdfLines[] = "BT /F1 11 Tf 50 $y Td (" . $esc("4. Pelaksanaan Kegiatan / Hasil Karya") . ") Tj ET";
        $y -= 16;
        $resLines = $wrapText($result, 72);
        foreach ($resLines as $rl) {
            $pdfLines[] = "BT /F2 9.5 Tf 65 $y Td ($rl) Tj ET";
            $y -= 14;
        }
        $y -= 6;

        // Section 5: Catatan Bimbingan / Verifikasi jika ada
        if (!empty($project->reviews) && count($project->reviews) > 0) {
            $pdfLines[] = "BT /F1 11 Tf 50 $y Td (" . $esc("5. Catatan Bimbingan & Catatan Pembimbing") . ") Tj ET";
            $y -= 16;
            foreach ($project->reviews as $rev) {
                $revRole = ($rev->reviewer?->role === 'teacher') ? 'Guru Sekolah' : 'Pembimbing DU/DI';
                $revNote = $rev->note ?? '-';
                $pdfLines[] = "BT /F1 9 Tf 65 $y Td (" . $esc("• Dari $revRole (" . ($rev->reviewer?->name ?? 'Pembimbing') . "):") . ") Tj ET";
                $y -= 13;
                $noteLines = $wrapText($revNote, 70);
                foreach ($noteLines as $nl) {
                    $pdfLines[] = "BT /F2 9 Tf 75 $y Td ($nl) Tj ET";
                    $y -= 13;
                }
            }
        }

        // Footer
        $pdfLines[] = "0.5 w 50 60 m 545 60 l S";
        $pdfLines[] = "BT /F2 8 Tf 50 46 Td (" . $esc("Dokumen ini dihasilkan secara otomatis oleh SMART PKL - SMK PKL Monitoring System.") . ") Tj ET";
        $pdfLines[] = "BT /F2 8 Tf 450 46 Td (" . $esc("Halaman 1 dari 1") . ") Tj ET";

        $stream = implode("\n", $pdfLines);
        $streamLen = strlen($stream);

        $objects = [];
        $objects[1] = "<< /Type /Catalog /Pages 2 0 R >>";
        $objects[2] = "<< /Type /Pages /Kids [3 0 R] /Count 1 >>";
        $objects[3] = "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595.28 841.89] /Contents 4 0 R /Resources << /Font << /F1 5 0 R /F2 6 0 R >> >> >>";
        $objects[4] = "<< /Length $streamLen >>\nstream\n" . $stream . "\nendstream";
        $objects[5] = "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>";
        $objects[6] = "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>";

        $output = "%PDF-1.4\n";
        $offsets = [];
        for ($i = 1; $i <= 6; $i++) {
            $offsets[$i] = strlen($output);
            $output .= "$i 0 obj\n" . $objects[$i] . "\nendobj\n";
        }
        $xrefOffset = strlen($output);
        $output .= "xref\n0 7\n0000000000 65535 f \n";
        for ($i = 1; $i <= 6; $i++) {
            $output .= sprintf("%010d 00000 n \n", $offsets[$i]);
        }
        $output .= "trailer\n<< /Size 7 /Root 1 0 R >>\nstartxref\n$xrefOffset\n%%EOF";

        return $output;
    }
}
