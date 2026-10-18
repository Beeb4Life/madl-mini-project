# madl_project
mad lab mini project

petsync - made by pratiksha and aiden

---

## PetSync — Offline-First Pet-Care Management Application

PetSync is a local-first Android and desktop pet management application inspired by Nothing OS typography and monochrome aesthetics (black, white, and subtle red accents). It operates 100% offline using a local SQLite database with cascade integrity.

### Features
1. **Pet Profiles**: Register, edit, view, and safely delete pets with species, breed, date of birth / age calculations, weight tracking, and special dietary/care notes.
2. **Daily Care Routines**: Organize routine care tasks (Feeding, Walking, Grooming, Other), time scheduling, pending vs completed separation, and one-tap completion checkboxes.
3. **Health Journal**: Chronological log of vaccinations, veterinary appointments, clinical observations, and weight milestones with veterinary disclaimers.
4. **Overview & Analytics**: Live home dashboard showing pet count, today's completion percentage, progress bar, and quick actions.

### Architecture
- **Offline Storage**: SQLite via `sqflite` (with `sqflite_common_ffi` cross-platform support).
- **Design Language**: Nothing OS inspired monochrome palette (`#000000`, `#101010`, `#262626`, `#FFFFFF`, accent red dot).
- **State & UI**: Flutter SDK reactive architecture with clean models, services, and zero heavyweight third-party framework dependencies.

### Build & Run Commands
- **Run on Linux Desktop**:
  ```bash
  flutter run -d linux
  ```
- **Build Release APK**:
  ```bash
  flutter build apk --release
  ```
- **Install on Android Phone via ADB**:
  ```bash
  adb install -r build/app/outputs/flutter-apk/app-release.apk
  ```
- **Launch via ADB**:
  ```bash
  adb shell monkey -p com.example.petsync -c android.intent.category.LAUNCHER 1
  ```