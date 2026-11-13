<?php

use App\Http\Controllers\Api\Admin\AttendanceController as AdminAttendanceController;
use App\Http\Controllers\Api\Admin\DashboardController as AdminDashboardController;
use App\Http\Controllers\Api\Admin\FieldSupervisorController as AdminFieldSupervisorController;
use App\Http\Controllers\Api\Admin\LocationController as AdminLocationController;
use App\Http\Controllers\Api\Admin\LogbookController as AdminLogbookController;
use App\Http\Controllers\Api\Admin\PeriodController as AdminPeriodController;
use App\Http\Controllers\Api\Admin\PlacementController as AdminPlacementController;
use App\Http\Controllers\Api\Admin\StudentController as AdminStudentController;
use App\Http\Controllers\Api\Admin\TeacherController as AdminTeacherController;
use App\Http\Controllers\Api\Admin\UserController as AdminUserController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\Student\StudentController;
use App\Http\Controllers\Api\Supervisor\SupervisorController;
use App\Http\Controllers\Api\Teacher\TeacherController;
use Illuminate\Support\Facades\Route;

// ─────────────────────────────────────────────
// Public routes (no auth required)
// ─────────────────────────────────────────────
Route::get('/ping', function () {
    return response()->json(['status' => 'ok', 'message' => 'PKL Monitoring API is running']);
});
Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:10,1');

// ─────────────────────────────────────────────
// Authenticated routes
// ─────────────────────────────────────────────
Route::middleware('auth:sanctum')->group(function () {

    // Auth endpoints
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);

    // ── Admin routes ──────────────────────────
    Route::prefix('admin')->middleware('role:admin')->group(function () {

        Route::get('/dashboard', [AdminDashboardController::class, 'index']);

        // Users Management & Admin Password Reset
        Route::post('/users/{id}/reset-password', [AdminUserController::class, 'resetPassword']);
        Route::apiResource('users', AdminUserController::class)->except(['store']);

        // Students CRUD
        Route::apiResource('students', AdminStudentController::class);

        // Teachers CRUD
        Route::apiResource('teachers', AdminTeacherController::class);

        // Field Supervisors CRUD
        Route::apiResource('field-supervisors', AdminFieldSupervisorController::class);

        // Locations CRUD
        Route::apiResource('locations', AdminLocationController::class);

        // Periods CRUD & Activation
        Route::post('/periods/{id}/activate', [AdminPeriodController::class, 'activate']);
        Route::apiResource('periods', AdminPeriodController::class);

        // Placements CRUD & Toggle Status
        Route::post('/placements/{id}/toggle-status', [AdminPlacementController::class, 'toggleStatus']);
        Route::apiResource('placements', AdminPlacementController::class);

        // Rekap Kehadiran (Attendances)
        Route::get('/attendances/export', [AdminAttendanceController::class, 'export']);
        Route::get('/attendances', [AdminAttendanceController::class, 'index']);
        Route::delete('/attendances/{id}', [AdminAttendanceController::class, 'destroy']);

        // Rekap Logbook / Jurnal (Logbooks)
        Route::get('/logbooks/export', [AdminLogbookController::class, 'export']);
        Route::get('/logbooks', [AdminLogbookController::class, 'index']);
        Route::delete('/logbooks/{id}', [AdminLogbookController::class, 'destroy']);
    });

    // ── Student routes ────────────────────────
    Route::prefix('student')->middleware('role:student')->group(function () {

        Route::get('/dashboard', [StudentController::class, 'dashboard']);

        // Profile
        Route::get('/profile', [StudentController::class, 'profile']);
        Route::put('/profile', [StudentController::class, 'updateProfile']);

        // Active placement
        Route::get('/placement', [StudentController::class, 'placement']);

        // Attendance
        Route::get('/attendances', [StudentController::class, 'attendances']);
        Route::post('/attendances/check-in', [StudentController::class, 'checkIn']);
        Route::post('/attendances/check-out', [StudentController::class, 'checkOut']);
        Route::get('/attendances/{id}', [StudentController::class, 'showAttendance']);

        // Logbooks
        Route::get('/logbooks', [StudentController::class, 'journals']);
        Route::post('/logbooks', [StudentController::class, 'storeJournal']);
        Route::get('/logbooks/{id}', [StudentController::class, 'showJournal']);
        Route::put('/logbooks/{id}', [StudentController::class, 'updateJournal']);
        Route::delete('/logbooks/{id}', [StudentController::class, 'destroyJournal']);
        Route::post('/logbooks/{id}/submit', [StudentController::class, 'submitJournal']);

        // Leave Requests (Izin & Sakit)
        Route::get('/leave-requests', [StudentController::class, 'leaveRequests']);
        Route::post('/leave-requests', [StudentController::class, 'storeLeaveRequest']);
    });

    // ── Teacher routes ────────────────────────
    Route::prefix('teacher')->middleware('role:teacher')->group(function () {

        Route::get('/dashboard', [TeacherController::class, 'dashboard']);
        Route::get('/students', [TeacherController::class, 'students']);
        Route::get('/students/{id}', [TeacherController::class, 'showStudent']);
        Route::get('/attendances', [TeacherController::class, 'attendances']);
        Route::get('/logbooks', [TeacherController::class, 'journals']);
        Route::get('/logbooks/{id}', [TeacherController::class, 'showJournal']);
        Route::post('/logbooks/{id}/approve', [TeacherController::class, 'approveJournal']);
        Route::post('/logbooks/{id}/reject', [TeacherController::class, 'rejectJournal']);
        Route::post('/logbooks/{id}/comment', [TeacherController::class, 'addComment']);

        // Leave Requests (Izin & Sakit)
        Route::get('/leave-requests', [TeacherController::class, 'leaveRequests']);
        Route::post('/leave-requests/{id}/verify', [TeacherController::class, 'verifyLeaveRequest']);
    });

    // ── Field Supervisor routes ───────────────
    Route::prefix('supervisor')->middleware('role:field_supervisor')->group(function () {

        Route::get('/dashboard', [SupervisorController::class, 'dashboard']);
        Route::get('/students', [SupervisorController::class, 'students']);
        Route::get('/students/{id}', [SupervisorController::class, 'showStudent']);

        // Field Supervisor Location Management
        Route::get('/locations', [SupervisorController::class, 'locations']);
        Route::post('/locations', [SupervisorController::class, 'storeLocation']);
        Route::get('/locations/{id}', [SupervisorController::class, 'showLocation']);
        Route::put('/locations/{id}', [SupervisorController::class, 'updateLocation']);

        // Logbooks
        Route::get('/logbooks', [SupervisorController::class, 'journals']);
        Route::get('/logbooks/{id}', [SupervisorController::class, 'showJournal']);
        Route::post('/logbooks/{id}/approve', [SupervisorController::class, 'approveJournal']);
        Route::post('/logbooks/{id}/reject', [SupervisorController::class, 'rejectJournal']);

        Route::get('/attendances', [SupervisorController::class, 'attendances']);
    });
});
