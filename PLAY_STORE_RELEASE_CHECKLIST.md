# QuizForge AI LMS — Google Play Store Release Pre-Flight Checklist

This checklist tracks production deployment readiness for the Google Play Console release of **QuizForge AI LMS** (Package: `com.sachinkumar.quizforge.quizforge_upsc`).

---

## Pre-Flight Status Overview

| Item | Category | Status | Technical Verification & Requirements |
|:---|:---|:---:|:---|
| **AAB** | Build Artifact | **ACTION REQUIRED** | Source and build configuration hardened (`targetSdk = 36`, `versionCode = 100`, `versionName = 2.0.0`). AAB generation executes in GitHub Actions CI/DevOps pipeline (`.github/workflows/ci_pipeline.yml`) where Android SDK & signing secrets reside. |
| **Backend** | Cloud Services | **READY** | Production FastAPI backend routes verified for all 11 LMS domains under `/api/v1/lms`, `/api/v1/auth`, `/api/v1/sync`, `/api/v1/quiz` with full audit trails. |
| **HTTPS** | Network Security | **READY** | Enforced via `https://api.quizforge.ai` default baseUrl, `android:networkSecurityConfig="@xml/network_security_config"` disallowing all cleartext HTTP traffic. |
| **Authentication** | Security / Identity | **READY** | JWT Bearer token authentication flow with bcrypt password hashing, dynamic header injection, and token refresh support. |
| **Database** | Persistence | **READY** | Complete PostgreSQL schema defined in `app/db/schema.sql` (courses, enrollments, assessments, attempts, results, gradebook, attendance, credentials, notifications, audit logs). |
| **AI** | Intelligent Services | **READY** | Google Gemini 2.5 Flash integrated server-side with `GEMINI_API_KEY` stored exclusively in server environment variables. Zero AI keys embedded in client code or Git. |
| **Privacy / Data Safety** | Compliance | **READY** | Technical audit completed: No third-party data tracking, user-controlled local offline storage, secure AI proxy payload validation. |
| **App Access** | Reviewer Verification | **READY** | App boots directly to dashboard with 100% offline-first fallback. Reviewer access instructions documented in Play Store Listing Draft. |
| **Store Listing** | Metadata | **READY** | Title, 80-character short description, and 4000-character full description finalized in `PLAY_STORE_LISTING_DRAFT.md`. |
| **Screenshots** | Visual Assets | **ACTION REQUIRED** | Capture at least 4 phone screenshots (minimum 1080x1920) + 7-inch/10-inch tablet screenshots from real device or emulator. |
| **Icon** | Visual Assets | **ACTION REQUIRED** | Prepare 512x512 PNG (32-bit color, no transparency, max 1MB) matching brand assets for Google Play icon slot. |
| **Feature Graphic** | Visual Assets | **ACTION REQUIRED** | Prepare 1024x500 PNG/JPEG (no transparency, max 15MB) for Play Store carousel promotion banner. |
| **Testing** | Quality Assurance | **READY** | 2,364 Garuda learning engine tests, 386 Flutter root tests, 9 HTTP repository integration tests, and 12 FastAPI backend tests passing (0 failures). |
| **Production Rollout** | Release Governance | **BLOCKED (TIME)** | For personal developer accounts created after Nov 13, 2023: 14 days of closed testing with 12+ opt-in testers required before production track rollout. |

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
