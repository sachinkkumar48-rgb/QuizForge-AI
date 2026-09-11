# QuizForge AI — Google Play Screenshot Specification & Capture Guide

This specification defines the exact requirements, dimensions, target screens, and capture procedures for Google Play Store listing screenshots.

---

## 1. Google Play Console Technical Requirements

| Platform Slot | Required Dimensions | Aspect Ratio | Format & Constraints | Quantity Required | Target Directory |
|:---|:---|:---:|:---|:---:|:---|
| **Phone** | `1080 x 1920` or `1080 x 2400` px | 9:16 or 9:20 | 24-bit PNG or JPEG, no alpha, max 8 MB | Min 4 (5 recommended) | `assets/play_store/screenshots/phone/` |
| **7-inch Tablet** | `1200 x 1920` px (portrait) or `1920 x 1200` px (landscape) | 16:10 | 24-bit PNG or JPEG, no alpha, max 8 MB | Min 1 (3 recommended) | `assets/play_store/screenshots/tablet_7in/` |
| **10-inch Tablet** | `1600 x 2560` px (portrait) or `2560 x 1600` px (landscape) | 16:10 | 24-bit PNG or JPEG, no alpha, max 8 MB | Min 1 (3 recommended) | `assets/play_store/screenshots/tablet_10in/` |

---

## 2. Mandatory Screen Catalog

The 5 representative screens to capture from the live Flutter application:

### Screen 1: Dashboard & Study Streak
- **Route / Component**: `LearnerDashboardPage` (`/dashboard`)
- **Key Visual Elements**:
  - Total questions attempted and accuracy gauge.
  - Active study streak counter and XP bar.
  - Quick action cards (Start PYQ Practice, Daily Review).
- **File Name**: `phone_01_dashboard.png`

### Screen 2: Adaptive PYQ Practice & Question Assessment
- **Route / Component**: `QuizPage` / `AdaptivePracticePage` (`/quiz`)
- **Key Visual Elements**:
  - UPSC Prelims General Studies question prompt.
  - Multiple-choice options with elimination rationale.
  - Timer and question progress dots.
- **File Name**: `phone_02_pyq_practice.png`

### Screen 3: Knowledge Map & Syllabus Frontier
- **Route / Component**: `ContentLearningPathPage` (`/learning_path`)
- **Key Visual Elements**:
  - Indian Polity & Constitution curriculum node tree.
  - Bloom's taxonomy mastery levels (Recall -> Analysis).
  - Unlocked frontier nodes and mastery percentage.
- **File Name**: `phone_03_learning_path.png`

### Screen 4: Academic Credentials & Verifiable Certificate
- **Route / Component**: `AcademicCredentialsPage` (`/credentials`)
- **Key Visual Elements**:
  - Verifiable Certificate of Completion with tamper-evident hash.
  - Cumulative GPA and topic proficiency scorecard.
  - Cryptographic verification badge.
- **File Name**: `phone_04_credentials.png`

### Screen 5: Cohort Management & Live Attendance
- **Route / Component**: `CohortManagementPage` (`/attendance`)
- **Key Visual Elements**:
  - Active cohort schedule and attendance roster.
  - Real-time attendance percentage and participation signals.
  - Faculty session details.
- **File Name**: `phone_05_attendance.png`

---

## 3. Capture Procedures

### Procedure A: Physical Android Device via ADB
Connect an Android device with USB debugging enabled, then execute:
```bash
# Capture and download Screen 1 (Dashboard)
adb exec-out screencap -p > assets/play_store/screenshots/phone/phone_01_dashboard.png

# Capture Screen 2 (PYQ Practice)
adb exec-out screencap -p > assets/play_store/screenshots/phone/phone_02_pyq_practice.png

# Capture Screen 3 (Learning Path)
adb exec-out screencap -p > assets/play_store/screenshots/phone/phone_03_learning_path.png

# Capture Screen 4 (Credentials)
adb exec-out screencap -p > assets/play_store/screenshots/phone/phone_04_credentials.png

# Capture Screen 5 (Attendance)
adb exec-out screencap -p > assets/play_store/screenshots/phone/phone_05_attendance.png
```

### Procedure B: Android Studio Emulator
1. Launch an emulator (e.g. Pixel 8 for Phone, Pixel Tablet for Tablet).
2. Run the application: `flutter run --release`.
3. Click the **Camera (Screenshot)** icon on the emulator sidebar or use `Ctrl + S`.
4. Save the generated PNG files directly into the target directories:
   - `assets/play_store/screenshots/phone/`
   - `assets/play_store/screenshots/tablet_7in/`
   - `assets/play_store/screenshots/tablet_10in/`

### Procedure C: Flutter Screenshot Command
When an emulator or device is running:
```bash
flutter screenshot --out=assets/play_store/screenshots/phone/phone_01_dashboard.png
```
