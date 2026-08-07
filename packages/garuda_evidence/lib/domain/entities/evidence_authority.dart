import 'package:meta/meta.dart';
import 'enums.dart';

/// Represents the issuing or ratifying authority for an evidence object.
@immutable
class EvidenceAuthority {
  final String id;
  final String name;
  final EvidenceSourceType type;
  final String jurisdiction;
  final Map<String, dynamic> metadata;

  const EvidenceAuthority({
    required this.id,
    required this.name,
    required this.type,
    required this.jurisdiction,
    this.metadata = const {},
  });

  EvidenceAuthority copyWith({
    String? id,
    String? name,
    EvidenceSourceType? type,
    String? jurisdiction,
    Map<String, dynamic>? metadata,
  }) {
    return EvidenceAuthority(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      jurisdiction: jurisdiction ?? this.jurisdiction,
      metadata: metadata ?? Map<String, dynamic>.from(this.metadata),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'jurisdiction': jurisdiction,
      'metadata': metadata,
    };
  }

  factory EvidenceAuthority.fromJson(Map<String, dynamic> json) {
    return EvidenceAuthority(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: EvidenceSourceType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => EvidenceSourceType.other,
      ),
      jurisdiction: json['jurisdiction'] as String? ?? 'India',
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EvidenceAuthority &&
        other.id == id &&
        other.name == name &&
        other.type == type &&
        other.jurisdiction == jurisdiction;
  }

  @override
  int get hashCode => Object.hash(id, name, type, jurisdiction);

  @override
  String toString() =>
      'EvidenceAuthority(id: $id, name: $name, type: $type, jurisdiction: $jurisdiction)';
}
