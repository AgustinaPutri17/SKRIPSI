<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Logbook extends Model
{
    use HasFactory;

    protected $table = 'logbooks';

    protected $fillable = [
        'placement_id',
        'attendance_id',
        'activity_id',
        'logbook_date',
        'journal_date',
        'start_time',
        'end_time',
        'activity',
        'description',
        'plan',
        'result',
        'obstacles',
        'photo_path',
        'status',
        'submitted_at',
        'verified_at',
        'verified_by',
        'verification_note',
        'verification_comment',
    ];

    protected function casts(): array
    {
        return [
            'logbook_date' => 'date',
            'submitted_at' => 'datetime',
            'verified_at' => 'datetime',
        ];
    }

    // ── Relationships ──

    public function placement(): BelongsTo
    {
        return $this->belongsTo(Placement::class);
    }

    public function attendance(): BelongsTo
    {
        return $this->belongsTo(Attendance::class);
    }

    public function activity(): BelongsTo
    {
        return $this->belongsTo(Activity::class, 'activity_id');
    }

    public function verifier(): BelongsTo
    {
        return $this->belongsTo(User::class, 'verified_by');
    }

    public function comments(): HasMany
    {
        return $this->hasMany(LogbookComment::class, 'logbook_id');
    }

    public function statusHistories(): HasMany
    {
        return $this->hasMany(LogbookStatusHistory::class, 'logbook_id')->latest('created_at');
    }

    // ── Backward Compatibility Accessors & Mutators ──

    public function getJournalDateAttribute()
    {
        return $this->logbook_date;
    }

    public function setJournalDateAttribute($value): void
    {
        $this->attributes['logbook_date'] = $value;
    }

    public function getVerificationCommentAttribute()
    {
        return $this->verification_note;
    }

    public function setVerificationCommentAttribute($value): void
    {
        $this->attributes['verification_note'] = $value;
    }

    // ── Status Helpers ──

    public function isDraft(): bool
    {
        return $this->status === 'draft';
    }

    public function isSubmitted(): bool
    {
        return $this->status === 'submitted';
    }

    public function isApproved(): bool
    {
        return $this->status === 'approved';
    }

    public function isRejected(): bool
    {
        return $this->status === 'rejected';
    }

    public function isEditable(): bool
    {
        return in_array($this->status, ['draft', 'rejected']);
    }
}
