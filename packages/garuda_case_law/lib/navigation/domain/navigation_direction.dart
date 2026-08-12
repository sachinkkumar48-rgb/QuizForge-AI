/// Traversal direction for the Knowledge Product Navigator
/// (TITAN-KO-015.0 P16).
///
/// P16 preserves the directionality of the underlying validated relationships.
/// For a query origin `O`, a reference records whether the destination is
/// reached through an edge pointing *out of* `O` (outgoing) or *into* `O`
/// (incoming). Direction is never invented: it mirrors the orientation of the
/// underlying P5 edge or association exactly. Incoming relationships are not
/// rewritten as outgoing ones — both are exposed explicitly.
library;

/// The direction of a navigation relationship relative to its origin.
enum NavigationDirection {
  /// The underlying relationship points away from the origin toward the
  /// destination (e.g. case `A` cites/relates-to case `B`; `A` engages a
  /// doctrine).
  outgoing,

  /// The underlying relationship points toward the origin; the destination is
  /// the source of that relationship (e.g. a case `B` cites the origin; a
  /// doctrine's constituent case points into the doctrine when queried from
  /// the doctrine).
  incoming,
}

extension NavigationDirectionExtension on NavigationDirection {
  /// Deterministic human-readable label for the direction.
  String get displayTitle => switch (this) {
        NavigationDirection.outgoing => 'Outgoing',
        NavigationDirection.incoming => 'Incoming',
      };

  /// Parses a direction from its serialized enum name, defaulting to
  /// [NavigationDirection.outgoing] for unknown values.
  static NavigationDirection fromName(String? name) =>
      NavigationDirection.values.firstWhere(
        (e) => e.name == name,
        orElse: () => NavigationDirection.outgoing,
      );
}
