# QuizForge AI LMS — Google Play Store Release Pre-Flight Checklist

This checklist tracks production deployment readiness for the Google Play Console release of **QuizForge AI LMS** (Package: `com.sachinkumar.quizforge.quizforge_upsc`).

---

## Pre-Flight Status Overview

| Item | Category | Status | Technical Verification & Requirements |
|:---|:---|:---:|:---|
| **AAB** | Build Artifact | **ACTION REQUIRED** | Automated in `.github/workflows/ci_pipeline.yml` (Java 17, Flutter 3.x, upload-artifact). AAB generated upon commit push to CI. Local machine lacks Android SDK. |
| **Backend** | Cloud Services | **VERIFIED** | Production FastAPI backend routes verified for all 11 LMS domains under `/api/v1/lms`, `/api/v1/auth`, `/api/v1/sync`, `/api/v1/quiz` with full audit trails. |
| **HTTPS** | Network Security | **VERIFIED** | Enforced via `https://api.quizforgeupsc.in` default baseUrl, `android:networkSecurityConfig="@xml/network_security_config"` disallowing all cleartext HTTP traffic. |
| **Authentication** | Security / Identity | **VERIFIED** | JWT Bearer token authentication flow with bcrypt password hashing, dynamic header injection, and token refresh support. |
| **Database** | Persistence | **VERIFIED** | Complete PostgreSQL schema defined in `app/db/schema.sql` (courses, enrollments, assessments, attempts, results, gradebook, attendance, credentials, notifications, audit logs). |
| **AI** | Intelligent Services | **VERIFIED** | Google Gemini 2.5 Flash integrated server-side with `GEMINI_API_KEY` stored exclusively in server environment variables. Zero AI keys embedded in client code or Git. |
| **Privacy / Data Safety** | Compliance | **VERIFIED** | `docs/PRIVACY_POLICY.md` established. Zero third-party tracking SDKs; user-controlled local offline storage; secure AI proxy payload validation. |
| **App Access** | Reviewer Verification | **VERIFIED** | App boots directly to dashboard with 100% offline-first fallback. Reviewer access instructions documented in Play Store Listing Draft. |
| **Store Listing** | Metadata | **VERIFIED** | Title, 80-character short description, and 4000-character full description finalized in `PLAY_STORE_LISTING_DRAFT.md`. |
| **Screenshots** | Visual Assets | **ACTION REQUIRED** | Follow `assets/play_store/screenshots/SCREENSHOT_SPECIFICATION.md` to capture live in-app screens (min 4 phone + 7"/10" tablet). |
| **Icon** | Visual Assets | **VERIFIED** | Verified at `assets/play_store/icon_512x512.png` (512x512 px, 32-bit PNG, 328 KB, no transparency). |
| **Feature Graphic** | Visual Assets | **VERIFIED** | Verified at `assets/play_store/feature_graphic_1024x500.png` (1024x500 px, PNG, 704 KB). |
| **Testing** | Quality Assurance | **VERIFIED** | 2,364 Garuda learning engine tests, 386 Flutter root tests, 9 HTTP repository integration tests, and 12 FastAPI backend tests passing (0 failures). |
| **Production Rollout** | Release Governance | **BLOCKED (TIME)** | For personal developer accounts created after Nov 13, 2023: 14 days of closed testing with 12+ opt-in testers required before production track rollout. |

---

## Technical Baseline Details

- **Application ID / Namespace**: `com.sachinkumar.quizforge.quizforge_upsc`
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
2. **Configure CI Secrets (GitHub Actions)**:
   Encode `upload-keystore.jks` in base64 and configure the following repository secrets:
   - `UPLOAD_KEYSTORE_BASE64`: Output of `base64 -w 0 android/upload-keystore.jks` (or `[Convert]::ToBase64String([IO.File]::ReadAllBytes('android/upload-keystore.jks'))` in PowerShell)
   - `KEYSTORE_PASSWORD`: Keystore password chosen during keytool generation
   - `KEY_PASSWORD`: Key password chosen during keytool generation
   - `KEY_ALIAS`: `quizforge-upload-key`
3. **Local Developer Alternative (Optional — Excluded by `.gitignore`)**:
   Create `android/key.properties`:
   ```properties
   storePassword=YourKeystorePassword
   keyPassword=YourKeyPassword
   keyAlias=quizforge-upload-key
   storeFile=../upload-keystore.jks
   ```
4. **Google Play App Signing**:
   Enroll in Google Play App Signing upon first AAB upload. Google manages the master app signing key while the upload key authenticates developer uploads.

---

## P63 Release Hardening & Closed Testing Verification

- **Release Signing Status**: **ACTION REQUIRED**. Release signing configuration is codified in `android/app/build.gradle.kts` and `.github/workflows/ci_pipeline.yml`. Keystore generation command specified; secrets must be populated in CI repository secrets.
- **AAB Build Status**: **ACTION REQUIRED**. Local development machine lacks Android SDK. AAB automated build step with artifact upload (`actions/upload-artifact@v4`) and post-build security cleanup is integrated into `.github/workflows/ci_pipeline.yml`.
- **AAB Verification Status**: Build configuration verified (`applicationId = com.sachinkumar.quizforge.quizforge_upsc`, `versionCode = 100`, `versionName = 2.0.0`, `targetSdk = 36`, `cleartextTrafficPermitted = false`, `API_BASE_URL = https://api.quizforgeupsc.in`).
- **Store Asset Status**:
  - App Name & Descriptions: **VERIFIED** (`PLAY_STORE_LISTING_DRAFT.md`)
  - Privacy Policy: **VERIFIED** (`docs/PRIVACY_POLICY.md`)
  - Data Safety Declaration: **VERIFIED** (`PLAY_STORE_LISTING_DRAFT.md`)
  - Reviewer Access: **VERIFIED** (Direct guest / offline access)
  - 512x512 Icon: **VERIFIED** (`assets/play_store/icon_512x512.png`)
  - 1024x500 Feature Graphic: **VERIFIED** (`assets/play_store/feature_graphic_1024x500.png`)
  - Phone & Tablet Screenshots: **ACTION REQUIRED** (`assets/play_store/screenshots/SCREENSHOT_SPECIFICATION.md`)
- **Closed Testing Status**: **ACTION REQUIRED**. Ready to deploy AAB to Google Play Console Closed Testing track once developer account is active and CI produces signed AAB artifact.
- **Remaining Blockers**:
  - Mandatory 14-day closed testing period with 12+ active testers required before Google Play grants production release track access.

---

## Google Play Console 14-Step Deployment Checklist

1. [ ] **Create/Select App**: In Google Play Console, click *Create app* with name `QuizForge AI: Learning OS`, Default language: `English (US)`, Type: `App`, Free.
2. [ ] **Complete App Content**: Complete Declarations for Ads (No), Content Rating (Everyone), Target Audience (18+), Financial/News/COVID Declarations (No).
3. [ ] **Complete Data Safety**: Enter answers as specified in `PLAY_STORE_LISTING_DRAFT.md` Section 3 (encrypted in transit, user data deletion supported, no third-party sharing).
4. [ ] **Complete Content Rating**: Submit questionnaire (Educational reference application, PEGI 3 / Everyone).
5. [ ] **Add Privacy Policy URL**: Provide public HTTPS link to `docs/PRIVACY_POLICY.md`.
6. [ ] **Add Store Listing Details**: Copy Title (25 chars), Short Description (79 chars), and Full Description (4000 chars) from `PLAY_STORE_LISTING_DRAFT.md`.
7. [ ] **Upload Application Icon**: Upload `assets/play_store/icon_512x512.png` to the Hi-res icon slot.
8. [ ] **Upload Feature Graphic**: Upload `assets/play_store/feature_graphic_1024x500.png` to the Feature graphic slot.
9. [ ] **Upload Phone Screenshots**: Capture and upload 5 screenshots from device/emulator into `assets/play_store/screenshots/phone/`.
10. [ ] **Upload Tablet Screenshots**: Capture and upload 7" and 10" screenshots from tablet emulator.
11. [ ] **Create Closed Testing Track**: Navigate to *Testing > Closed testing*, select/create the primary closed track.
12. [ ] **Upload Signed AAB**: Upload `app-release.aab` downloaded from GitHub Actions artifact.
13. [ ] **Add Testers**: Create an email list and add at least 12 Google account testers.
14. [ ] **Start Closed Testing**: Distribute opt-in link, verify all 12+ testers have accepted, and begin the 14-day testing period.
