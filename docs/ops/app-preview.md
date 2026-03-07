# App Preview

## Purpose
Define how to inspect the app visually while development is in progress.

## Preview Modes
- `flutter run -d windows`: fastest local layout preview if the app supports desktop
- `flutter run -d chrome`: quick browser preview for layout and API wiring checks
- `flutter run -d emulator-<id>`: primary Android preview during feature development
- `flutter run -d <device-id>`: best validation path on a physical Android device

## Recommended Progression
1. use mock data and run the UI in a fast preview target first
2. connect the app to the local Docker backend
3. validate Android behavior in an emulator
4. validate final behavior on a real Android device before release

## Local Preview Windows
- keep one support window for `docker compose up`
- keep one support window for `flutter run`
- launch the Android emulator separately when needed
- do not count support windows as specialist worker sessions

## Typical Commands
Prepare backend:
- `Set-Location E:\source\signal-desk`
- `docker compose --env-file .\infra\local\.env -f .\infra\local\docker-compose.yml up -d`

Run Flutter app from the future mobile worktree:
- `Set-Location E:\source\signal-desk-worktrees\app-001`
- `flutter devices`
- `flutter run -d chrome`
- `flutter run -d emulator-5554`

Capture evidence for reviews:
- take screenshots for major screens after each milestone
- attach the preview target used in the handoff note
- if layout differs by target, note the difference explicitly

## Preview Checklist
- dashboard loads without empty-state confusion
- keyword ranking is readable at phone width
- detail screen shows score, evidence, and related items clearly
- loading and error states are visible and understandable
- local API endpoint configuration is documented

## When To Use Which Target
- use browser preview for fast UI iteration
- use emulator preview for Android behavior and navigation
- use physical device preview for final acceptance and performance sanity checks
