# P40 Learner Workflow Integration Audit

## 1. CURRENT UI
* **Application Entry Point (`lib/main.dart`)**:
  Initializes `TitanServiceLocator` via `setupServiceLocator()` and presents `QuizForgeDashboardPage` as the primary application view.
* **Dashboard (`lib/pages/quizforge_dashboard_page.dart`)**:
  - `DashboardHeaderWidget`: Welcomes learner, shows active exam context (`UPSC Civil Services`).
  - `StatSummaryCardWidget`: Real authoritative metrics (quizzes taken, accuracy, active streaks).
  - `QuickActionCardWidget`: Quick navigation triggers to AI Coach, PYQ Explorer, Library, and Quiz Generation.
  - `RecentActivityCardWidget`: Surfaces in-flight and recommended adaptive sessions with resume and targeted start callbacks.
  - `PluginModuleGridWidget`: Displays installed exam content modules (UPSC, BPSC, SSC, etc.).
* **Adaptive Practice Page (`lib/pages/adaptive_practice_page.dart`)**:
  - Full-screen interactive learning surface.
  - Progress header with question count and completion percentage.
  - Topic, difficulty, and exam badge chips.
  - Multiple-choice option selection with immediate correctness feedback and explanation sheets.
  - Action controls with single-submission protection.
  - Authoritative revision indicator in the AppBar (`Rev N`).
  - Completion summary screen with authoritative revision advancement, score metrics, remedial recommendation cards, and "Continue Learning" action.
* **PYQ & Study Screens (`lib/pages/pyq/`)**:
  - `PyqDashboardPage`: Navigation by year, subject, topic.
  - `PyqSubjectTopicPage`: Subject breakdown (Polity, History, Economy, etc.).

---

## 2. CURRENT NAVIGATION
* Central router is root `QuizForgeDashboardPage`.
* Navigation uses direct `Navigator.push` with `MaterialPageRoute`.
* Tapping an adaptive activity tile in `RecentActivityCardWidget` navigates to `AdaptivePracticePage(targetTopic: ...)` and triggers `_controller.refresh()` upon return.
* Tapping `"Resume Session"` on the active session banner navigates to `AdaptivePracticePage(isResumeMode: true)`.
* Tapping `"Return to Dashboard"` on `AdaptivePracticePage` pops the navigator back to the dashboard.
* Tapping `"Continue Learning"` resets the question state and initiates the next adaptive drill seamlessly.

---

## 3. EXISTING LEARNING SERVICES
1. **Diagnostic Assessment & Placement (P26)**:
   - `DiagnosticAssessmentService`: Evaluates target objectives and generates `DiagnosticPlacementResult` with `DiagnosticPlacementFrontier`.
   - `DeterministicDiagnosticEvaluator`: Evaluates prerequisite and frontier status deterministically.
2. **Remedial Framework (P25)**:
   - `DeterministicRemedialLessonService`: Resolves micro-lessons for weak spots and builds retry configurations.
3. **Adaptive Practice Execution (P35)**:
   - `AdaptivePracticeExecutionEngine`: Handles session initialization, question presentation, answer scoring, and time tracking.
4. **Outcome Consolidation (P36)**:
   - `PracticeOutcomeConsolidator`: Consolidates question results into `ConsolidatedPracticeOutcome`.
5. **State Reconciliation (P38)**:
   - `AdaptiveLearningStateReconciliationPipeline`: Validates proposals, enforces monotonic revision increments, and prevents stale writes.
6. **Authoritative State Persistence & Recovery (P39–P40)**:
   - `AuthoritativeLearningStateRepository` (Hive / In-Memory): Atomic commits with checksum and fingerprint verification.
   - `SessionCheckpointRepository` (Hive / In-Memory): Incremental durable session checkpointing.
   - `LearningSessionRecoveryService` & `AuthoritativeLearningStateRecoveryService`: Verifies data integrity, schema versions, and crash recovery.
7. **Production Journey Orchestrator (P40–P41)**:
   - `AdaptiveLearningJourneyOrchestrator`: High-level coordination of start, answer, reconcile, persist, and recovery.
   - `AdaptiveLearningJourneyController`: UI presentation controller exposing state, progress, errors, and listeners.
   - `PyqCorpusAdapterService`: Adapts PYQ models to `NormalizedQuestion` with fallback UPSC seed dataset.

---

## 4. EXISTING DATA FLOW
```text
Home / Dashboard
       ↓
Choose Exam / Topic (e.g. UPSC GS1 / Fundamental Rights)
       ↓
Diagnostic Placement (when required for cold-start / unassessed frontier)
       ↓
AdaptivePracticePage initializes AdaptiveLearningJourneyController
       ↓
AdaptiveLearningJourneyOrchestrator selects questions via PyqCorpusAdapterService
       ↓
Question Presented to Learner (Stem + Options)
       ↓
Learner Selects Option & Submits Answer (Single-submission guarded)
       ↓
PracticeOutcomeConsolidator aggregates attempt outcome
       ↓
AdaptiveLearningStateReconciliationPipeline computes diff & increments revision
       ↓
SessionCheckpointRepository saves durable checkpoint (chkRev: N+1, cursor: K+1)
       ↓
AuthoritativeLearningStateRepository commits atomic state (rev: N+1)
       ↓
Next Question Presented OR Session Completed
       ↓
Completion Summary reflects authoritative metrics & Remedial Recommendations
       ↓
App Restart / Exit → LearningSessionRecoveryService recovers session from checkpoint
       ↓
Learner Continues from exact uncompleted question cursor
```

---

## 5. INTEGRATION GAPS
1. **Diagnostic Placement Integration in Journey Entry**:
   While `DiagnosticAssessmentService` existed in `packages/garuda_learning`, the `AdaptiveLearningJourneyOrchestrator` did not expose a direct hook to trigger diagnostic placement and feed the resulting active frontier into question selection.
2. **Diagnostic Assessment Request Execution in Controller**:
   Need `executeDiagnosticPlacement` exposed on `AdaptiveLearningJourneyOrchestrator` and `AdaptiveLearningJourneyController` to enable the full Home $\to$ Exam $\to$ Topic $\to$ Diagnostic/Placement $\to$ Practice flow.
3. **Comprehensive P40 20-Scenario Test Matrix (A–T)**:
   Need complete automated test coverage in `packages/garuda_learning/test/integration/p40_end_to_end_learner_workflow_test.dart` explicitly exercising all 20 scenarios specified in Step 8 (A through T).

---

## 6. FILES TO MODIFY
* `packages/garuda_learning/lib/service/adaptive_learning_journey_orchestrator.dart`:
  - Add optional `DiagnosticAssessmentService? diagnosticService` parameter.
  - Implement `executeDiagnosticPlacement({learnerId, targetObjectiveIds, requestedAt})`.
* `packages/garuda_learning/lib/adapter/adaptive_learning_journey_controller.dart`:
  - Expose `executeDiagnosticPlacement` on the presentation controller.
* `packages/garuda_learning/test/integration/p40_end_to_end_learner_workflow_test.dart`:
  - Implement comprehensive integration test suite covering all 20 scenarios (A through T).

---

## 7. FILES NOT TO MODIFY
* **GARUDA Game / Unreal Engine**: Completely out of scope. 0 files touched.
* **Platform generated files**: `linux/`, `macos/`, `windows/`, `android/`, `ios/` preserved in clean state.
* **Unrelated packages**: `packages/garuda_pyq`, `titan_core`, etc. untouched.
* **Linter / Formatter configurations**: `analysis_options.yaml` untouched.

---

## 8. P40 IMPLEMENTATION PLAN
1. **Step 1**: Audit established and recorded in `docs/P40_LEARNER_WORKFLOW_AUDIT.md`.
2. **Step 2**: Wire `DiagnosticAssessmentService` into `AdaptiveLearningJourneyOrchestrator` and `AdaptiveLearningJourneyController` for real placement execution.
3. **Step 3**: Verify question presentation, single-submission answer protection, feedback, and progression.
4. **Step 4**: Verify consolidation, state reconciliation, and authoritative persistence contracts.
5. **Step 5**: Expose real progress, authoritative revisions, and remedial recommendations in UI surfaces.
6. **Step 6**: Verify restart recovery and session continuation without evidence duplication.
7. **Step 7**: Verify graceful error handling across loading, empty corpus, invalid questions, and service failures.
8. **Step 8**: Implement the complete 20-scenario test suite (A–T) in `p40_end_to_end_learner_workflow_test.dart`.
9. **Step 9**: Execute targeted tests, full `garuda_learning` suite, analyze, and format.
10. **Step 10 & 11**: Verify clean scope, commit, and push to `garuda/p23`.
