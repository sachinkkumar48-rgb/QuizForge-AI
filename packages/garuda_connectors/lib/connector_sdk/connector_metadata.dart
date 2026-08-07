library;

import 'package:garuda_evidence/garuda_evidence.dart';
import 'package:meta/meta.dart';

/// Immutable metadata descriptor describing capabilities and rules of a GARUDA Connector.
@immutable
class ConnectorMetadata {
  final String connectorName;
  final EvidenceSource source;
  final String version;
  final String maintainer;
  final bool supportsIncrementalSync;
  final bool supportsFullSync;
  final bool supportsAttachments;
  final bool supportsPdfs;
  final bool supportsHtml;
  final int rateLimitPerMinute;
  final int retryCount;
  final List<String> categories;
  final List<String> subjects;

  const ConnectorMetadata({
    required this.connectorName,
    required this.source,
    this.version = '1.0.0',
    this.maintainer = 'Project TITAN Core Team',
    this.supportsIncrementalSync = true,
    this.supportsFullSync = true,
    this.supportsAttachments = true,
    this.supportsPdfs = true,
    this.supportsHtml = true,
    this.rateLimitPerMinute = 60,
    this.retryCount = 3,
    this.categories = const [],
    this.subjects = const [],
  });

  Map<String, dynamic> toJson() => {
        'connectorName': connectorName,
        'source': source.toJson(),
        'version': version,
        'maintainer': maintainer,
        'supportsIncrementalSync': supportsIncrementalSync,
        'supportsFullSync': supportsFullSync,
        'supportsAttachments': supportsAttachments,
        'supportsPdfs': supportsPdfs,
        'supportsHtml': supportsHtml,
        'rateLimitPerMinute': rateLimitPerMinute,
        'retryCount': retryCount,
        'categories': categories,
        'subjects': subjects,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConnectorMetadata &&
        other.connectorName == connectorName &&
        other.version == version &&
        other.source == source;
  }

  @override
  int get hashCode => Object.hash(connectorName, version, source);
}
