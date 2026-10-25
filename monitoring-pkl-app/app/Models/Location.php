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
            'is_active' => 'boolean',
            'approved_at' => 'datetime',
        ];
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
