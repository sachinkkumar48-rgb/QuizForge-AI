# Universal Flashcard Schema v1.0

## Purpose

The **Universal Flashcard Schema v1.0** specifies the data architecture, flashcard item types, spaced repetition integration parameters, and memory technique hooks for **Project SARTHI**. It provides a standardized specification for atomic active recall items optimized for high-retention learning and intelligent offline review engines.

---

## Metadata

Each flashcard element must incorporate standardized metadata fields:

| Field Name | Type | Description | Example |
| :--- | :--- | :--- | :--- |
| `card_id` | String | Unique flashcard identifier | `"POL-FR-001-FC-01"` |
| `lesson_id` | String | Parent lesson module ID | `"POL-FR-001"` |
| `subject` | String | Subject classification | `"Indian Polity"` |
| `topic` | String | Topic classification | `"Fundamental Rights"` |
| `card_type` | Enum | Classification of card prompt format | `"Atomic Fact"` |
| `memory_technique` | Enum | Applied mnemonic or cognitive anchor | `"Keyword Association"` |
| `deck_tags` | List[String] | Category tags for custom revision deck filtering | `["Polity", "Writs", "High Yield"]` |
| `version` | String | Schema / card version string | `"1.0.0"` |
| `created_at` | ISO 8601 | Card creation timestamp | `"2026-08-03T00:00:00Z"` |
| `updated_at` | ISO 8601 | Card last updated timestamp | `"2026-08-03T04:47:00Z"` |

---

## Card Types

SARTHI flashcards are categorized into four structural card types:

| Card Type | Code | Front (Prompt) Specification | Back (Response) Specification |
| :--- | :--- | :--- | :--- |
| **Atomic Fact** | `ATOMIC_FACT` | Single, unambiguous factual prompt. | Concise 1-2 sentence core fact. |
| **Cloze Deletion** | `CLOZE` | Sentence prompt containing hidden bracketed terms (`{{c1::key term}}`). | Revealed hidden term with brief context. |
| **Article / Term Definition** | `ARTICLE_DEF` | Constitutional article number or legal term. | Precise legal definition, scope, and key exception. |
| **Case Law Anchor** | `CASE_ANCHOR` | Name of landmark Supreme Court case. | Core ruling, principle established, and key constitutional article. |

---

## Spaced Repetition Fields

To power intelligent spaced repetition algorithms (such as SM-2 or FSRS), each card tracks state parameters:

| Parameter Field | Type | Description | Default / Range |
| :--- | :--- | :--- | :--- |
| `repetition_count` | Integer | Consecutive successful reviews count | `0` |
| `ease_factor` | Float | Difficulty multiplier factor | `2.5` (Range: 1.3 - 3.0) |
| `interval_days` | Integer | Scheduled days until next review | `1` day |
| `stability` | Float | FSRS memory stability rating | Calculated value |
| `difficulty_rating` | Float | FSRS card difficulty metric | Calculated value |
| `due_date` | ISO 8601 | Next calculated review timestamp | Initial review date |

---

## Hint Rules

To assist recall without prematurely revealing full answers, cards support structured progressive hints:

1. **Non-Triviality:** Hints must provide structural clues (e.g., first letter, word count, broad category) rather than giving away the core answer.
2. **Layered Progressive Hints:** Support up to 2 optional hint tiers (`Hint 1: Category Anchor`, `Hint 2: First Letter / Keyword`).
3. **No Penalty for Hint Use:** Accessing hints logs telemetry but does not reset the consecutive repetition streak to zero.

---

## Memory Techniques

Every flashcard explicitly integrates one or more cognitive memory techniques:

- **Keyword Association:** Highlighted core trigger words bolded in prompt/response.
- **Visual Mnemonic Anchors:** Short visual image descriptions or icon associations linked to abstract concepts.
- **Acronyms & Chunking:** Grouping multi-item constitutional lists into memorable acronyms (e.g., *SHARES* for right categories).
- **Contrast Pairing:** Explicit side-by-side distinction between easily confused articles or legal writs.

---

## Review Algorithm Fields

Review engines process performance grading using standard 4-point response inputs:

| Rating Code | Rating Label | Algorithm Action |
| :--- | :--- | :--- |
| `1` | **Again (Forgot)** | Reset interval to 1 day; ease factor decreases by 0.20. |
| `2` | **Hard (Struggled)** | Interval multiplied by 1.2; ease factor decreases by 0.15. |
| `3` | **Good (Recalled)** | Interval multiplied by current ease factor; ease factor unchanged. |
| `4` | **Easy (Instant)** | Interval multiplied by ease factor * 1.3; ease factor increases by 0.15. |

---

## Analytics

Individual flashcard telemetries track retention curves and card quality:

| Metric Field | Type | Description |
| :--- | :--- | :--- |
| `total_reviews` | Integer | Total number of user reviews recorded across sessions |
| `lapse_count` | Integer | Times candidate rated card as `Again` after mastering |
| `average_latency_ms` | Float | Average time taken to flip card front to back |
| `retention_score` | Float | Percentage of reviews graded `Good` or `Easy` |

---

## Review Checklist

Pre-publication checklist for content creators and AI validators:

- [ ] **Atomicity Check:** Card tests exactly one memory node / concept.
- [ ] **Prompt Clarity:** Question prompt is clear and unambiguous without hidden assumptions.
- [ ] **Response Rigor:** Answer is concise (max 30 words for facts, max 50 words for case law).
- [ ] **Spaced Repetition Compliance:** Front/Back fields properly formatted; Cloze syntax valid.
- [ ] **Mnemonic Hook:** Memory technique tag applied.

---

## Versioning

Flashcard Schema follows **Semantic Versioning (MAJOR.MINOR.PATCH)**:

- **1.0.0:** Initial Gold Standard Flashcard schema specification.
- **1.1.0:** Support for multi-media hints or additional spaced repetition algorithm parameters.
- **2.0.0:** Structural modifications to card payload fields or cloze syntax specification.

