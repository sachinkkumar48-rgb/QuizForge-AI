# P42 Learner Learning-Path Completion Specification & Audit

## Document Metadata
- **Project**: TITAN / QuizForge AI LMS
- **Milestone**: P42 Learner Learning-Path Completion Sprint
- **Status**: IMPLEMENTATION READY
- **Date**: 2026-09-07

---

## 1. Executive Summary

This document audits the current learning path capabilities delivered across P26–P41 and defines the concrete integration ensuring a completely operational, closed-loop learner journey:

```
LEARNER
  ↓
SELECT EXAM
  ↓
SELECT SUBJECT / TOPIC
  ↓
VIEW LEARNING OBJECTIVE
  ↓
SEE CURRENT STATE
  ↓
GET NEXT LEARNING ACTION
  ↓
START REAL LEARNING
  ↓
PRACTICE / PYQ / REMEDIATION
  ↓
COMPLETE SESSION
  ↓
CONSOLIDATE OUTCOME
  ↓
RECONCILE AUTHORITATIVE STATE
  ↓
PERSIST AUTHORITATIVE STATE
  ↓
REFRESH LEARNING PATH
  ↓
NEXT OBJECTIVE IN SYLLABUS
```

Zero Unreal Engine / Garuda Game files are modified, imported, or referenced.

---

## 2. Capability Audit

### A. Currently Working
1. **Exam, Subject, and Topic Hierarchy**:
   - `ContentLearningPathService.getAvailableExams()` exposes UPSC Prelims GS1 and catalog previews.
   - `ContentLearningPathService.getSubjectsForExam(...)` returns Indian Polity and Economy with rich metadata.
   - `ContentLearningPathService.getTopicsForSubject(...)` maps topics to questions and canonical curriculum objectives.
2. **Empty Content Handling**:
   - Topics with 0 questions in the active corpus are detected and assigned `ContentPathStatus.emptyContent` without crashing or inventing questions.
3. **Session Checkpoint Resumption**:
   - In-flight uncompleted sessions in `SessionCheckpointRepository` are detected and surface `canResumeActiveSession: true` with cursor and total question count.
4. **Authoritative Persistence & Recovery**:
   - Learner progress and state revisions are retrieved from `AuthoritativeLearningStateRecoveryService`.
5. **Execution Workflows**:
   - `AdaptivePracticePage` and `AdaptiveLearningJourneyController` execute real drills, consolidate question outcomes, reconcile state via `AdaptiveLearningStateReconciler`, and persist to `AuthoritativeLearningStateRepository`.

### B. Currently Partial
1. **Next Learning Action Resolution**:
   - `resolveLearningPath(...)` handles cold-start diagnostic and persistent weakness remediation, but:
     - Fails to distinguish between incomplete learning vs completed mastery.
     - When an objective is achieved (`isAchieved == true`), it still recommends regular practice instead of revision/mastery review or advancing to the next objective.
     - Does not consult `DiagnosticPlacementRepository` when diagnostic evaluation evidence exists for the target objective.
2. **Post-Session Advancement**:
   - Completing a practice session updates state, but does not provide an automatic, guided transition to the next sequential objective in the syllabus.
3. **Action Specificity**:
   - All actions launch into standard practice without passing lesson IDs for remediation or differentiating pure PYQ practice drills.

### C. Missing
1. **Next Sequential Objective Resolution**:
   - When an objective is achieved, resolving the path should identify and expose the next logical objective from `CurriculumService.getDeterministicSequence()`.
2. **Comprehensive 23-Scenario Integration Test**:
   - `packages/garuda_learning/test/integration/p42_learning_path_completion_test.dart` verifying the complete end-to-end lifecycle, edge cases, error conditions, and recovery.

---

## 3. Existing Services to Reuse (No Duplicate Systems)

| Capability | Existing Service | Integration Role |
| :--- | :--- | :--- |
| Curriculum Graph & Prerequisite Sequence | `CurriculumService` | Deterministic topological order of objectives and next objective resolution. |
| State Recovery & Snapshot | `AuthoritativeLearningStateRecoveryService` | Recovers authoritative attempts, accuracy, and state revision. |
| Checkpoint Persistence & Resumption | `SessionCheckpointRepository`, `LearningSessionRecoveryService` | Detects in-flight sessions and retrieves resumable cursors. |
| Remedial Content | `DeterministicRemedialLessonService` | Attaches verified remedial micro-lessons for conceptual gaps. |
| Diagnostic Placement | `DiagnosticPlacementRepository` | Feeds assessed placement evidence into the action resolver. |
| Practice Execution & Orchestration | `AdaptiveLearningJourneyController`, `AdaptivePracticePage` | Executes interactive sessions, outcome consolidation, and state reconciliation. |
| Content Corpus | `PyqCorpusAdapterService` | Delivers real UPSC PYQ questions without fabrication. |

---

## 4. Planned Modifications (Strict 3-File Budget)

1. `packages/garuda_learning/lib/domain/entities/content_learning_path.dart`:
   - Enhance `ContentLearningPathState` with `isObjectiveAchieved`, `nextObjectiveId`, `nextObjectiveTitle`, and `remedialLessonId`.
2. `packages/garuda_learning/lib/service/content_learning_path_service.dart`:
   - Enhance `resolveLearningPath` with full 7-step priority:
     1. Resume active/recoverable session (`continueSession`)
     2. Incomplete learning in progress (`continuePractice`)
     3. Diagnostic placement cold-start or assessment gap (`takeDiagnostic`)
     4. Remedial review for weak spots (`startRemedialLesson`)
     5. PYQ practice drill for available content (`practicePyqs`)
     6. Spaced revision for completed objectives (`reviewWeakTopic`)
     7. Objective completed status with next sequential objective resolution.
3. `lib/pages/content_learning_path_page.dart`:
   - Render mastery status, remedial review button, and "Next Objective" advancement button upon objective completion.
