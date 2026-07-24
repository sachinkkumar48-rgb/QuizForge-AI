/// Knowledge graph engine, graph traversal algorithms, learning paths, and M3 visualization for Project TITAN.
library titan_knowledge_graph;

export 'src/engine/knowledge_graph_engine.dart';
export 'src/models/knowledge_edge.dart';
export 'src/models/knowledge_graph.dart';
export 'src/models/knowledge_node.dart';
export 'src/models/knowledge_path.dart';
export 'src/repository/knowledge_graph_repository.dart';
export 'src/repository/knowledge_graph_repository_impl.dart';
export 'src/use_cases/build_knowledge_graph_use_case.dart';
export 'src/use_cases/find_related_topics_use_case.dart';
export 'src/use_cases/get_learning_path_use_case.dart';
export 'src/use_cases/query_knowledge_graph_use_case.dart';
export 'src/widgets/graph_node_chip.dart';
export 'src/widgets/knowledge_explorer_panel.dart';
export 'src/widgets/knowledge_graph_card.dart';
export 'src/widgets/learning_path_card.dart';
export 'src/widgets/related_topics_card.dart';
