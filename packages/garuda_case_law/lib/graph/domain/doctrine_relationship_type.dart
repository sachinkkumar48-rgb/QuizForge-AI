/// Relationship vocabulary between a landmark case and a Constitutional
/// Doctrine (TITAN-KO-015.0 P5).
///
/// These are the legal semantics of a case↔doctrine edge. They are never
/// guessed: a role is recorded only where the case record's `doctrines` field
/// or the canonical `garuda_doctrine` record itself establishes it.
library;

/// How a landmark case relates to a Constitutional Doctrine.
///
/// Ordered by specificity, so that when both a generic and a specific role are
/// evidenced for the same (case, doctrine) pair the more precise role wins.
enum DoctrineRelationshipType {
  /// The case is the originating authority of the doctrine.
  establishes,

  /// The case is a landmark authority that applies the doctrine.
  applies,

  /// The case develops / refines the doctrine in later decisions.
  develops,

  /// A later case that follows the doctrine.
  follows,

  /// A case that expands the reach of the doctrine.
  expands,

  /// A case that limits the reach of the doctrine.
  limits,

  /// A case that distinguishes the doctrine.
  distinguishes,

  /// The case engages the doctrine (curated affinity), without a more specific
  /// role being established.
  engages,
}

extension DoctrineRelationshipTypeExtension on DoctrineRelationshipType {
  /// Human-readable label used in analytics and reporting.
  String get displayName => switch (this) {
        DoctrineRelationshipType.establishes => 'Establishes',
        DoctrineRelationshipType.applies => 'Applies',
        DoctrineRelationshipType.develops => 'Develops',
        DoctrineRelationshipType.follows => 'Follows',
        DoctrineRelationshipType.expands => 'Expands',
        DoctrineRelationshipType.limits => 'Limits',
        DoctrineRelationshipType.distinguishes => 'Distinguishes',
        DoctrineRelationshipType.engages => 'Engages',
      };

  /// Specificity ordering used when several roles are evidenced for the same
  /// (case, doctrine) pair — the most specific evidenced role wins.
  int get specificity => switch (this) {
        DoctrineRelationshipType.establishes => 7,
        DoctrineRelationshipType.expands => 6,
        DoctrineRelationshipType.limits => 5,
        DoctrineRelationshipType.distinguishes => 4,
        DoctrineRelationshipType.applies => 3,
        DoctrineRelationshipType.follows => 2,
        DoctrineRelationshipType.develops => 2,
        DoctrineRelationshipType.engages => 1,
      };
}
