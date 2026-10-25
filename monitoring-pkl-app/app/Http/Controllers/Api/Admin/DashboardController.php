<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\PeriodResource;
use App\Models\Attendance;
use App\Models\FieldSupervisor;
use App\Models\Journal;
use App\Models\Location;
use App\Models\Period;
use App\Models\Placement;
use App\Models\Student;
use App\Models\Teacher;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;

class DashboardController extends Controller
{
    use ApiResponse;

    public function index(): JsonResponse
    {
        $today = now()->toDateString();
        $activePeriod = Period::where('status', 'active')->first();

        return $this->success([
            'active_period' => $activePeriod ? new PeriodResource($activePeriod) : null,
            'total_students' => Student::count(),
            'total_active_placements' => Placement::where('status', 'active')->count(),
            'total_inactive_placements' => Placement::where('status', 'inactive')->count(),
            'total_locations' => Location::count(),
            'total_teachers' => Teacher::count(),
            'total_field_supervisors' => FieldSupervisor::count(),
            'total_periods' => Period::count(),
            'attendance_today' => Attendance::where('attendance_date', $today)->count(),
            'journals_pending' => Journal::where('status', 'submitted')->count(),
        ]);
    }
}
