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
            'student_id' => ['required_without:student_ids', 'nullable', 'exists:students,id'],
            'student_ids' => ['required_without:student_id', 'nullable', 'array', 'min:1'],
            'student_ids.*' => ['exists:students,id'],
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
                $studentIds = $this->input('student_ids');
                if (empty($studentIds) && $this->filled('student_id')) {
                    $studentIds = [$this->input('student_id')];
                }
                $studentIds = is_array($studentIds) ? $studentIds : [$studentIds];
                $periodId = $this->input('period_id');

                foreach ($studentIds as $sid) {
                    if (!$sid) continue;
                    $conflict = Placement::where('student_id', $sid)
                        ->where('period_id', $periodId)
                        ->where('status', 'active')
                        ->exists();

                    if ($conflict) {
                        $studentName = \App\Models\Student::find($sid)?->user?->name ?? "ID $sid";
                        $validator->errors()->add(
                            'student_ids',
                            "Siswa '{$studentName}' sudah memiliki penempatan aktif pada periode ini."
                        );
                    }
                }
            }
        });
    }
}
