<div align="center">

<img src="https://img.shields.io/badge/Platform-Android-3DDC84?style=for-the-badge&logo=android&logoColor=white"/>
<img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white"/>
<img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white"/>
<img src="https://img.shields.io/badge/Offline--First-✓-00FF7F?style=for-the-badge"/>

# ⛰️ TrailMate

**An offline-first mobile hiking companion for Sri Lanka's wilderness.**

*PUSL3190 Computing Project · BSc (Hons) Software Engineering · University of Plymouth*

</div>

---

## 📖 Overview

TrailMate is an autonomous, edge-computing mobile navigation application designed specifically for hikers exploring Sri Lanka's remote highland regions — where mobile data is unreliable or completely absent.

Standard navigation apps like Google Maps and AllTrails fail without internet. TrailMate shifts all computation to the device, providing continuous GPS tracking, offline maps, real-time deviation alerts, and a visual wayfinding system — all without a single bar of signal.

---

## ✨ Features

| Feature | Description |
|---|---|
| 🗺️ **Offline Map Engine** | Renders OpenStreetMap tiles cached locally on the device — no internet needed |
| 📍 **GPS Breadcrumb Tracking** | Records your path to a local SQLite database with a 3-metre hardware distance filter to suppress GPS jitter |
| ⚠️ **Off-Route Safety Alerts** | Uses the Haversine formula to calculate real-time deviation; triggers a high-contrast red warning if you stray >25 m from your path |
| 📸 **Visual Wayfinding** | Automatically prompts you to capture geotagged landmark photos every 200 m, creating a visual timeline for the return journey |
| ☁️ **Hybrid Cloud Sync** | Silently backs up hike data to Firebase Firestore and photos to Cloudinary once Wi-Fi/cellular is restored |
| 🔋 **Battery Conservation** | High-contrast dark mode UI + hardware-level GPS filtering drastically reduces battery drain |
| ⚙️ **Settings Dashboard** | Toggle GPS accuracy, off-route vibrations, and Wi-Fi-only sync via SharedPreferences |

---

## 🏗️ Architecture

TrailMate follows a **three-tier edge-computing architecture** — all core logic runs on-device with no cloud dependency during a hike.

```
┌─────────────────────────────────────────────┐
│            Presentation Layer (UI)           │
│  Map View · Dashboard Stats · Albums · Auth  │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│         Application Logic Layer             │
│  LocationController · DatabaseHelper        │
│  SyncService · Map Rendering Engine         │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│           Data Layer (Local Storage)        │
│  SQLite Database · OSM Tile Cache           │
│  Local File System (Visual Anchors)         │
└─────────────────────────────────────────────┘
         ↕ (on network restore only)
┌─────────────────────────────────────────────┐
│              Cloud (Optional)               │
│     Firebase Firestore · Cloudinary API     │
└─────────────────────────────────────────────┘
```

### Core Components

- **`LocationController`** — Streams GPS coordinates, applies the 3-metre distance filter, runs the Haversine deviation check, and triggers Visual Wayfinding prompts every 200 m.
- **`DatabaseHelper`** — Manages the local SQLite database (`trailmate.db`), persisting breadcrumbs, hike metadata, and image file paths.
- **`SyncService`** — Monitors network state; on reconnection, uploads photos to Cloudinary (unsigned REST), retrieves secure URLs, and writes the complete hike package to Firestore.

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| Local Database | SQLite via `sqflite` |
| Maps | OpenStreetMap via `flutter_map` |
| GPS | `geolocator` (hardware-level distance filter) |
| Spatial Maths | `latlong2` (Haversine formula) |
| Camera | `image_picker` |
| Cloud DB | Firebase Firestore |
| Media Storage | Cloudinary REST API (unsigned upload) |
| Network Detection | `connectivity_plus` |
| User Preferences | `shared_preferences` |

---

## 📋 Requirements

### Software
- Flutter SDK `>=3.0.0`
- Dart SDK `>=3.0.0 <4.0.0`
- Android SDK (API level 26 / Android 8.0 Oreo or higher)
- VS Code with Flutter & Dart extensions, **or** Android Studio

### Hardware (target device)
- Android smartphone running **Android 8.0+**
- Functional internal GPS receiver
- Camera module
- Minimum **3 GB RAM** recommended
- Adequate storage for offline map tiles and photos

---

## 🚀 Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/YOUR_USERNAME/trailmate.git
cd trailmate
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure Firebase

- Place your `google-services.json` inside `android/app/`.
- This file is obtained from your Firebase project console (Project Settings → Android app).

> ⚠️ **Never commit `google-services.json` to a public repository.** It is already listed in `.gitignore`.

### 4. Configure Cloudinary

Add your Cloudinary credentials to `lib/config/api_keys.dart` (or your `.env` file):

```dart
const String cloudinaryUploadPreset = 'YOUR_UPLOAD_PRESET';
const String cloudinaryCloudName   = 'YOUR_CLOUD_NAME';
```

> ⚠️ **Never commit API keys to a public repository.**

### 5. Run the app

Connect a physical Android device or launch an emulator, then:

```bash
flutter run
```

### 6. Simulate GPS (Emulator only)

Since emulators have no physical movement, use the **Extended Controls → Location** panel in Android Studio / the emulator window to manually set coordinates or import a `.gpx` / `.kml` route file to simulate a hike and trigger the 25 m deviation alerts.

---

## 📁 Project Structure

```
lib/
├── controllers/
│   ├── dashboard_controller.dart   # Dashboard state logic
│   └── location_controller.dart    # GPS stream, Haversine, wayfinding
├── database/
│   └── database_helper.dart        # SQLite CRUD operations
├── models/
│   ├── app_colors.dart             # Design system colours
│   └── hike_model.dart             # HikeSession data model
├── services/
│   └── sync_service.dart           # Cloud sync (Cloudinary + Firestore)
├── views/
│   ├── album_detail_screen.dart
│   ├── albums_screen.dart
│   ├── auth_screen.dart
│   ├── home_screen.dart
│   ├── main_navigation.dart
│   ├── map_screen.dart             # Core map HUD + tracking controls
│   ├── settings_screen.dart
│   ├── splash_screen.dart
│   └── widgets/
│       └── trailmate_logo.dart
├── firebase_options.dart           # Auto-generated Firebase config
└── main.dart
```

---

## 🧪 Key Algorithms

### Haversine Off-Route Detection

During the return journey, every new GPS coordinate is compared against the full array of ascent breadcrumbs stored in SQLite. If the minimum spherical distance to any breadcrumb exceeds **25 metres**, an off-route alert fires immediately.

```dart
// Pseudocode
for (LatLng breadcrumb in ascentPath) {
  double dist = Distance().as(LengthUnit.Meter, currentPos, breadcrumb);
  if (dist < minDistance) minDistance = dist;
}
if (minDistance > 25) triggerOffRouteAlert();
```

### 3-Metre Hardware Distance Filter

Configured at the `geolocator` stream level — the OS discards any coordinate update where the device has not physically moved at least 3 metres, eliminating GPS jitter and redundant database writes.

```dart
const LocationSettings locationSettings = LocationSettings(
  accuracy: LocationAccuracy.high,
  distanceFilter: 3, // metres
);
```

---

## 🔒 Security Notes

The following files contain sensitive credentials and are **excluded from version control** via `.gitignore`:

- `android/app/google-services.json` — Firebase configuration
- `lib/config/api_keys.dart` — Cloudinary upload preset & cloud name
- `.env` — Environment variables (if used)

---

## ⚠️ Known Limitations

- **GPS hardware dependency** — Accuracy is bound by the physical quality of the host device's GPS receiver. Budget devices under dense canopy may occasionally produce tracking anomalies despite the software filter.
- **Flat map tiles** — Current OSM tiles provide 2D spatial awareness only; topographical contour lines and elevation profiles are not yet rendered.
- **Android-only** — Background location tracking uses Android-specific protocols; iOS support requires additional engineering for Apple's strict background-location permissions.
- **Aggressive battery savers** — Certain Android OEM skins (MIUI, EMUI) may terminate background services unless TrailMate is whitelisted in battery settings.

---

## 🔮 Future Work

- Integrate **digital elevation models (DEM)** for topographical contour rendering
- **iOS support** — Navigate Apple's background-location permission model
- **On-device ML** — Predict estimated time of arrival based on elevation gain and historical pacing
- Expand **offline trail data** coverage for rural Sri Lankan footpaths

---

## 📚 References

- Sinnott, R.W. (1984) 'Virtues of the Haversine', *Sky and Telescope*, 68(2), p. 159.
- OpenStreetMap Contributors (2026) *Planet dump*. Available at: https://planet.osm.org
- Google (2026) *Flutter Architectural Overview*. Available at: https://docs.flutter.dev/resources/architectural-overview
- Cloudinary (2026) *Unsigned Upload Integration Guide*. Available at: https://cloudinary.com/documentation/upload_images

---

## 📄 Licence

This project is developed as an academic prototype for PUSL3190 Computing Project at the University of Plymouth / NSBM Green University. All rights reserved by the author.

---

<div align="center">
  <sub>Built with ❤️ for the Sri Lankan hiking community · Supervisor: Mr. Diluka Wijesinghe</sub>
</div>
