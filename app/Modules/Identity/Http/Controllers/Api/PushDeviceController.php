<?php

namespace App\Modules\Identity\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Modules\Identity\Models\PushDevice;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PushDeviceController extends Controller
{
    public function register(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'token' => 'required|string',
            'platform' => 'required|in:android,ios',
        ]);

        PushDevice::updateOrCreate(
            ['token' => $validated['token']],
            [
                'user_id' => $request->user()->id,
                'platform' => $validated['platform'],
            ],
        );

        return response()->json(['data' => ['message' => 'Device registered']], 201);
    }

    public function destroy(Request $request, PushDevice $pushDevice): JsonResponse
    {
        if ($pushDevice->user_id !== $request->user()->id) {
            abort(403, 'Forbidden');
        }

        $pushDevice->delete();

        return response()->json(null, 204);
    }
}
