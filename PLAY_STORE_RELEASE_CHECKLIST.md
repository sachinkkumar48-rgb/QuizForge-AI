# QuizForge AI LMS — Google Play Store Release Pre-Flight Checklist

This checklist tracks production deployment readiness for the Google Play Console release of **QuizForge AI LMS** (Package: `com.sachinkumar.quizforge.quizforge_upsc`).

---

## Pre-Flight Status Overview

| Section | Item | Status | Notes / Requirements |
|:---|:---|:---:|:---|
| **A** | **Developer Account** | **ACTION REQUIRED** | Ensure Google Play Console developer account registration and identity verification is completed. |
| **B** | **App Registration** | **ACTION REQUIRED** | Create new app entry: "QuizForge AI", Default Language: English (United States), Type: App, Free. |
| **C** | **Application ID** | **READY** | Confirmed: `com.sachinkumar.quizforge.quizforge_upsc` declared across Android namespace and Gradle. |
| **D** | **Store Listing** | **READY** | Copy, metadata, and category finalized in `PLAY_STORE_LISTING_DRAFT.md`. |
| **E** | **App Icon** | **ACTION REQUIRED** | Prepare 512x512 PNG (32-bit color, no transparency, max 1MB) matching brand assets. |
| **F** | **Feature Graphic** | **ACTION REQUIRED** | Prepare 1024x500 PNG/JPEG (no transparency, max 15MB) for Play Store carousel. |
| **G** | **Screenshots** | **ACTION REQUIRED** | Capture at least 4 phone screenshots (minimum 1080x1920) + 7-inch/10-inch tablet screenshots. |
| **H** | **App Description** | **READY** | Short description (80 chars) and full description (4000 chars) prepared in draft document. |
| **I** | **Privacy Policy URL** | **ACTION REQUIRED** | Host privacy statement on public HTTPS URL and link in Play Console App Content. |
| **J** | **Data Safety** | **READY** | Technical audit completed: No third-party data sharing, user-controlled local storage, optional encrypted AI proxy. |
| **K** | **Content Rating** | **READY** | Questionnaire answers: Educational reference tool, PEGI 3 / Everyone, no profanity or violence. |
| **L** | **Target Audience** | **READY** | Primary target: Adults and students aged 18+ (UPSC and civil service aspirants). Declare 18+ to avoid Families policy overhead. |
| **M** | **Ads Declaration** | **READY** | App does NOT contain ads (`No, my app does not contain ads`). |
| **N** | **App Access / Demo Credentials** | **READY** | App boots directly to dashboard with offline support; reviewer access instructions documented. |
| **O** | **Countries / Regions** | **READY** | Initial target: India (primary UPSC market) + worldwide availability for global civil service aspirants. |
| **P** | **Pricing** | **READY** | Free application. In-app purchases: None currently configured. |
| **Q** | **Closed Testing** | **ACTION REQUIRED** | Fast-track track: Release AAB to Closed Track and recruit 12+ verified testers. |
| **R** | **Production Access (14-Day Rule)** | **BLOCKED (TIME)** | For personal developer accounts created after Nov 13, 2023: 14 days of closed testing required before production access. |
| **S** | **Production Release** | **ACTION REQUIRED** | Promote tested AAB from closed testing to Production track once 14-day threshold is met. |

---

## Technical Baseline Details

- **Target SDK**: Android 16 / API 36 (`targetSdk = 36`, `compileSdk = 36`)
- **Min SDK**: API 24 (Android 7.0+)
- **Version Name**: `2.0.0`
- **Version Code**: `100`
- **Permissions**: `android.permission.INTERNET` (strictly required for AI tutor & cloud sync)
- **NDK Version**: `28.2.13676358`
- **Java / JVM Compatibility**: Java 17 (`JavaVersion.VERSION_17`, `JvmTarget.JVM_17`)

---

## Release Signing Instructions

1. **Generate Upload Keystore (One-Time Developer Action)**:
   ```bash
   keytool -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias quizforge-upload-key
   ```
2. **Create `android/key.properties` (Excluded by `.gitignore`)**:
   ```properties
   storePassword=YourKeystorePassword
   keyPassword=YourKeyPassword
   keyAlias=quizforge-upload-key
   storeFile=../upload-keystore.jks
   ```
3. **Google Play App Signing**:
   Enroll in Google Play App Signing upon first AAB upload. Google manages the master app signing key while the upload key authenticates developer uploads.
