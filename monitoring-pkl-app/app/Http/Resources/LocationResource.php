<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class LocationResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'address' => $this->address,
            'latitude' => $this->latitude,
            'longitude' => $this->longitude,
            'radius' => $this->radius,
            'check_in_start' => $this->check_in_start ? substr($this->check_in_start, 0, 5) : '06:00',
            'check_in_time' => $this->check_in_time ? substr($this->check_in_time, 0, 5) : '08:00',
            'check_out_time' => $this->check_out_time ? substr($this->check_out_time, 0, 5) : '16:00',
            'check_out_end' => $this->check_out_end ? substr($this->check_out_end, 0, 5) : '20:00',
            'is_active' => $this->is_active,
            'field_supervisors' => FieldSupervisorResource::collection($this->whenLoaded('fieldSupervisors')),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
