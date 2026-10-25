<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ProjectSubmission extends Model
{
    use HasFactory;

    protected $fillable = [
        'placement_id',
        'title',
        'description',
        'plan',
        'result',
        'document_path',
        'document_name',
        'document_size',
        'status',
        'submitted_at',
    ];

    protected function casts(): array
    {
        return [
            'submitted_at' => 'datetime',
            'document_size' => 'integer',
        ];
    }

    public function placement(): BelongsTo
    {
        return $this->belongsTo(Placement::class);
    }

    public function reviews(): HasMany
    {
        return $this->hasMany(ProjectReview::class)->latest('created_at');
    }

    public function isEditable(): bool
    {
        return in_array($this->status, ['draft', 'revision']);
    }
}
