<?php

namespace App\Http\Requests\Student;

use Illuminate\Foundation\Http\FormRequest;

class UpdateJournalRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'logbook_date' => ['sometimes', 'date'],
            'journal_date' => ['sometimes', 'date'],
            'attendance_id' => ['nullable', 'exists:attendances,id'],
            'activity_id' => ['nullable', 'exists:activities,id'],
            'activity' => ['sometimes', 'string'],
            'description' => ['nullable', 'string'],
            'start_time' => ['nullable', 'date_format:H:i'],
            'end_time' => ['nullable', 'date_format:H:i', 'after:start_time'],
            'result' => ['nullable', 'string'],
            'obstacles' => ['nullable', 'string'],
            'photo' => ['nullable', 'image', 'mimes:jpeg,jpg,png', 'max:5120'],
        ];
    }
}
