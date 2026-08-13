# TITAN-KO-017.0 — P17 Learning Objectives & Curriculum Framework

## 1. Overview & Purpose
The `garuda_learning` package implements **P17 Learning Objectives & Curriculum Framework** for Project TITAN.

It provides a deterministic, versioned, evidence-backed curriculum configuration and sequence layer that organizes existing GARUDA knowledge products (P11–P16) into:
- **Curriculum Framework & Hierarchy**: `CurriculumFramework` → `CurriculumDomain` → `CurriculumUnit` → `LearningObjective`.
- **Knowledge Product Mappings**: Binds each learning objective to canonical P11–P16 Knowledge Products (`caseLaw`, `doctrine`, `provision`, `topic`, `question`).
- **Explicit Prerequisites**: Declares immutable prerequisite relationships between learning objectives. No implicit prerequisites are inferred from chronology, graph edges, or legal similarity.
- **Deterministic Sequencing**: Computes deterministic learning paths via topological sorting on explicit prerequisite DAGs with deterministic tie-breaking.
- **Validation & Provenance**: Rejects invalid knowledge-product references, dangling prerequisite IDs, self-loops, and cycles, while preserving source evidence and provenance.

> [!NOTE]
> This package is strictly a **Knowledge / Curriculum Configuration Read Layer**. It is **NOT** a learner-management system (LMS). It contains no learner profiles, user progress, scoring, adaptive algorithms, remote DBs, authentication, or AI/LLM components.

---

## 2. Architectural Boundaries & Domain Principles

### Clean Architecture & Domain-Driven Design (DDD)
- **Domain Layer (`lib/domain/`)**: Immutable entities and value objects (`LearningObjective`, `CurriculumFramework`, `CurriculumDomain`, `CurriculumUnit`, `PrerequisiteRelationship`, `KnowledgeProductMapping`, `StaticMasteryCriteria`, `CurriculumVersion`, `BloomTaxonomyLevel`).
- **Validation Layer (`lib/validation/`)**: `CurriculumValidator` enforcing graph integrity, P11–P16 product resolution, and evidence boundaries.
- **Service Layer (`lib/service/`)**: `CurriculumService` and `DeterministicSequenceResolver` providing deterministic read models and sequence calculations.
- **Data Layer (`lib/data/`)**: Static offline seed data (`CurriculumSeedData`) representing structured UPSC Constitutional Law curricula.

### Reuse of P11–P16 Knowledge Products
`garuda_learning` composes with existing P11–P16 capabilities via `KnowledgeProductReference` and `KnowledgeProductNavigatorService`:
- **P11**: Case Explanations (`KnowledgeProductType.caseLaw`)
- **P12**: Doctrine Knowledge Products (`KnowledgeProductType.doctrine`)
- **P13**: Statute / Article Knowledge Products (`KnowledgeProductType.provision`)
- **P14**: UPSC Topic Knowledge Products (`KnowledgeProductType.topic`)
- **P15**: Question Knowledge Products (`KnowledgeProductType.question`)
- **P16**: Knowledge Product Navigator (cross-referencing & canonical ID resolution)

---

## 3. Core Models & Interfaces

### 3.1 Learning Objective (`LearningObjective`)
Immutable entity representing a single pedagogical goal:
- `id`: Canonical string ID (e.g. `'lo_fr_art21'`).
- `unitId`: Parent unit identifier.
- `title`: Human-readable title.
- `description`: Detailed explanation.
- `bloomLevel`: `BloomTaxonomyLevel` (`remember`, `understand`, `apply`, `analyze`, `evaluate`, `create`).
- `prerequisites`: List of `PrerequisiteRelationship` declarations.
- `supportedProducts`: List of `KnowledgeProductMapping` refs to P11–P16.
- `masteryCriteria`: `StaticMasteryCriteria` defining static coverage requirements (e.g., required product types or minimum products to cover).
- `sequenceIndex`: Deterministic ordering index within parent unit.
- `provenance`: Provenance metadata string (e.g. `'upsc_gs2_syllabus'`).

### 3.2 Prerequisite Model (`PrerequisiteRelationship`)
Explicitly declared link to a prerequisite learning objective:
- `prerequisiteObjectiveId`: Target objective ID.
- `provenance`: Source justification for the dependency.
- `isMandatory`: Whether prerequisite must precede objective in sequence.

### 3.3 Knowledge Product Mapping (`KnowledgeProductMapping`)
Binding to a canonical P11–P16 product:
- `productType`: `KnowledgeProductType` (`caseLaw`, `doctrine`, `provision`, `topic`, `question`).
- `productId`: Canonical ID (e.g., `'kesavananda_1973'`, `'basic_structure'`, `'art_21'`).
- `provisionType`: `ProvisionType` (only for provision references).
- `provenance`: Evidence/source string.
- `role`: Role of product in objective (e.g. `'foundation'`, `'leading_case'`, `'statutory_basis'`).

### 3.4 Curriculum Framework & Hierarchy
- `CurriculumFramework`: Aggregate root containing version, domains, units, objectives.
- `CurriculumDomain`: Domain grouping (e.g. `'domain_constitutional_law'`).
- `CurriculumUnit`: Unit grouping (e.g. `'unit_fundamental_rights'`).
- `CurriculumVersion`: Version descriptor (e.g. `version: '1.0.0'`).

---

## 4. Prerequisite Safety & Determinism Rules

1. **No Inferred Prerequisites**: Every prerequisite must be explicitly declared in `prerequisites`. No implicit dependencies based on dates, similarity, or graph links.
2. **Cycle & Self-Loop Rejection**: `CurriculumValidator` rejects any curriculum where `A → ... → A` or `A → A`.
3. **Invalid Reference Rejection**: Rejects references to non-existent learning objectives or non-existent P11–P16 products.
4. **Deterministic Sorting**: Sequences are sorted strictly by `(topological_level, sequenceIndex, id)`.

---

## 5. Offline Operation & Evidence Preservation
- **100% Offline**: Operates in-memory from compiled seed data or verified JSON configs.
- **Evidence Bounded**: Every mapped product carries provenance tracing to underlying GARUDA sources. No fake claims or synthetic evidence.
