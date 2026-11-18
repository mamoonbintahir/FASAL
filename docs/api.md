# FASAL API reference (v1)

Base URL: `http://localhost:8080` in development. Every `/v1` endpoint except the two auth calls
needs `Authorization: Bearer <token>`. Bodies and responses are JSON whose shapes match the
`toJson()` of the models in `packages/fasal_core`. Errors have the form:

```json
{ "error": { "code": "validation", "message": "\"area\" is out of range" } }
```

| Status | Meaning |
|---|---|
| 400 | Validation error (`validation`, `invalid_phone`, `otp_invalid`, `otp_expired`, `missing_location`, `invalid_json`) |
| 401 | Missing/invalid/expired token (the app returns to sign-in) |
| 404 | Not found / not yours |
| 413 | Body over 64 KB |
| 429 | Too many requests (OTP resend < 60 s, wrong code 5×, > 10 auth calls/min per IP) |
| 503 | Weather temporarily unavailable |

## Auth

| Method & path | Body | Response |
|---|---|---|
| `POST /v1/auth/otp/request` | `{"phone": "0300 1234567"}` | `{"sent": true, "phone": "+923001234567", "devCode": "123456"}` (`devCode` only when `APP_ENV≠production`) |
| `POST /v1/auth/otp/verify` | `{"phone", "code"}` | `{"token", "user": {"id", "phone"}, "profile": UserProfile \| null}` |

## Account & profile

| Method & path | Body | Response |
|---|---|---|
| `GET /v1/me` | — | `{"user": {...}, "profile": UserProfile \| null}` |
| `PUT /v1/me/profile` | `UserProfile` (`district` must be a known district, `farmArea` > 0) | `UserProfile` |
| `DELETE /v1/me` | — | `204` — deletes the account and all data |

## Crops & tasks

| Method & path | Body | Response |
|---|---|---|
| `GET /v1/crops` | — | `Crop[]` |
| `POST /v1/crops` | `Crop` (`cropTypeId`, `sowingDate` within −365…+60 days, `area` > 0) | `201 Crop` (server assigns `id`; past tasks marked done) |
| `PUT /v1/crops/:id` | `Crop` | `Crop` |
| `DELETE /v1/crops/:id` | — | `204` (its task states and notifications are removed; records kept) |
| `GET /v1/tasks` | — | `FarmTask[]` generated from each crop's calendar |
| `PATCH /v1/tasks/:id` | `{"done": bool?, "reminder": "off"\|"sameDay"\|"dayBefore"?}` | `FarmTask` (done ⇒ an `ActivityRecord` is logged; undo removes it) |

## Weather

| Method & path | Response |
|---|---|
| `GET /v1/weather[?district=Multan]` | `WeatherReport` (defaults to the profile's district) |
| `GET /v1/weather/alerts` | `WeatherAlert[]` (last 30 days, newest first) |
| `POST /v1/weather/alerts/:id/read`, `POST /v1/weather/alerts/read-all` | `204` |

## Guidance, advice, Ask Fasal

| Method & path | Response |
|---|---|
| `GET /v1/guidance/:cropType/fertilizer` | `FertilizerGuide[]` |
| `GET /v1/guidance/:cropType/pests` | `PestGuide[]` |
| `GET /v1/guidance/:cropType/sprays` | `PesticideGuide[]` (category + safety only, no doses) |
| `GET /v1/guidance/:cropType/irrigation` | `IrrigationGuide \| null` |
| `GET /v1/advice` | `Advice[]` personalised from crops, tasks and weather |
| `POST /v1/ask` `{"question"}` | `AssistantAnswer` (`isSample: true` — rule-based, not AI) |

## Notifications & devices

| Method & path | Response |
|---|---|
| `GET /v1/notifications` | `AppNotification[]` (syncs due reminders/alerts first) |
| `POST /v1/notifications/:id/read`, `/read-all`, `/:id/restore` | `204` |
| `DELETE /v1/notifications/:id` | `204` (stays deleted, never regenerated) |
| `POST /v1/devices` `{"token", "platform"}` | `204` — registers an FCM token for push |

## Records

| Method & path | Body | Response |
|---|---|---|
| `GET/POST /v1/records/activities` | `{"type", "date", "cropId"?, "note"?}` | `ActivityRecord[]` / `201 ActivityRecord` |
| `DELETE /v1/records/activities/:id` | — | `204` |
| `GET/POST /v1/records/expenses` | `{"category", "amount" (whole Rs), "date", "cropId"?, "note"?}` | `ExpenseRecord[]` / `201 ExpenseRecord` |
| `DELETE /v1/records/expenses/:id` | — | `204` |

## Health

`GET /health` → `{"status": "ok", "db": "mongodb" | "memory", "time": "..."}`
