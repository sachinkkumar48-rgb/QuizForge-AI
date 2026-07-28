import 'package:meta/meta.dart';

/// Immutable domain entity representing video technical metadata.
@immutable
class VideoMetadata {
  final String resolution;
  final int frameRate;
  final String codec;
  final int bitRateBps;
  final double aspectRatio;
  final bool isHls;
  final int durationSeconds;
  final String thumbnailUri;

  const VideoMetadata({
    required this.resolution,
    this.frameRate = 30,
    this.codec = 'h264',
    this.bitRateBps = 2500000,
    this.aspectRatio = 1.7777777777777777, // 16:9
    this.isHls = true,
    required this.durationSeconds,
    required this.thumbnailUri,
  });

  VideoMetadata copyWith({
    String? resolution,
    int? frameRate,
    String? codec,
    int? bitRateBps,
    double? aspectRatio,
    bool? isHls,
    int? durationSeconds,
    String? thumbnailUri,
  }) {
    return VideoMetadata(
      resolution: resolution ?? this.resolution,
      frameRate: frameRate ?? this.frameRate,
      codec: codec ?? this.codec,
      bitRateBps: bitRateBps ?? this.bitRateBps,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      isHls: isHls ?? this.isHls,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      thumbnailUri: thumbnailUri ?? this.thumbnailUri,
    );
  }

  Map<String, dynamic> toJson() => {
        'resolution': resolution,
        'frameRate': frameRate,
        'codec': codec,
        'bitRateBps': bitRateBps,
        'aspectRatio': aspectRatio,
        'isHls': isHls,
        'durationSeconds': durationSeconds,
        'thumbnailUri': thumbnailUri,
      };

  factory VideoMetadata.fromJson(Map<String, dynamic> json) => VideoMetadata(
        resolution: json['resolution'] as String? ?? '1080p',
        frameRate: json['frameRate'] as int? ?? 30,
        codec: json['codec'] as String? ?? 'h264',
        bitRateBps: json['bitRateBps'] as int? ?? 2500000,
        aspectRatio:
            (json['aspectRatio'] as num? ?? 1.7777777777777777).toDouble(),
        isHls: json['isHls'] as bool? ?? true,
        durationSeconds: json['durationSeconds'] as int? ?? 0,
        thumbnailUri: json['thumbnailUri'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoMetadata &&
          runtimeType == other.runtimeType &&
          resolution == other.resolution &&
          frameRate == other.frameRate &&
          codec == other.codec &&
          bitRateBps == other.bitRateBps &&
          aspectRatio == other.aspectRatio &&
          isHls == other.isHls &&
          durationSeconds == other.durationSeconds &&
          thumbnailUri == other.thumbnailUri;

  @override
  int get hashCode => Object.hash(
        resolution,
        frameRate,
        codec,
        bitRateBps,
        aspectRatio,
        isHls,
        durationSeconds,
        thumbnailUri,
      );
}
