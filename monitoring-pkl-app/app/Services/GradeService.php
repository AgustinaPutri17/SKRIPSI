<?php

namespace App\Services;

use InvalidArgumentException;

/**
 * Single authoritative place for final-grade calculation.
 * Weights and KKM come from config/pkl.php; never duplicate this in controllers or UI.
 */
class GradeService
{
    /**
     * @return array{final_score: float, weight_dudi: float, weight_teacher: float, kkm: float, passed: bool}
     */
    public function calculate(float $dudiScore, float $teacherScore): array
    {
        $min = (float) config('pkl.assessment.min_score');
        $max = (float) config('pkl.assessment.max_score');

        foreach (['DUDI' => $dudiScore, 'guru' => $teacherScore] as $label => $score) {
            if ($score < $min || $score > $max) {
                throw new InvalidArgumentException("Nilai {$label} harus di antara {$min} dan {$max}.");
            }
        }

        $weightDudi = (float) config('pkl.assessment.weight_dudi');
        $weightTeacher = (float) config('pkl.assessment.weight_teacher');
        $totalWeight = $weightDudi + $weightTeacher;

        if ($totalWeight <= 0) {
            throw new InvalidArgumentException('Total bobot penilaian harus lebih dari 0.');
        }

        $final = round((($dudiScore * $weightDudi) + ($teacherScore * $weightTeacher)) / $totalWeight, 2);
        $kkm = (float) config('pkl.assessment.kkm');

        return [
            'final_score' => $final,
            'weight_dudi' => $weightDudi,
            'weight_teacher' => $weightTeacher,
            'kkm' => $kkm,
            'passed' => $final >= $kkm,
        ];
    }
}
