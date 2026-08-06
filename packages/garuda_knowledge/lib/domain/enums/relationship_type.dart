/// Enum representing relationship types between Knowledge Objects.
enum RelationshipType {
  relatedTo,
  references,
  dependsOn,
  implements,
  overrules,
  amends,
  interprets,
  supersedes,
  generates,
  derivedFrom,
  partOf,
  hasChild,
  hasParent,
  supportedBy,
  questionOn,
  currentlyRelated,
  custom;

  String toJson() => name;

  static RelationshipType fromJson(String json) {
    return RelationshipType.values.firstWhere(
      (e) => e.name == json,
      orElse: () => RelationshipType.relatedTo,
    );
  }
}
