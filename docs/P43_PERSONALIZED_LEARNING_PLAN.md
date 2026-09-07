# P43: Personalized Learning Plan Specification & Audit

**Project TITAN / QuizForge AI LMS — Milestone P43**  
*Role: Senior Implementation Engineer (Antigravity)*  
*Date: 2026-09-07*  

---

## 1. Executive Summary
Milestone P43 operationalizes the **Personalized Learning Plan** process in QuizForge AI. It builds upon P26 (Diagnostic Assessment & Placement), P35 (Adaptive Practice Execution), P36 (Practice Outcome Consolidation), P38 (Learning-State Reconciliation), P39 (Authoritative State Persistence & Recovery), P40 (Durable Checkpoints & Crash Recovery), and P41/P42 (Learner Dashboard & Content-to-Learning-Path Discovery).

The learning plan is not an isolated speculative data structure; it is a **deterministic, explainable, and executable roadmap** derived directly from authoritative learner state, diagnostic placement, curriculum prerequisites, and verified PYQ content availability:
```
DIAGNOSTIC RESULT
       +
AUTHORITATIVE LEARNER STATE
       +
AVAILABLE CONTENT
       +
TOPIC/OBJECTIVE STRUCTURE
       ↓
PERSONALIZED LEARNING PLAN
       ↓
ORDERED LEARNING ACTIONS
       ↓
PRACTICE / REMEDIATION / REVISION
       ↓
OUTCOME
       ↓
UPDATED LEARNER STATE
       ↓
PLAN REFRESH
```

---

## 2. Comprehensive Audit of Existing Decision Data

### 2.1 Existing Decision-Capable Inputs
1. **Diagnostic Placement Result (`DiagnosticPlacementResult` / `DiagnosticPlacementFrontier`)**:
   - Available via `DiagnosticPlacementRepository` (`InMemoryDiagnosticPlacementRepository`).
   - Fields:
     - `frontier.remediationTargetObjectiveIds`: High-priority remediation targets identified during diagnostic evaluation.
     - `frontier.activeFrontierObjectiveIds`: Objectives whose prerequisites are demonstrated but the objective itself is developing or unassessed.
     - `frontier.developingObjectiveIds`: Objectives with evidence below mastery threshold.
     - `frontier.demonstratedObjectiveIds`: Objectives where mastery is verified.
     - `frontier.unassessedObjectiveIds`: Objectives with no assessment evidence.
     - `objectiveResults[objectiveId]`: Granular `attemptsCount`, `correctCount`, `observedAccuracy`, `placementStatus`.

2. **Authoritative Learner State (`AuthoritativeLearnerState` / `LearnerProgress`)**:
   - Recoverable via `AuthoritativeLearningStateRecoveryService` and `AuthoritativeLearningStateRepository`.
   - Fields:
     - `progressMap[objectiveId]`: Deeply immutable map of `LearnerProgress`.
     - `progress.attemptCount`: Real question attempt count.
     - `progress.correctCount`: Number of correct answers.
     - `progress.successRate`: `correctCount / attemptCount`.
     - `progress.isAchieved`: Whether objective criteria have been met.
     - `progress.status`: `LearnerObjectiveStatus.notStarted`, `inProgress`, `achieved`.
     - `progress.lastAttemptAt`: Timestamp of latest attempt.
     - `revision`: Monotonic revision number of the authoritative state snapshot.
     - `stateFingerprint`: Deterministic SHA-256 state hash.

3. **Session Checkpoints & Recovery (`SessionCheckpoint`)**:
   - Managed by `SessionCheckpointRepository` (`InMemorySessionCheckpointRepository`).
   - Fields:
     - `isCompleted == false`: In-flight active practice session.
     - `sessionId`: Session UUID for resumption.
     - `questionIndex`: Current question cursor.
     - `activeObjectiveId`: Objective being practiced.
     - `metadata['topic']`, `metadata['totalQuestions']`.

4. **Curriculum Framework & Objective Sequence (`CurriculumFramework` / `CurriculumService`)**:
   - Seed data in `CurriculumSeedData.buildUpscConstitutionalLawFramework()`.
   - Methods:
     - `getDeterministicSequence()`: Topological sort respecting explicit prerequisites.
     - `getObjectiveById(id)`: Metadata, title, description, Bloom level, prerequisites.
     - `getPrerequisiteClosure(id)`: Full transitive dependency closure.

5. **Content Discovery & Question Corpus (`ContentLearningPathService` / `PyqCorpusAdapterService`)**:
   - Seed questions from `PyqCorpusAdapterService.getDefaultSeedCorpus()`.
   - `TopicContext`: Topic-to-objective binding, `hasPyqContent`, and `questionCount`.

6. **Remedial Lessons (`DeterministicRemedialLessonService`)**:
   - Backed by `RemedialLessonRepository`.
   - `findBestLessonForObjective(objectiveId)`: Supplies targeted micro-lessons.

### 2.2 Missing Capability
- Multi-objective sequence synthesis: Before P43, the application could only recommend a single next best action (`NextBestActionState`) or allow ad-hoc topic browsing.
- Downstream plan execution: Learners had no cohesive view of their full learning journey: which objective comes next, why it was chosen, what comes after, and what has already been achieved.
- Closed-loop plan refresh: When an action completed, the system updated progress, but had no unified plan regeneration service to immediately re-order subsequent actions.

---

## 3. Proposed Minimal Implementation

### 3.1 Domain Model (`PersonalizedLearningPlan` & `PersonalizedLearningAction`)
- **`PlanActionType`**: `continueSession`, `takeDiagnostic`, `startRemedialLesson`, `practiceObjective`, `practicePyqs`, `reviewRevision`.
- **`PlanActionStatus`**: `recommended`, `inProgress`, `completed`, `pending`.
- **`PlanReasonCode`**:
  - `IN_FLIGHT_SESSION`: Uncompleted session checkpoint detected.
  - `DIAGNOSTIC_WEAKNESS`: Diagnosed as weak in baseline assessment.
  - `PERSISTENT_FAILURE`: Authoritative accuracy below 60% with 3+ attempts.
  - `PREREQUISITE_FOUNDATION`: Prerequisite objective must be completed first.
  - `ACTIVE_FRONTIER`: Immediate learning edge ready for practice.
  - `REVISION_REINFORCEMENT`: Mastered topic due for retention review.
  - `CURRICULUM_REMAINING`: Scheduled topic in curriculum sequence.
- **`PersonalizedLearningAction`**:
  - Stable action ID: `act_{actionType}_{objectiveId}_{orderIndex}`
  - Target coordinates: `examId`, `subjectId`, `subjectName`, `topicId`, `topicName`, `objectiveId`, `objectiveTitle`
  - Action parameters: `actionType`, `orderIndex`, `reasonCode`, `reason`, `status`, `sessionId`, `remedialLessonId`, `targetQuestionCount`, `isExecutable`.
- **`PersonalizedLearningPlan`**:
  - Immutable state: `planId`, `learnerId`, `examId`, `generatedAt`, `stateRevision`, `actions`, `recommendedAction`, `upcomingActions`, `completedActions`, `progressPercentage`.

### 3.2 Plan Generation Service (`PersonalizedLearningPlanService`)
Pure deterministic domain service:
1. Prioritize in-flight session checkpoints (`continueSession`).
2. Prioritize diagnosed or authoritative weak spots (`startRemedialLesson` / `practiceObjective`).
3. Prioritize unmet prerequisite foundational objectives (`practiceObjective`).
4. Prioritize active frontier objectives (`practiceObjective`).
5. Prioritize revision of mastered topics (`reviewRevision`).
6. Prioritize remaining syllabus topics (`practiceObjective`).
7. If learner is completely cold-start without diagnostic, surface diagnostic first (`takeDiagnostic`).

### 3.3 Application & UI Integration
- **`LearningPlanPage`**: Learner-facing screen displaying current recommended action with reason badge, upcoming roadmap, and completed milestones.
- Tapping the recommended action launches `AdaptivePracticePage`.
- On completion of practice, outcome consolidation and state reconciliation update authoritative state, and the plan refreshes automatically.

---

## 4. Scope Audit & Files Targeted

### 4.1 Production Source Files (New)
- `packages/garuda_learning/lib/domain/entities/personalized_learning_plan.dart`
- `packages/garuda_learning/lib/service/personalized_learning_plan_service.dart`
- `lib/pages/learning_plan_page.dart`

### 4.2 Production Source Files (Modified - EXACTLY 3)
1. `packages/garuda_learning/lib/garuda_learning.dart` (exports P43 entities and service)
2. `lib/core/di/service_locator_init.dart` (registers `PersonalizedLearningPlanService`)
3. `lib/pages/quizforge_dashboard_page.dart` (wires learning plan navigation & dashboard card)

### 4.3 Test Files (New)
- `packages/garuda_learning/test/p43_personalized_learning_plan_test.dart` (20 scenarios)
- `packages/garuda_learning/test/integration/p43_personalized_learning_plan_integration_test.dart` (lifecycle & refresh)
- `test/p43_learning_plan_ui_integration_test.dart` (root UI test)

### 4.4 Files Intentionally NOT Changed
- Zero Garuda Game / Unreal Engine files touched or imported.
- Zero duplicate practice engines or duplicate learner-state stores.
- Zero generated platform files touched.
