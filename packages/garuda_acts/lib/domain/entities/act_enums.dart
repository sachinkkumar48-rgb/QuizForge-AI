library;

/// Status of an Act in legal force.
enum ActStatus {
  inForce,
  repealed,
  amended,
  pendingCommencement,
  partiallyInForce,
}

/// Primary legal category of an Act.
enum ActCategory {
  criminal,
  civil,
  constitutional,
  commercial,
  environmental,
  governance,
  tax,
  socialJustice,
  technology,
  security,
  regulatory,
}

/// Type of inter-domain relationship between Act/Section and another entity.
enum RelationshipType {
  constitution,
  caseLaw,
  doctrine,
  pyq,
  currentAffairs,
  knowledgeGraph,
  sectionReference,
  ruleSource,
  notificationSource,
  parentAct,
  amendedBy,
}

/// Editorial verification status for GARUDA engine.
enum EditorialStatus {
  draft,
  underReview,
  verified,
  productionReady,
}

/// Type of official gazette publication.
enum GazetteType {
  ordinary,
  extraordinary,
}

/// Type of section in statutory interpretation.
enum SectionType {
  substantive,
  procedural,
  penal,
  definition,
  savings,
  repealing,
  transitional,
}
