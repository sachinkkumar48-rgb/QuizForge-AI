# P41 Learner Dashboard & Learning Control Center Audit

## 1. EXISTING LEARNER UI
* **Application Entry Point (`lib/main.dart`)**:
  - Initializes TITAN dependency injection via `setupServiceLocator()`.
  - Initializes Hive local storage via `Hive.initFlutter()`.
  - Mounts `MaterialApp` with `home: const QuizForgeDashboardPage()`.
* **Primary Dashboard Surface (`lib/pages/quizforge_dashboard_page.dart`)**:
  - Built as a Material 3 responsive dashboard with `DashboardController`.
  - Sections:
    1. `DashboardHeaderWidget`: Greets learner, displays exam context (`UPSC Civil Services`).
    2. `StatSummaryCardWidget`: Displays metrics (quizzes completed, avg accuracy, questions solved, PDF sources). *Note: Previously had hardcoded fallback default values (12, 78.5%, 145, 4).*
    3. `QuickActionCardWidget`: Grid of quick actions (Generate Quiz, PYQ Bank, AI Coach, PDF Library, History, Plugin Hub).
    4. `RecentActivityCardWidget`: Shows "Unfinished Quiz Found" banner if an active session exists; lists recent activities. *Note: Previously fell back to 3 hardcoded static activities when empty.*
    5. `PluginModuleGridWidget`: Displays installed exam content modules (UPSC GS1, BPSC, SSC CGL, etc.).
* **Adaptive Practice & Learning Surface (`lib/pages/adaptive_practice_page.dart`)**:
  - Step-by-step adaptive practice loop powered by `AdaptiveLearningJourneyController`.
  - Displays question stem, options, difficulty badge, single-submission guarded answers, feedback explanation card.
  - Completion summary screen shows total answered, correct count, accuracy percentage, authoritative state revision advancement, and remedial recommendations.
* **PYQ Content Navigation Surfaces (`lib/pages/pyq/`)**:
  - `PyqDashboardPage`: Entry point to previous year questions.
  - `PyqSubjectTopicPage`: Navigation by Exam Subject $\to$ Topic.
  - `PyqAttemptPage`: Direct question attempt interface.
* **History Surface (`lib/pages/history_page.dart`)**:
  - List of past attempts with search, sorting, and deletion.
  - Details view in `AttemptSummaryPage`.

---

## 2. EXISTING STATE / DATA SOURCES
* **`AuthoritativeLearningStateRepository` (InMemory & Hive)**:
  - Authoritative store for `AuthoritativeLearnerState`.
  - Tracks monotonic revisions, SHA-256 state fingerprints, and `progressMap` mapping `objectiveId` $\to$ `LearnerProgress` (attempts, correct count, success rate, status, `lastAttemptAt`).
* **`SessionCheckpointRepository` (InMemory & Hive)**:
  - Durable store for `SessionCheckpoint`.
  - Records session ID, learner ID, exam ID, question index cursor, completed question IDs, active objective ID, timestamp, and `isCompleted` flag.
  - Provides `listCheckpoints(learnerId, examId)` to list all persisted checkpoints for recovery and history.
* **`QuizHistoryRepository` & `QuizSessionRepository`**:
  - Legacy repositories for mock quiz attempts and active quiz drafts.
* **`AttemptRepository` & `ProgressRepository`**:
  - Domain-level attempt and progress record storage for GARUDA learning.

---

## 3. REUSABLE SERVICES
* **`AdaptiveLearningDecisionEngine` (P41)**:
  - Deterministic pedagogical engine that evaluates authoritative learner state, checkpoints, and curriculum to produce an `AdaptiveLearningDecision`.
  - Evaluates priority order: continuation $\to$ remediation $\to$ review $\to$ reinforcement $\to$ advancement $\to$ complete.
  - Outputs typed target (`sessionCursor`, `remedialLesson`, `practiceObjective`, `curriculumObjective`) and machine-readable `DecisionEvidence`.
* **`LearningSessionRecoveryService` & `AuthoritativeLearningStateRecoveryService` (P39-P40)**:
  - Verify cryptographic checksums, validate schema versions, and recover interrupted sessions without evidence duplication.
* **`AdaptiveLearningJourneyOrchestrator` & `AdaptiveLearningJourneyController` (P40-P41)**:
  - Coordinates starting sessions, submitting answers, outcome consolidation, state reconciliation, and session recovery.
  - Exposes diagnostic placement via `executeDiagnosticPlacement`.
* **`DeterministicRemedialLessonService` & `WeakSpotDiagnosticEvaluator` (P23, P25)**:
  - Evaluates weak learning objectives and resolves targeted micro-lessons.
* **`CurriculumService` (P17)**:
  - Provides hierarchical syllabus navigation: Exam Framework $\to$ Domains $\to$ Units $\to$ Objectives.
* **`PyqCorpusAdapterService` (P40)**:
  - Bridges PYQ questions into `NormalizedQuestion` corpus for adaptive practice.

---

## 4. REUSABLE ENTITIES
* `AuthoritativeLearnerState`
* `LearnerProgress` & `LearnerObjectiveStatus`
* `SessionCheckpoint`
* `AdaptiveLearningDecision` & `LearningTarget` & `DecisionEvidence`
* `LearningContinuationPlan`
* `LearningJourneySession` & `LearningJourneyStatus`
* `DiagnosticPlacementResult` & `DiagnosticPlacementFrontier`
* `RemedialLesson` & `RemedialBinding`
* `NormalizedQuestion` & `Option` & `Answer`

---

## 5. MISSING DASHBOARD CAPABILITIES (GAPS FOR P41)
1. **Unification of Authoritative Recovery with Dashboard Entry**:
   - The dashboard currently relied only on legacy `QuizSessionRepository.hasActiveSession()`, failing to query `SessionCheckpointRepository` for uncompleted adaptive learning sessions.
   - On dashboard initialization, it must query `SessionCheckpointRepository` and `AuthoritativeLearningStateRepository` to detect recoverable adaptive sessions immediately.
2. **Elimination of Fabricated Metrics & Placeholder Content**:
   - `DashboardStats` defaulted to 12 quizzes, 78.5% accuracy, 5-day streak, 145 questions solved.
   - `RecentActivityCardWidget` fell back to hardcoded mock questions when no attempts existed.
   - For first-time learners or when data is absent, the dashboard must accurately reflect empty/initial state (e.g., 0 attempts, "Not yet assessed") without fake numbers.
3. **Dedicated Next Best Learning Action Presentation**:
   - The dashboard lacked a first-class card presenting the learner with their concrete Next Best Action derived from `AdaptiveLearningDecisionEngine` (e.g., "Resume Unfinished Session", "Targeted Remedial Drill", "Practice Active Frontier", "Spaced Review").
4. **Authoritative Progress History Surface**:
   - The dashboard lacked a way to inspect real adaptive learning history derived from `SessionCheckpointRepository` and `AuthoritativeLearnerState`, showing session exam/topic, question completion cursor, and resumption triggers.
5. **Seamless Content Navigation (Exam $\to$ Subject $\to$ Objective $\to$ Start)**:
   - Direct pathway from the dashboard to explore the curriculum hierarchy and launch adaptive practice on any selected objective.
6. **Robust Dashboard State Handling**:
   - Must handle all 15 states cleanly: first-time learner, no content, no active session, active session, completed session, recovered session, loading, persistence failure, recovery failure, invalid learner state, and unavailable recommendation without crashes.

---

## 6. EXACT FILES TO MODIFY / CREATE
### Production Source Files
1. `packages/garuda_learning/lib/domain/entities/learner_dashboard_state.dart` [NEW]
   - Encapsulates clean domain model for dashboard state: `ContinueLearningCardState`, `LearnerProgressSummaryState`, `NextBestActionState`, `LearnerHistoryItem`, and `LearnerDashboardStatus`.
2. `packages/garuda_learning/lib/adapter/learner_dashboard_controller.dart` [NEW]
   - Clean Architecture presentation controller for the learner control center. Coordinates recovery, authoritative progress extraction, decision engine recommendations, and history queries without widget logic.
3. `packages/garuda_learning/lib/garuda_learning.dart` [MODIFY]
   - Export new P41 learner dashboard entities and controller.
4. `lib/controllers/dashboard_state.dart` [MODIFY]
   - Update `DashboardStats` and `DashboardState` to eliminate hardcoded fake defaults, support nulls for unassessed metrics, and embed authoritative adaptive dashboard state.
5. `lib/pages/quizforge_dashboard_page.dart` [MODIFY]
   - Upgrade the dashboard UI to render real Continue Learning (active session resume or start learning), real Progress Summary, real Next Best Action, and real Learning History.

### Test Files
1. `packages/garuda_learning/test/integration/p41_learner_dashboard_test.dart` [NEW]
   - Comprehensive integration test suite covering all 15 scenarios specified in Section 8.
2. `test/p41_learner_dashboard_ui_integration_test.dart` [NEW]
   - Flutter UI integration tests validating widget rendering, state changes, and navigation.

---

## 7. EXACT FILES INTENTIONALLY LEFT UNTOUCHED
* **GARUDA Game / Unreal Engine**: Completely out of scope. 0 files touched.
* **Platform generated files**: `android/`, `ios/`, `linux/`, `macos/`, `windows/`, `web/` untouched.
* **Packages `garuda_case_law` and `garuda_pyq`**: Left untouched.
* **P38-P40 core engines**: `ProgressiveMasteryEngine`, `AdaptiveLearningStateReconciliationPipeline`, `AuthoritativeLearningStateRecoveryService`, and `LearningSessionRecoveryService` untouched (reused as-is).
* **Linter & CI configs**: `analysis_options.yaml` untouched.
