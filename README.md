# 🌾 FASAL — Helping Farmers Know What to Do and When

FASAL is a Flutter app for Pakistani farmers. It tells them **what to do, when, and how**
through the crop season: crop calendar, today's tasks, weather explained for their crop,
irrigation/fertilizer/pest guidance, voice read-out in Urdu or English, and farm records.

> **Phase 1:** complete Flutter frontend (works offline on mock data).
> **Phase 2:** a **Dart backend** (`server/`: Shelf + MongoDB) with phone/OTP sign-in, live
> weather (Open-Meteo), weather alerts, reminders and synced farm data. App and server share
> one Dart package (`packages/fasal_core`) for models, the crop catalog and the farming rules.
> Agricultural guidance is still **sample content** (labelled in the app) until reviewed by experts.

---

## Repository layout

```
FASAL/
├── lib/, test/            Flutter app (Android/iOS)
├── packages/fasal_core/   Shared Dart: models + JSON, crop catalog, guidance, task/irrigation/alert rules
├── server/                Dart REST API (Shelf) + MongoDB, Dockerfile, tests
├── docker-compose.yml     MongoDB + API for local development
└── docs/                  User flow diagram, API reference
```

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

### Run the app against the backend

```bash
# 1. Start MongoDB + the API (needs Docker)
docker compose up --build            # API on http://localhost:8080

#    …or without Docker (in-memory storage, data lost on restart):
cd server && dart pub get && dart run bin/server.dart

# 2. Run the app pointed at it
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080   # Android emulator
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8080   # real phone on the same Wi-Fi (your PC's IP)
```

Without `API_BASE_URL` the app runs fully offline on mock data (no sign-in), as in Phase 1.
With it, the flow becomes: language → onboarding → **phone number → 6-digit code** → profile → crops.
In development the server returns the code in the response and the app shows it, so no SMS
provider is needed for testing.

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

## Backend (Phase 2) — Dart + MongoDB

**Why Dart:** one language across the whole project. The app and server import the same
`fasal_core` models (`toJson`/`fromJson`), crop catalog and rules (task scheduling, irrigation
advice, weather alerts, Ask Fasal). The wire format can't drift, and offline mode gives the same answers.

| Concern | Implementation |
|---|---|
| HTTP | `shelf` + `shelf_router`, JSON, `/v1` prefix, CORS, request logging, 64 KB body limit |
| Database | MongoDB (local Docker or **MongoDB Atlas**) via `mongo_dart`; an in-memory store for tests/dev; indexes on `userId`, unique `phone` |
| Auth | Phone + 6-digit OTP (hashed, 5-min expiry, 5 attempts, 60 s resend, per-IP rate limit) → HS256 JWT (30 days) stored in the app's secure storage |
| Weather | **Open-Meteo** (free, no API key) per district coordinates, cached 30 min, stale-on-error fallback |
| Alerts | Generated from the forecast (rain/heavy rain, heat ≥38 °C, cold ≤4 °C, wind ≥30 km/h), history + read state per user |
| Notifications | Task-due, day-before, stage-change and weather notifications, idempotent; hourly background sync; `PushSender` interface ready for FCM |
| Privacy | `DELETE /v1/me` erases the account and all data; secrets only from environment variables |

### Server configuration (`server/.env.example`)

| Variable | Default | Notes |
|---|---|---|
| `PORT` | `8080` | |
| `APP_ENV` | `development` | `production` disables returning the OTP and requires `JWT_SECRET` + `MONGODB_URI` |
| `JWT_SECRET` | random (dev) | ≥32 characters in production |
| `MONGODB_URI` | — (in-memory) | e.g. `mongodb+srv://user:pass@cluster.mongodb.net/fasal` |
| `WEATHER_PROVIDER` | `openmeteo` | `sample` for offline development |
| `CORS_ORIGINS` | `*` | |

### Deploying (free/cheap options)

1. Create a free **MongoDB Atlas** cluster and copy its connection string.
2. Deploy the Docker image (`docker build -f server/Dockerfile .`) to Render, Railway, Fly.io or
   Google Cloud Run with `APP_ENV=production`, `JWT_SECRET`, `MONGODB_URI`.
3. Build the app with `--dart-define=API_BASE_URL=https://your-api-host`.

**Before real farmers use it:** plug an SMS gateway into `SmsSender` (Twilio or a local Pakistani
aggregator), add Firebase Cloud Messaging to the app and a `PushSender` on the server for push
notifications, and have the guidance content reviewed by agronomists.

Full endpoint list: [`docs/api.md`](docs/api.md).

### Backend contract (summary)

| Method | Endpoint | Used by |
|---|---|---|
| `POST` | `/v1/auth/otp/request`, `/v1/auth/otp/verify` | AuthRepository |
| `GET` `PUT` `DELETE` | `/v1/me`, `/v1/me/profile` | ProfileRepository, account deletion |
| `GET` `POST` `PUT` `DELETE` | `/v1/crops`, `/v1/crops/:id` | CropRepository |
| `GET` `PATCH` | `/v1/tasks`, `/v1/tasks/:id` | TaskRepository (completing logs a record) |
| `GET` `POST` | `/v1/weather`, `/v1/weather/alerts`, `…/:id/read`, `…/read-all` | WeatherRepository |
| `GET` | `/v1/guidance/:cropType/{fertilizer,pests,sprays,irrigation}`, `/v1/advice` | RecommendationRepository |
| `POST` | `/v1/ask` | Ask Fasal |
| `GET` `POST` `DELETE` | `/v1/notifications…`, `/v1/devices` | NotificationRepository, push tokens |
| `GET` `POST` `DELETE` | `/v1/records/activities…`, `/v1/records/expenses…` | RecordsRepository |

## Tests

- `test/unit/domain_test.dart`: crop stages and progress, task scheduling and statuses,
  irrigation hold-on-rain, Ask Fasal rules, validators, formatting, Urdu/English strings,
  settings persistence, catalog integrity and the "no doses" check.
- `test/widget/app_flow_test.dart`: first-run flow end to end, form validation, completing
  a task (dashboard + records), Urdu RTL, removing a crop, weather-unavailable state, adding
  an expense, voice controls.
- `test/widget/screens_render_test.dart`: opens every screen in English and Urdu at
  320×640 and 412×915; any overflow or exception fails the test.
- `test/unit/api_repositories_test.dart`: the app's API repositories against a fake HTTP layer
  (request shapes, token handling, error mapping, session expiry).
- `packages/fasal_core/test/`: JSON round trips for every model (the app⇄server contract), alert rules, phone rules.
- `server/test/api_test.dart`: 17 API tests covering OTP auth (validation, expiry, resend limit, single use),
  JWT tampering/expiry, data isolation between users, crop/task/record flows, weather and alerts,
  notifications, guidance, Ask Fasal and account deletion.
- `server/test/mongo_test.dart`: the same main flow against a real MongoDB (CI service container).
  CI also compiles the server, smoke-tests it over HTTP and builds the Docker image.

### Latest results (CI on Flutter 3.50.0 stable)

- `flutter analyze` — **no issues**
- `flutter test` — **28 tests, all passing** (unit + widget + render tests in EN/UR at two screen sizes)
- `flutter build apk --debug` — **builds**; APK attached to each CI run as `fasal-debug-apk`
- Screenshots of 22 screens are rendered on every push to `main` and published to the
  [`ci-screenshots`](https://github.com/mamoonbintahir/FASAL/tree/ci-screenshots) branch
  (emoji appear monochrome there; phones show the colour system emoji).

## User flow

See [`docs/user-flow.md`](docs/user-flow.md) for the full Mermaid flowchart, including
alternate flows (no crops, invalid input, missing location, weather unavailable, empty
notifications, task completed, crop edited/removed, permission denied, errors).

## Known limitations

- SMS delivery is not connected yet: the dev server returns the code instead (`SmsSender` interface ready).
- Push notifications: notifications are created on the server and shown in the app, but phone push
  needs Firebase Cloud Messaging set up (`PushSender` interface ready).
- "Use my location" still returns a demo district; GPS needs `geolocator` + location permission.
- Guidance content and Ask Fasal answers are sample rules, not expert-verified or AI.
- Photo diagnosis and voice questions are still shown as "coming soon".

## License & credits

Fonts: Manrope and Noto Nastaliq Urdu (SIL Open Font License; see `assets/fonts/`).
