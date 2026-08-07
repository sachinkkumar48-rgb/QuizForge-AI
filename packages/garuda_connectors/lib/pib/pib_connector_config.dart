library;

import 'package:meta/meta.dart';

/// Configuration options for PIB Connector execution.
@immutable
class PIBConnectorConfig {
  final String baseUrl;
  final int retryCount;
  final int timeoutSeconds;
  final String userAgent;
  final int rateLimitPerMinute;
  final int maxParallelDownloads;

  const PIBConnectorConfig({
    this.baseUrl = 'https://pib.gov.in',
    this.retryCount = 3,
    this.timeoutSeconds = 30,
    this.userAgent = 'ProjectTITAN-GARUDA/1.0 (India Govt Information Engine)',
    this.rateLimitPerMinute = 60,
    this.maxParallelDownloads = 5,
  });

  Map<String, dynamic> toJson() => {
        'baseUrl': baseUrl,
        'retryCount': retryCount,
        'timeoutSeconds': timeoutSeconds,
        'userAgent': userAgent,
        'rateLimitPerMinute': rateLimitPerMinute,
        'maxParallelDownloads': maxParallelDownloads,
      };

  factory PIBConnectorConfig.fromJson(Map<String, dynamic> json) =>
      PIBConnectorConfig(
        baseUrl: json['baseUrl'] as String? ?? 'https://pib.gov.in',
        retryCount: (json['retryCount'] as num?)?.toInt() ?? 3,
        timeoutSeconds: (json['timeoutSeconds'] as num?)?.toInt() ?? 30,
        userAgent: json['userAgent'] as String? ??
            'ProjectTITAN-GARUDA/1.0 (India Govt Information Engine)',
        rateLimitPerMinute:
            (json['rateLimitPerMinute'] as num?)?.toInt() ?? 60,
        maxParallelDownloads:
            (json['maxParallelDownloads'] as num?)?.toInt() ?? 5,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PIBConnectorConfig &&
        other.baseUrl == baseUrl &&
        other.rateLimitPerMinute == rateLimitPerMinute;
  }

  @override
  int get hashCode => Object.hash(baseUrl, rateLimitPerMinute);
}
