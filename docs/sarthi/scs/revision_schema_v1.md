# Universal Revision Schema v1.0

## Purpose

The **Universal Revision Schema v1.0** establishes the architectural framework, revision modes, AI-driven scheduling algorithms, and review telemetry models for **Project SARTHI**. It ensures candidates achieve long-term memory retention and conceptual consolidation through structured, adaptive revision workflows.

---

## Revision Modes

SARTHI provides four distinct operational revision modes tailored to time constraints and candidate mastery:

### Quick Revision
- **Target Duration:** 3 - 5 minutes per topic.
- **Focus:** High-yield summary cards, bulleted key takeaways, article numbers, and core legal exceptions.
- **Payload Components:** Revision summary tables, high-yield flashcard decks, and key formula/article anchors.
- **Use Case:** Last-minute exam prep or daily warm-up sessions.

### Smart Revision
- **Target Duration:** 10 - 15 minutes per topic.
- **Focus:** Adaptive review targeting dynamic retention decay curves and high-yield PYQ themes.
- **Payload Components:** Mind maps, active recall flashcards, targeted misconception pairs, and 2-3 adaptive MCQs.
- **Use Case:** Daily and weekly spaced repetition routines.

### Deep Revision
- **Target Duration:** 25 - 30 minutes per topic.
- **Focus:** Complete holistic review including core concept re-reading, structural comparisons, and subjective analytical prompts.
- **Payload Components:** Full concept notes, detailed comparative tables, landmark case breakdowns, and Mains answer structure prompts.
- **Use Case:** Monthly topic consolidation or post-mock diagnostic remediation.

### Weak Topic Revision
- **Target Duration:** Variable (15 - 20 minutes).
- **Focus:** Targeted diagnostic intervention triggered by accuracy drops below threshold (<60%).
- **Payload Components:** Myth vs. Fact contrast grids, step-by-step concept deconstructions, and targeted practice sets.
- **Use Case:** Automated remediation recommended by the recommendation engine.

---

## AI Revision Logic

The AI Revision Engine dynamically customizes content delivery based on:

1. **Forgetting Curve Modeling:** Calculates decay functions $R = e^{-\frac{t}{S}}$ to trigger revision prior to memory retrieval failure.
2. **Weakness Pattern Detection:** Identifies recurring error clusters across subtopics or statement types (e.g., confusing Writ conditions).
3. **Adaptive Compression:** Dynamically truncates or expands concept explanations based on past accuracy metrics.
4. **Contextual Bridging:** Integrates dynamic current affairs updates into static revision nodes.

---

## Scheduling Rules

Revision intervals are dynamically generated based on candidate performance logs:

| Review Trigger Stage | Schedule Interval | Minimum Mastery Required |
| :--- | :--- | :--- |
| **Stage 1 (Initial Review)** | 24 Hours post-learning | Lesson completed |
| **Stage 2 (Short-Term Lock)** | 3 Days post-Stage 1 | $\ge 70\%$ MCQ accuracy |
| **Stage 3 (Medium-Term Lock)** | 7 Days post-Stage 2 | $\ge 80\%$ Flashcard recall |
| **Stage 4 (Long-Term Mastery)** | 30 Days post-Stage 3 | $\ge 85\%$ Cumulative accuracy |
| **Remediation Reset** | Immediate (within 12 Hours) | Accuracy drops $< 60\%$ |

---

## Analytics

Revision session data is captured across several key performance indicators:

| Analytics Metric | Type | Description |
| :--- | :--- | :--- |
| `revision_session_id` | String | Unique identifier for revision session |
| `mode_used` | Enum | Revision mode (`QUICK`, `SMART`, `DEEP`, `WEAK_TOPIC`) |
| `duration_seconds` | Integer | Total time spent in revision session |
| `retention_gain` | Float | Measured accuracy delta pre- vs. post-revision session |
| `cards_reviewed` | Integer | Count of flashcards reviewed during session |
| `remediation_success` | Boolean | Indicates if weak topic accuracy crossed threshold post-session |

---

## Review Checklist

Pre-deployment verification checklist for revision modules:

- [ ] **Mode Coverage:** All four revision modes defined with valid content payload references.
- [ ] **High-Yield Compression:** Quick Revision mode limited strictly to top 20% high-yield points.
- [ ] **Algorithmic Triggers:** Spaced repetition scheduling parameters validated.
- [ ] **Remediation Links:** Weak Topic payloads linked directly to diagnostic error patterns.

---

## Versioning

Revision Schema follows **Semantic Versioning (MAJOR.MINOR.PATCH)**:

- **1.0.0:** Initial Gold Standard Revision schema specification.
- **1.1.0:** Introduction of new revision modes or updated decay curve parameters.
- **2.0.0:** Structural breaking changes to revision engine payloads or scheduling interfaces.

