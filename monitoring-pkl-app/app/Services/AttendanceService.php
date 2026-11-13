<?php

namespace App\Services;

use App\Models\Attendance;
use App\Models\Placement;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class AttendanceService
{
    public function __construct(
        protected GeoService $geoService
    ) {}

    /**
     * Process check-in for a student.
     *
     * @throws \Exception
     */
    public function checkIn(
        Placement $placement,
        float $latitude,
        float $longitude,
        float $accuracy,
        UploadedFile $photo
    ): Attendance {
        // Validate placement is active
        if (!$placement->isActive()) {
            throw new \Exception('Placement tidak aktif.', 422);
        }

        $today = now()->toDateString();

        // Check if already checked in today
        $existing = Attendance::where('placement_id', $placement->id)
            ->whereDate('attendance_date', $today)
            ->first();

        if ($existing && $existing->hasCheckedIn()) {
            throw new \Exception('Anda sudah melakukan check-in hari ini.', 422);
        }

        // Calculate distance from location
        $location = $placement->location;
        $geoResult = $this->geoService->isWithinRadius(
            $latitude,
            $longitude,
            (float) $location->latitude,
            (float) $location->longitude,
            $location->radius
        );

        if (!$geoResult['within']) {
            throw new \Exception(
                "Anda berada di luar radius lokasi PKL. Jarak: {$geoResult['distance']}m, Radius: {$location->radius}m.",
                422
            );
        }

        // Store photo
        $photoPath = $photo->store('attendances/check-in/' . $today, 'public');

        // Evaluasi jam presensi masuk terhadap jam kantor DUDI siswa
        $currentTime = now();
        $targetCheckInTimeStr = $location->check_in_time ? substr($location->check_in_time, 0, 5) : '08:00';
        $targetTime = \Carbon\Carbon::parse($today . ' ' . $targetCheckInTimeStr);

        $status = 'present';
        $lateMinutes = 0;
        $notes = 'Hadir tepat waktu';

        if ($currentTime->gt($targetTime)) {
            $status = 'late';
            $lateMinutes = (int) $targetTime->diffInMinutes($currentTime);
            $notes = "Terlambat {$lateMinutes} menit (Batas masuk DUDI: {$targetCheckInTimeStr} WIB)";
        } else {
            $status = 'present';
            $lateMinutes = 0;
            $notes = "Hadir tepat waktu (Sebelum {$targetCheckInTimeStr} WIB)";
        }

        return DB::transaction(function () use ($placement, $today, $latitude, $longitude, $accuracy, $geoResult, $photoPath, $existing, $status, $lateMinutes, $notes, $currentTime) {
            if ($existing) {
                $existing->update([
                    'check_in_at' => $currentTime,
                    'check_in_latitude' => $latitude,
                    'check_in_longitude' => $longitude,
                    'check_in_accuracy' => $accuracy,
                    'check_in_distance' => $geoResult['distance'],
                    'check_in_photo_path' => $photoPath,
                    'status' => $status,
                    'late_minutes' => $lateMinutes,
                    'notes' => $notes,
                ]);
                return $existing->fresh();
            }

            return Attendance::create([
                'placement_id' => $placement->id,
                'attendance_date' => $today,
                'check_in_at' => $currentTime,
                'check_in_latitude' => $latitude,
                'check_in_longitude' => $longitude,
                'check_in_accuracy' => $accuracy,
                'check_in_distance' => $geoResult['distance'],
                'check_in_photo_path' => $photoPath,
                'status' => $status,
                'late_minutes' => $lateMinutes,
                'notes' => $notes,
            ]);
        });
    }

    /**
     * Process check-out for a student.
     *
     * @throws \Exception
     */
    public function checkOut(
        Placement $placement,
        float $latitude,
        float $longitude,
        float $accuracy,
        UploadedFile $photo
    ): Attendance {
        if (!$placement->isActive()) {
            throw new \Exception('Placement tidak aktif.', 422);
        }

        $today = now()->toDateString();

        $attendance = Attendance::where('placement_id', $placement->id)
            ->whereDate('attendance_date', $today)
            ->first();

        if (!$attendance || !$attendance->hasCheckedIn()) {
            throw new \Exception('Anda belum melakukan check-in hari ini.', 422);
        }

        if ($attendance->hasCheckedOut()) {
            throw new \Exception('Anda sudah melakukan check-out hari ini.', 422);
        }

        // Validasi jam pulang: siswa baru bisa absen pulang jika sudah memasuki check_out_time DU/DI
        $location = $placement->location;
        $currentTime = now();
        $targetCheckOutTimeStr = $location->check_out_time ? substr($location->check_out_time, 0, 5) : '16:00';
        $targetCheckOutTime = \Carbon\Carbon::parse($today . ' ' . $targetCheckOutTimeStr);
        if ($currentTime->lt($targetCheckOutTime)) {
            throw new \Exception(
                "Belum waktunya absen pulang. Presensi pulang baru dibuka mulai pukul {$targetCheckOutTimeStr} WIB.",
                422
            );
        }

        // Calculate distance
        $geoResult = $this->geoService->isWithinRadius(
            $latitude,
            $longitude,
            (float) $location->latitude,
            (float) $location->longitude,
            $location->radius
        );

        if (!$geoResult['within']) {
            throw new \Exception(
                "Anda berada di luar radius lokasi PKL. Jarak: {$geoResult['distance']}m, Radius: {$location->radius}m.",
                422
            );
        }

        // Store photo
        $photoPath = $photo->store('attendances/check-out/' . $today, 'public');

        $attendance->update([
            'check_out_at' => now(),
            'check_out_latitude' => $latitude,
            'check_out_longitude' => $longitude,
            'check_out_accuracy' => $accuracy,
            'check_out_distance' => $geoResult['distance'],
            'check_out_photo_path' => $photoPath,
        ]);

        return $attendance->fresh();
    }
}
