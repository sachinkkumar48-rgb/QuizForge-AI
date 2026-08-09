/// Node types in the GARUDA Precedent & Doctrine Graph (TITAN-KO-015.0 P5).
library;

/// The kind of node a [LegalGraphNodeRef] references.
enum LegalGraphNodeType {
  /// A landmark case node, identified by its canonical corpus `caseId`.
  caseLaw,

  /// A Constitutional Doctrine node, identified by its canonical
  /// `garuda_doctrine` `doctrineId`.
  doctrine,
}
