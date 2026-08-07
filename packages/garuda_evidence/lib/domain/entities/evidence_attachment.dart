import 'package:meta/meta.dart';

/// Represents an attached file or binary asset associated with an evidence object.
@immutable
class EvidenceAttachment {
  final String id;
  final String title;
  final String fileType;
  final String url;
  final String mimeType;
  final String checksum;
  final int sizeInBytes;

  const EvidenceAttachment({
    required this.id,
    required this.title,
    required this.fileType,
    required this.url,
    this.mimeType = 'application/pdf',
    this.checksum = '',
    this.sizeInBytes = 0,
  });

  EvidenceAttachment copyWith({
    String? id,
    String? title,
    String? fileType,
    String? url,
    String? mimeType,
    String? checksum,
    int? sizeInBytes,
  }) {
    return EvidenceAttachment(
      id: id ?? this.id,
      title: title ?? this.title,
      fileType: fileType ?? this.fileType,
      url: url ?? this.url,
      mimeType: mimeType ?? this.mimeType,
      checksum: checksum ?? this.checksum,
      sizeInBytes: sizeInBytes ?? this.sizeInBytes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'fileType': fileType,
      'url': url,
      'mimeType': mimeType,
      'checksum': checksum,
      'sizeInBytes': sizeInBytes,
    };
  }

  factory EvidenceAttachment.fromJson(Map<String, dynamic> json) {
    return EvidenceAttachment(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      fileType: json['fileType'] as String? ?? 'pdf',
      url: json['url'] as String? ?? '',
      mimeType: json['mimeType'] as String? ?? 'application/pdf',
      checksum: json['checksum'] as String? ?? '',
      sizeInBytes: (json['sizeInBytes'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EvidenceAttachment &&
        other.id == id &&
        other.title == title &&
        other.fileType == fileType &&
        other.url == url &&
        other.mimeType == mimeType &&
        other.checksum == checksum &&
        other.sizeInBytes == sizeInBytes;
  }

  @override
  int get hashCode =>
      Object.hash(id, title, fileType, url, mimeType, checksum, sizeInBytes);

  @override
  String toString() =>
      'EvidenceAttachment(id: $id, title: $title, url: $url)';
}
