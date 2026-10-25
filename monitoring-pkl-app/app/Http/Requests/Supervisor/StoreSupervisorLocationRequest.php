<?php

namespace App\Http\Requests\Supervisor;

use Illuminate\Foundation\Http\FormRequest;

class StoreSupervisorLocationRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'address' => ['required', 'string'],
            'latitude' => ['nullable', 'numeric', 'between:-90,90'],
            'longitude' => ['nullable', 'numeric', 'between:-180,180'],
            'radius' => ['sometimes', 'integer', 'min:10', 'max:10000'],
            'check_in_start' => ['sometimes', 'nullable'],
            'check_in_time' => ['sometimes', 'nullable'],
            'check_out_time' => ['sometimes', 'nullable'],
            'check_out_end' => ['sometimes', 'nullable'],
        ];
    }
}
