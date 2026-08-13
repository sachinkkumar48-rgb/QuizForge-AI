/// Learner Identity Entity (TITAN-KO-018.0 P18).
///
/// Immutable entity representing a learner profile.
library;

import 'package:meta/meta.dart';

@immutable
class Learner {
  /// Stable unique learner identifier (e.g. `learner_101`).
  final String id;

  /// Human-readable learner display name.
  final String name;

  /// Optional contact / email address.
  final String? email;

  /// Timestamp when learner profile was created.
  final DateTime createdAt;

  /// Additional metadata.
  final Map<String, String> metadata;

  Learner({
    required this.id,
    required this.name,
    this.email,
    DateTime? createdAt,
    Map<String, String>? metadata,
  })  : createdAt = createdAt ?? DateTime.now().toUtc(),
        metadata = Map<String, String>.unmodifiable(metadata ?? const {}) {
    if (id.trim().isEmpty) {
      throw ArgumentError('Learner ID cannot be empty');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError('Learner name cannot be empty');
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (email != null) 'email': email,
        'createdAt': createdAt.toIso8601String(),
        'metadata': metadata,
      };

  factory Learner.fromJson(Map<String, dynamic> json) => Learner(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        email: json['email'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String).toUtc()
            : null,
        metadata: Map<String, String>.from(
            json['metadata'] as Map? ?? const <String, String>{}),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Learner &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          _mapEquals(metadata, other.metadata);

  @override
  int get hashCode => Object.hash(id, name, email);

  @override
  String toString() => 'Learner($id, $name)';

  static bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (b[key] != a[key]) return false;
    }
    return true;
  }
}
