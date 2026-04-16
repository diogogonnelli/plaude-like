<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Profile;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class UserController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = User::with('profile');

        if ($request->has('search')) {
            $search = $request->string('search');
            $query->where(function ($q) use ($search) {
                $q->where('email', 'like', "%{$search}%")
                  ->orWhere('full_name', 'like', "%{$search}%");
            });
        }

        $users = $query->orderByDesc('created_at')->paginate($request->integer('per_page', 25));

        return response()->json([
            'data' => $users->map(fn ($u) => $this->formatUser($u)),
            'meta' => [
                'current_page' => $users->currentPage(),
                'last_page' => $users->lastPage(),
                'total' => $users->total(),
            ],
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => 'required|email|unique:users',
            'full_name' => 'required|string|max:255',
            'profile_id' => 'required|uuid|exists:profiles,id',
            'password' => 'required|string|min:8',
            'is_active' => 'sometimes|boolean',
        ]);

        $user = User::create($validated);

        return response()->json([
            'data' => $this->formatUser($user->load('profile')),
        ], 201);
    }

    public function show(User $user): JsonResponse
    {
        return response()->json([
            'data' => $this->formatUser($user->load('profile')),
        ]);
    }

    public function update(Request $request, User $user): JsonResponse
    {
        $validated = $request->validate([
            'email' => 'sometimes|email|unique:users,email,' . $user->id . ',id',
            'full_name' => 'sometimes|string|max:255',
            'profile_id' => 'sometimes|uuid|exists:profiles,id',
            'is_active' => 'sometimes|boolean',
            'password' => 'sometimes|string|min:8',
        ]);

        $user->update($validated);

        return response()->json([
            'data' => $this->formatUser($user->fresh('profile')),
        ]);
    }

    public function destroy(User $user): JsonResponse
    {
        $user->delete();

        return response()->json(null, 204);
    }

    private function formatUser(User $user): array
    {
        return [
            'id' => $user->id,
            'email' => $user->email,
            'full_name' => $user->full_name,
            'profile_id' => $user->profile_id,
            'profile_code' => $user->profile->code,
            'profile_name' => $user->profile->name,
            'is_active' => $user->is_active,
            'created_at' => $user->created_at->toIso8601String(),
            'updated_at' => $user->updated_at->toIso8601String(),
        ];
    }
}
