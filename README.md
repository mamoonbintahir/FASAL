# 🌾 FASAL — Helping Farmers Know What to Do and When

FASAL is a Flutter app for Pakistani farmers. It tells them **what to do, when, and how**
through the crop season: crop calendar, today's tasks, weather explained for their crop,
irrigation/fertilizer/pest guidance, voice read-out in Urdu or English, and farm records.

> **Phase 1 (this repo): complete frontend with mock data.** No backend, live weather, AI or
> push notifications yet. All agricultural content is **sample data** and is labelled as such
> in the app. Phase 2 adds the Node.js/Express + MongoDB backend.

---

## Quick start

Requirements: **Flutter 3.47+ stable** (developed against 3.50 / Dart 3.13+), Android Studio
or VS Code, an Android device/emulator.

```bash
git clone https://github.com/mamoonbintahir/FASAL.git
cd FASAL
bash tool/setup_platforms.sh   # one time: creates android/ & ios/ and patches the manifest
flutter pub get
flutter run
```

On Windows without bash: run `flutter create . --project-name fasal --org pk.fasal --platforms android,ios`,
delete `test/widget_test.dart` if it was created, and add this inside `<queries>` in
`android/app/src/main/AndroidManifest.xml` so voice works on Android 11+:

```xml
<intent>
    <action android:name="android.intent.action.TTS_SERVICE" />
</intent>
```

### Quality checks

```bash
flutter analyze
flutter test
flutter build apk --debug
```

The GitHub Actions workflow (`.github/workflows/flutter-ci.yml`) runs all three on every push
and uploads a debug APK as an artifact.

### Demo tips

- **Settings → Demo options → Load sample farm** adds the reference farm (wheat, day 38,
  5 acres, sample records totalling Rs 23,500).
- **Simulate weather unavailable** shows the weather error/retry flow.
- **Restart demo** clears all local data and starts from the language screen.
- Urdu voice needs an Urdu TTS voice on the phone (Google Text-to-speech → Urdu). If it is
  missing, the app says so and reads in English.

---

## Features (Phase 1)

| Area | What works |
|---|---|
| First run | Splash → language (English / اردو, full RTL) → 4-page skippable onboarding → profile (name, district picker, farm area + unit) → add first crop or skip |
| Dashboard | Greeting, location, weather chip, priority weather alert with Listen, crop hero card (stage, day, harvest window), Today's tasks with check-off, quick actions, Ask Fasal, 7-day strip, crop care |
| My Crops | Crop cards (stage, day, sowing date, area, progress, next task), add / edit / remove with confirmation |
| Crop details | What to do now, stage timeline, expected harvest, calendar/care/irrigation/history tiles, what's next, what to avoid, overview |
| Crop calendar | Date strip with rain icons, tasks for the selected day, coming next, Upcoming / Completed / Overdue / Full timeline, activity details sheet with mark done + reminder choice |
| Today's tasks | Overdue, today, next 7 days, completed; filter by crop |
| Crop care | Fertilizer (current stage first), pests & diseases (symptoms, prevention, rain risk), sprays (product *category* + safety only), photo-diagnosis entry marked "coming soon" |
| Irrigation | Status (hold / due soon / OK) from schedule + rain forecast, next irrigation, forecast, reminders, critical stages |
| Weather | Current conditions, rain/wind/humidity, "what this means for your crop", 7-day list with day details, alerts with active/past and read/unread |
| Notifications | Today / earlier, unread state, tap to open, swipe to delete with undo, mark all read |
| Ask Fasal | Suggested and typed questions answered from the crop calendar + weather (labelled sample answers); mic explains voice input is coming |
| Advice | Today, crop care, irrigation, fertilizer, pests, weather |
| Records | Season total, activities and expenses, add/delete with validation; completing a task logs an activity |
| Crop history | Timeline of crop added, sowing, activities, expenses, notes; add note |
| Settings | Language, profile, location, area unit, notification types, voice speed + test, about, privacy, help, demo options |
| Voice | Listen / Pause / Resume / Stop on cards, reads exactly the text on screen, Urdu or English |

## Safety of agricultural content

- No fertilizer quantities, pesticide product names or doses anywhere in the app. Fertilizer
  cards say to use the quantity from the extension office or bag label; spray guidance shows
  only the product category, timing and safety.
- Every guidance item carries a `GuidanceSource` (`sample` / `verified`). Phase 1 content is
  all `sample` and the UI shows a "Sample guidance — confirm with your local agriculture
  office" note. Only expert-reviewed backend content should ever be marked `verified`.
- A unit test fails if any task text contains a numeric dose (e.g. "50 kg").

---

## Architecture

```
lib/
├── main.dart / app.dart        # bootstrap, ProviderScope, MaterialApp.router, locale & theme
├── core/
│   ├── config/env.dart         # --dart-define config (USE_MOCK_DATA, API_BASE_URL)
│   ├── constants/              # districts
│   ├── l10n/                   # AppStrings (EN+UR side by side) + delegate
│   ├── network/                # Dio ApiClient + AppException types
│   ├── router/app_router.dart  # go_router: onboarding routes + 5-tab StatefulShellRoute
│   ├── storage/                # LocalStore (prefs JSON), SecureStorage (tokens)
│   ├── theme/                  # colors, typography, spacing, ThemeData
│   ├── utils/                  # dates, formatters, validators
│   └── widgets/                # design-system components (cards, buttons, inputs, states…)
├── data/
│   ├── models/                 # Crop, FarmTask, Weather, Guidance, Records, Profile…
│   ├── repositories/           # repository INTERFACES (the UI depends only on these)
│   ├── mock/                   # Phase 1 implementations + sample catalog/guidance/weather
│   │   └── engine/             # task scheduler, irrigation/advice/assistant rules
│   └── api/                    # Phase 2 API implementations (skeletons + DTO pattern)
├── providers/                  # Riverpod: repositories, settings, farm state, TTS
├── services/tts_service.dart   # text-to-speech engine abstraction
├── widgets/                    # app-specific widgets (task tile, crop cards, weather, Listen)
└── features/                   # one folder per screen group
    ├── onboarding/ shell/ home/ crops/ calendar/ care/ irrigation/
    └── weather/ notifications/ ask/ advice/ records/ settings/
```

### Key decisions

- **`material_ui` instead of `package:flutter/material.dart`.** Flutter 3.47 deprecated the
  built-in Material library in favour of the `material_ui` package (go_router 18 and
  Riverpod 3 already depend on it). Localizations come from `GlobalMaterialLocalizations.delegates`.
- **Riverpod 3** for state, with automatic retry disabled so failures show an explicit
  "Try again". Async state uses `AsyncNotifier`s; derived views (`CropView`, irrigation
  status) are plain providers.
- **go_router `StatefulShellRoute`** for the 5-tab bottom navigation. Detail routes are
  registered under every tab, so the bottom bar stays visible (as in the reference design)
  and Back always returns to where the farmer came from.
- **Repository pattern.** Every data source sits behind an interface in
  `data/repositories/repositories.dart`. Swapping mock → API is a one-line change per
  repository in `providers/repository_providers.dart`, or set `USE_MOCK_DATA=false`.
- **Localization without code generation.** `AppStrings` holds each string once with its
  English and Urdu versions side by side, so a missing translation is a compile error.
  Agricultural content uses `LocalizedText {en, ur}`, which the backend will return in the same shape.
- **Fonts bundled** (Manrope for English, Noto Nastaliq Urdu for Urdu, both OFL) so text
  renders correctly offline. Emoji are used as icons, matching the reference design and
  recognisable to low-literacy users.
- **Mock data persists locally** (SharedPreferences) with a small artificial delay so
  loading states are visible and the demo survives restarts.
- **Tasks before Fasal:** when a crop is added with a past sowing date, tasks due more than
  3 days earlier count as already done, so the farmer isn't flooded with "overdue" items.

### Backend contract (Phase 2 draft)

| Method | Endpoint | Used by |
|---|---|---|
| `POST` | `/auth/otp`, `/auth/verify` | AuthRepository (phone OTP) |
| `GET/PUT` | `/me` | ProfileRepository |
| `GET/POST/PUT/DELETE` | `/crops`, `/crops/:id` | CropRepository (`ApiCropRepository` written) |
| `GET` | `/crops/:id/tasks`, `PATCH /tasks/:id` | TaskRepository |
| `GET` | `/weather?district=`, `/weather/alerts?district=` | WeatherRepository (`ApiWeatherRepository` written); the server holds the weather API key |
| `GET` | `/guidance/:cropType/{fertilizer,pests,sprays,irrigation}` | RecommendationRepository |
| `POST` | `/ask` | Ask Fasal |
| `GET/PATCH/DELETE` | `/notifications` | NotificationRepository (+ FCM push) |
| `GET/POST/DELETE` | `/records/activities`, `/records/expenses` | RecordsRepository |

Run against a backend:
`flutter run --dart-define=USE_MOCK_DATA=false --dart-define=API_BASE_URL=https://api.example.com/v1`

## Tests

- `test/unit/domain_test.dart`: crop stages and progress, task scheduling and statuses,
  irrigation hold-on-rain, Ask Fasal rules, validators, formatting, Urdu/English strings,
  settings persistence, catalog integrity and the "no doses" check.
- `test/widget/app_flow_test.dart`: first-run flow end to end, form validation, completing
  a task (dashboard + records), Urdu RTL, removing a crop, weather-unavailable state, adding
  an expense, voice controls.
- `test/widget/screens_render_test.dart`: opens every screen in English and Urdu at
  320×640 and 412×915; any overflow or exception fails the test.

## User flow

See [`docs/user-flow.md`](docs/user-flow.md) for the full Mermaid flowchart, including
alternate flows (no crops, invalid input, missing location, weather unavailable, empty
notifications, task completed, crop edited/removed, permission denied, errors).

## Known limitations (by design in Phase 1)

- Weather, alerts, notifications and advice are sample data; nothing is fetched online.
- "Use my location" returns a demo district; GPS comes with the backend.
- Reminders are saved but not delivered as phone notifications yet.
- Photo diagnosis and voice questions are shown as "coming soon".

## License & credits

Fonts: Manrope and Noto Nastaliq Urdu (SIL Open Font License; see `assets/fonts/`).
