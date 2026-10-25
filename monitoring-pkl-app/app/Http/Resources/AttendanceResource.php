<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AttendanceResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'placement_id' => $this->placement_id,
            'attendance_date' => $this->attendance_date?->toDateString(),
            'check_in_at' => $this->check_in_at,
            'check_in_latitude' => $this->check_in_latitude,
            'check_in_longitude' => $this->check_in_longitude,
            'check_in_accuracy' => $this->check_in_accuracy,
            'check_in_distance' => $this->check_in_distance,
            'check_in_photo_url' => $this->check_in_photo_path
                ? asset('storage/' . $this->check_in_photo_path)
                : null,
            'check_out_at' => $this->check_out_at,
            'check_out_latitude' => $this->check_out_latitude,
            'check_out_longitude' => $this->check_out_longitude,
            'check_out_accuracy' => $this->check_out_accuracy,
            'check_out_distance' => $this->check_out_distance,
            'check_out_photo_url' => $this->check_out_photo_path
                ? asset('storage/' . $this->check_out_photo_path)
                : null,
            'status' => $this->status,
            'late_minutes' => (int) ($this->late_minutes ?? 0),
            'notes' => $this->notes,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
            'placement' => new PlacementResource($this->whenLoaded('placement')),
        ];
    }
}
