/// Directed semantic relationship categories between Knowledge Objects in Project TITAN.
enum RelationshipType {
  /// General thematic or contextual link.
  relatedTo,

  /// Source entity clarifies, defines, or explains the target entity.
  explains,

  /// Source entity is a required foundational concept for understanding target entity.
  prerequisiteOf,

  /// Source entity was extracted, compiled, or derived from target entity.
  derivedFrom,

  /// Source entity (e.g. PYQ question) appeared in target entity (e.g. 2025 Paper).
  appearedIn,

  /// Source entity cites or references target entity.
  references,

  /// Source entity presents opposing views or contradicts target entity.
  contradicts,

  /// Source entity expands upon or elaborates target entity.
  expands,

  /// Source entity is a condensed summary of target entity.
  summarizes,
}
