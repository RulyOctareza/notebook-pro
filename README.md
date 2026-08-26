# Notebook Pro

Lightweight offline-first desktop notepad for macOS, Windows, and Linux — inspired by Apple Notes.

## Features

- Two-pane note list + rich text editor (Quill)
- Folders, tags, pin sections, Trash / restore
- Title, headings, bold/italic, links, images, find-in-note
- Markdown import + export (PDF / MD / TXT / print)
- Offline SQLite (Drift) with Firebase sync when signed in
- Sync status indicator + last-write-wins conflict handling
- Daily writing streak, weekly word goal, achievement badges
- Focus mode, command palette, settings, local JSON backup
- Light / Dark / System theme

## Run

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d macos
```

## Test

```bash
flutter test
```

## Architecture

Clean Architecture + feature folders (`notes`, `gamification`, `settings`).
Local-first via Drift; `FirebaseSyncService` (or `NoopSyncService` offline)
syncs under `users/{uid}/…` after Google sign-in.
