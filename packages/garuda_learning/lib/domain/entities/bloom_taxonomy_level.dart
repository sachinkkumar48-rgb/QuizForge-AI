/// Bloom's Taxonomy levels for learning objectives (TITAN-KO-017.0 P17).
library;

/// Educational cognitive complexity levels for a [LearningObjective].
enum BloomTaxonomyLevel {
  /// Recalling facts and basic concepts.
  remember,

  /// Explaining ideas or concepts.
  understand,

  /// Using information in new situations.
  apply,

  /// Drawing connections among ideas.
  analyze,

  /// Justifying a stand or decision.
  evaluate,

  /// Producing new or original work.
  create,
}

extension BloomTaxonomyLevelExtension on BloomTaxonomyLevel {
  /// Human-readable display label.
  String get displayTitle => switch (this) {
        BloomTaxonomyLevel.remember => 'Remember',
        BloomTaxonomyLevel.understand => 'Understand',
        BloomTaxonomyLevel.apply => 'Apply',
        BloomTaxonomyLevel.analyze => 'Analyze',
        BloomTaxonomyLevel.evaluate => 'Evaluate',
        BloomTaxonomyLevel.create => 'Create',
      };

  /// Parse from serialized string name.
  static BloomTaxonomyLevel fromName(String? name) {
    return BloomTaxonomyLevel.values.firstWhere(
      (e) => e.name == name,
      orElse: () => BloomTaxonomyLevel.understand,
    );
  }
}
