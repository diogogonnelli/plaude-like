<?php

namespace App\Modules\Projects\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Modules\Projects\Models\Project;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class ProjectController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $projects = $request->user()
            ->projects()
            ->withCount('recordings')
            ->orderByDesc('created_at')
            ->get();

        return response()->json([
            'data' => $projects->map(fn ($p) => $this->formatProject($p)),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
        ]);

        $project = Project::create([
            'name' => $validated['name'],
            'slug' => Str::slug($validated['name']) . '-' . Str::random(6),
            'status' => 'active',
        ]);

        $project->members()->create([
            'user_id' => $request->user()->id,
            'role' => 'owner',
        ]);

        return response()->json([
            'data' => $this->formatProject($project),
        ], 201);
    }

    public function show(Request $request, Project $project): JsonResponse
    {
        $this->authorizeProject($request, $project);

        return response()->json([
            'data' => $this->formatProject($project->loadCount('recordings')),
        ]);
    }

    public function update(Request $request, Project $project): JsonResponse
    {
        $this->authorizeProject($request, $project);

        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'status' => 'sometimes|in:active,archived',
        ]);

        $project->update($validated);

        return response()->json([
            'data' => $this->formatProject($project->fresh()->loadCount('recordings')),
        ]);
    }

    public function members(Request $request, Project $project): JsonResponse
    {
        $this->authorizeProject($request, $project);

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
        $this->authorizeProject($request, $project);

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

    public function removeMember(Request $request, Project $project, string $user): JsonResponse
    {
        $this->authorizeProject($request, $project);

        $project->members()->where('user_id', $user)->delete();

        return response()->json(null, 204);
    }

    private function authorizeProject(Request $request, Project $project): void
    {
        $isMember = $project->members()->where('user_id', $request->user()->id)->exists();
        if (!$isMember) {
            abort(403, 'Forbidden');
        }
    }

    private function formatProject(Project $project): array
    {
        return [
            'id' => $project->id,
            'name' => $project->name,
            'slug' => $project->slug,
            'status' => $project->status,
            'recordings_count' => $project->recordings_count ?? 0,
            'created_at' => $project->created_at->toIso8601String(),
            'updated_at' => $project->updated_at->toIso8601String(),
        ];
    }
}
