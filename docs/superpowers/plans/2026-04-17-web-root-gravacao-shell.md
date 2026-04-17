# Web Root GravAção Shell Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the simple Laravel root dashboard with a Flutter-like root shell that keeps all interaction on `/`.

**Architecture:** `GET /` renders a tabbed one-route shell and `POST /` dispatches authenticated actions by `intent`. The Blade layer mirrors the Flutter layout while controller methods reuse the existing Laravel models and services for recordings, chat, projects, and admin data.

**Tech Stack:** Laravel, Blade, Tailwind CSS via Vite, vanilla browser JavaScript, PHPUnit feature tests.

---

### Task 1: Lock the root-shell contract in feature tests

**Files:**
- Modify: `tests/Feature/WebAccessTest.php`

- [ ] **Step 1: Write failing assertions for the new authenticated shell**

- [ ] **Step 2: Run `php artisan test tests/Feature/WebAccessTest.php` and confirm the old Blade no longer matches**

- [ ] **Step 3: Add failing tests for active project selection and root audio upload**

- [ ] **Step 4: Re-run `php artisan test tests/Feature/WebAccessTest.php` and confirm failures are for missing root intents and shell content**

### Task 2: Expand the web controller contract

**Files:**
- Modify: `app/Http/Controllers/Web/DashboardController.php`
- Modify: `routes/web.php`
- Modify: `app/Http/Controllers/Web/AuthController.php`

- [ ] **Step 1: Add query-driven tab/detail state loading to `DashboardController@index`**

- [ ] **Step 2: Add `DashboardController@submit` with `intent` dispatch for authenticated root actions**

- [ ] **Step 3: Keep login/logout working from `POST /` without breaking guest auth**

- [ ] **Step 4: Run targeted web feature tests**

### Task 3: Implement root web actions

**Files:**
- Modify: `app/Http/Controllers/Web/DashboardController.php`

- [ ] **Step 1: Implement active project session persistence**

- [ ] **Step 2: Implement project creation**

- [ ] **Step 3: Implement audio upload/microphone upload using `RecordingService` and storage disk `recordings`**

- [ ] **Step 4: Implement recording reassignment, reprocess, and chat send**

- [ ] **Step 5: Run targeted web feature tests**

### Task 4: Rebuild the authenticated Blade shell

**Files:**
- Modify: `resources/views/home.blade.php`

- [ ] **Step 1: Replace the old simple dashboard layout with a Flutter-like sidebar/header shell**

- [ ] **Step 2: Add `home`, `library`, `system`, and `admin` tab rendering in the root view**

- [ ] **Step 3: Add inline detail/chat surface for the selected recording**

- [ ] **Step 4: Keep the guest login flow visually aligned with the new shell**

### Task 5: Add root-shell browser behavior

**Files:**
- Modify: `resources/js/app.js`

- [ ] **Step 1: Add microphone capture logic with `MediaRecorder` and hidden multipart form submission**

- [ ] **Step 2: Add lightweight client behavior for file-picker submission and section affordances where needed**

- [ ] **Step 3: Verify the built page still works without JavaScript for non-capture actions**

### Task 6: Verify end-to-end

**Files:**
- Modify if needed: `tests/Feature/WebAccessTest.php`

- [ ] **Step 1: Run `php artisan test tests/Feature/WebAccessTest.php`**

- [ ] **Step 2: Run `php artisan test`**

- [ ] **Step 3: If markup or JS changed build inputs, run `npm run build` or the repo’s equivalent frontend build**

