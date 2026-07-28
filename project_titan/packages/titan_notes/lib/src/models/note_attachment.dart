import 'package:meta/meta.dart';

/// Immutable domain model representing a file attachment attached to a smart note.
@immutable
class NoteAttachment {
  final String id;
  final String fileName;
  final String filePath;
  final String mimeType;
  final int fileSizeBytes;

  const NoteAttachment({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.mimeType,
    required this.fileSizeBytes,
  });

  NoteAttachment copyWith({
    String? id,
    String? fileName,
    String? filePath,
    String? mimeType,
    int? fileSizeBytes,
  }) {
    return NoteAttachment(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      mimeType: mimeType ?? this.mimeType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'filePath': filePath,
        'mimeType': mimeType,
        'fileSizeBytes': fileSizeBytes,
      };

  factory NoteAttachment.fromJson(Map<String, dynamic> json) => NoteAttachment(
        id: json['id'] as String,
        fileName: json['fileName'] as String,
        filePath: json['filePath'] as String,
        mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
        fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteAttachment &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          fileName == other.fileName &&
          filePath == other.filePath &&
          mimeType == other.mimeType &&
          fileSizeBytes == other.fileSizeBytes;

  @override
  int get hashCode =>
      Object.hash(id, fileName, filePath, mimeType, fileSizeBytes);
}
