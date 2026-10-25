<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class LogbookStatusHistory extends Model
{
    public const UPDATED_AT = null;

    protected $fillable = [
        'logbook_id',
        'changed_by',
        'from_status',
        'to_status',
        'note',
    ];

    public function logbook(): BelongsTo
    {
        return $this->belongsTo(Logbook::class);
    }

    public function changedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'changed_by');
    }
}
