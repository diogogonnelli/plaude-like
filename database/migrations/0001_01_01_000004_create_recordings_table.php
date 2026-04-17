<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('recordings', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('user_id');
            $table->uuid('created_by_user_id');
            $table->uuid('project_id')->nullable();
            $table->string('title');
            $table->string('source_type'); // microphone, upload, desktop_meeting
            $table->string('status')->default('uploaded'); // uploaded, processing_transcript, processing_summary, indexing, ready, failed
            $table->integer('duration_ms')->nullable();
            $table->string('audio_path')->nullable();
            $table->text('capture_metadata')->nullable(); // JSON stored as nvarchar(max)
            $table->string('transcription_provider')->nullable(); // assemblyai, mock
            $table->string('transcription_job_id')->nullable();
            $table->timestamp('transcription_started_at')->nullable();
            $table->timestamp('transcription_completed_at')->nullable();
            $table->text('last_error')->nullable();
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
            $table->foreign('created_by_user_id')->references('id')->on('users')->cascadeOnDelete();
            $table->foreign('project_id')->references('id')->on('projects')->cascadeOnDelete();
            $table->index(['user_id', 'created_at']);
            $table->index(['created_by_user_id', 'created_at']);
            $table->index(['project_id', 'created_at']);
            $table->index('transcription_job_id');
        });

        Schema::create('transcript_segments', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('recording_id');
            $table->string('speaker_label');
            $table->integer('start_ms');
            $table->integer('end_ms');
            $table->text('text');

            $table->foreign('recording_id')->references('id')->on('recordings')->cascadeOnDelete();
            $table->index(['recording_id', 'start_ms']);
        });

        Schema::create('summaries', function (Blueprint $table) {
            $table->uuid('recording_id')->primary();
            $table->text('overview');
            $table->text('chapters'); // JSON stored as nvarchar(max)

            $table->foreign('recording_id')->references('id')->on('recordings')->cascadeOnDelete();
        });

        Schema::create('note_artifacts', function (Blueprint $table) {
            $table->uuid('recording_id')->primary();
            $table->string('title');
            $table->text('tags'); // JSON array stored as nvarchar(max)
            $table->text('highlights'); // JSON array stored as nvarchar(max)
            $table->text('action_items'); // JSON array stored as nvarchar(max)

            $table->foreign('recording_id')->references('id')->on('recordings')->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('note_artifacts');
        Schema::dropIfExists('summaries');
        Schema::dropIfExists('transcript_segments');
        Schema::dropIfExists('recordings');
    }
};
