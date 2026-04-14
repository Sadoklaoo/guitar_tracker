# Guitar Tracker

Guitar Tracker is a Flutter app for managing songs, chords, and fingerstyle arrangements. It includes support for:

- browsing and editing songs
- chord management
- fingerstyle song creation with mixed note/chord sequence support
- backend integration via Dio and FastAPI-style JSON endpoints
- state management with Riverpod and navigation with GoRouter

## Key Features

- Add/edit fingerstyle songs with metadata, technique, tuning, tempo, capo, tab URL, and notes
- Build a mixed `sequence` of notes and chords with duration values
- Preserve legacy `chordIds` only when no sequence is provided
- Fetch technique options from the backend
- Keep UI data fresh by invalidating providers after create/update

## Project Structure

- `lib/main.dart` — app bootstrap and router initialization
- `lib/config/router.dart` — navigation routes and bottom nav shell
- `lib/services/api_service.dart` — HTTP client and backend API methods
- `lib/providers/` — Riverpod providers for songs, chords, fingerstyle, and API services
- `lib/models/` — app domain models, including `FingerstyleSong` and sequence item serialization
- `lib/screens/` — UI screens for home, songs, chords, and fingerstyle features
- `lib/widgets/` — reusable UI components and app state widgets

## Fingerstyle JSON Contract

This app uses the following primary shape for fingerstyle songs:

```json
{
  "title": "Blackbird",
  "artist": "Beatles",
  "genre": "Classic Rock",
  "difficulty": "Intermediate",
  "rating": 5,
  "technique": "Fingerstyle",
  "tuning": "Standard",
  "tempo_bpm": 92,
  "time_signature": "4/4",
  "key": "G major",
  "capo": 0,
  "tab_url": "https://example.com/tab",
  "arrangement_notes": "Play softly, let notes ring",
  "sequence": [
    { "type": "chord", "value": "G", "duration": 1.0 },
    { "type": "chord", "value": "Em", "duration": 1.0 },
    { "type": "note", "value": "B2", "duration": 0.5 },
    { "type": "note", "value": "D3", "duration": 0.5 }
  ],
  "chordIds": []
}
```

- `sequence` is the primary source of chord/note data
- `chordIds` is legacy and should only be included when `sequence` is empty or absent
- The frontend never sends a derived `chords` field

## Setup

1. Install Flutter SDK: https://flutter.dev/docs/get-started/install
2. Open `guitar_tracker` in your editor.
3. Run:

```bash
flutter pub get
flutter analyze
flutter run
```

## Notes

- The app currently targets Flutter `>=3.2.0 <4.0.0`.
- Backend API integration relies on `lib/services/api_service.dart` and `lib/providers/api_service_provider.dart`.
- Major fingerstyle flow files: `lib/models/fingerstyle_song.dart`, `lib/providers/fingerstyle_provider.dart`, `lib/screens/fingerstyle/fingerstyle_form_screen.dart`.
