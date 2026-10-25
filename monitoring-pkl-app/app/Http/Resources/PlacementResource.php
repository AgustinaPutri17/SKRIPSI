<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PlacementResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'student_id' => $this->student_id,
            'location_id' => $this->location_id,
            'period_id' => $this->period_id,
            'teacher_id' => $this->teacher_id,
            'field_supervisor_id' => $this->field_supervisor_id,
            'start_date' => $this->start_date?->toDateString(),
            'end_date' => $this->end_date?->toDateString(),
            'status' => $this->status,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
            'student' => new StudentResource($this->whenLoaded('student')),
            'location' => new LocationResource($this->whenLoaded('location')),
            'period' => new PeriodResource($this->whenLoaded('period')),
            'teacher' => new TeacherResource($this->whenLoaded('teacher')),
            'field_supervisor' => new FieldSupervisorResource($this->whenLoaded('fieldSupervisor')),
        ];
    }
}
