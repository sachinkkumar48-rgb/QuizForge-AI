/// GARUDA Knowledge Graph & Knowledge Linking Engine Package for Project TITAN.
library;

// Domain Entities & Repositories
export 'domain/entities/enums.dart';
export 'domain/entities/knowledge_link.dart';
export 'domain/entities/knowledge_node_ref.dart';
export 'domain/repositories/knowledge_graph_repository.dart';

// Events
export 'events/knowledge_graph_events.dart';

// Infrastructure Storage
export 'infrastructure/in_memory_knowledge_graph_repository.dart';

// Linking Service
export 'linking/knowledge_linking_service.dart';

// Ontology Engine
export 'ontology/knowledge_ontology.dart';
export 'ontology/knowledge_ontology_node.dart';

// Scoring Engine
export 'scoring/link_score_result.dart';
export 'scoring/link_scoring_engine.dart';

// Search Engine
export 'search/knowledge_graph_search_engine.dart';

// Validation Framework
export 'validators/link_validation_result.dart';
export 'validators/link_validator_engine.dart';
