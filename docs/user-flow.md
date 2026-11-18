# FASAL — End-to-end farmer flow

Main flow (solid) and alternate flows (dashed). Matches the Phase 1 frontend.

```mermaid
flowchart TD
    A([App launch]) --> B[Splash]
    B -->|first run| C[Language selection<br/>English / اردو]
    B -->|returning farmer| H
    C --> D[Onboarding · 4 pages<br/>Skip available]
    D -->|offline build| E
    D -->|connected to server| L1[Phone number]
    L1 --> L2[6-digit SMS code]
    L2 -->|existing account| H
    L2 -->|new farmer| E
    E[Farmer setup<br/>name · district · farm area + unit]
    E --> F[Add crop<br/>select crop · variety]
    F --> F1[Enter sowing date]
    F1 --> F2[Enter farm area · seed · field]
    F2 --> F3[Save crop · Start Fasal]
    F3 --> H[Home dashboard<br/>Today on your farm]

    H --> I[Crop dashboard / details]
    I --> J[Crop growth stage<br/>stage timeline · progress · harvest window]
    J --> K[Farming timeline<br/>crop calendar]
    K --> L[Today's tasks]
    H --> L
    L --> M[Recommendations / Advice]
    M --> N[Irrigation · Fertilizer · Pest & spray guidance]
    H --> O[Weather · 7-day forecast]
    O --> P[Weather alerts]
    N --> Q[🔊 Voice guidance<br/>Listen · Pause · Stop]
    P --> Q
    L --> R[Complete farming activity ✔]
    R --> S[Crop history & records updated]
    S --> H

    H --> T[Ask Fasal<br/>suggested / typed questions]
    H --> U[Notifications]
    H --> V[Settings<br/>language · profile · location · voice · units]

    %% Alternate flows
    H -. no crops added .-> X1[Empty state<br/>+ Add your crop]
    X1 -.-> F
    E -. invalid input .-> X2[Inline errors<br/>district / area required]
    X2 -.-> E
    F3 -. invalid input .-> X3[Inline errors<br/>crop · date window · area]
    X3 -.-> F
    E -. use my location denied .-> X4[Message + manual district picker]
    X4 -.-> E
    O -. missing location .-> X5[Add your location card → Profile]
    O -. weather unavailable .-> X6[Error state + Try again]
    X6 -.-> O
    U -. none .-> X7[Empty notifications]
    L -. task completed .-> X8[Struck through · logged in records · Undo by tapping again]
    I -. crop edited .-> X9[Edit crop form → dates/tasks recalculated]
    I -. crop removed .-> X10[Confirm dialog → crop + tasks removed, records kept]
    Q -. Urdu voice missing .-> X11[Notice + falls back to English voice]
    H -. any load error .-> X12[Error state + Try again]
    L1 -. invalid number .-> X13[Inline error]
    L2 -. wrong / expired code .-> X14[Message · resend after 60 s]
    H -. session expired .-> L1
    V -. sign out / delete account .-> L1
```

## Notes

- **Language first:** the language screen comes before onboarding so the onboarding
  text is shown in the farmer's language (matches the reference design).
- **"Use my location"** is simulated in Phase 1 (returns a demo district and says so);
  GPS + permission handling arrive with the backend phase.
- **Ask Fasal** voice input is shown as "coming soon" — questions can be tapped or typed
  and are answered by clearly-labelled sample rules, not live AI.
