# madl_project
mad lab mini project

petsync - made by pratiksha and aiden

---

## PetSync — Offline-First Pet-Care & Veterinary Intelligence Platform

PetSync is an offline-first Android and desktop pet management application with Nothing OS typography, monochrome aesthetics (deep dark canvas, graphite cards, and signature red accents), and local veterinary intelligence. It operates 100% offline using an embedded SQLite database with relational cascade integrity.

---

### Core Modules & Features

1. **Pet Profiles**:
   - Register, view, edit, and delete pet profiles (Name, Species, Breed, Date of Birth, Weight, Dietary/Care Notes).
   - High-contrast custom photo support and 8 stylized minimalist avatars.
   - Smart age and life-stage calculations.

2. **Daily Care Routines**:
   - Schedule daily routines (Feeding, Walking, Grooming, Medication).
   - One-tap completion checkboxes, real-time daily routine progress bar, and category filtering.

3. **Health Journal & Clinical Records**:
   - Chronological logging of vaccinations, vet visits, clinical observations, and weight milestones.
   - Embedded image attachment support for physical vet prescription receipts and vaccine cards.

4. **Vets Near Me (Local & 24/7 Emergency Directory)**:
   - Curated directory of veterinary clinics and 24-hour animal trauma emergency hospitals.
   - Search by clinic name, doctor, and specialty filter chips (24/7 Emergency, Dental, Surgery, Exotic & Avian).
   - Tap-to-call phone dialer intent and Google Maps navigation integration.
   - Ability to add custom local veterinary clinics with persistent SQLite storage and designate "Primary Vet".

5. **PetSync PRO & SaaS Business Model Canvas**:
   - Comprehensive monetization framework designed for presentation and academic evaluation.
   - Tiered pricing plans: Free Starter (up to 2 pets), Pro Monthly (₹199 / $2.99), Pro Annual (₹1,499 / $19.99, Save 40%), and Lifetime (₹2,999 / $39.99).
   - Interactive live simulation button to toggle between Free and Pro active memberships.
   - Built-in Business Model Canvas breakdown detailing Customer Acquisition Cost (CAC), Lifetime Value (LTV:CAC 8.0x), and revenue streams.

6. **Pet Understanding Quiz & Daily Needs Calculator**:
   - Interactive 8-question veterinary science trivia assessing nutrition, theobromine/allium food toxicities, body language myths, vital sign norms, and heatstroke first aid.
   - Immediate answer feedback with scientific explanations and high-score persistence.
   - Algorithmic daily needs calculator: computes daily water requirements (ml), resting energy requirements (kcal/day), exercise duration, and rest hours by pet weight and life stage.

7. **SyncAI — Offline Clinical Triage Assistant**:
   - Conversational AI triage engine operating 100% locally on device without external API tokens or internet dependencies.
   - Comprehensive symptom analyzer matching 25+ critical scenarios (toxic foods, gastric bloat/GDV, respiratory distress, dehydration, ticks/fleas, vaccination timelines).
   - Triage severity tagging (Urgent Emergency, Moderate Risk, Mild Home Care) and direct emergency vet hospital escalation shortcuts.

8. **Custom Minimalist Nothing OS App Logo & Iconography**:
   - Custom-engineered geometric app logo combining pet paw geometry, sync orbital track, and signature red dot.
   - Full Android launcher icon asset suite (`mipmap-mdpi` through `mipmap-xxxhdpi`, including round icons).
   - Dedicated vector `PetSyncLogo` widget rendered with `CustomPainter`.

9. **Unified Signature Dark Theme**:
   - Standardized Nothing OS dark monochrome palette (`#0C0C0E` background, `#1E1E24` graphite cards, `#282830` elevated elements, `#FFFFFF` high-contrast typography, and `#E50914` red accents).

---

### Technical Architecture
- **Framework**: Flutter SDK (Material 3 with custom Nothing OS design system).
- **Offline Database**: SQLite via `sqflite` (Android) and `sqflite_common_ffi` (Linux/Desktop).
- **Device Integrations**: `url_launcher` (direct phone dialer & maps navigation), `image_picker` (camera/gallery photos), `path_provider`.
- **Zero Cloud Overhead**: Operates entirely offline without Firebase, sign-in gates, or external paid APIs.

---

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
