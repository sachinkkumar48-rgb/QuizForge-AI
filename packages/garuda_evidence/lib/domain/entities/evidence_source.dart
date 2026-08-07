import 'package:meta/meta.dart';
import 'enums.dart';

/// Represents an external information provider source in Project TITAN.
@immutable
class EvidenceSource {
  final String id;
  final String name;
  final EvidenceSourceType type;
  final String baseUrl;
  final double trustworthinessScore;
  final bool isVerified;

  const EvidenceSource({
    required this.id,
    required this.name,
    required this.type,
    required this.baseUrl,
    this.trustworthinessScore = 1.0,
    this.isVerified = true,
  });

  EvidenceSource copyWith({
    String? id,
    String? name,
    EvidenceSourceType? type,
    String? baseUrl,
    double? trustworthinessScore,
    bool? isVerified,
  }) {
    return EvidenceSource(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      baseUrl: baseUrl ?? this.baseUrl,
      trustworthinessScore: trustworthinessScore ?? this.trustworthinessScore,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'baseUrl': baseUrl,
      'trustworthinessScore': trustworthinessScore,
      'isVerified': isVerified,
    };
  }

  factory EvidenceSource.fromJson(Map<String, dynamic> json) {
    return EvidenceSource(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: EvidenceSourceType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => EvidenceSourceType.other,
      ),
      baseUrl: json['baseUrl'] as String? ?? '',
      trustworthinessScore:
          (json['trustworthinessScore'] as num?)?.toDouble() ?? 1.0,
      isVerified: json['isVerified'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EvidenceSource &&
        other.id == id &&
        other.name == name &&
        other.type == type &&
        other.baseUrl == baseUrl &&
        other.trustworthinessScore == trustworthinessScore &&
        other.isVerified == isVerified;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        type,
        baseUrl,
        trustworthinessScore,
        isVerified,
      );

  @override
  String toString() => 'EvidenceSource(id: $id, name: $name, type: $type)';
}
