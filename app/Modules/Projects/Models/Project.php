<?php

namespace App\Modules\Projects\Models;

use App\Modules\Identity\Models\User;
use App\Modules\Recordings\Models\Recording;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class Project extends Model
{
    use HasUuids;

    protected $fillable = [
        'name',
        'slug',
        'status',
    ];

    public function members(): HasMany
    {
        return $this->hasMany(ProjectMember::class);
    }

    public function users(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'project_members')
            ->withPivot(['role', 'created_at']);
    }

    public function recordings(): HasMany
    {
        return $this->hasMany(Recording::class);
    }
}
