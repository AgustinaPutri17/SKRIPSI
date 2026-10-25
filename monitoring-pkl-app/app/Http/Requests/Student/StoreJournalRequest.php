<?php

namespace App\Http\Requests\Student;

use Illuminate\Foundation\Http\FormRequest;

class StoreJournalRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'logbook_date' => ['required_without:journal_date', 'date'],
            'journal_date' => ['required_without:logbook_date', 'date'],
            'attendance_id' => ['nullable', 'exists:attendances,id'],
            'activity_id' => ['nullable', 'exists:activities,id'],
            'activity' => ['required', 'string'],
            'description' => ['nullable', 'string'],
            'start_time' => ['nullable', 'date_format:H:i'],
            'end_time' => ['nullable', 'date_format:H:i', 'after:start_time'],
            'result' => ['nullable', 'string'],
            'obstacles' => ['nullable', 'string'],
            'photo' => ['nullable', 'image', 'mimes:jpeg,jpg,png', 'max:5120'],
        ];
    }

    public function getLogbookDate(): string
    {
        return (string) ($this->input('logbook_date') ?? $this->input('journal_date'));
    }
}
