/// Enum representing the type of Knowledge Object.
enum KnowledgeObjectType {
  constitutionArticle,
  amendment,
  caseLaw,
  doctrine,
  act,
  rule,
  regulation,
  committee,
  commission,
  report,
  scheme,
  institution,
  treaty,
  currentAffair,
  pyq,
  lesson,
  concept,
  microConcept,
  map,
  timeline,
  custom;

  String toJson() => name;

  static KnowledgeObjectType fromJson(String json) {
    return KnowledgeObjectType.values.firstWhere(
      (e) => e.name == json,
      orElse: () => KnowledgeObjectType.custom,
    );
  }
}
