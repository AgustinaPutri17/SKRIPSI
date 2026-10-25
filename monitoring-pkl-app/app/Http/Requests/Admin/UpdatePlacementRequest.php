<?php

namespace App\Http\Requests\Admin;

use App\Models\Placement;
use Illuminate\Foundation\Http\FormRequest;

class UpdatePlacementRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'student_id' => ['sometimes', 'exists:students,id'],
            'location_id' => ['sometimes', 'exists:locations,id'],
            'period_id' => ['sometimes', 'exists:periods,id'],
            'teacher_id' => ['sometimes', 'exists:teachers,id'],
            'field_supervisor_id' => ['nullable', 'exists:field_supervisors,id'],
            'start_date' => ['sometimes', 'date'],
            'end_date' => ['sometimes', 'date', 'after:start_date'],
            'status' => ['sometimes', 'in:active,inactive,completed'],
        ];
    }

    /**
     * Prevent conflicting active placements for the same student within the same period on update.
     */
    public function withValidator($validator): void
    {
        $validator->after(function ($validator) {
            $placementId = (int) $this->route('placement');
            $placement = Placement::find($placementId);

            if (!$placement) {
                return;
            }

            $studentId = $this->input('student_id', $placement->student_id);
            $periodId = $this->input('period_id', $placement->period_id);
            $status = $this->input('status', $placement->status);

            if ($status === 'active') {
                $conflict = Placement::where('student_id', $studentId)
                    ->where('period_id', $periodId)
                    ->where('status', 'active')
                    ->where('id', '!=', $placementId)
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
