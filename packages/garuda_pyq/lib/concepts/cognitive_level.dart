/// Cognitive levels based on Bloom's Taxonomy.
enum CognitiveLevel {
  remember,
  understand,
  apply,
  analyze,
  evaluate,
  create,
}

extension CognitiveLevelX on CognitiveLevel {
  String get label {
    switch (this) {
      case CognitiveLevel.remember:
        return 'Remember';
      case CognitiveLevel.understand:
        return 'Understand';
      case CognitiveLevel.apply:
        return 'Apply';
      case CognitiveLevel.analyze:
        return 'Analyze';
      case CognitiveLevel.evaluate:
        return 'Evaluate';
      case CognitiveLevel.create:
        return 'Create';
    }
  }
}
