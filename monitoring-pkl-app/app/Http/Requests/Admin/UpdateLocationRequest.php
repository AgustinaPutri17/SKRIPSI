<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;

class UpdateLocationRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['sometimes', 'string', 'max:255'],
            'address' => ['sometimes', 'string'],
            'latitude' => ['sometimes', 'nullable', 'numeric', 'between:-90,90'],
            'longitude' => ['sometimes', 'nullable', 'numeric', 'between:-180,180'],
            'radius' => ['sometimes', 'integer', 'min:10', 'max:10000'],
            'check_in_start' => ['sometimes', 'nullable'],
            'check_in_time' => ['sometimes', 'nullable'],
            'check_out_time' => ['sometimes', 'nullable'],
            'check_out_end' => ['sometimes', 'nullable'],
            'work_days' => ['sometimes', 'nullable', 'string'],
            'start_date' => ['sometimes', 'nullable', 'date'],
            'end_date' => ['sometimes', 'nullable', 'date'],
            'is_active' => ['sometimes', 'boolean'],
            'field_supervisor_ids' => ['sometimes', 'array'],
            'field_supervisor_ids.*' => ['exists:field_supervisors,id'],
        ];
    }
}
