# Universal Progress Schema v1.0

## Purpose

The **Universal Progress Schema v1.0** defines the telemetry data models, mastery calculation frameworks, analytics indicators, and recommendation engine feeds for **Project SARTHI**. It provides a comprehensive model for tracking candidate proficiency, identifying knowledge deficits, and generating personalized learning paths.

---

## Mastery Levels

Candidate proficiency per subtopic/topic is classified into five progressive mastery tiers:

| Mastery Level | Code | Threshold Criteria | Description |
| :--- | :--- | :--- | :--- |
| **Novice** | `NOVICE` | Lesson unread or $<40\%$ MCQ accuracy | Initial exposure; foundational concepts incomplete. |
| **Developing** | `DEVELOPING` | Lesson read; MCQ accuracy 40% - 59% | Basic understanding; frequent distractor errors. |
| **Proficient** | `PROFICIENT` | MCQ accuracy 60% - 74%; 2+ revisions | Functional mastery; ready for standard practice. |
| **Advanced** | `ADVANCED` | MCQ accuracy 75% - 89%; 3+ revisions | Strong conceptual grip; minor legal nuance gaps. |
| **Mastered (Gold)** | `MASTERED` | Cumulative accuracy $\ge 90\%$; Mains evaluated | Exceptional retention; exam-ready performance. |

---

## Learning Metrics

Captures engagement and coverage metrics across lessons and subjects:

- `lessons_completed`: Total count of micro-lessons marked complete.
- `syllabus_coverage_pct`: Percentage of total target exam syllabus completed ($0.0\% - 100.0\%$).
- `learning_time_seconds`: Total active time spent studying lesson modules.
- `streak_days`: Consecutive days of active learning platform engagement.

---

## Revision Metrics

Tracks candidate adherence to spaced repetition and review schedules:

- `total_revisions_completed`: Total revision sessions completed across all topics.
- `spaced_repetition_adherence`: Percentage of scheduled revision items completed on or before due date ($0.0\% - 100.0\%$).
- `cards_mastered`: Count of active recall flashcards with interval $>30$ days.
- `retention_rate_pct`: Percentage of flashcards correctly recalled during review sessions.

---

## MCQ Metrics

Tracks quantitative performance across practice questions and test series:

- `total_mcqs_attempted`: Cumulative number of MCQs attempted.
- `overall_accuracy_pct`: Global MCQ accuracy percentage (`correct_attempts / total_mcqs_attempted * 100`).
- `average_time_per_mcq`: Mean time taken to answer a single MCQ (seconds).
- `difficulty_breakdown`: Map tracking accuracy across `EASY`, `INTERMEDIATE`, and `ADVANCED` tiers.

---

## Mains Metrics

Tracks qualitative evaluation metrics for subjective answer writing:

- `mains_answers_submitted`: Count of subjective Mains practice answers evaluated.
- `average_mains_score_pct`: Mean score achieved relative to max marks ($0.0\% - 100.0\%$).
- `structure_clarity_rating`: Rubric score for intro-body-conclusion structuring (scale 1-5).
- `case_law_integration_score`: Rubric score for legal precedent/constitutional article usage (scale 1-5).

---

## Confidence Score

The **Confidence Score** ($CS \in [0, 100]$) represents candidate readiness for a specific topic, calculated via weighted aggregation:

$$CS = (0.35 \times \text{MCQ Accuracy}) + (0.25 \times \text{Revision Retention}) + (0.20 \times \text{Mains Score}) + (0.20 \times \text{Syllabus Coverage})$$

- High Confidence: $CS \ge 80$
- Moderate Confidence: $50 \le CS < 80$
- Low Confidence (Action Required): $CS < 50$

---

## Recommendation Engine Inputs

The Progress Schema feeds structured data into the AI Recommendation Engine to generate real-time study plans:

- `weakness_flags`: List of topic IDs where $CS < 50$ or MCQ accuracy $<60\%$.
- `due_revisions`: List of topics with overdue spaced repetition review dates.
- `next_best_action`: Recommended learning activity (`READ_LESSON`, `REVISE_CARDS`, `PRACTICE_MCQ`, `WRITE_MAINS`).
- `predicted_readiness`: Estimated probability of clearing topic-level exam questions.

---

## Dashboard Metrics

Aggregated metrics surfaced on the candidate and mentor dashboards:

| Dashboard Metric | Data Type | Refresh Rate | Visual Component |
| :--- | :--- | :--- | :--- |
| **Overall Mastery Index** | Float ($0-100\%$) | Real-time | Circular Gauge Chart |
| **Weakness Heatmap** | Map[Subject, Level] | Daily | Matrix Heatmap Chart |
| **Weekly Study Velocity** | Hours / Day | Daily | Bar Graph |
| **Predicted Prelims Score** | Integer Range | Post-Mock Test | Stat Card |

---

## Review Checklist

Pre-implementation check for progress analytics services:

- [ ] **Data Model Validation:** All metrics defined with valid data types and ranges.
- [ ] **Formula Accuracy:** Confidence Score calculation verified against edge-case inputs.
- [ ] **Telemetry Hooks:** Real-time event triggers mapped for MCQ, Flashcard, and Lesson completions.
- [ ] **Privacy & Security:** Candidate progress metrics compliant with user privacy protocols.

---

## Versioning

Progress Schema follows **Semantic Versioning (MAJOR.MINOR.PATCH)**:

- **1.0.0:** Initial Gold Standard Progress schema specification.
- **1.1.0:** Addition of new telemetry metrics or updated confidence score weights.
- **2.0.0:** Structural breaking changes to metrics schema or recommendation engine inputs.

