<?php

namespace App\Modules\Projects\Models;

use App\Modules\Identity\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ProjectMember extends Model
{
    protected $table = 'project_members';
    public $incrementing = false;
    public $timestamps = false;

    protected $primaryKey = null;

    protected $fillable = [
        'project_id',
        'user_id',
        'role',
    ];

    public function project(): BelongsTo
    {
        return $this->belongsTo(Project::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
