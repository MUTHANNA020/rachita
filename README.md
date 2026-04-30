# Smart Medical Clinic System (Lite Version)

A high-performance, **strictly offline-first** medical prescription management system built with Flutter. Designed for clinics needing speed, privacy, and reliability without cloud dependence.

## 🚀 Key Features (Lite Version)
- **Offline-First Excellence**: All data resides locally using SQLite. No internet connection required.
- **Rapid Prescriptions**: Streamlined workflow with **Prescription Templates** and **FTS (Full-Text Search)** for 50+ built-in medicines.
- **Clinic Branding**: Customizable doctor profiles with support for **Clinic Logo** and **Signature** images.
- **Professional PDF Generation**: RTL-supported prescriptions with QR codes for RX-ID verification.
- **Security**: PIN-based login and **Biometric Authentication** (Fingerprint/Face Unlock).
- **Auto-Save**: Background saving for prescriptions to prevent data loss.
- **Local History**: `sync_log` tracks all local changes for future audit or optional export.

## 🏗 Architecture
Strict adherence to **Clean Architecture**:
- `core/`: Shared infrastructure (Database, Security, Utils).
- `features/`: Module-based features (Doctor, Patient, Prescription, Medicine).
  - Each feature contains `domain`, `data`, and `presentation` layers.

## 🛠 Tech Stack
- **Framework**: Flutter (Pin `fl_chart: ^0.68.0` for stability).
- **State Management**: Riverpod (`flutter_riverpod: ^2.5.1`).
- **Database**: `sqflite` (Core SQLite).
- **PDF**: `pdf`, `printing`.
- **Auth**: `local_auth` (Biometrics).

## 📦 Setup & Installation
1.  **Environment**: Flutter SDK (Stable).
2.  **Dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Android Configuration**:
    - Ensure your device supports biometrics.
    - Uses `FlutterFragmentActivity` for local_auth compatibility.
4.  **Run**:
    ```bash
    flutter run
    ```

## 📝 Customization
- **Logo/Signature**: Upload via **Settings (Doctor Profile)**. Images are stored locally on the device.
- **Templates**: Can be expanded in `assets/data/prescription_templates.json`.
- **Medicines**: Seeded from `assets/data/medicines_seed.json`.

## 🔒 Privacy & Security
- **Screenshot Proof**: Screens are protected from capture (Android).
- **Auto-Lock**: App locks automatically on pause to protect patient data.

---
*Built for doctors, by developers who value speed and privacy.*
