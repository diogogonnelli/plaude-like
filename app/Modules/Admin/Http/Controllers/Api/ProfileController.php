<?php

namespace App\Modules\Admin\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Modules\Identity\Models\Profile;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProfileController extends Controller
{
    public function index(): JsonResponse
    {
        $profiles = Profile::withCount('users')->orderBy('name')->get();

        return response()->json([
            'data' => $profiles->map(fn ($p) => [
                'id' => $p->id,
                'code' => $p->code,
                'name' => $p->name,
                'description' => $p->description,
                'is_system' => $p->is_system,
                'users_count' => $p->users_count,
                'created_at' => $p->created_at->toIso8601String(),
                'updated_at' => $p->updated_at->toIso8601String(),
            ]),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'code' => 'required|string|regex:/^[a-z0-9_]+$/|unique:profiles',
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
        ]);

        $profile = Profile::create($validated);

        return response()->json(['data' => $profile], 201);
    }

    public function show(Profile $profile): JsonResponse
    {
        return response()->json([
            'data' => $profile->loadCount('users'),
        ]);
    }

    public function update(Request $request, Profile $profile): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'description' => 'sometimes|nullable|string',
        ]);

        $profile->update($validated);

        return response()->json(['data' => $profile->fresh()]);
    }

    public function destroy(Profile $profile): JsonResponse
    {
        if ($profile->is_system) {
            return response()->json(['message' => 'Cannot delete system profiles'], 422);
        }

        $profile->delete();

        return response()->json(null, 204);
    }
}
