// Domain Entities & Enums
export 'domain/entities/case_enums.dart';
export 'domain/entities/case_knowledge_object.dart';
export 'domain/entities/precedent_relationship.dart';

// Judgment Intelligence (TITAN-KO-015.0 P4)
export 'intelligence/domain/intelligence_enums.dart';
export 'intelligence/domain/judgment_intelligence.dart';
export 'intelligence/data/judgment_intelligence_seed.dart';
export 'intelligence/data/judgment_intelligence_support.dart';
export 'intelligence/service/judgment_intelligence_service.dart';
export 'intelligence/service/upsc_intelligence_engine.dart';
export 'intelligence/search/judgment_intelligence_search.dart';
export 'intelligence/analytics/judgment_intelligence_analytics.dart';
export 'intelligence/validation/judgment_intelligence_validator.dart';
export 'intelligence/editorial/judgment_intelligence_editorial_service.dart';

// Data Seed Corpus
export 'data/case_seed_data.dart';
export 'data/landmark_cases_phase1.dart';
export 'data/landmark_cases_phase2.dart';
export 'data/case_official_sources.dart';
export 'data/case_corpus_support.dart';

// Analyzer & Repositories
export 'analyzer/case_analyzer.dart';
export 'repositories/case_repository.dart';
export 'repositories/in_memory_case_repository.dart';

// Validators
export 'validators/case_validator.dart';
