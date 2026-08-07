import 'package:meta/meta.dart';

/// Immutable snapshot model for evidence versioning history.
@immutable
class EvidenceVersion {
  final int versionNumber;
  final DateTime createdAt;
  final String createdBy;
  final String reason;
  final String checksum;
  final int? previousVersion;
  final bool isCurrentVersion;

  const EvidenceVersion({
    required this.versionNumber,
    required this.createdAt,
    this.createdBy = 'system',
    this.reason = 'Initial creation',
    this.checksum = '',
    this.previousVersion,
    this.isCurrentVersion = true,
  });

  EvidenceVersion markPrevious() {
    return EvidenceVersion(
      versionNumber: versionNumber,
      createdAt: createdAt,
      createdBy: createdBy,
      reason: reason,
      checksum: checksum,
      previousVersion: previousVersion,
      isCurrentVersion: false,
    );
  }

  Map<String, dynamic> toJson() => {
        'versionNumber': versionNumber,
        'createdAt': createdAt.toIso8601String(),
        'createdBy': createdBy,
        'reason': reason,
        'checksum': checksum,
        'previousVersion': previousVersion,
        'isCurrentVersion': isCurrentVersion,
      };

  factory EvidenceVersion.fromJson(Map<String, dynamic> json) =>
      EvidenceVersion(
        versionNumber: (json['versionNumber'] as num?)?.toInt() ?? 1,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        createdBy: json['createdBy'] as String? ?? 'system',
        reason: json['reason'] as String? ?? 'Initial creation',
        checksum: json['checksum'] as String? ?? '',
        previousVersion: (json['previousVersion'] as num?)?.toInt(),
        isCurrentVersion: json['isCurrentVersion'] as bool? ?? true,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EvidenceVersion &&
        other.versionNumber == versionNumber &&
        other.checksum == checksum &&
        other.isCurrentVersion == isCurrentVersion;
  }

  @override
  int get hashCode => Object.hash(versionNumber, checksum, isCurrentVersion);
}
