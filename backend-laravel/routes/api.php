<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\RecordingController;
use App\Http\Controllers\Api\ProjectController;
use App\Http\Controllers\Api\ChatController;
use App\Http\Controllers\Api\PushDeviceController;
use App\Http\Controllers\Api\WebhookController;
use App\Http\Controllers\Api\Admin\UserController as AdminUserController;
use App\Http\Controllers\Api\Admin\ProfileController as AdminProfileController;
use App\Http\Controllers\Api\Admin\ProjectController as AdminProjectController;
use App\Http\Controllers\Api\Admin\RecordingController as AdminRecordingController;
use Illuminate\Support\Facades\Route;

// Public
Route::get('/health', fn () => response()->json(['status' => 'ok']));
Route::post('/auth/login', [AuthController::class, 'login']);
Route::post('/webhooks/assemblyai', [WebhookController::class, 'assemblyai']);

// Authenticated (Sanctum)
Route::middleware('auth:sanctum')->group(function () {
    // Auth
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::get('/auth/me', [AuthController::class, 'me']);

    // Recordings
    Route::get('/recordings', [RecordingController::class, 'index']);
    Route::post('/recordings', [RecordingController::class, 'store']);
    Route::get('/recordings/{recording}', [RecordingController::class, 'show']);
    Route::patch('/recordings/{recording}', [RecordingController::class, 'update']);
    Route::delete('/recordings/{recording}', [RecordingController::class, 'destroy']);
    Route::post('/recordings/{recording}/upload', [RecordingController::class, 'upload']);
    Route::get('/recordings/{recording}/audio', [RecordingController::class, 'audio']);
    Route::post('/recordings/{recording}/process', [RecordingController::class, 'process']);
    Route::post('/recordings/{recording}/reprocess', [RecordingController::class, 'reprocess']);
    Route::get('/recordings/{recording}/export/{format}', [RecordingController::class, 'export']);

    // Projects
    Route::get('/projects', [ProjectController::class, 'index']);
    Route::post('/projects', [ProjectController::class, 'store']);
    Route::get('/projects/{project}', [ProjectController::class, 'show']);
    Route::patch('/projects/{project}', [ProjectController::class, 'update']);
    Route::get('/projects/{project}/members', [ProjectController::class, 'members']);
    Route::post('/projects/{project}/members', [ProjectController::class, 'addMember']);
    Route::delete('/projects/{project}/members/{user}', [ProjectController::class, 'removeMember']);

    // Chat
    Route::get('/recordings/{recording}/chat', [ChatController::class, 'show']);
    Route::post('/recordings/{recording}/chat', [ChatController::class, 'send']);

    // Push devices
    Route::post('/push-devices', [PushDeviceController::class, 'register']);
    Route::delete('/push-devices/{pushDevice}', [PushDeviceController::class, 'destroy']);

    // Admin routes
    Route::middleware('admin')->prefix('admin')->group(function () {
        Route::apiResource('users', AdminUserController::class);
        Route::apiResource('profiles', AdminProfileController::class);

        Route::get('/projects', [AdminProjectController::class, 'index']);
        Route::get('/projects/{project}', [AdminProjectController::class, 'show']);
        Route::get('/projects/{project}/members', [AdminProjectController::class, 'members']);
        Route::post('/projects/{project}/members', [AdminProjectController::class, 'addMember']);
        Route::delete('/projects/{project}/members/{user}', [AdminProjectController::class, 'removeMember']);

        Route::get('/recordings', [AdminRecordingController::class, 'index']);
        Route::get('/recordings/{recording}', [AdminRecordingController::class, 'show']);
        Route::post('/recordings/{recording}/reprocess', [AdminRecordingController::class, 'reprocess']);
    });
});
