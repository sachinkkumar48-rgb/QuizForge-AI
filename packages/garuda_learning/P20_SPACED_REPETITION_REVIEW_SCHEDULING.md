# TITAN-KO-020.0 P20 — Spaced Repetition & Review Scheduling

## 1. Overview & Architectural Purpose

The **Spaced Repetition & Review Scheduling** engine (P20) completes the learning loop within `garuda_learning` by introducing evidence-backed, deterministic review interval calculations based on SuperMemo 2 (SM-2).

P20 bridges **P18 Assessment & Learner Progress** and **P19 Learning Session Orchestration** by automatically scheduling review sessions for learned objectives based on empirical assessment evidence, preventing forgetting without fabricating mastery claims.

```
+-----------------------------------------------------------------------------------+
|               P20 Spaced Repetition & Review Scheduling Engine                    |
+-----------------------------------------------------------------------------------+
| Domain Entities:  ReviewItem | ReviewSchedule | ReviewResult | PerformanceRating |
| Service Engine:   SpacedRepetitionService                                         |
| Repository:       ReviewScheduleRepository | InMemoryReviewScheduleRepository    |
+-----------------------------------------------------------------------------------+
                                         |
                                         v
+-----------------------------------------------------------------------------------+
| P19 Learning Session Orchestration (SessionConfiguration, LearningSession)       |
| P18 Learner Progress & Assessment Engine (Learner, AttemptResult, ProgressTracker)|
| P17 Learning Objectives Framework (LearningObjective)                             |
+-----------------------------------------------------------------------------------+
```

---

## 2. Domain Models

### `PerformanceRating`
- `again` (grade 2): Complete recall failure. Resets interval to 1 day.
- `hard` (grade 3): Difficult recall. Moderate interval expansion (1.2x).
- `good` (grade 4): Successful recall. Standard SM-2 interval expansion (`interval * easeFactor`).
- `easy` (grade 5): Trivial recall. Accelerated SM-2 interval expansion (`interval * easeFactor * 1.3`).
- Deterministically maps scores float `[0.0, 1.0]` to ratings.

### `ReviewItem`
- `objectiveId`: P17 learning objective ID.
- `intervalDays`: Bounded between `1` and `180` days.
- `easeFactor`: Bounded between `1.3` and `2.5` (SM-2 standard).
- `nextReviewDate`: UTC timestamp when next review is due.
- `lastReviewed`: Optional UTC timestamp of last review attempt.
- `reviewCount`: Total review attempts completed.

### `ReviewResult`
- `objectiveId`: P17 target objective ID.
- `rating`: PerformanceRating enum.
- `assessmentScore`: Normalized assessment score `[0.0, 1.0]`.
- `timestamp`: UTC timestamp of assessment completion.

### `ReviewSchedule`
- Aggregate root mapping learner ID to `ReviewItem`s.
- `getDueItems(asOfDate)`: Returns due review items sorted by priority (most overdue first).

---

## 3. SuperMemo-2 (SM-2) Algorithm Integration

1. **Ease Factor Adjustment**:
   $$\text{EF}' = \text{clamp}\left(\text{EF} + \left(0.1 - (5 - q) \times (0.08 + (5 - q) \times 0.02)\right), 1.3, 2.5\right)$$
   where $q \in \{2, 3, 4, 5\}$ is the numeric grade corresponding to `PerformanceRating`.

2. **Interval Calculation**:
   - $q < 3$ (`again`): Interval resets to 1 day.
   - $q \ge 3$ (`hard`, `good`, `easy`):
     - Initial attempt ($I_{prev} \le 1$): $I' = 1$ (Hard), $3$ (Good), or $4$ (Easy).
     - Subsequent attempts ($I_{prev} > 1$):
       - Hard ($q = 3$): $I' = \text{round}(I_{prev} \times 1.2)$
       - Good ($q = 4$): $I' = \text{round}(I_{prev} \times \text{EF}')$
       - Easy ($q = 5$): $I' = \text{round}(I_{prev} \times \text{EF}' \times 1.3)$
   - Clamped to $[1, 180]$ days.

---

## 4. Verification Summary

- **P20 Domain & Service Unit Tests**: 25+ comprehensive tests covering SM-2 math, interval clamping, ease factor boundaries, schedule priority sorting, and P18/P19 integration flows.
- **Full Suite Regression**: 1,200+ tests passing across `garuda_learning` and `garuda_case_law`.
- **Static Analysis**: `flutter analyze` clean (`0` issues).
- **Formatting**: `dart format` clean (`0` unformatted files).
