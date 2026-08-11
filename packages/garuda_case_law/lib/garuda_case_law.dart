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

// Precedent & Doctrine Graph (TITAN-KO-015.0 P5)
export 'graph/domain/doctrine_relationship_type.dart';
export 'graph/domain/legal_graph_node_type.dart';
export 'graph/domain/legal_graph_node_ref.dart';
export 'graph/domain/legal_graph_edge.dart';
export 'graph/domain/legal_graph.dart';
export 'graph/domain/legal_graph_path.dart';
export 'graph/data/legal_graph_seed.dart';
export 'graph/service/precedent_graph_service.dart';
export 'graph/service/doctrine_relationship_service.dart';
export 'graph/service/legal_graph_traversal_service.dart';
export 'graph/validation/legal_graph_validator.dart';
export 'graph/analytics/legal_graph_analytics.dart';
export 'graph/integration/garuda_knowledge_graph_bridge.dart';

// Case Law Search Engine (TITAN-KO-015.0 P6)
export 'search/domain/case_search_enums.dart';
export 'search/domain/case_search_result.dart';
export 'search/domain/case_search_suggestion.dart';
export 'search/domain/case_search_query.dart';
export 'search/domain/case_search_filters.dart';
export 'search/data/case_search_normalizer.dart';
export 'search/data/case_search_index.dart';
export 'search/service/case_search_engine.dart';

// Corpus Validation (TITAN-KO-015.0 P7)
export 'validation/corpus_validation_models.dart';
export 'validation/corpus_validator.dart';

// Export & Rendering (TITAN-KO-015.0 P8)
export 'rendering/render_format.dart';
export 'rendering/html_safety.dart';
export 'rendering/evidence_entry.dart';
export 'rendering/markdown_case_renderer.dart';
export 'rendering/html_case_renderer.dart';
export 'rendering/json_case_renderer.dart';
export 'rendering/corpus_index_renderer.dart';
export 'rendering/corpus_statistics_renderer.dart';
export 'rendering/case_export_service.dart';

// Case Discovery & Exploration (TITAN-KO-015.0 P9)
export 'discovery/domain/discovery_reason.dart';
export 'discovery/domain/related_case_result.dart';
export 'discovery/service/case_discovery_service.dart';

// Evidence-Bounded Cross-Case Analysis (TITAN-KO-015.0 P10)
export 'analysis/domain/analysis_enums.dart';
export 'analysis/domain/structural_observation.dart';
export 'analysis/domain/case_comparison.dart';
export 'analysis/domain/chronology.dart';
export 'analysis/domain/precedent_chain_analysis.dart';
export 'analysis/domain/doctrine_analysis.dart';
export 'analysis/domain/case_synthesis.dart';
export 'analysis/service/cross_case_analysis_service.dart';

// Evidence-Backed Case Explanation (TITAN-KO-015.0 P11)
export 'explanation/domain/explanation_enums.dart';
export 'explanation/domain/explanation_section.dart';
export 'explanation/domain/case_explanation.dart';
export 'explanation/service/case_explanation_service.dart';

// Evidence-Backed Doctrine Knowledge Products (TITAN-KO-015.0 P12)
export 'doctrine_product/domain/doctrine_product_enums.dart';
export 'doctrine_product/domain/doctrine_product_section.dart';
export 'doctrine_product/domain/doctrine_knowledge_product.dart';
export 'doctrine_product/service/doctrine_knowledge_product_service.dart';

// Evidence-Backed Statute / Article Knowledge Products (TITAN-KO-015.0 P13)
export 'statute_product/domain/statute_product_enums.dart';
export 'statute_product/domain/statute_product_section.dart';
export 'statute_product/domain/statute_knowledge_product.dart';
export 'statute_product/service/statute_knowledge_product_service.dart';
