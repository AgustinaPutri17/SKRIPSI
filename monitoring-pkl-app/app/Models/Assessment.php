<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Assessment extends Model
{
    use HasFactory;

    protected $fillable = [
        'placement_id',
        'dudi_score',
        'dudi_components',
        'dudi_notes',
        'dudi_scored_by',
        'dudi_scored_at',
        'teacher_score',
        'teacher_components',
        'teacher_notes',
        'teacher_scored_by',
        'teacher_scored_at',
        'final_score',
        'weight_dudi',
        'weight_teacher',
        'kkm',
        'status',
        'finalized_by',
        'finalized_at',
    ];

    protected function casts(): array
    {
        return [
            'dudi_score' => 'decimal:2',
            'teacher_score' => 'decimal:2',
            'final_score' => 'decimal:2',
            'weight_dudi' => 'decimal:2',
            'weight_teacher' => 'decimal:2',
            'kkm' => 'decimal:2',
            'dudi_components' => 'array',
            'teacher_components' => 'array',
            'dudi_scored_at' => 'datetime',
            'teacher_scored_at' => 'datetime',
            'finalized_at' => 'datetime',
        ];
    }

    public function placement(): BelongsTo
    {
        return $this->belongsTo(Placement::class);
    }

    public function isFinalized(): bool
    {
        return $this->status === 'finalized';
    }

    public function isComplete(): bool
    {
        return $this->dudi_score !== null && $this->teacher_score !== null;
    }
}
