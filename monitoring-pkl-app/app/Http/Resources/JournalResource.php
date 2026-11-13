<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class JournalResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $date = ($this->logbook_date ?? $this->journal_date)?->toDateString();
        $verificationNote = $this->verification_note ?? $this->verification_comment;

        // Ambil attendance yang berelasi atau cari berdasarkan placement dan tanggal yang sama
        $attendance = $this->attendance;
        if (!$attendance && $this->placement_id && $date) {
            $attendance = \App\Models\Attendance::where('placement_id', $this->placement_id)
                ->whereDate('attendance_date', $date)
                ->first();
        }

        $checkInPhotoUrl = $attendance?->check_in_photo_path
            ? asset('storage/' . $attendance->check_in_photo_path)
            : null;

        $checkOutPhotoUrl = $attendance?->check_out_photo_path
            ? asset('storage/' . $attendance->check_out_photo_path)
            : null;

        $checkInTime = $attendance?->check_in_at
            ? \Carbon\Carbon::parse($attendance->check_in_at)->format('H:i') . ' WIB'
            : ($this->start_time ?? '07:30 WIB');

        $checkOutTime = $attendance?->check_out_at
            ? \Carbon\Carbon::parse($attendance->check_out_at)->format('H:i') . ' WIB'
            : ($this->end_time ?? '16:00 WIB');

        return [
            'id' => $this->id,
            'placement_id' => $this->placement_id,
            'attendance_id' => $this->attendance_id ?? $attendance?->id,
            'activity_id' => $this->activity_id,
            'logbook_date' => $date,
            'journal_date' => $date,
            'start_time' => $this->start_time ?? $checkInTime,
            'end_time' => $this->end_time ?? $checkOutTime,
            'check_in_time' => $checkInTime,
            'check_out_time' => $checkOutTime,
            'activity' => $this->activity,
            'description' => $this->description,
            'result' => $this->result,
            'obstacles' => $this->obstacles,
            'photo_url' => $this->photo_path
                ? asset('storage/' . $this->photo_path)
                : null,
            'check_in_photo_url' => $checkInPhotoUrl,
            'check_out_photo_url' => $checkOutPhotoUrl,
            'status' => $this->status,
            'submitted_at' => $this->submitted_at,
            'verified_at' => $this->verified_at,
            'verified_by' => $this->verified_by,
            'verification_note' => $verificationNote,
            'verification_comment' => $verificationNote,
            'dudi_note' => (\App\Models\LogbookComment::where('logbook_id', $this->id)->whereHas('user', fn($q) => $q->where('role', 'field_supervisor'))->latest()->first()?->comment) ?? $verificationNote,
            'dudi_name' => (\App\Models\LogbookComment::where('logbook_id', $this->id)->whereHas('user', fn($q) => $q->where('role', 'field_supervisor'))->latest()->first()?->user?->name) ?? ($this->relationLoaded('verifier') ? $this->verifier?->name : null),
            'teacher_note' => (\App\Models\LogbookComment::where('logbook_id', $this->id)->where(function($q) use ($request) {
                if ($request->user()?->role === 'teacher') {
                    $q->where('user_id', $request->user()->id)->orWhereHas('user', fn($u) => $u->where('role', 'teacher'));
                } else {
                    $q->whereHas('user', fn($u) => $u->where('role', 'teacher'));
                }
            })->latest()->first()?->comment) ?? ($this->relationLoaded('verifier') && $this->verifier?->role === 'teacher' ? $verificationNote : null),
            'teacher_name' => (\App\Models\LogbookComment::where('logbook_id', $this->id)->where(function($q) use ($request) {
                if ($request->user()?->role === 'teacher') {
                    $q->where('user_id', $request->user()->id)->orWhereHas('user', fn($u) => $u->where('role', 'teacher'));
                } else {
                    $q->whereHas('user', fn($u) => $u->where('role', 'teacher'));
                }
            })->latest()->first()?->user?->name) ?? ($this->relationLoaded('verifier') && $this->verifier?->role === 'teacher' ? $this->verifier?->name : null),
            'has_teacher_note' => !empty((\App\Models\LogbookComment::where('logbook_id', $this->id)->where(function($q) use ($request) {
                if ($request->user()?->role === 'teacher') {
                    $q->where('user_id', $request->user()->id)->orWhereHas('user', fn($u) => $u->where('role', 'teacher'));
                } else {
                    $q->whereHas('user', fn($u) => $u->where('role', 'teacher'));
                }
            })->latest()->first()?->comment) ?? ($this->relationLoaded('verifier') && $this->verifier?->role === 'teacher' ? $verificationNote : null)),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
            'placement' => $this->relationLoaded('placement') && $this->placement ? new PlacementResource($this->placement) : null,
            'student' => $this->relationLoaded('placement') && $this->placement?->student ? new StudentResource($this->placement->student) : null,
            'location' => $this->relationLoaded('placement') && $this->placement?->location ? new LocationResource($this->placement->location) : null,
            'verifier' => $this->relationLoaded('verifier') && $this->verifier ? new UserResource($this->verifier) : null,
        ];
    }
}
