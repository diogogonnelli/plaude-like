<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Profile;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\View\View;

class DashboardController extends Controller
{
    public function index(Request $request): View
    {
        $user = $request->user();

        if (! $user) {
            return view('home', [
                'user' => null,
                'recordings' => collect(),
                'projects' => collect(),
                'adminOverview' => null,
            ]);
        }

        $user->loadMissing('profile');

        $recordings = $user->recordings()
            ->with(['summary', 'noteArtifact', 'project'])
            ->orderByDesc('created_at')
            ->limit(10)
            ->get();

        $projects = $user->projects()
            ->orderBy('name')
            ->get();

        return view('home', [
            'user' => $user,
            'recordings' => $recordings,
            'projects' => $projects,
            'adminOverview' => $this->adminOverviewFor($user),
        ]);
    }

    private function adminOverviewFor(User $user): ?array
    {
        if (! $user->isAdmin()) {
            return null;
        }

        return [
            'usersCount' => User::query()->count(),
            'profilesCount' => Profile::query()->count(),
            'recentUsers' => User::query()
                ->with('profile')
                ->orderByDesc('created_at')
                ->limit(5)
                ->get(),
            'profiles' => Profile::query()
                ->withCount('users')
                ->orderBy('name')
                ->get(),
        ];
    }
}
