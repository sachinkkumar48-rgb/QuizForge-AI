# P42: Content-to-Learning-Path Integration Audit & Technical Specification

**Project TITAN / QuizForge AI LMS — Milestone P42**  
*Date: 2026-09-07*  
*Role: Senior Implementation Engineer (Antigravity)*  

---

## 1. Executive Summary & Mission
Milestone P42 bridges content discovery and pedagogical execution in QuizForge AI. Previous milestones built robust adaptive practice loops (P25–P40), session checkpoint durability, authoritative state recovery, and an authoritative learner control center (P41). However, the path connecting **EXAM → SUBJECT → TOPIC → LEARNING OBJECTIVE → DIAGNOSTIC / START POINT → PRACTICE / REMEDIAL → PROGRESS** remained fragmented across isolated subsystems.

This document audits the existing implementations across `packages/garuda_learning`, `packages/garuda_pyq`, and root `lib/`, and defines the exact integration path that operationalizes the content-to-learning-path pipeline without rebuilding existing diagnostic, adaptive, or persistence machinery.

---

## 2. Comprehensive Codebase Audit

### 2.1 Exam Catalogue
- **`packages/garuda_pyq/lib/models/exam_model.dart`**:
  - Defines `SupportedExam` with pre-configured static instances: `upscCse` (UPSC Civil Services Examination, Central Civil Services), `cds`, `nda`, `capf`, `epfoEoAo`, `rbiGradeB`, `uppsc`, `bpsc`, and 16 other state exams in `SupportedExam.initialExams`.
  - Provides category grouping: `centralCivilServices`, `defenseServices`, `regulatoryAndBanking`, `statePublicService`, `custom`.
- **`lib/models/exam.dart`**:
  - Legacy `Exam` model (`examId`, `code`, `name`, `conductingBody`, `category`).
- **Canonical Learning Exam Context**:
  - `upsc_prelims_gs1` is the canonical exam ID throughout `packages/garuda_learning` (`AuthoritativeLearnerState`, `SessionCheckpoint`, `AdaptivePracticePage`, `CurriculumSeedData`).

### 2.2 Curriculum Framework & Learning Objectives
- **`packages/garuda_learning/lib/domain/entities/curriculum_framework.dart`**:
  - Hierarchy: `CurriculumFramework` → `CurriculumDomain` → `CurriculumUnit` → `LearningObjective`.
  - Seed implementation in `CurriculumSeedData.buildUpscConstitutionalLawFramework()`:
    - **Domain**: `domain_constitutional_foundations` ("Constitutional Foundations & Fundamental Rights").
    - **Units**:
      - `unit_preamble_and_basic_structure` ("Preamble & Basic Structure Doctrine")
      - `unit_personal_liberty_art21` ("Right to Life & Personal Liberty (Article 21)")
    - **Objectives**:
      - `lo_preamble_identity` ("Understand the Preamble as the Key to the Constitution")
      - `lo_basic_structure_doctrine` ("Analyze the Basic Structure Doctrine", prereq: `lo_preamble_identity`)
      - `lo_article_21_foundations` ("Evaluate the Expansion of Article 21 Rights", prereq: `lo_basic_structure_doctrine`)
- **`CurriculumService` (`packages/garuda_learning/lib/service/curriculum_service.dart`)**:
  - Provides `getObjectiveById()`, `getUnitById()`, `getDomainById()`, `getPrerequisiteClosure()`, and `getDeterministicSequence()`.

### 2.3 Questions & Normalized Questions
- **`packages/garuda_pyq/lib/models/normalized_question_model.dart`**:
  - Canonical `NormalizedQuestion` with `id`, `examId`, `year`, `paper`, `stage`, `subject`, `topic`, `options`, `officialAnswer`, `explanation`, `difficulty`, `objectiveIds`.
- **`lib/services/pyq_corpus_adapter_service.dart`**:
  - Provides `toNormalized()` translating `PyqQuestionModel` to `NormalizedQuestion`.
  - `getDefaultSeedCorpus()` supplies verified Prelims questions:
    - Subject: `Indian Polity`, Topic: `Fundamental Rights` (`pyq_polity_art14`, `pyq_polity_art32`)
    - Subject: `Indian Polity`, Topic: `Emergency Provisions` (`pyq_polity_emergency`)
    - Subject: `Indian Polity`, Topic: `Directive Principles` (`pyq_polity_dpsp`)
    - Subject: `Economy`, Topic: `Macroeconomics` (`pyq_economy_inflation`)
  - Provides `getCorpus({String? subject, String? topic})` filtering dynamically.

### 2.4 Diagnostic Assessment & Placement
- **`DiagnosticAssessmentService` (`packages/garuda_learning/lib/service/diagnostic_assessment_service.dart`)**:
  - Accepts `DiagnosticAssessmentRequest` and evaluates learner responses across target objectives to compute `DiagnosticPlacementResult`.
  - Determines `DiagnosticPlacementFrontier`, baseline competency score, placement band (`novice`, `foundational`, `competent`, `proficient`), and recommended entry objective.
- **`AdaptiveLearningJourneyOrchestrator`**:
  - Exposes `executeDiagnosticPlacement(learnerId, targetObjectiveIds)`.

### 2.5 Remedial Lessons & Weak Spot Detection
- **`DeterministicRemedialLessonService` (`packages/garuda_learning/lib/service/deterministic_remedial_lesson_service.dart`)**:
  - Delivers structured remedial micro-lessons when an objective exhibits persistent failure (`attemptCount >= 3` and `successRate < 0.6`).
- **`AdaptiveLearningDecisionEngine` (`packages/garuda_learning/lib/service/adaptive_learning_decision_engine.dart`)**:
  - Formulates `AdaptiveActionType`:
    - `continueSession` (resumable active checkpoint)
    - `startRemedialLesson` (weak topic remediation)
    - `reviewWeakTopic` (decayed mastery review)
    - `continuePractice` (active frontier)
    - `takeDiagnostic` (cold-start unassessed)

### 2.6 Adaptive Practice & Recovery Loops
- **`AdaptiveLearningJourneyController` & `AdaptivePracticePage`**:
  - Executes full practice execution: question presentation → answer submission → outcome consolidation → state reconciliation → durable checkpointing.
  - Supports `isResumeMode: true` and `resumeSessionId` for crash recovery.
- **`AuthoritativeLearnerState` & `SessionCheckpoint`**:
  - Persistent state in `InMemoryAuthoritativeLearningStateRepository` and `InMemorySessionCheckpointRepository`.

### 2.7 Learner Dashboard (P41)
- **`QuizForgeDashboardPage` & `DashboardController`**:
  - Surfaces Continue Learning card, Next Best Action card, Current Learning Progress card, Quick Actions grid, and Recent Activities list.

---

## 3. The Shortest Operational Integration Path

```
Learner Opens Content Discovery (Screen / Action)
                   ↓
1. SELECT EXAM (e.g. UPSC CSE / Prelims GS1)
   - Exposes real exams from SupportedExam.initialExams / CurriculumFramework.
                   ↓
2. SELECT SUBJECT (e.g. Indian Polity, Economy, History)
   - Discovered from curriculum domains or question corpus subjects.
                   ↓
3. SELECT TOPIC (e.g. Fundamental Rights, Basic Structure, Emergency Provisions)
   - Displays topic details, available question count, and associated Learning Objective.
                   ↓
4. RESOLVE LEARNING OBJECTIVE & STATE
   - Maps topic to canonical LearningObjective (e.g. lo_article_21_foundations).
   - Inspects AuthoritativeLearnerState for prior attempts / mastery.
   - Inspects SessionCheckpointRepository for in-flight sessions.
                   ↓
5. BRANCH DETERMINISTICALLY:
   ├─ If uncompleted checkpoint exists → ACTION: "Resume Learning"
   ├─ If unassessed (cold start)       → ACTION: "Take Diagnostic"
   ├─ If weak spot detected (< 60%)    → ACTION: "Start Remedial Lesson"
   └─ If ready for practice            → ACTION: "Start Adaptive Practice"
                   ↓
6. LAUNCH ADAPTIVE PRACTICE / DIAGNOSTIC
   - Invokes AdaptivePracticePage with topic, examId, corpus, and resume parameters.
```

---

## 4. Architectural Boundaries & Clean Design

1. **Domain Entities** (`packages/garuda_learning/lib/domain/entities/content_learning_path.dart`):
   - `ExamContext`: `id`, `code`, `name`, `category`, `conductingBody`, `isAvailable`.
   - `SubjectContext`: `id`, `name`, `examId`, `topicCount`.
   - `TopicContext`: `id`, `name`, `subjectId`, `examId`, `objectiveId`, `objectiveTitle`, `description`, `questionCount`, `hasPyqContent`.
   - `ContentLearningPathState`: complete snapshot with selected exam, subject, topic, resolved objective, active session resume opportunity, authoritative progress, and recommended action.

2. **Domain Service** (`packages/garuda_learning/lib/service/content_learning_path_service.dart`):
   - Pure business logic orchestrating curriculum, PYQ corpus, learner state recovery, checkpoint detection, and decision evaluation.
   - Zero UI dependencies.

3. **Presentation Page** (`lib/pages/content_learning_path_page.dart`):
   - Learner-facing screens for:
     A. Exam selection
     B. Subject/topic selection
     C. Topic/objective details
     D. Start Learning & Resume Learning actions
     E. Truthful empty content handling when no questions exist for a topic
     F. Loading and error states.

4. **Integration with Existing App**:
   - Wired into `QuizForgeDashboardPage` (via Quick Actions / Content Discovery) and registered in `service_locator_init.dart`.

---

## 5. Scope Control & Rules Adherence
- Existing production source files modified: **EXACTLY 3** (`packages/garuda_learning/lib/garuda_learning.dart`, `lib/pages/quizforge_dashboard_page.dart`, `lib/core/di/service_locator_init.dart`).
- Zero Garuda Game / Unreal Engine files touched or imported.
- No fake/fabricated catalogues or numbers: truthful representations of available exams, topics, and question counts.
