<?php

namespace App\Modules\Recordings\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class NoteArtifact extends Model
{
    public $incrementing = false;
    public $timestamps = false;
    protected $primaryKey = 'recording_id';
    protected $keyType = 'string';

    protected $fillable = [
        'recording_id',
        'title',
        'tags',
        'highlights',
        'action_items',
    ];

    protected function casts(): array
    {
        return [
            'tags' => 'json',
            'highlights' => 'json',
            'action_items' => 'json',
        ];
    }

    public function recording(): BelongsTo
    {
        return $this->belongsTo(Recording::class);
    }
}
