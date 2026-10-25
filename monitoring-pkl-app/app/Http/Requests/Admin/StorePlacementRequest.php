<?php

namespace App\Http\Requests\Admin;

use App\Models\Placement;
use Illuminate\Foundation\Http\FormRequest;

class StorePlacementRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'student_id' => ['required', 'exists:students,id'],
            'location_id' => ['required', 'exists:locations,id'],
            'period_id' => ['required', 'exists:periods,id'],
            'teacher_id' => ['required', 'exists:teachers,id'],
            'field_supervisor_id' => ['nullable', 'exists:field_supervisors,id'],
            'start_date' => ['required', 'date'],
            'end_date' => ['required', 'date', 'after:start_date'],
            'status' => ['sometimes', 'in:active,inactive,completed'],
        ];
    }

    /**
     * Prevent conflicting active placements for the same student within the same period.
     */
    public function withValidator($validator): void
    {
        $validator->after(function ($validator) {
            $status = $this->input('status', 'active');

            if ($status === 'active') {
                $studentId = $this->input('student_id');
                $periodId = $this->input('period_id');

                $conflict = Placement::where('student_id', $studentId)
                    ->where('period_id', $periodId)
                    ->where('status', 'active')
                    ->exists();

                if ($conflict) {
                    $validator->errors()->add(
                        'student_id',
                        'Siswa sudah memiliki penempatan aktif pada periode ini.'
                    );
                }
            }
        });
    }
}
