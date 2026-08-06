/// Methodology used to establish a Question -> Concept mapping.
enum MappingMethod {
  manual,
  ruleBased,
  knowledgeGraphAssisted,
  futureAiSuggested,
}

extension MappingMethodX on MappingMethod {
  String get label {
    switch (this) {
      case MappingMethod.manual:
        return 'Manual';
      case MappingMethod.ruleBased:
        return 'Rule Based';
      case MappingMethod.knowledgeGraphAssisted:
        return 'Knowledge Graph Assisted';
      case MappingMethod.futureAiSuggested:
        return 'Future AI Suggested';
    }
  }
}
