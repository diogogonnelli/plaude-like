<?php

namespace App\Modules\Recordings\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TranscriptSegment extends Model
{
    use HasUuids;

    public $timestamps = false;

    protected $fillable = [
        'recording_id',
        'speaker_label',
        'start_ms',
        'end_ms',
        'text',
    ];

    protected function casts(): array
    {
        return [
            'start_ms' => 'integer',
            'end_ms' => 'integer',
        ];
    }

    public function recording(): BelongsTo
    {
        return $this->belongsTo(Recording::class);
    }
}
