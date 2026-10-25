<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateStudentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $studentId = $this->route('student');

        return [
            'nis' => ['sometimes', 'string', 'max:50', Rule::unique('students', 'nis')->ignore($studentId)],
            'name' => ['sometimes', 'string', 'max:255'],
            'class' => ['sometimes', 'string', 'max:50'],
            'major' => ['nullable', 'string', 'max:255'],
            'phone' => ['nullable', 'string', 'max:20'],
        ];
    }
}
