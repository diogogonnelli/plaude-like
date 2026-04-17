<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\View\View;

class DashboardController extends Controller
{
    public function index(Request $request): View
    {
        $user = $request->user();
        $recordings = $user->recordings()
            ->with(['summary', 'noteArtifact', 'project'])
            ->orderByDesc('created_at')
            ->limit(10)
            ->get();

        return view('dashboard', compact('user', 'recordings'));
    }
}
