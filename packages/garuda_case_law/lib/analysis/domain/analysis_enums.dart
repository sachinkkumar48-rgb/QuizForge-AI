/// Enums for the Evidence-Bounded Cross-Case Analysis layer
/// (TITAN-KO-015.0 P10).
///
/// P10 makes the existing validated P3–P9 knowledge easier to compare and
/// understand. The vocabulary below is deliberately *structural* — it names
/// what can be observed deterministically from existing data, never a legal
/// conclusion about similarity, overruling, refinement or extension.
library;

/// What kind of validated structured attribute is shared by two or more
/// compared cases. Ordering is fixed for deterministic serialization.
enum SharedAttributeKind {
  /// Both cases reference the same constitutional Article (P3
  /// `relatedArticles`, normalized).
  article,

  /// Both cases reference the same Act (P3 `relatedActs`, normalized).
  act,

  /// Both cases engage the same validated doctrine (P5 case → doctrine edge).
  doctrine,

  /// Both cases name the same judge on the bench (P3 `judges`).
  judge,
}

/// What kind of deterministic structural observation an analysis emits.
///
/// Every type is an *observation over existing evidence* — never a legal
/// verdict. Ordering is fixed for deterministic serialization.
enum StructuralObservationType {
  /// Case A (year) precedes case B (year) chronologically.
  chronologicalOrder,

  /// The selection spans a determinable year range.
  chronologicalSpan,

  /// The P5 graph records an explicit case → case edge between selection
  /// members. The edge type is exposed verbatim — it is never reinterpreted.
  graphRelationship,

  /// Holdings differ across the compared cases (present/absent or content).
  holdingDifference,

  /// Ratios differ across the compared cases.
  ratioDifference,

  /// Issues differ across the compared cases.
  issueDifference,

  /// Outcomes differ across the compared cases.
  outcomeDifference,

  /// The compared cases share no structured attribute.
  noSharedAttributes,
}

/// Direction of a precedent-chain analysis over the P5 graph.
///
/// - [predecessor] — the authorities the anchor case relies on (outgoing
///   authority edges, P5 `predecessorChain`).
/// - [successor] — the cases that rely on the anchor case (incoming authority
///   edges, P5 `successorChain`).
enum PrecedentChainDirection {
  predecessor,
  successor,
}
