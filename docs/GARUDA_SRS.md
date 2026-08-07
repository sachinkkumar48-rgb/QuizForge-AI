# Software Requirements Specification (SRS)
## Project TITAN — GARUDA AI Engine

**Document Identifier:** TITAN-SRS-GARUDA-V1.0  
**Status:** Approved Architectural Blueprint  
**Sprint:** 7.0  
**Author:** Senior Solution Architect, Project TITAN  

---

## 1. Introduction

### 1.1 Purpose
This Software Requirements Specification (SRS) defines the functional, non-functional, interface, and structural requirements for **GARUDA AI** — the flagship autonomous intelligent Learning Engine of Project TITAN. GARUDA AI powers adaptive learning, cognitive profile tracking, conversational Socratic tutoring, dynamic study planning, automated content synthesis (flashcards/notes), and intelligent spaced repetition across Project TITAN.

### 1.2 Scope
GARUDA AI operates as a decoupled, modular service layer integrated with Project TITAN's FastAPI backend and Flutter cross-platform mobile/desktop client. It does NOT alter existing legacy data schemas or core FastAPI authentication mechanisms.

---

## 2. Overall Description

### 2.1 Product Perspective
GARUDA AI serves as the core intelligence coordinator of Project TITAN. It acts as the central brain linking user attempts, knowledge graphs, LLM providers, and spaced repetition engines.

```
+-------------------------------------------------------------------+
|                        Flutter Presentation UI                    |
+-------------------------------------------------------------------+
                                  | (REST / HTTPS)
+-------------------------------------------------------------------+
|                       FastAPI API Gateway                         |
|                   (/api/v1/auth, /api/v1/quiz)                    |
+-------------------------------------------------------------------+
                                  | (Internal Router Ingress)
+-------------------------------------------------------------------+
|                         GARUDA AI MODULE                          |
|  [Conversation Engine]  [Learning Profile Engine] [Memory Engine] |
|  [Knowledge Layer]     [Recommendation Engine]   [AI Providers]  |
+-------------------------------------------------------------------+
```

### 2.2 System Functions
1. **Adaptive Tutoring & Socratic Dialogue:** Multi-turn conversational guidance powered by context-aware LLMs.
2. **Cognitive Profile Engine:** Real-time user mastery tracking, weakness identification, and retention curve modeling.
3. **Retrieval-Augmented Generation (RAG):** Context extraction from user documents (PDFs, notes, PYQs) using semantic indexing.
4. **Intelligent Spaced Repetition (SM-2+):** Dynamic scheduling of quizzes, flashcards, and revision tasks based on confidence and retention decay.
5. **Automated Content Synthesis:** Dynamic generation of flashcards, cloze deletions, concept summaries, and practice quizzes.
6. **Adaptive Study Planning:** Automated calendar generation and daily workload balancing tailored to target exam dates.

---

## 3. Functional Requirements (FR)

### 3.1 AI Service & Provider Orchestration
- **FR-01 (Multi-Provider Routing):** The system shall support pluggable AI providers (Gemini API, Anthropic Claude, OpenAI, and Local Ollama/LLM endpoints) with automatic fallback handling.
- **FR-02 (Token Streaming):** The system shall support asynchronous token streaming for conversational responses to minimize perceived latency.

### 3.2 Knowledge & RAG Layer
- **FR-03 (Document Vector Indexing):** The system shall parse, chunk, and index user documents (PDF, TXT, Markdown) into a vector knowledge store.
- **FR-04 (Semantic Retrieval):** The system shall execute top-K similarity search to retrieve relevant context snippets prior to prompting the LLM.

### 3.3 Learning Profile & Analytics Engine
- **FR-05 (Mastery Tracking):** The system shall compute subject/topic mastery scores (0.0 to 1.0) based on user response accuracy, difficulty, and confidence ratings.
- **FR-06 (Retention Curve Modeling):** The system shall estimate memory decay rates per topic using modified Ebbinghaus forgetting curve algorithms.

### 3.4 Recommendation & Revision Engine
- **FR-07 (Next-Best-Action Engine):** The system shall generate prioritized daily action items (e.g. "Revise Modern History Weak Concepts", "Take 5-Question Quiz on Polity").
- **FR-08 (Spaced Repetition Queue):** The system shall schedule flashcards and questions using an enhanced SuperMemo-2 (SM-2) algorithm.

### 3.5 Content Synthesis (Flashcards, Notes, Quizzes)
- **FR-09 (Automated Flashcard Generation):** The system shall extract atomic key-concept pairs and cloze deletions from raw user notes and document chunks.
- **FR-10 (Structured Quiz Synthesis):** The system shall generate validated multiple-choice questions (MCQs) with distractors, explanations, and difficulty ratings.

### 3.6 Conversation & Context Memory
- **FR-11 (Context-Aware Chat):** The system shall maintain session conversation memory windows and inject historical context into active prompt templates.
- **FR-12 (Socratic Guardrails):** The system shall enforce Socratic dialogue prompts that guide users toward answers rather than giving direct solutions unless requested.

---

## 4. Non-Functional Requirements (NFR)

### 4.1 Performance & Latency
- **NFR-01 (Streaming Latency):** First token TTFT (Time-To-First-Token) shall be under 1.5 seconds for streamed responses.
- **NFR-02 (API Response Time):** Non-LLM REST responses (profile, recommendation queue, schedule query) shall execute in under 200 ms.

### 4.2 Security & Privacy
- **NFR-03 (JWT Authorization):** All GARUDA endpoints must require valid JWT Bearer tokens issued by existing `app.identity`.
- **NFR-04 (Sensitive Data Redaction):** Prompt pipelines and logging layers must strip PII and sensitive user credentials prior to external LLM dispatch.

### 4.3 Reliability & Availability
- **NFR-05 (Fault Tolerance):** LLM API timeouts or rate-limit errors (429) must trigger exponential backoff and fallback provider routing without crashing the client session.
- **NFR-06 (Stateless Execution):** GARUDA backend services shall remain stateless, storing persistence in database repositories to facilitate horizontal scaling.

### 4.4 Architecture & Maintainability
- **NFR-07 (Clean Architecture Compliance):** Domain interfaces shall remain completely independent of FastAPI framework dependencies and Flutter UI packages.
- **NFR-08 (Modular Pluggability):** All sub-engines must expose explicit abstract interfaces (`IGarudaEngine`) registered via Dependency Injection containers.

---

## 5. Interface Specifications

### 5.1 API Protocol
- **Format:** JSON over HTTPS REST.
- **Base Endpoint Namespace:** `/api/v1/garuda`
- **Authentication Header:** `Authorization: Bearer <jwt_token>`
- **Request ID Header:** `X-Request-ID: <uuid_v4>`

---

## 6. Verification & Quality Acceptance Criteria

1. All GARUDA sub-modules must achieve >85% unit test coverage.
2. Static analysis (`compileall app`, `pytest`, `flutter analyze`) must return zero critical errors.
3. API routes must validate request/response payloads using Pydantic v2 schemas.
