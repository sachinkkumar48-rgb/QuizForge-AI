enum KmpMediaType {
  video,
  pdf,
  image,
  audio,
  infographic,
  attachment;

  String get label {
    switch (this) {
      case KmpMediaType.video:
        return 'Video Stream / File';
      case KmpMediaType.pdf:
        return 'PDF Document';
      case KmpMediaType.image:
        return 'Image Asset';
      case KmpMediaType.audio:
        return 'Audio Recording';
      case KmpMediaType.infographic:
        return 'Educational Infographic';
      case KmpMediaType.attachment:
        return 'Supplemental Attachment';
    }
  }
}

class MediaMetadata {
  final int fileSizeBytes;
  final String mimeType;
  final int? widthPixels;
  final int? heightPixels;
  final int? durationSeconds;
  final String? encodingCodec;
  final Map<String, String> customAttributes;

  const MediaMetadata({
    required this.fileSizeBytes,
    required this.mimeType,
    this.widthPixels,
    this.heightPixels,
    this.durationSeconds,
    this.encodingCodec,
    this.customAttributes = const {},
  });

  Map<String, dynamic> toJson() => {
        'fileSizeBytes': fileSizeBytes,
        'mimeType': mimeType,
        'widthPixels': widthPixels,
        'heightPixels': heightPixels,
        'durationSeconds': durationSeconds,
        'encodingCodec': encodingCodec,
        'customAttributes': customAttributes,
      };

  factory MediaMetadata.fromJson(Map<String, dynamic> json) => MediaMetadata(
        fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
        mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
        widthPixels: json['widthPixels'] as int?,
        heightPixels: json['heightPixels'] as int?,
        durationSeconds: json['durationSeconds'] as int?,
        encodingCodec: json['encodingCodec'] as String?,
        customAttributes: (json['customAttributes'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v.toString())) ??
            const {},
      );
}

class KmpMediaAsset {
  final String id;
  final String filename;
  final String title;
  final KmpMediaType type;
  final String remoteStorageUrl;
  final String? localStoragePath;
  final MediaMetadata metadata;
  final String uploadedBy;
  final DateTime uploadedAt;

  const KmpMediaAsset({
    required this.id,
    required this.filename,
    required this.title,
    required this.type,
    required this.remoteStorageUrl,
    this.localStoragePath,
    required this.metadata,
    required this.uploadedBy,
    required this.uploadedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'filename': filename,
        'title': title,
        'type': type.name,
        'remoteStorageUrl': remoteStorageUrl,
        'localStoragePath': localStoragePath,
        'metadata': metadata.toJson(),
        'uploadedBy': uploadedBy,
        'uploadedAt': uploadedAt.toIso8601String(),
      };
}
