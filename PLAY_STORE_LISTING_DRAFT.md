# QuizForge AI LMS — Google Play Store Listing Draft

This document contains factual store-listing metadata, descriptions, category recommendations, and compliance declarations for Google Play Console submission.

---

## 1. Store Listing Details

### App Name
**QuizForge AI: Learning OS**
*(25 characters — fully compliant with Google Play Console 30-character title limit. Alternative: **QuizForge AI - UPSC Prep** (24 characters))*

### Short Description (Max 80 characters)
**Adaptive civil service exam preparation with PYQs, analytics, and study plans.**
*(79 characters)*

### Full Description (Max 4000 characters)

QuizForge AI is a comprehensive Learning Operating System designed for civil service and competitive examination preparation, featuring focused support for UPSC Prelims and Mains frameworks.

Built on deterministic mastery progression and evidence-backed curriculum architecture, QuizForge AI empowers aspirants to systematically evaluate their knowledge, practice past examination questions, track attendance and study streaks, and follow personalized learning schedules.

KEY FEATURES:

1. OFFICIAL PREVIOUS YEAR QUESTIONS (PYQs)
- Access extensive archives of UPSC Prelims General Studies questions.
- Practice by topic, exam year, or custom exam sizes.
- Detailed question explanations, elimination rationales, and subject classification.

2. ADAPTIVE LEARNING & PROGRESSIVE MASTERY
- Diagnostic placement assessments evaluate foundational strengths.
- Closed-loop adaptive practice recommends questions targeting identified weak areas.
- Automated Bloom's taxonomy tracking highlights knowledge retention across cognitive tiers.

3. PERSONALIZED STUDY PLANS & DASHBOARD
- Real-time dashboard summarizing total questions attempted, accuracy, and active streaks.
- Daily study agendas scheduled based on syllabus weightage and priority frontiers.
- Continuous learning session checkpoints allow you to pause and resume exams anytime.

4. ACADEMIC CREDENTIALS & PERFORMANCE AUDIT
- Verified academic record logging for quizzes, mock exams, and milestones.
- View cumulative GPA, topic proficiency heatmaps, and transcripts.
- Printable completion certificates backed by verifiable tamper-evident hashes.

5. OFFLINE-FIRST ARCHITECTURE
- Fully functional offline practice: study questions, answer quizzes, and review notes without active internet connectivity.
- Local encrypted storage guarantees privacy and responsiveness on the go.
- Automatic conflict-free background synchronization when connectivity is restored.

6. AI STUDY MENTOR (OPTIONAL)
- In-depth concept clarifications, answer deconstruction, and structured doubt resolution.
- Direct user control: enter your own Gemini or OpenAI API key or use local learning modes.

---

## 2. Categorization & Contact Information

- **Application Category**: Education
- **Content Rating**: Everyone / PEGI 3
- **Tags / Keywords**: Civil Services, UPSC Preparation, IAS Exam, PYQ Mock Tests, Adaptive Learning, Study Planner
- **Developer Email**: support@quizforge.ai (or sachinkkumar48@gmail.com)
- **Website URL**: https://github.com/sachinkkumar48-rgb/QuizForge-AI
- **Privacy Policy URL**: https://github.com/sachinkkumar48-rgb/QuizForge-AI/blob/main/docs/PRIVACY_POLICY.md

---

## 3. Data Safety Declaration (Play Console Questionnaire)

| Data Category | Data Type | Collected? | Shared? | Purpose | Retention / Deletion |
|:---|:---|:---:|:---:|:---|:---|
| **Personal Info** | Name, Email address | Optional | No | Account personalization | Stored locally in Hive; user can reset in Settings |
| **Academic Activity** | Quiz answers, scores, study progress | Yes | No | App functionality & progress analytics | Stored on-device; offline persistence |
| **Messages / Prompts** | User queries to AI Mentor | Optional | Only with AI API | Educational explanation & tutoring | Transmitted over HTTPS only when requested |
| **Identifiers** | Device ID, Advertising ID | **No** | No | N/A | Not collected |
| **Financial / Payment** | Credit card, purchase history | **No** | No | N/A | App is 100% free; no IAP |
| **Location / Media** | GPS, Photos, Audio, Camera | **No** | No | N/A | No permissions requested |

- **Security Practices**:
  - Data encrypted in transit via standard TLS/HTTPS.
  - Keystore-backed encrypted storage for sensitive credentials.
  - User can delete all local data and session history directly within the application.

---

## 4. App Access & Reviewer Instructions

- **Authentication Required**: **No login wall**. Reviewers can immediately access the dashboard upon launch.
- **Guest / Aspirant Mode**: Enabled by default. Pre-seeded with official UPSC Indian Polity & Constitution curriculum framework and PYQ questions.
- **AI Features**: Optional API Key setup page available in Settings. The entire core application (PYQ practice, adaptive tests, analytics, transcripts) functions completely offline without requiring third-party credentials.
- **Demo Reviewer Credentials**: Not applicable (guest profile active by default).
