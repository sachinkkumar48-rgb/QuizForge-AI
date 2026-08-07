import 'package:meta/meta.dart';

/// Metadata accompanying an evidence object including source attributes, history, and checksum.
@immutable
class EvidenceMetadata {
  final Map<String, dynamic> customAttributes;
  final Map<String, dynamic> sourceMetadata;
  final List<String> processingHistory;
  final String checksum;

  const EvidenceMetadata({
    this.customAttributes = const {},
    this.sourceMetadata = const {},
    this.processingHistory = const [],
    this.checksum = '',
  });

  EvidenceMetadata copyWith({
    Map<String, dynamic>? customAttributes,
    Map<String, dynamic>? sourceMetadata,
    List<String>? processingHistory,
    String? checksum,
  }) {
    return EvidenceMetadata(
      customAttributes: customAttributes ?? Map<String, dynamic>.from(this.customAttributes),
      sourceMetadata: sourceMetadata ?? Map<String, dynamic>.from(this.sourceMetadata),
      processingHistory: processingHistory ?? List<String>.from(this.processingHistory),
      checksum: checksum ?? this.checksum,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customAttributes': customAttributes,
      'sourceMetadata': sourceMetadata,
      'processingHistory': processingHistory,
      'checksum': checksum,
    };
  }

  factory EvidenceMetadata.fromJson(Map<String, dynamic> json) {
    return EvidenceMetadata(
      customAttributes: Map<String, dynamic>.from(json['customAttributes'] as Map? ?? {}),
      sourceMetadata: Map<String, dynamic>.from(json['sourceMetadata'] as Map? ?? {}),
      processingHistory: (json['processingHistory'] as List?)?.map((e) => e.toString()).toList() ?? [],
      checksum: json['checksum'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EvidenceMetadata && other.checksum == checksum;
  }

  @override
  int get hashCode => checksum.hashCode;

  @override
  String toString() => 'EvidenceMetadata(checksum: $checksum)';
}
