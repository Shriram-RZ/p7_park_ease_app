# ParkFlow — Real‑Time Smart Parking (Offline‑First Flutter App)

ParkFlow is a futuristic, offline‑first smart parking ecosystem built in
Flutter. It pairs an animated parking visualization engine with reservation
flow, QR ticketing, indoor navigation, vehicle management, parking history,
analytics and a local notification surface — all without any cloud service.

Inspired by Tesla, Apple Maps, Linear and Arc Browser, the UI leans into
glassmorphism, glowing gradients, animated radar pulses and floating cards
to deliver a premium feel on Android phones, tablets and foldables.

## Highlights

- 🅿️ Real‑time parking layout with `CustomPainter`, pan & zoom, moving
  vehicles, animated occupancy and dashed route lines.
- 🎟 QR tickets with a wallet‑style pass UI (powered by `qr_flutter`) and a
  simulated offline scanner with animated frame, beam and success ring.
- 🚗 Garage with multiple vehicles, paint color picker and live preview card.
- 🗺 Offline indoor navigation with neon path drawing and an animated beacon.
- 📊 Insights dashboard: occupancy donut, animated bar/line charts.
- 🔔 Notification center with swipe‑to‑read, priority indicators and badges.
- 🌗 Dark and light themes, reduce‑motion accessibility toggle, PIN +
  biometric demo and offline simulation engine.
- 🧱 Clean feature‑first architecture with repositories, services and a
  single `ChangeNotifier`‑powered `AppState` exposed via `InheritedNotifier`.

## Folder structure

```
lib/
├─ app/                  # Bootstrapping, routing, dependency injection
├─ core/                 # Theme, constants, storage, extensions
├─ data/
│  ├─ models/            # User, Vehicle, Slot, Booking, Ticket, Notification
│  ├─ repositories/      # Auth, Vehicles, Parking, Bookings, Tickets, Notif
│  └─ services/          # Real‑time simulation engine
├─ features/
│  ├─ splash/
│  ├─ onboarding/
│  ├─ auth/              # Login, Signup, PIN setup
│  ├─ dashboard/
│  ├─ main_shell/        # Floating animated bottom navigation
│  ├─ parking_map/       # Painter + screen with InteractiveViewer
│  ├─ booking/           # Multi‑step reservation + success screen
│  ├─ navigation/        # Glowing route painter
│  ├─ tickets/           # Wallet pass + QR scanner
│  ├─ vehicles/          # Garage + add vehicle
│  ├─ history/
│  ├─ analytics/
│  ├─ notifications/
│  ├─ settings/
│  └─ profile/
└─ widgets/              # GlassCard, GradientButton, RadarPulse, charts…
```

## Architecture

ParkFlow follows a **feature‑first clean architecture**:

| Layer            | Responsibility                                                |
| ---------------- | ------------------------------------------------------------- |
| Models           | Pure Dart classes with `fromJson`/`toJson` for persistence.   |
| Repositories     | Read/write models through a `LocalStorage` wrapper.           |
| Services         | Cross‑cutting offline logic — e.g. the simulation engine.     |
| AppState         | `ChangeNotifier` aggregating repositories + UI state.         |
| Features         | Screens, painters, and feature‑local widgets.                 |
| Shared widgets   | Reusable building blocks: glass cards, charts, radar, etc.    |

`AppScope` is an `InheritedNotifier<AppState>` so any descendant can grab
state and rebuild on changes without an external state management package.

### Offline persistence

All data is stored through `SharedPreferences`, JSON‑encoded for collections
(`vehicles`, `bookings`, `tickets`, `parkingLayout`, `notifications`). The
parking layout is generated once from a seeded `Random` for stable IDs and
positions across cold starts.

### Real‑time simulation

`SimulationService` runs a `Timer.periodic` (3s default) that randomly
mutates a handful of slot statuses based on a synthetic "pressure" curve
(peak hour windows + a toggleable peak mode). All listeners — including
`AppState` itself — receive a notification, which propagates through the
inherited notifier and triggers the painters to repaint.

## Running

This project targets the latest stable Flutter (Dart SDK `>=3.11`).

```bash
# Install dependencies
flutter pub get

# Run on a connected Android device or emulator
flutter run

# Run tests
flutter test
```

### Building a release APK

```bash
flutter build apk --release
```

The signed APK lands in `build/app/outputs/flutter-apk/app-release.apk`.

If you want a Play‑ready bundle:

```bash
flutter build appbundle --release
```

### Useful flags

- `--release` — full optimisations + tree‑shaking.
- `--split-per-abi` — generates per‑ABI APKs (smaller downloads).
- `--no-tree-shake-icons` — only needed if you use dynamic icon glyphs.

## Permissions

ParkFlow is fully offline by design. The app **does not request internet,
location, camera, or any other runtime permission**. The "QR scanner" is a
visual simulation that validates against the local ticket database.

## Customising

| What                | Where                                       |
| ------------------- | ------------------------------------------- |
| Colors / typography | `lib/core/theme.dart`                       |
| Floors / slots / fee| `lib/core/constants.dart`                   |
| Simulation tempo    | `PFConstants.simulationTick`                |
| Floor plan layout   | `ParkingRepository._generate()`             |
| Onboarding copy     | `OnboardingScreen._pages`                   |

## Roadmap

- Hive/Isar backed persistence for larger histories.
- Real `mobile_scanner` integration behind a feature flag.
- PDF export of parking history via `pdf` + `printing`.
- Foldable + tablet two‑pane layouts on the parking map.

---

Built with 💚 and `flutter`.
