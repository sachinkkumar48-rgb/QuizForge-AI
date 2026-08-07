# Universal Lesson Schema v1.0

## Purpose

The **Universal Lesson Schema v1.0** establishes the architectural blueprint and standardized content framework for all micro-lessons produced under **Project SARTHI** within Project TITAN. It ensures uniform pedagogical quality, seamless multi-format exports (web, mobile, offline engines), and optimal integration with AI-assisted content generation and evaluation workflows.

---

## Design Principles

The schema is anchored on five fundamental engineering and instructional design principles:

- **Modular:** Every lesson is composed of independent, decoupled sections that can be rendered individually, reordered, or consumed via API endpoints.
- **Reusable:** Content components (MCQs, flashcards, visual charts, revision notes) can be extracted and repurposed across revision decks, test series, and mentorship guides.
- **AI-first:** Structured with clear boundaries, strict output types, and defined AI responsibilities to enable automated generation, quality auditing, and personalized tutoring.
- **Offline-first:** Formatted in pure, lightweight Markdown with standardized JSON/YAML metadata wrappers to guarantee full local caching and offline operation.
- **Versioned:** Governed by strict semantic versioning to track content iterations, syllabus updates, and structural enhancements over time.

---

## Lesson Metadata

Every SARTHI lesson file must begin with a standardized YAML frontmatter metadata block containing the following mandatory fields:

| Field Name | Type | Description / Constraints | Example |
| :--- | :--- | :--- | :--- |
| `lesson_id` | String | Unique lesson identifier (Format: `{SUBJECT}-{TOPIC_CODE}-{INDEX}`) | `"POL-FR-001"` |
| `subject` | String | Primary subject category | `"Indian Polity"` |
| `topic` | String | Primary topic module | `"Fundamental Rights"` |
| `subtopic` | String | Specific sub-topic focus | `"Overview & Classification"` |
| `difficulty` | Enum | Difficulty tier (`Beginner`, `Intermediate`, `Advanced`) | `"Intermediate"` |
| `exam` | String | Target competitive examination | `"UPSC CSE"` |
| `estimated_duration` | String | Estimated time to complete micro-lesson | `"25 mins"` |
| `prerequisites` | List[String] | Array of prerequisite lesson IDs or topic prerequisites | `["POL-CON-001"]` |
| `learning_objectives` | List[String] | List of measurable student learning outcomes | `["Understand Articles 12-35 classification"]` |
| `tags` | List[String] | Key taxonomy tags for search and categorization | `["Polity", "Part III", "Fundamental Rights"]` |
| `version` | String | Semantic version of the lesson content | `"1.0.0"` |
| `reviewer` | String | Assigned Senior Content Engineer / Reviewer ID | `"REV-POL-04"` |
| `status` | Enum | Publication status (`Draft`, `Review`, `Approved`, `Gold Standard`) | `"Gold Standard"` |
| `created_at` | ISO 8601 | Initial file creation timestamp | `"2026-08-03T00:00:00Z"` |
| `updated_at` | ISO 8601 | Most recent update timestamp | `"2026-08-03T04:45:00Z"` |

---

## Lesson Structure

A production-ready SARTHI lesson consists of 15 mandatory structural sections arranged in sequential order.

### 1. Why This Matters
- **Purpose:** Contextualize the importance of the topic for the exam and real-world governance to drive student engagement.
- **Required Elements:** High-level relevance summary, historical/constitutional significance, and exam weightage overview.
- **Output Type:** Markdown text callout block.
- **AI Responsibility:** Synthesize syllabus connection and historical exam frequency into a compelling narrative opener.

### 2. Learning Objectives
- **Purpose:** Clearly state what the learner will know, understand, and be able to apply upon completing the lesson.
- **Required Elements:** 3-5 bulleted, action-oriented objectives adhering to Bloom's Taxonomy.
- **Output Type:** Bulleted Markdown list.
- **AI Responsibility:** Draft outcome-focused statements based on topic scope and core concepts.

### 3. AI Hook
- **Purpose:** Provide an engaging, thought-provoking scenario or dilemma to trigger active learning.
- **Required Elements:** A real-world or hypothetical problem scenario, interactive question, or paradox.
- **Output Type:** Markdown blockquote with prompt anchor.
- **AI Responsibility:** Formulate contextually relevant, thought-provoking scenarios tailored to candidate difficulty level.

### 4. Story Mode
- **Purpose:** Explain complex concepts using intuitive analogies, narrative storytelling, or real-life cases.
- **Required Elements:** Narrative arc, real-world case study or relatable metaphor, and clear bridge to formal concepts.
- **Output Type:** Extended Markdown text with italicized key metaphors.
- **AI Responsibility:** Generate relatable, memorable analogies while preserving conceptual precision.

### 5. Core Concepts
- **Purpose:** Present the primary theoretical framework, statutory/constitutional clauses, and foundational knowledge.
- **Required Elements:** Subheadings per concept, precise definitions, statutory/article references, and logical progressions.
- **Output Type:** Structured Markdown with sub-headers, bolded key terms, and summary tables.
- **AI Responsibility:** Structure concept definitions comprehensively, highlighting legal/constitutional accuracy.

### 6. Visual Learning
- **Purpose:** Enhance cognitive retention through visual diagrams, mind maps, flowcharts, or structural tables.
- **Required Elements:** Mermaid.js diagrams, structured comparison matrices, or visual flowchart specifications.
- **Output Type:** Mermaid code block (`mermaid`) or Markdown table.
- **AI Responsibility:** Construct valid syntax Mermaid diagrams (flowcharts, mindmaps) representing process or hierarchy.

### 7. Examples
- **Purpose:** Demonstrate practical applications of core concepts through concrete scenarios or judicial precedents.
- **Required Elements:** Minimum 2 illustrative examples or landmark case law breakdowns with context and key rulings.
- **Output Type:** Formatted Markdown example cards / callouts.
- **AI Responsibility:** Extract landmark cases or real-world policy scenarios illustrating concept applications.

### 8. Common Misconceptions
- **Purpose:** Preemptively correct frequent student mistakes, myths, and exam traps.
- **Required Elements:** Myth vs. Fact contrast pairs, explanation of why the myth arises, and correct mental model.
- **Output Type:** Markdown comparison table or structured side-by-side callouts.
- **AI Responsibility:** Identify high-frequency error points from student response data and contrast Myth vs. Fact.

### 9. PYQ Connection
- **Purpose:** Explicitly link lesson concepts to Previous Years Questions (Prelims & Mains).
- **Required Elements:** Reference to specific exam years, question trend analysis, and key themes tested.
- **Output Type:** Structured Markdown list with year badges.
- **AI Responsibility:** Map lesson concepts to historical PYQ databases and extract recurring question themes.

### 10. MCQ Practice
- **Purpose:** Provide immediate self-assessment to reinforce concept mastery.
- **Required Elements:** 3-5 standard MCQs with multi-statement options, answer key, and detailed explanation for each statement.
- **Output Type:** Formatted MCQ blocks (linking to or embedding schema-compliant MCQ structures).
- **AI Responsibility:** Draft exam-standard distractor options, statement-wise explanations, and difficulty ratings.

### 11. Flashcards
- **Purpose:** Support spaced repetition and high-speed active recall of key facts, articles, and definitions.
- **Required Elements:** 5-10 Front/Back flashcard pairs covering key terms, numbers, articles, and landmark cases.
- **Output Type:** Key-value or tabular Flashcard schema elements.
- **AI Responsibility:** Extract high-yield atomic facts and formulate unambiguous Q&A pairs for active recall.

### 12. Revision Summary
- **Purpose:** Offer a condensed, high-yield summary for quick review before exams.
- **Required Elements:** One-page summary, bulleted key takeaways, and quick-reference cheatsheet table.
- **Output Type:** Markdown summary box.
- **AI Responsibility:** Condense core concepts into bulleted high-yield takeaways without omitting critical facts.

### 13. Mains Practice
- **Purpose:** Develop subjective answer-writing skills and analytical depth for Mains examinations.
- **Required Elements:** 1-2 analytical Mains prompts, directive keywords (Discuss, Analyze, Critically Evaluate), and answer structuring outline.
- **Output Type:** Markdown Mains prompt block with framework outline.
- **AI Responsibility:** Generate analytical prompts aligned with contemporary trends and construct model response frameworks.

### 14. Current Affairs Link
- **Purpose:** Connect static core concepts with dynamic contemporary events, recent bills, or judicial rulings.
- **Required Elements:** Recent developments (last 12-24 months), policy relevance, and analytical perspective.
- **Output Type:** Dated Markdown news-link callout block.
- **AI Responsibility:** Cross-reference static syllabus points with recent news developments and policy updates.

### 15. Next Topic
- **Purpose:** Provide clear learning navigation and continuity into the subsequent lesson module.
- **Required Elements:** Summary of conceptual transition, recommended next lesson ID, and preliminary preview question.
- **Output Type:** Markdown navigation footer block.
- **AI Responsibility:** Recommend logically ordered follow-up lessons based on prerequisite trees.

---

## Completion Rules

A SARTHI lesson file must meet strict quality metrics before receiving the **Gold Standard** certification:

1. **Mandatory Sections Presence:** All 15 structural sections must exist in the exact defined sequence. No section may be omitted or left as an empty placeholder.
2. **Metadata Completeness:** All 15 metadata attributes must be present, valid, and fully populated in the frontmatter block.
3. **Schema Compliance:** Nested components (MCQs, Flashcards, Mains Prompts) must strictly adhere to their respective sub-schemas (`mcq_schema_v1`, `flashcard_schema_v1`, etc.).
4. **Pedagogical Audit:** The lesson must undergo automated AI quality evaluation and human reviewer sign-off, indicated by `status: Gold Standard`.

---

## Versioning Rules

Lesson documentation and schemas follow standard **Semantic Versioning (MAJOR.MINOR.PATCH)**:

- **MAJOR (X.0.0):** Incremented when structural breaking changes occur (e.g., reordering mandatory sections, schema field deprecations, or core pedagogical restructuring).
- **MINOR (1.X.0):** Incremented when new content elements, additional MCQs, flashcards, or non-breaking optional fields are added to an existing lesson.
- **PATCH (1.0.X):** Incremented for typo corrections, formatting adjustments, minor factual updates, or clarification edits.

### Version Progression Examples:
- `1.0.0` : Initial Gold Standard publication of a lesson module.
- `1.1.0` : Minor content update adding 2 new Mains prompts and updated Current Affairs link.
- `2.0.0` : Major schema overhaul re-structuring core concept blocks and updating metadata models.

---

## Review Checklist

Content Engineers and AI Auditors must execute the following checklist prior to approving a lesson:

- [ ] **Metadata Verification**
  - [ ] `lesson_id` follows standard naming convention (`SUBJECT-TOPIC-INDEX`).
  - [ ] All 15 frontmatter fields are present and valid.
  - [ ] Prerequisites and learning objectives are explicitly defined.
- [ ] **Structural Integrity**
  - [ ] All 15 mandatory sections exist in exact sequential order.
  - [ ] Headings conform to defined Markdown standards (`#`, `##`, `###`).
- [ ] **AI-First & Content Quality**
  - [ ] AI Hook and Story Mode offer clear, accurate analogies without factual distortions.
  - [ ] Visual Learning section includes valid Mermaid syntax or structured table.
  - [ ] Common Misconceptions section clearly delineates Myth vs. Fact.
  - [ ] MCQ Practice contains accurate distractor rationale and statement breakdowns.
  - [ ] Flashcards are atomic and suitable for spaced repetition engines.
- [ ] **QA & Compliance**
  - [ ] Factual data and legal/constitutional citations verified against primary sources.
  - [ ] Reviewer ID and timestamp updated upon sign-off.
  - [ ] Final status updated to `Gold Standard`.

---

## Future Extensions

Placeholders for upcoming schema expansions in subsequent minor/major releases:

- `[EXTENSION_ADAPTIVE_PATHS]` : Dynamic branching rules based on candidate mastery level.
- `[EXTENSION_MULTILINGUAL_AUDIO]` : Phonetic script hooks and audio timestamp markers for multi-language TTS.
- `[EXTENSION_INTERACTIVE_SIM]` : Schema specs for embedded web-assembly interactive policy simulations.
- `[EXTENSION_GAMIFICATION_HOOKS]` : XP rewards, achievement badges, and streak triggers mapped to lesson milestones.

