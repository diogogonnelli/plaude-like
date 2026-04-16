<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Summary extends Model
{
    public $incrementing = false;
    public $timestamps = false;
    protected $primaryKey = 'recording_id';
    protected $keyType = 'string';

    protected $fillable = [
        'recording_id',
        'overview',
        'chapters',
    ];

    protected function casts(): array
    {
        return [
            'chapters' => 'json',
        ];
    }

    public function recording(): BelongsTo
    {
        return $this->belongsTo(Recording::class);
    }
}
