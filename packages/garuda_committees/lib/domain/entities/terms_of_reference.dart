library;

import 'package:meta/meta.dart';

/// Immutable model for a Committee's official Terms of Reference (TOR).
@immutable
class TermsOfReference {
  final String id;
  final String description;
  final String scope;
  final List<String> focusAreas;

  const TermsOfReference({
    required this.id,
    required this.description,
    this.scope = '',
    this.focusAreas = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'scope': scope,
        'focusAreas': focusAreas,
      };

  factory TermsOfReference.fromJson(Map<String, dynamic> json) => TermsOfReference(
        id: json['id'] as String? ?? '',
        description: json['description'] as String? ?? '',
        scope: json['scope'] as String? ?? '',
        focusAreas: (json['focusAreas'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      );
}
