<?php

namespace App\Console\Commands;

use App\Models\Attendance;
use App\Models\LeaveRequest;
use App\Models\Placement;
use Carbon\Carbon;
use Illuminate\Console\Command;

class MarkAbsentStudentsCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'attendance:mark-absent {--date= : Tanggal target evaluasi (default: hari ini)} {--force : Jalankan tanpa menunggu jam pulang DUDI}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Otomatis menandai siswa yang tidak presensi dan tanpa izin sebagai Alfa (absent) sesuai jam kerja DUDI';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $targetDateStr = $this->option('date') ?: now()->toDateString();
        $targetDate = Carbon::parse($targetDateStr);
        $isForce = $this->option('force');

        $this->info("Menjalankan evaluasi kehadiran alfa untuk tanggal: {$targetDateStr}");

        $activePlacements = Placement::with(['student.user', 'location'])
            ->where('status', 'active')
            ->where('start_date', '<=', $targetDateStr)
            ->where('end_date', '>=', $targetDateStr)
            ->get();

        $markedCount = 0;
        $skippedCount = 0;

        foreach ($activePlacements as $placement) {
            $studentName = $placement->student?->name ?? 'Siswa';
            $location = $placement->location;
            $checkOutTimeStr = $location?->check_out_time ? substr($location->check_out_time, 0, 5) : '16:00';

            // Jika bukan force dan tanggalnya hari ini, pastikan sudah lewat jam pulang DUDI
            if (!$isForce && $targetDate->isToday()) {
                $closingTime = Carbon::parse($targetDateStr . ' ' . $checkOutTimeStr);
                if (now()->lt($closingTime)) {
                    $this->line("  [Menunggu] {$studentName} ({$location?->name}): Jam kerja DUDI belum berakhir (Jam pulang: {$checkOutTimeStr} WIB)");
                    continue;
                }
            }

            // 1. Cek apakah sudah ada presensi pada tanggal tersebut
            $existingAttendance = Attendance::where('placement_id', $placement->id)
                ->whereDate('attendance_date', $targetDateStr)
                ->first();

            if ($existingAttendance) {
                $skippedCount++;
                continue;
            }

            // 2. Cek apakah ada permohonan izin/sakit yang sudah disetujui (approved)
            $approvedLeave = LeaveRequest::where('placement_id', $placement->id)
                ->where('start_date', '<=', $targetDateStr)
                ->where('end_date', '>=', $targetDateStr)
                ->where('status', 'approved')
                ->first();

            if ($approvedLeave) {
                // Catat sebagai excused
                Attendance::create([
                    'placement_id' => $placement->id,
                    'attendance_date' => $targetDateStr,
                    'status' => 'excused',
                    'notes' => 'Izin/Sakit disetujui: ' . ($approvedLeave->reason ?? $approvedLeave->type),
                ]);
                $this->line("  [Izin] {$studentName} tercatat Izin/Sakit resmi.");
                continue;
            }

            // 3. Siswa tidak presensi dan tidak ada izin resmi -> Tandai sebagai Alfa (absent)
            Attendance::create([
                'placement_id' => $placement->id,
                'attendance_date' => $targetDateStr,
                'status' => 'absent',
                'notes' => "Alfa: Tidak presensi hingga batas jam kerja DUDI ({$checkOutTimeStr} WIB) tanpa keterangan",
            ]);

            $markedCount++;
            $this->warn("  [ALFA] {$studentName} ({$location?->name}) ditandai Alfa (tidak presensi).");
        }

        $this->info("Selesai! Ditandai Alfa: {$markedCount}, Sudah Hadir/Izin: {$skippedCount}");
        return Command::SUCCESS;
    }
}
