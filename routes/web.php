<?php

use App\Modules\Admin\Http\Controllers\Web\AdminController;
use App\Modules\Recordings\Http\Controllers\Web\AppController;
use App\Modules\Identity\Http\Controllers\Web\AuthController;
use App\Modules\Recordings\Http\Controllers\Web\DashboardController;
use Illuminate\Support\Facades\Route;

Route::get('/', [AppController::class, 'entry'])->name('home');
Route::post('/', [DashboardController::class, 'submit'])->name('home.submit');

Route::get('/login', [AuthController::class, 'showLogin']);
Route::post('/login', [AuthController::class, 'login'])->name('login');
Route::post('/logout', [AuthController::class, 'logout'])->name('logout');

Route::middleware('auth')->group(function (): void {
    Route::get('/home', [AppController::class, 'home'])->name('workspace.home');
    Route::get('/library', [AppController::class, 'library'])->name('workspace.library');
    Route::get('/recordings/{recording}', [AppController::class, 'recording'])->name('workspace.recordings.show');
    Route::get('/recordings/{recording}/chat', [AppController::class, 'chat'])->name('workspace.recordings.chat');
    Route::get('/settings', [AppController::class, 'settings'])->name('workspace.settings');

    Route::post('/projects/active', [AppController::class, 'setActiveProject'])->name('workspace.projects.active');
    Route::post('/projects', [AppController::class, 'storeProject'])->name('workspace.projects.store');

    Route::post('/recordings/upload', [AppController::class, 'uploadAudio'])->name('workspace.recordings.upload');
    Route::post('/recordings/{recording}/project', [AppController::class, 'updateRecordingProject'])->name('workspace.recordings.project');
    Route::post('/recordings/{recording}/reprocess', [AppController::class, 'reprocessRecording'])->name('workspace.recordings.reprocess');
    Route::post('/recordings/{recording}/chat', [AppController::class, 'sendChat'])->name('workspace.recordings.chat.send');
    Route::get('/recordings/{recording}/audio', [AppController::class, 'audio'])->name('workspace.recordings.audio');
    Route::get('/recordings/{recording}/export/{format}', [AppController::class, 'export'])->name('workspace.recordings.export');
});

Route::prefix('admin')
    ->middleware(['auth', 'admin.web'])
    ->name('workspace.admin.')
    ->group(function (): void {
        Route::get('/', [AdminController::class, 'dashboard'])->name('dashboard');

        Route::get('/users', [AdminController::class, 'users'])->name('users');
        Route::post('/users', [AdminController::class, 'storeUser'])->name('users.store');
        Route::patch('/users/{user}', [AdminController::class, 'updateUser'])->name('users.update');
        Route::delete('/users/{user}', [AdminController::class, 'destroyUser'])->name('users.destroy');

        Route::get('/profiles', [AdminController::class, 'profiles'])->name('profiles');
        Route::post('/profiles', [AdminController::class, 'storeProfile'])->name('profiles.store');
        Route::patch('/profiles/{profile}', [AdminController::class, 'updateProfile'])->name('profiles.update');
        Route::delete('/profiles/{profile}', [AdminController::class, 'destroyProfile'])->name('profiles.destroy');

        Route::get('/projects', [AdminController::class, 'projects'])->name('projects');
        Route::post('/projects', [AdminController::class, 'storeProject'])->name('projects.store');
        Route::patch('/projects/{project}', [AdminController::class, 'updateProject'])->name('projects.update');
        Route::get('/projects/{project}/members', [AdminController::class, 'members'])->name('projects.members');
        Route::post('/projects/{project}/members', [AdminController::class, 'addMember'])->name('projects.members.store');
        Route::delete('/projects/{project}/members/{user}', [AdminController::class, 'removeMember'])->name('projects.members.destroy');

        Route::get('/recordings', [AdminController::class, 'recordings'])->name('recordings');
        Route::get('/recordings/{recording}', [AdminController::class, 'recording'])->name('recordings.show');
        Route::post('/recordings/{recording}/project', [AdminController::class, 'updateRecordingProject'])->name('recordings.project');
        Route::post('/recordings/{recording}/reprocess', [AdminController::class, 'reprocessRecording'])->name('recordings.reprocess');
        Route::get('/recordings/{recording}/export/{format}', [AdminController::class, 'exportRecording'])->name('recordings.export');

        Route::get('/jobs', [AdminController::class, 'jobs'])->name('jobs');
    });
