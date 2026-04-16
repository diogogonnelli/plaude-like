<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('chat_sessions', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('recording_id')->unique();
            $table->timestamp('created_at')->useCurrent();

            $table->foreign('recording_id')->references('id')->on('recordings')->cascadeOnDelete();
        });

        Schema::create('chat_messages', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('chat_session_id');
            $table->string('role'); // user, assistant
            $table->text('content');
            $table->text('citations')->nullable(); // JSON stored as nvarchar(max)
            $table->timestamp('created_at')->useCurrent();

            $table->foreign('chat_session_id')->references('id')->on('chat_sessions')->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('chat_messages');
        Schema::dropIfExists('chat_sessions');
    }
};
