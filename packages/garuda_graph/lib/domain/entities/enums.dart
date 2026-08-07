library;

/// Complete semantic relationship types between nodes in the GARUDA Knowledge Graph.
enum KnowledgeRelationshipType {
  relatedTo,
  references,
  amends,
  overrules,
  interprets,
  implements,
  derivedFrom,
  affects,
  supersedes,
  partOf,
  leadsTo,
  usedIn,
  testedIn,
  supportedBy,
  questionedIn,
}

/// Editorial and verification status of a Knowledge Link.
enum LinkStatus {
  linkReviewPending,
  approved,
  rejected,
  deprecated,
}

/// Types of nodes supported in the GARUDA Knowledge Graph hierarchy.
enum NodeType {
  subject,
  module,
  topic,
  subtopic,
  concept,
  knowledgeObject,
  evidence,
  article,
  caseLaw,
  act,
  amendment,
  committee,
  pyq,
  lesson,
}
