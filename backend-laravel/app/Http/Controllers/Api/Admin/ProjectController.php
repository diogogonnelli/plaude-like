<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Project;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProjectController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $projects = Project::withCount(['recordings', 'members'])
            ->orderByDesc('created_at')
            ->paginate($request->integer('per_page', 25));

        return response()->json([
            'data' => $projects->map(fn ($p) => [
                'id' => $p->id,
                'name' => $p->name,
                'slug' => $p->slug,
                'status' => $p->status,
                'recordings_count' => $p->recordings_count,
                'members_count' => $p->members_count,
                'created_at' => $p->created_at->toIso8601String(),
                'updated_at' => $p->updated_at->toIso8601String(),
            ]),
            'meta' => [
                'current_page' => $projects->currentPage(),
                'last_page' => $projects->lastPage(),
                'total' => $projects->total(),
            ],
        ]);
    }

    public function show(Project $project): JsonResponse
    {
        return response()->json([
            'data' => $project->loadCount(['recordings', 'members']),
        ]);
    }

    public function members(Project $project): JsonResponse
    {
        $members = $project->members()->with('user.profile')->get();

        return response()->json([
            'data' => $members->map(fn ($m) => [
                'project_id' => $m->project_id,
                'user_id' => $m->user_id,
                'role' => $m->role,
                'created_at' => $m->created_at,
                'user' => $m->user ? [
                    'id' => $m->user->id,
                    'email' => $m->user->email,
                    'full_name' => $m->user->full_name,
                    'profile_code' => $m->user->profile->code,
                ] : null,
            ]),
        ]);
    }

    public function addMember(Request $request, Project $project): JsonResponse
    {
        $validated = $request->validate([
            'user_id' => 'required|uuid|exists:users,id',
            'role' => 'sometimes|in:owner,member',
        ]);

        $project->members()->updateOrCreate(
            ['user_id' => $validated['user_id']],
            ['role' => $validated['role'] ?? 'member'],
        );

        return response()->json(['data' => ['message' => 'Member added']], 201);
    }

    public function removeMember(Project $project, string $user): JsonResponse
    {
        $project->members()->where('user_id', $user)->delete();

        return response()->json(null, 204);
    }
}
