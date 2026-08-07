# Universal MCQ Schema v1.0

## Purpose

The **Universal MCQ Schema v1.0** defines the standardized data models, quality benchmarks, distractor rules, and evaluation criteria for all Multiple Choice Questions (MCQs) within **Project SARTHI**. It ensures question items are structurally rigorous, pedagogical aligned with UPSC CSE standards, fully trackable for student analytics, and compatible with AI item generation and validation pipelines.

---

## Metadata

Every MCQ item must adhere to a strict metadata model:

| Field Name | Type | Description | Example |
| :--- | :--- | :--- | :--- |
| `mcq_id` | String | Unique question identifier | `"POL-FR-001-MCQ-01"` |
| `lesson_id` | String | Parent lesson module ID | `"POL-FR-001"` |
| `subject` | String | Core subject domain | `"Indian Polity"` |
| `topic` | String | Specific topic module | `"Fundamental Rights"` |
| `subtopic` | String | Subtopic focus area | `"Articles 12-35 Classification"` |
| `question_type` | Enum | Classification of question structure | `"Multi-Statement"` |
| `difficulty_level` | Enum | Calibrated difficulty tier | `"Intermediate"` |
| `bloom_level` | Enum | Cognitive processing level | `"Analyze"` |
| `version` | String | Item schema / content version | `"1.0.0"` |
| `created_at` | ISO 8601 | Item creation timestamp | `"2026-08-03T00:00:00Z"` |
| `updated_at` | ISO 8601 | Item last updated timestamp | `"2026-08-03T04:47:00Z"` |

---

## Question Types

SARTHI supports five distinct MCQ structural formats tailored for high-stakes competitive examinations:

| Question Type | Code | Structural Description | Example Prompt Pattern |
| :--- | :--- | :--- | :--- |
| **Single Statement Direct** | `SINGLE_DIRECT` | Direct factual or conceptual question with 4 mutually exclusive options. | *"Which Article of the Constitution guarantees..."* |
| **Multi-Statement Combination** | `MULTI_STMT` | 2 to 4 numbered statements followed by option combinations (e.g., 1 and 2 only). | *"Consider the following statements... Which of the statements given above is/are correct?"* |
| **Matching Pair** | `MATCH_PAIR` | Two columns of terms/concepts to pair accurately. | *"Match List-I with List-II..."* |
| **Assertion & Reason** | `ASSERT_REASON` | Statement (A) and Reason (R) with standard evaluation of validity and causal link. | *"Assertion (A): ... Reason (R): ..."* |
| **Case Scenario Based** | `CASE_SCENARIO` | Paragraph-based factual or legal scenario requiring applied conceptual deduction. | *"A citizen is detained under statutory law... Which writ applies?"* |

---

## Difficulty Levels

Question difficulty is categorized into three calibrated tiers based on cognitive load and option complexity:

- **Easy (`EASY`):** Direct recall of articles, definitions, or basic facts; obvious distractors. Target accuracy: 75%-90%.
- **Intermediate (`INTERMEDIATE`):** Multi-statement evaluation requiring conceptual synthesis and elimination skills. Target accuracy: 45%-65%.
- **Advanced (`ADVANCED`):** Fine-grained legal nuances, edge-case exceptions, or multi-topic integration with high-plausibility distractors. Target accuracy: 25%-40%.

---

## Bloom Taxonomy

Every MCQ is mapped to Bloom's Revised Taxonomy to ensure balanced cognitive assessment:

1. **Remember (`REMEMBER`):** Retrieval of explicit constitutional articles, terms, or historical dates.
2. **Understand (`UNDERSTAND`):** Comprehension of underlying principles, doctrines, and constitutional intent.
3. **Apply (`APPLY`):** Application of legal rules or doctrines to hypothetical governance scenarios.
4. **Analyze (`ANALYZE`):** Deconstruction of complex multi-statement scenarios, identifying subtle fallacies or exceptions.
5. **Evaluate (`EVALUATE`):** Critical judgment of constitutional validity, judicial precedents, or policy impacts.

---

## Explanation Rules

Explanations must follow strict pedagogical formatting guidelines to maximize learning:

- **Statement-by-Statement Breakdown:** For multi-statement MCQs, every statement must be explicitly marked as `CORRECT` or `INCORRECT` with specific statutory/judicial justifications.
- **Primary Source Citations:** Direct references to Constitutional Articles, Supreme Court judgments, or official acts must be cited (e.g., *Article 19(1)(a)*, *Kesavananda Bharati v. State of Kerala (1973)*).
- **Why Other Options Fail:** Explanations must articulate why distractor options are wrong, not just why the correct answer is right.
- **High-Yield Key Takeaway:** Conclude with a highlighted 1-2 sentence core memory node for fast revision.

---

## Distractor Design Rules

Distractors must be crafted intentionally to test genuine conceptual clarity rather than trickery:

1. **Plausibility:** All distractors must represent plausible misconceptions, partial truths, or common student memory swaps.
2. **Homogeneity:** Options must be parallel in structure, grammar, length, and detail.
3. **No Giveaways:** Avoid absolute qualifiers (*always*, *never*, *only*) unless specifically testing absolute constitutional provisions.
4. **Mutually Exclusive:** Options must not overlap logically or contain subset answers that render multiple choices correct.

---

## AI Evaluation Rules

Automated AI item validation algorithms must check:

- **Ambiguity Index:** Verify that exactly one option is indisputably correct.
- **Factual Integrity:** Cross-reference statement assertions against primary legal/constitutional reference databases.
- **Distractor Quality Score:** Measure semantic distance between options to prevent trivial elimination.
- **Bias & Clarity Filter:** Ensure gender-neutral, objective, clear language free of regional jargon.

---

## Analytics Fields

Every MCQ item captures user performance telemetries for adaptive learning:

| Analytics Field | Type | Description |
| :--- | :--- | :--- |
| `total_attempts` | Integer | Cumulative times question has been answered |
| `correct_attempts` | Integer | Total correct student responses |
| `accuracy_rate` | Float | Percentage of correct responses (`correct_attempts / total_attempts`) |
| `average_time_seconds` | Float | Mean time spent by candidates before submitting answer |
| `distractor_distribution` | Map[String, Integer] | Selection frequency per option (`A`, `B`, `C`, `D`) |
| `discrimination_index` | Float | Item discrimination power comparing top 27% vs bottom 27% scorers |

---

## Review Checklist

Content reviewers must complete this verification prior to item publication:

- [ ] **Structural Check:** Metadata fields populated correctly; valid `mcq_id` format.
- [ ] **Pedagogical Alignment:** Mapped to valid Bloom Taxonomy level and difficulty tier.
- [ ] **Content Accuracy:** Statements verified against official Constitutional text / acts.
- [ ] **Distractor Rigor:** Options are homogeneous, non-overlapping, and plausible.
- [ ] **Explanation Completeness:** All statements broken down; primary source cited.

---

## Versioning

MCQ Schema follows **Semantic Versioning (MAJOR.MINOR.PATCH)**:

- **1.0.0:** Initial Gold Standard MCQ schema specification.
- **1.1.0:** Addition of new telemetry analytics fields or question sub-types.
- **2.0.0:** Breaking changes to JSON format, option keys, or mandatory metadata model.

