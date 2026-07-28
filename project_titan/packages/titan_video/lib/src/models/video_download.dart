import 'package:meta/meta.dart';

/// Immutable domain model representing offline video download status.
@immutable
class VideoDownload {
  final String contentId;
  final String localPath;
  final int downloadedBytes;
  final int totalBytes;
  final String status; // 'pending', 'downloading', 'completed', 'failed'
  final DateTime? expiresAt;

  const VideoDownload({
    required this.contentId,
    required this.localPath,
    required this.downloadedBytes,
    required this.totalBytes,
    this.status = 'pending',
    this.expiresAt,
  });

  double get downloadPercentage {
    if (totalBytes <= 0) return 0.0;
    return (downloadedBytes / totalBytes * 100.0).clamp(0.0, 100.0);
  }

  VideoDownload copyWith({
    String? contentId,
    String? localPath,
    int? downloadedBytes,
    int? totalBytes,
    String? status,
    DateTime? expiresAt,
  }) {
    return VideoDownload(
      contentId: contentId ?? this.contentId,
      localPath: localPath ?? this.localPath,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      status: status ?? this.status,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'contentId': contentId,
        'localPath': localPath,
        'downloadedBytes': downloadedBytes,
        'totalBytes': totalBytes,
        'status': status,
        'expiresAt': expiresAt?.toIso8601String(),
      };

  factory VideoDownload.fromJson(Map<String, dynamic> json) => VideoDownload(
        contentId: json['contentId'] as String,
        localPath: json['localPath'] as String? ?? '',
        downloadedBytes: json['downloadedBytes'] as int? ?? 0,
        totalBytes: json['totalBytes'] as int? ?? 0,
        status: json['status'] as String? ?? 'pending',
        expiresAt: json['expiresAt'] != null
            ? DateTime.parse(json['expiresAt'] as String)
            : null,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoDownload &&
          runtimeType == other.runtimeType &&
          contentId == other.contentId &&
          localPath == other.localPath &&
          downloadedBytes == other.downloadedBytes &&
          totalBytes == other.totalBytes &&
          status == other.status &&
          expiresAt == other.expiresAt;

  @override
  int get hashCode => Object.hash(
        contentId,
        localPath,
        downloadedBytes,
        totalBytes,
        status,
        expiresAt,
      );
}
