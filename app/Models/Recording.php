<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Recording extends Model
{
    use HasUuids;

    protected $fillable = [
        'user_id',
        'created_by_user_id',
        'project_id',
        'title',
        'source_type',
        'status',
        'duration_ms',
        'audio_path',
        'capture_metadata',
        'transcription_provider',
        'transcription_job_id',
        'transcription_started_at',
        'transcription_completed_at',
        'last_error',
    ];

    protected function casts(): array
    {
        return [
            'capture_metadata' => 'json',
            'duration_ms' => 'integer',
            'transcription_started_at' => 'datetime',
            'transcription_completed_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function createdByUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by_user_id');
    }

    public function project(): BelongsTo
    {
        return $this->belongsTo(Project::class);
    }

    public function transcriptSegments(): HasMany
    {
        return $this->hasMany(TranscriptSegment::class)->orderBy('start_ms');
    }

    public function summary(): HasOne
    {
        return $this->hasOne(Summary::class);
    }

    public function noteArtifact(): HasOne
    {
        return $this->hasOne(NoteArtifact::class);
    }

    public function chatSession(): HasOne
    {
        return $this->hasOne(ChatSession::class);
    }
}
