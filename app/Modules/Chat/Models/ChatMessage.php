<?php

namespace App\Modules\Chat\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ChatMessage extends Model
{
    use HasUuids;

    public $timestamps = false;

    protected $fillable = [
        'chat_session_id',
        'role',
        'content',
        'citations',
    ];

    protected function casts(): array
    {
        return [
            'citations' => 'json',
            'created_at' => 'datetime',
        ];
    }

    public function chatSession(): BelongsTo
    {
        return $this->belongsTo(ChatSession::class);
    }
}
