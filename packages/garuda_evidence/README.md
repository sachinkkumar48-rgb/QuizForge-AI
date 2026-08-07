# Project TITAN - GARUDA Evidence Engine (`garuda_evidence`)

The `garuda_evidence` package is the production-ready foundation and single entry point through which all external current affairs and official data (Government Notifications, PIB Releases, Judicial Judgments, Gazette Notifications, Committee Reports, International Org Publications, etc.) enter Project TITAN.

All external information MUST pass through the GARUDA Evidence Engine before entering the GARUDA Knowledge Graph.

---

## Architectural Principles

- **Clean Architecture**: Clear separation of Domain, Application, and Infrastructure layers.
- **SOLID & DDD**: Rich immutable domain entities encapsulating core business behavior.
- **Repository Pattern**: Abstract data contracts with offline-first in-memory persistence.
- **Dependency Injection**: Decoupled validators, collectors, and repositories.
- **Offline & JSON First**: Immutable models with 100% JSON roundtrip serialization.
- **Test Driven Development (TDD)**: 100% test pass rate with zero static analysis errors and zero warnings.

---

## Folder Structure

```
packages/garuda_evidence/
├── lib/
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── enums.dart
│   │   │   ├── evidence_attachment.dart
│   │   │   ├── evidence_authority.dart
│   │   │   ├── evidence_metadata.dart
│   │   │   ├── evidence_object.dart
│   │   │   ├── evidence_relationship.dart
│   │   │   ├── evidence_search_query.dart
│   │   │   ├── evidence_source.dart
│   │   │   ├── evidence_tag.dart
│   │   │   └── knowledge_object_links.dart
│   │   ├── repositories/
│   │   │   └── evidence_repository.dart
│   │   └── usecases/
│   │       ├── collect_evidence_usecase.dart
│   │       ├── link_knowledge_object_usecase.dart
│   │       ├── search_evidence_usecase.dart
│   │       ├── store_evidence_usecase.dart
│   │       └── validate_evidence_usecase.dart
│   ├── infrastructure/
│   │   ├── collectors/
│   │   │   ├── base_evidence_collector.dart
│   │   │   ├── collector_stubs.dart
│   │   │   └── evidence_collector.dart
│   │   ├── validators/
│   │   │   ├── authority_validator.dart
│   │   │   ├── composite_evidence_validator.dart
│   │   │   ├── date_validator.dart
│   │   │   ├── duplicate_validator.dart
│   │   │   ├── evidence_validator.dart
│   │   │   ├── json_validator.dart
│   │   │   ├── metadata_validator.dart
│   │   │   ├── url_validator.dart
│   │   │   └── validation_result.dart
│   │   └── storage/
│   │       └── in_memory_evidence_repository.dart
│   ├── services/
│   │   └── garuda_evidence_service.dart
│   ├── utils/
│   │   ├── date_utils.dart
│   │   ├── hash_utils.dart
│   │   └── url_utils.dart
│   └── garuda_evidence.dart
├── test/
│   ├── domain/entities/evidence_object_test.dart
│   ├── infrastructure/collectors/collector_stubs_test.dart
│   ├── infrastructure/validators/validator_test.dart
│   ├── infrastructure/storage/evidence_repository_test.dart
│   └── application/garuda_evidence_service_test.dart
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

---

## 17 Evidence Source Collectors

1. `PIBCollector` (PIB Releases)
2. `PRSCollector` (PRS Legislative Research)
3. `ParliamentCollector` (Parliament Documents)
4. `GazetteCollector` (Gazette Notifications)
5. `SupremeCourtCollector` (Supreme Court Judgments)
6. `HighCourtCollector` (High Court Judgments)
7. `RBICollector` (RBI Releases)
8. `SEBICollector` (SEBI Circulars)
9. `NITICollector` (NITI Aayog Reports)
10. `CAGCollector` (CAG Reports)
11. `ISROCollector` (ISRO Publications)
12. `DRDOCollector` (DRDO Publications)
13. `MinistryCollector` (Ministry Websites)
14. `WHOCollector` (WHO Reports)
15. `UNCollector` (UN Reports)
16. `IMFCollector` (IMF Publications)
17. `WorldBankCollector` (World Bank Reports)

---

## Validation Framework

The validation framework evaluates Evidence Objects across 6 core validators:
- **DuplicateValidator**: Identifies duplicate IDs and duplicate fingerprint hashes.
- **MetadataValidator**: Verifies title, source, summary, keywords, and confidence score bounds.
- **AuthorityValidator**: Ensures authority ID, name, and jurisdiction integrity.
- **DateValidator**: Enforces publication date <= retrieved date and flags future dates.
- **URLValidator**: Verifies original URL and PDF URL format conformance.
- **JSONValidator**: Validates JSON schema serialization roundtrip integrity.

---

## Knowledge Graph Support

`EvidenceObject` natively supports linking to 14 core Knowledge Graph entity types:
1. Constitution Articles
2. Case Laws
3. Acts
4. Amendments
5. Committees
6. Reports
7. Schemes
8. People
9. Institutions
10. Lessons
11. PYQs
12. Maps
13. Timeline
14. Current Affairs

---

## Integration Guide

### 1. Integration with GARUDA Knowledge Graph
`EvidenceObject` instances ingested by the Evidence Engine contain `KnowledgeObjectLinks` metadata. The GARUDA Knowledge Graph consumes verified `EvidenceObject` records and creates graph nodes/edges connecting evidence to Constitution Articles, Case Laws, Acts, PYQs, and Schemes.

### 2. Integration with SARTHI AI
SARTHI AI queries the Evidence Engine via `GarudaEvidenceService.search()` or `findByTopic()` to retrieve authenticated primary source evidence (e.g. Supreme Court judgments, NITI Aayog reports) for factual grounding, RAG context enrichment, and student query answers.

### 3. Integration with QuizForge AI
QuizForge AI uses verified `EvidenceObject` entities to generate current affairs questions, statement-based MCQs, and explanation rationales linked directly to official source URLs and publication dates.

### 4. Integration with Current Affairs Engine
The Current Affairs Engine sits directly downstream of `garuda_evidence`. It processes validated `EvidenceObject` instances, generates daily/monthly current affairs summaries, tags relevant UPSC syllabus topics, and updates static syllabus nodes.
