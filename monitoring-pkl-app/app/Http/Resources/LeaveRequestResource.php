<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class LeaveRequestResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $startDate = $this->start_date?->toDateString();
        $endDate = $this->end_date?->toDateString();
        
        $diffDays = 1;
        if ($this->start_date && $this->end_date) {
            $diffDays = $this->start_date->diffInDays($this->end_date) + 1;
        }

        $typeLabel = match (strtolower($this->type ?? '')) {
            'sick', 'sakit' => 'Sakit / Medis',
            'urgent', 'mendesak', 'emergency' => 'Izin Mendesak',
            default => 'Izin / Sakit',
        };

        return [
            'id' => $this->id,
            'placement_id' => $this->placement_id,
            'start_date' => $startDate,
            'end_date' => $endDate,
            'days_count' => $diffDays,
            'date_range_label' => $startDate === $endDate
                ? ($startDate . ' (1 Hari)')
                : ($startDate . ' s/d ' . $endDate . ' (' . $diffDays . ' Hari)'),
            'type' => $this->type,
            'type_label' => $typeLabel,
            'reason' => $this->reason,
            'attachment_path' => $this->attachment_path,
            'attachment_url' => $this->attachment_path ? asset('storage/' . $this->attachment_path) : null,
            'attachment_name' => $this->attachment_path ? basename($this->attachment_path) : null,
            'status' => $this->status ?? 'pending',
            'is_approved' => $this->status === 'approved',
            'is_rejected' => $this->status === 'rejected',
            'is_pending' => $this->status === 'pending',
            'reviewed_by' => $this->reviewed_by,
            'reviewed_at' => $this->reviewed_at,
            'reviewer_note' => $this->reviewer_note,
            'reviewer' => $this->relationLoaded('reviewer') && $this->reviewer ? new UserResource($this->reviewer) : null,
            'student' => $this->relationLoaded('placement') && $this->placement?->student
                ? new StudentResource($this->placement->student)
                : null,
            'location' => $this->relationLoaded('placement') && $this->placement?->location
                ? new LocationResource($this->placement->location)
                : null,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
