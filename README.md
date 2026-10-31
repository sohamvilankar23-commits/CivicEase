# 🏛️ CivicEase - Civic Grievance Redressal & Municipal Management Platform

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com/)
[![Cloudinary](https://img.shields.io/badge/Cloudinary-3448C5?style=for-the-badge&logo=cloudinary&logoColor=white)](https://cloudinary.com/)
[![Google Maps](https://img.shields.io/badge/Google%20Maps-4285F4?style=for-the-badge&logo=google-maps&logoColor=white)](https://developers.google.com/maps)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

**CivicEase** is a modern, cross-platform civic issue reporting and municipal grievance management system built with Flutter and Firebase. It bridges the gap between citizens and municipal authorities, empowering citizens to report local infrastructure issues (water supply failures, electrical hazards, potholes, sanitation lapses) and track their resolution in real time, while providing municipal administrators with an end-to-end dashboard to triage, monitor, and resolve complaints efficiently.

---

## 📌 Table of Contents

- [Key Features](#-key-features)
  - [Citizen Capabilities](#1-citizen-capabilities)
  - [Municipal Authority & Admin Capabilities](#2-municipal-authority--admin-capabilities)
  - [Emergency Response System](#3-emergency-response-system)
- [System Architecture & Technology Stack](#-system-architecture--technology-stack)
- [Project Directory Structure](#-project-directory-structure)
- [Database Schema (Firestore)](#-database-schema-firestore)
- [Cloud Functions & Cloudinary Integration](#-cloud-functions--cloudinary-integration)
- [Getting Started & Installation](#-getting-started--installation)
  - [Prerequisites](#prerequisites)
  - [Cloning and Dependencies](#step-1-clone-and-install-dependencies)
  - [Firebase Configuration](#step-2-firebase-setup)
  - [Cloud Functions Setup](#step-3-cloud-functions-setup)
  - [Running the Application](#step-4-run-the-app)
- [Routes and Navigation Flow](#-routes-and-navigation-flow)
- [UI & Theming System](#-ui--theming-system)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🌟 Key Features

### 1. Citizen Capabilities
* **Flexible Authentication**: Secure registration and sign-in via Email/Password and Google OAuth sign-in (`firebase_auth`, `google_sign_in`), with credential caching via `SharedPreferences`.
* **Grievance Filing**:
  * Category-based submission across major civic sectors: **Water**, **Electrical**, **Roads**, and **Sanitation**.
  * Input fields for complaint title, location address, and detailed description.
  * **Anonymous Reporting**: Option to submit grievances anonymously to protect whistleblower identity while still allowing authorities to take action.
  * Geolocation coordinate tagging using `geolocator` and `google_maps_flutter`.
  * Visual proof attachments via image capture / gallery picker with Cloudinary upload integration.
* **Real-Time Status Tracking**:
  * Track complaint status pipeline: `Pending` ➔ `In Progress` ➔ `Resolved`.
  * View detailed complaint timelines, admin progress notes, and geotagged map view.
* **Categorical Browsing & Filtering**:
  * Live category counts and issue summaries right on the dashboard.
  * Search complaints by keywords and filter by date range, category, or resolution status.
* **Profile & Account Management**:
  * Edit user profiles, contact numbers, and passwords directly inside the app.

### 2. Municipal Authority & Admin Capabilities
* **Role-Based Access Control (RBAC)**: Elevated administrative privileges based on Firestore `users.isAdmin` attribute.
* **Administrative Analytics Dashboard**:
  * High-level statistical summaries: real-time counters for Total, Pending, In Progress, and Resolved grievances.
  * System-wide Admin Announcement / Bulletin board note synchronized in real time (`admin_dashboard/note`).
* **Complaint Triage & Resolution Management**:
  * Fast status toggling between `Pending`, `In Progress`, and `Resolved`.
  * Dedicated note-taking and progress update field per complaint for transparency.
  * Full visibility into complaint coordinates with embedded interactive Google Maps and media proofs.
  * Ability to view reporter identity (with elevated admin access for anonymous reports when necessary).

### 3. Emergency Response System
* **One-Tap Emergency Calling**: Direct phone launcher integration (`url_launcher`) for vital Indian public service and emergency contacts:
  * 🚓 Police (`100`)
  * 🚑 Ambulance (`108`)
  * 🚒 Fire Brigade (`101`)
  * 👩 Women Helpline (`1091`)
  * 🧒 Child Helpline (`1098`)
  * 👴 Senior Citizen Helpline (`14567`)
  * ⚖️ Anti-Corruption Helpline (`1031`)
  * 🚆 Railway Enquiry (`139`)
* **Emergency Safety Tips**: Built-in actionable emergency guidelines and situational response checklist.

---

## 🛠️ System Architecture & Technology Stack

```mermaid

graph TD
    subgraph ClientApp["Client Application - Flutter Multi-Platform Frontend"]
        UI["Material UI & Dark Theme"]
        AuthUI["Auth & Profile Screens"]
        GrievanceUI["Grievance Submission & Tracking"]
        AdminUI["Admin Dashboard & Control Panel"]
        EmergUI["Emergency Dialer Screen"]
        Router["GoRouter Navigation & Guards"]
    end

    subgraph FirebaseCloud["Firebase Cloud - Backend as a Service"]
        FAuth["Firebase Authentication"]
        Firestore[("Cloud Firestore NoSQL")]
        FCF["Firebase Cloud Functions"]
    end

    subgraph ThirdParty["Third-Party Services"]
        Cloudinary["Cloudinary Media Storage"]
        GMaps["Google Maps Platform"]
    end

    ClientApp -->|Authentication| FAuth
    ClientApp -->|Real-time Streams & CRUD| Firestore
    ClientApp -->|Request Upload Signature| FCF
    FCF -->|Signed Token| ClientApp
    ClientApp -->|Direct Signed Upload| Cloudinary
    ClientApp -->|Map Tiles & Geocoding| GMaps
### Core Technologies

| Layer | Technology | Details |
|---|---|---|
| **Frontend Framework** | **Flutter 3.x (Dart 3.x)** | Cross-platform UI toolkit targeting Mobile (Android/iOS) and Web |
| **Routing & Navigation** | **GoRouter (`go_router`)** | Declarative routing with route guards, redirect logic, and web URL strategy |
| **Authentication** | **Firebase Auth & Google Sign-In** | Email/password auth, Google OAuth provider, persistent session state |
| **Database** | **Cloud Firestore** | Real-time NoSQL document database for grievances, user profiles, and notes |
| **Serverless Backend** | **Firebase Cloud Functions (Node.js)** | Secure cryptographic signature generation for Cloudinary uploads |
| **Media Storage** | **Cloudinary API** | Secure cloud image storage with transformations and fast CDN delivery |
| **Mapping & Location** | **Google Maps Flutter, Geolocator** | Location picker, geolocation capture, interactive maps |
| **Styling & Fonts** | **Google Fonts (Poppins)** | Bespoke dark-mode palette with clean municipal design system |

---

## 📁 Project Directory Structure

```text
CivicEase/
├── android/                        # Android native configurations & build files
├── assets/                         # Static assets & graphics
│   ├── app_icon.png                # Application launcher icon
│   └── images/
│       └── logo.png                # CivicEase branding logo
├── functions/                      # Firebase Cloud Functions (Node.js backend)
│   ├── index.js                    # Cloudinary signature generation function
│   ├── package.json                # Cloud functions dependencies
│   └── package-lock.json
├── ios/                            # iOS native configurations
├── lib/                            # Application Dart codebase
│   ├── firebase_options.dart       # Firebase CLI generated platform configuration
│   ├── main.dart                   # Application entry point, GoRouter setup, error screens
│   ├── theme.dart                  # AppTheme, dark palette (Colors, Typography, Themes)
│   ├── web_url_strategy.dart       # Path-based URL strategy for Web
│   ├── web_url_strategy_stub.dart  # Stub for non-web platforms
│   ├── screens/                    # UI Screens
│   │   ├── welcome_screen.dart           # Onboarding splash / landing screen
│   │   ├── login_screen.dart             # Email/Password login with Remember Me
│   │   ├── register_screen.dart          # Registration & Google Sign-In
│   │   ├── home_screen.dart              # User dashboard with status summaries & category cards
│   │   ├── category_screen.dart          # Filtered category view (Water, Roads, etc.)
│   │   ├── complaint_screen.dart         # Grievances list with search and date filters
│   │   ├── complaint_detail_screen.dart  # Full complaint details, Google Map, progress note
│   │   ├── add_complaint_screen.dart     # Grievance submission form (anonymous toggle, photo)
│   │   ├── tracking_screen.dart          # Individual grievance tracker
│   │   ├── emergency_screen.dart         # Emergency hotlines and quick-dial actions
│   │   ├── profile_screen.dart           # User profile info and admin link
│   │   ├── edit_profile_screen.dart      # Edit user profile details
│   │   ├── change_password_screen.dart   # Change password utility
│   │   ├── admin_dashboard_screen.dart   # Admin analytics, stats, and bulletin note
│   │   └── admin_panel_screen.dart       # Admin management, bulk triage, and search
│   └── widgets/                    # Reusable components
│       ├── app_bottom_nav_bar.dart       # Standardized bottom navigation bar
│       ├── custom_text_field.dart        # Reusable themed input fields
│       └── rounded_button.dart           # Themed primary call-to-action buttons
├── firebase.json                   # Firebase configurations (Functions, Flutter targets)
├── pubspec.yaml                    # Flutter dependencies and asset declarations
└── README.md                       # Comprehensive project documentation
```

---

## 🗄️ Database Schema (Firestore)

### 1. `users` Collection
Stores registered user information and administrative privileges.
```json
{
  "uid": "FIREBASE_AUTH_UID",
  "name": "Jane Citizen",
  "email": "jane@example.com",
  "number": "+91 9876543210",
  "isAdmin": false,
  "createdAt": "Timestamp"
}
```

### 2. `grievances` Collection
Stores every civic issue filed through the application.
```json
{
  "title": "Broken Water Pipeline causing leakage",
  "category": "Water",
  "description": "Continuous water outflow near Main Cross Street.",
  "address": "45 Park Avenue, Ward 12",
  "location": "GeoPoint(18.5204, 73.8567)",
  "photoUrl": "https://res.cloudinary.com/civicease1/image/upload/...",
  "userId": "FIREBASE_AUTH_UID",
  "userName": "Jane Citizen",
  "isAnonymous": false,
  "status": "Pending",
  "progressNote": "Municipal crew dispatched for site inspection.",
  "createdAt": "Timestamp"
}
```

### 3. `admin_dashboard` Collection
Houses municipal administrative broadcasts and global notes.
* **Document**: `admin_dashboard/note`
```json
{
  "text": "Monsoon preparedness review scheduled for this Friday across all sectors."
}
```

---

## ☁️ Cloud Functions & Cloudinary Integration

CivicEase uses a serverless approach for media uploads. Rather than exposing Cloudinary API secrets on the mobile client, Firebase Cloud Functions generate a secure HMAC-SHA1 signature:

1. **Client** invokes `getCloudinarySignature` via Firebase Functions SDK.
2. **Function** (`functions/index.js`):
   - Validates user authentication (`context.auth`).
   - Creates a timestamped, user-isolated folder path: `complaint_photos/{userId}`.
   - Computes a SHA-1 HMAC hash using the Cloudinary API secret.
   - Returns signature, timestamp, apiKey, and cloud name to the client.
3. **Client** uploads the image file directly to Cloudinary using the authorized signature.
4. The resulting Cloudinary URL is stored in Firestore with the grievance document.

---

## 🚀 Getting Started & Installation

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`v3.0.0` or higher)
- [Node.js](https://nodejs.org/) (`v18` or `v20`) & npm
- [Firebase CLI](https://firebase.google.com/docs/cli) (`npm install -g firebase-tools`)
- A physical Android/iOS device or emulator, or Chrome for Web testing
- A Google Maps API key (for map views and geocoding)

---

### Step 1: Clone and Install Dependencies

```bash
# Clone the repository
git clone https://github.com/sohamvilankar23-commits/CivicEase.git

# Navigate to project directory
cd CivicEase

# Install Flutter dependencies
flutter pub get
```

---

### Step 2: Firebase Setup

1. Log into your Firebase account:
   ```bash
   firebase login
   ```
2. Configure FlutterFire for your platforms:
   ```bash
   flutterfire configure
   ```
   *Select your Firebase project (e.g. `civicease1`). This regenerates/updates `lib/firebase_options.dart` and `android/app/google-services.json`.*

3. Enable the following Firebase services in the [Firebase Console](https://console.firebase.google.com/):
   - **Authentication**: Enable **Email/Password** and **Google Sign-In**.
   - **Firestore Database**: Create database in production mode.
   - Set up Firestore Security Rules:
     ```javascript
     rules_version = '2';
     service cloud.firestore {
       match /databases/{database}/documents {
         match /users/{userId} {
           allow read, write: if request.auth != null;
         }
         match /grievances/{grievanceId} {
           allow read: if request.auth != null;
           allow create: if request.auth != null;
           allow update, delete: if request.auth != null;
         }
         match /admin_dashboard/{docId} {
           allow read, write: if request.auth != null;
         }
       }
     }
     ```

---

### Step 3: Cloud Functions Setup

1. Navigate to the `functions/` directory:
   ```bash
   cd functions
   npm install
   ```
2. Configure your Cloudinary credentials in `functions/index.js` or via Firebase environment config:
   ```javascript
   const CLOUDINARY_API_KEY = 'YOUR_API_KEY';
   const CLOUDINARY_API_SECRET = 'YOUR_API_SECRET';
   const CLOUDINARY_CLOUD_NAME = 'YOUR_CLOUD_NAME';
   ```
3. Deploy functions to Firebase:
   ```bash
   firebase deploy --only functions
   cd ..
   ```

---

### Step 4: Run the App

#### Android
Ensure Android device or emulator is connected:
```bash
flutter run -d android
```

#### Web
Launch with Chrome:
```bash
flutter run -d chrome
```

#### Windows Desktop
```bash
flutter run -d windows
```

---

## 🧭 Routes and Navigation Flow

CivicEase uses **GoRouter** with route guards that automatically redirect unauthenticated users to `/welcome`:

```text
/welcome              --> Onboarding landing screen
   ├── /login         --> Sign in with Email / Password
   └── /register      --> Create new account or Google Sign-In
/home                 --> Main Citizen Dashboard
   ├── /category/:id  --> Category details (Water, Electrical, Roads, Sanitation)
   ├── /complaint     --> Grievance directory with search & date filters
   ├── /add-complaint --> File a new civic grievance
   ├── /tracking      --> Track status of a specific complaint
   ├── /emergency     --> Emergency helplines & quick dialer
   ├── /profile       --> User account info
   │     ├── /edit-profile
   │     └── /change-password
   ├── /admin-panel   --> Admin complaint triage & filter tool
   └── /admin-dashboard -> Admin statistical metrics & public noticeboard
```

---

## 🎨 UI & Theming System

The app applies an intuitive, modern civic theme customized in [lib/theme.dart](file:///e:/app%20made%20by%20soham/first%20successfully%20made%20app/CivicEase/lib/theme.dart):

* **Primary Color**: `#1E3A8A` (Deep Blue - authoritative and clean)
* **Secondary Color**: `#1F2937` (Dark Slate Gray - sleek dark background)
* **Accent Color**: `#F59E0B` (Vibrant Amber - call-to-actions and pending status)
* **Card Color**: `#374151` / `#2A2A2A` (Elevated card contrast)
* **Typography**: Powered by `GoogleFonts.poppins` for readability and modern polish

---

## 🤝 Contributing

Contributions to CivicEase are welcome! To contribute:

1. **Fork the Repository**
2. **Create a Feature Branch**:
   ```bash
   git checkout -b feature/NewCivicFeature
   ```
3. **Commit your changes**:
   ```bash
   git commit -m "feat: Add new municipal feature"
   ```
4. **Push to branch**:
   ```bash
   git push origin feature/NewCivicFeature
   ```
5. **Open a Pull Request**

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
