<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Location extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'address',
        'latitude',
        'longitude',
        'radius',
        'check_in_start',
        'check_in_time',
        'check_out_time',
        'check_out_end',
        'work_days',
        'start_date',
        'end_date',
        'is_active',
        'approval_status',
        'approved_by',
        'approved_at',
        'approval_note',
    ];

    protected function casts(): array
    {
        return [
            'latitude' => 'decimal:7',
            'longitude' => 'decimal:7',
            'radius' => 'integer',
            'start_date' => 'date',
            'end_date' => 'date',
            'is_active' => 'boolean',
            'approved_at' => 'datetime',
        ];
    }

    /**
     * Calculate total business/work days in the PKL period.
     */
    public function calculateTotalWorkDays(): int
    {
        if (!$this->start_date || !$this->end_date) {
            return 60; // Default baseline PKL work days (approx. 3 months)
        }

        $start = \Carbon\Carbon::parse($this->start_date);
        $end = \Carbon\Carbon::parse($this->end_date);
        if ($start->gt($end)) {
            return 60;
        }

        $workDays = 0;
        $isSixDays = $this->work_days === 'monday_saturday';

        $curr = $start->copy();
        while ($curr->lte($end)) {
            // 1: Monday, ..., 5: Friday, 6: Saturday, 7: Sunday
            if ($curr->isWeekday() || ($isSixDays && $curr->isSaturday())) {
                $workDays++;
            }
            $curr->addDay();
        }

        return max(1, $workDays);
    }

    public function placements(): HasMany
    {
        return $this->hasMany(Placement::class);
    }

    public function fieldSupervisors(): BelongsToMany
    {
        return $this->belongsToMany(
            FieldSupervisor::class,
            'location_field_supervisor',
            'location_id',
            'field_supervisor_id'
        )->withTimestamps();
    }
}
