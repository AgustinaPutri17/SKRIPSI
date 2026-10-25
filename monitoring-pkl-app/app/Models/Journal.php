<?php

namespace App\Models;

/**
 * Legacy Journal model bridging to Logbook for backward compatibility.
 *
 * @deprecated Use App\Models\Logbook instead.
 */
class Journal extends Logbook
{
    protected $table = 'logbooks';

    public function getForeignKey()
    {
        return 'logbook_id';
    }
}
