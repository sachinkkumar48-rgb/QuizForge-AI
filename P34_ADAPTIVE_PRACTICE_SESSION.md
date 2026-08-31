# P34: Adaptive Practice Session Orchestration

## Overview & Architecture

Project TITAN — QuizForge-AI Practice Intelligence Pipeline.

P34 implements the deterministic **Practice Session Orchestration** layer in `garuda_learning`. It converts P33-selected question candidates (`AdaptiveQuestionSelectionResult`) into an evidence-ready, structured practice session specification (`AdaptivePracticeSessionSpec`).

```
QUESTION CORPUS (P29 / P30 NormalizedQuestion)
         │
         ▼
HISTORICAL INTELLIGENCE (P31 ExamIntelligenceProfile)
         │
         ▼
LEARNING PRIORITY SIGNALS (P32 PyqLearningPriorityProfile)
         │
         ▼
LEARNER DIAGNOSTICS & ATTEMPTS (P23 WeakSpotProfile & P18 Progress)
         │
         ▼
ADAPTIVE QUESTION SELECTION (P33 AdaptiveQuestionSelectionResult)
         │
         ▼
P34 ADAPTIVE PRACTICE SESSION ORCHESTRATION LAYER
├── 1. Validation & Multi-Exam Check
├── 2. Deterministic Deduplication
├── 3. Mode-Specific Pedagogical Ordering
├── 4. Objective & Topic Balancing Policies
├── 5. Difficulty Progression (Easy -> Medium -> Hard)
├── 6. Pedagogical Section Construction (e.g. 5 questions/section)
├── 7. Multi-Dimensional Distribution Analytics
├── 8. Deterministic SHA-256 Session Fingerprint
└── 9. Workload & Time Estimation (e.g. 60s/question)
         │
         ▼
EVIDENCE-READY SPECIFICATION (AdaptivePracticeSessionSpec)
         │
         ▼ (Adapter: toLearningSession)
P19 LEARNING SESSION LIFECYCLE (Execution & Attempt Persistence)
```

---

## 1. Product Boundary & Invariants

### What P34 Owns
- **Question Organization & Sequencing**: How selected questions are arranged for effective, coherent practice.
- **Section Construction**: Partitioning practice questions into structured pedagogical blocks.
- **Distribution Summaries**: Objective, topic, year, difficulty, historical PYQ, and learner weakness summaries.
- **Deterministic Session Identity**: Stable SHA-256 fingerprint generated from session inputs.
- **Workload Estimation**: Declarative time estimates based on configured seconds per question.

### What P34 Does NOT Own
- **P18**: Learner attempt recording, attempt evaluation, and mastery progression.
- **P19**: Session persistence, active timer ticking, attempt logging, and completion state machine.
- **P20**: SM-2 spaced repetition interval calculation, ease factor adjustment, and review scheduling.
- **P21 / P22**: Learning recommendations and effectiveness measurements.
- **P23**: Learner analytics, retention modeling, and diagnostic weak spot profiles.
- **P24**: Study planning, daily agenda generation, and time budgeting.
- **P25**: Remedial lesson generation and content authoring.
- **P26**: Diagnostic placement tests and assessment scoring.
- **P29 / P30 / P31**: Question ingestion, normalization, and historical PYQ corpus analytics.
- **P32**: Deterministic PYQ learning priority profile calculation.
- **P33**: Adaptive question selection and candidate filtering.

---

## 2. Session Modes

| Mode | Description & Composition Rule |
|---|---|
| `standard` | Pedagogical 4-stage block sequencing: 1. Warm-up (foundational/fresh) $\to$ 2. Core Weak Areas (high deficiency) $\to$ 3. High-Yield PYQs (high recurrence) $\to$ 4. Reinforcement (consolidation). |
| `weaknessFocused` | Orders questions strictly by observed learner weakness descending ($W(q)$ DESC) with tie-breakers. |
| `pyqFocused` | Orders questions strictly by historical PYQ priority descending ($P(q)$ DESC) with tie-breakers. |
| `balanced` | Interleaves questions evenly across syllabus topics and learning objectives via round-robin distribution. |
| `remedialPractice` | Targets diagnosed weak objectives first with progressive difficulty ordering (Easy $\to$ Medium $\to$ Hard). |
| `mixedRevision` | Round-robin interleaves across distinct topics for varied review practice. |

---

## 3. Balancing Policies & Difficulty Progression

### Objective & Topic Balancing
- `ObjectiveBalancingPolicy.none`: Preserves raw priority-ranked sequence.
- `ObjectiveBalancingPolicy.balanced`: Round-robins across distinct learning objectives.
- `ObjectiveBalancingPolicy.priorityWeighted`: Prioritizes objectives with higher P32 learning priority.
- `TopicBalancingPolicy.none`: Preserves raw priority-ranked sequence.
- `TopicBalancingPolicy.balanced`: Round-robins across syllabus topics.

### Difficulty Progression
- `PracticeDifficultyProgression.none`: Preserves mode-determined sequence.
- `PracticeDifficultyProgression.easyToHard`: Sorts Easy (0) $\to$ Medium (1) $\to$ Hard (2) $\to$ Unspecified (1.5).
- `PracticeDifficultyProgression.mediumToHard`: Sorts Medium (0) $\to$ Hard (1) $\to$ Easy (2) $\to$ Unspecified (1.5).

---

## 4. Multi-Dimensional Distribution Analytics

The session specification includes full distribution analytics calculated over the selected practice questions:
- `objectiveCounts`: Question count per mapped objective.
- `topicCounts`: Question count per syllabus topic.
- `yearCounts`: Question count per examination year.
- `difficultyCounts`: Question count per difficulty tier (`easy`, `medium`, `hard`, `unspecified`).
- `historicalQuestionCount`: Count of verified past examination questions.
- `historicalQuestionRatio`: Ratio of PYQ questions in $[0.0, 1.0]$.
- `recentHistoricalQuestionCount`: Count of PYQs from the most recent 3 examination years.
- `nonHistoricalQuestionCount`: Count of model or non-dated practice questions.
- `highWeaknessCount`: Questions targeting learner deficiency $\ge 0.6$.
- `mediumWeaknessCount`: Questions targeting learner deficiency in $[0.2, 0.6)$.
- `lowWeaknessCount`: Questions targeting learner deficiency $< 0.2$ or unattempted areas ($0.0$).

---

## 5. Educational Safety & Non-Predictive Invariants

1. **Zero Question Fabrication**: Questions in the session are verbatim instances of `NormalizedQuestion`. Options, expected answer keys, and explanations are never modified.
2. **Zero Predictive Claims**: Strictly avoids non-deterministic assertions regarding future examinations ("will appear in next exam", "guaranteed question").
3. **Deterministic Session Identity**: `sessionId` is generated via a content-addressable SHA-256 fingerprint:
   `sess_${examId}_${sha256(examId|mode|questionIds|sectionSize|policies)}`.
4. **Order & Replay Stability**: 10 consecutive executions on identical inputs produce byte-identical JSON serialized specifications.
5. **No `DateTime.now()` Drift**: Only caller-supplied timestamps are used.

---

## 6. Performance Benchmarks

| Scope | Benchmark Duration | Requirement Target | Status |
|---|---|---|---|
| **1,000 Questions** | **4 ms** | $< 100\text{ ms}$ | **PASSED** |
| **10,000 Questions** | **35 ms** | $< 500\text{ ms}$ | **PASSED** |
| **50,000 Questions** | **107 ms** | $< 2,000\text{ ms}$ | **PASSED** |
| **100,000 Questions** | **129 ms** | $< 5,000\text{ ms}$ | **PASSED** |
