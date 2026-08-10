# Notebook Pro

Lightweight offline-first desktop notepad for macOS, Windows, and Linux — inspired by Apple Notes.

## Features (MVP)

- Two-pane note list + rich text editor
- Title, subtitle, headings, bold/italic, links, images
- Offline SQLite storage (Drift) with sync stub for future Firebase
- Daily writing streak + achievement badges
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
Local-first via Drift; `NoopSyncService` is the extension point for Firebase later.
