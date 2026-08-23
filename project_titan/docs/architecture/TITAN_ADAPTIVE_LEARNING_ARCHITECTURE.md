# TITAN Adaptive Learning & Remedial Intelligence Architecture

## 1. Overview & Vision
Phase 8D establishes TITAN's first production-grade Adaptive Learning & Remedial Intelligence engine within `packages/titan_quiz_ai` and `apps/quizforge_ai`.

The system implements a continuous, closed-loop learning cycle:
```
Assessment Attempt
       ↓
Performance Analysis
       ↓
Learner Profile & Bayesian Topic Mastery Update
       ↓
Weakness & Retention Trend Detection
       ↓
Difficulty Adaptation
       ↓
Spaced Review Scheduling (Ladder Intervals)
       ↓
Targeted Remedial Recommendations & Reader Deep Linking
       ↓
Adaptive Mini-Assessment / Practice Weak Areas
```

## 2. Core Principles
1. **100% Offline & Deterministic**: Zero AI token quota required for learner profile calculation, weakness detection, difficulty transitions, spaced repetition scheduling, and candidate question ranking.
2. **Zero PII & Data Privacy**: Learner profile records only store aggregated learning metrics, Bayesian probabilities, error tags, and topic accuracies. No raw PDF text or external user identifiers are persisted.
3. **Clean Architecture Boundary**:
   - `QuizForge AI` $\to$ `shared packages (titan_pdf, titan_quiz_ai, titan_quiz)` $\leftarrow$ `TITAN Reader`.
   - Reuses `ReaderDeepLinkRequest` contract from `titan_pdf` to allow precise provenance deep linking without violating architectural boundaries.

## 3. Mathematical & Algorithmic Models

### 3.1 Bayesian Smoothed Topic Mastery
To avoid extreme volatility from small sample sizes, topic mastery incorporates Bayesian smoothing:
$$M_{base} = \frac{\text{correct} + 1.0}{\text{attempts} + 2.0}$$

Rolling weighted mastery score combining recent window ($\le 5$ sessions) and lifetime Bayesian baseline:
$$M = 0.6 \cdot \text{recentAccuracy} + 0.4 \cdot M_{base}$$

Confidence metric:
$$C = \frac{\text{attempts}}{\text{attempts} + 5.0}$$

- **Weak Topic**: $M < 0.60$ or (attempts $\ge 2$ and accuracy $< 0.50$).
- **Strong Topic**: $M \ge 0.80$ and $C \ge 0.40$ (guarantees at least 4 attempts before certifying strength).

### 3.2 Dynamic Difficulty Adaptation
- **Step Down** (`hard` $\to$ `medium` $\to$ `easy`): Triggered when recent accuracy is $< 0.40$ or performance trend is `declining` with low accuracy.
- **Step Up** (`easy` $\to$ `medium` $\to$ `hard`): Triggered when recent accuracy is $\ge 0.85$ and confidence is $\ge 0.35$.
- **Maintain**: When mastery is in the stable zone ($0.50 \le \text{accuracy} < 0.85$).

### 3.3 Spaced Review Ladder
Implements expanding interval ladder:
$$\text{Intervals} = [1, 3, 7, 14, 30] \text{ days}$$
- Successful review advances streak and interval index.
- Incorrect review resets streak to 0 and interval to 1 day.

### 3.4 Multi-Tier Deterministic "Study Next" Recommendation Engine
Prioritizes next learning action based on a 6-tier deterministic hierarchy:
1. **Critical Overdue Review**: Spaced review items overdue by $\ge 2$ days.
2. **Repeated Mistake Topic**: Topics with $\ge 2$ incorrect attempts and accuracy $< 0.50$.
3. **Declining Trend Topic**: Topics with negative retention signal.
4. **Weak Area Practice**: General weak topics requiring reinforcement.
5. **New Topic Exploration**: Untested topics from ingested learning documents.
6. **First Assessment**: Empty profile initial document assessment.

### 3.5 Candidate Ranking & Anti-Repetition Strategy
Selects and ranks question candidates:
$$\text{Score} = \text{WeakBoost}(+50) + \text{InvertedMastery}((1 - M) \cdot 30) + \text{DueReviewBoost}(+40) + \text{DiffMatch}(+20) - \text{RecentExposurePenalty}(-80)$$
Recent questions (attempted within last 3 sessions) receive heavy penalty to ensure variety unless explicitly flagged as overdue review.

## 4. UI Presentation & Integration
- **`StudyNextHeroCard`**: Prominent hero card with dynamic icon, color badge, rationale, and one-tap direct action.
- **`LearnerMasteryCard`**: Visual mastery percentage breakdown, weakness tags, and overall accuracy.
- **`ReviewScheduleCard`**: Due spaced repetition items with streak indicators.
- **`PracticeWeakAreasCard`**: One-tap launch button generating adaptive practice quizzes targeting weak topics without AI.
