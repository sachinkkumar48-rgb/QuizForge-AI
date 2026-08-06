library;

import 'package:meta/meta.dart';

/// Aggregated dashboard statistics for GARUDA Editorial Studio.
@immutable
class DashboardMetrics {
  final int pendingEvidenceCount;
  final int pendingLinksCount;
  final int pendingPublicationsCount;
  final int publishedTodayCount;
  final int recentlyUpdatedCount;
  final int draftObjectsCount;
  final int rejectedObjectsCount;

  const DashboardMetrics({
    this.pendingEvidenceCount = 0,
    this.pendingLinksCount = 0,
    this.pendingPublicationsCount = 0,
    this.publishedTodayCount = 0,
    this.recentlyUpdatedCount = 0,
    this.draftObjectsCount = 0,
    this.rejectedObjectsCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'pendingEvidenceCount': pendingEvidenceCount,
        'pendingLinksCount': pendingLinksCount,
        'pendingPublicationsCount': pendingPublicationsCount,
        'publishedTodayCount': publishedTodayCount,
        'recentlyUpdatedCount': recentlyUpdatedCount,
        'draftObjectsCount': draftObjectsCount,
        'rejectedObjectsCount': rejectedObjectsCount,
      };

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) =>
      DashboardMetrics(
        pendingEvidenceCount:
            (json['pendingEvidenceCount'] as num?)?.toInt() ?? 0,
        pendingLinksCount: (json['pendingLinksCount'] as num?)?.toInt() ?? 0,
        pendingPublicationsCount:
            (json['pendingPublicationsCount'] as num?)?.toInt() ?? 0,
        publishedTodayCount:
            (json['publishedTodayCount'] as num?)?.toInt() ?? 0,
        recentlyUpdatedCount:
            (json['recentlyUpdatedCount'] as num?)?.toInt() ?? 0,
        draftObjectsCount: (json['draftObjectsCount'] as num?)?.toInt() ?? 0,
        rejectedObjectsCount:
            (json['rejectedObjectsCount'] as num?)?.toInt() ?? 0,
      );
}
