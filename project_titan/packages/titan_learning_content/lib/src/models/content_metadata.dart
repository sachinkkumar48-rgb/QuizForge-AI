import 'package:meta/meta.dart';

/// Immutable domain model representing metadata for a learning content item.
@immutable
class ContentMetadata {
  final String author;
  final String subject;
  final String topic;
  final String difficultyLevel;
  final int estimatedDurationMinutes;
  final String format;
  final String? fileSizeFormat;
  final String language;
  final List<String> tags;
  final bool isOfflineAvailable;
  final Map<String, dynamic> metadataMap;

  ContentMetadata({
    required this.author,
    required this.subject,
    required this.topic,
    required this.difficultyLevel,
    required this.estimatedDurationMinutes,
    required this.format,
    this.fileSizeFormat,
    this.language = 'en',
    required List<String> tags,
    this.isOfflineAvailable = false,
    Map<String, dynamic>? metadataMap,
  })  : tags = List<String>.unmodifiable(tags),
        metadataMap =
            Map<String, dynamic>.unmodifiable(metadataMap ?? const {});

  ContentMetadata copyWith({
    String? author,
    String? subject,
    String? topic,
    String? difficultyLevel,
    int? estimatedDurationMinutes,
    String? format,
    String? fileSizeFormat,
    String? language,
    List<String>? tags,
    bool? isOfflineAvailable,
    Map<String, dynamic>? metadataMap,
  }) {
    return ContentMetadata(
      author: author ?? this.author,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      estimatedDurationMinutes:
          estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      format: format ?? this.format,
      fileSizeFormat: fileSizeFormat ?? this.fileSizeFormat,
      language: language ?? this.language,
      tags: tags ?? this.tags,
      isOfflineAvailable: isOfflineAvailable ?? this.isOfflineAvailable,
      metadataMap: metadataMap ?? this.metadataMap,
    );
  }

  Map<String, dynamic> toJson() => {
        'author': author,
        'subject': subject,
        'topic': topic,
        'difficultyLevel': difficultyLevel,
        'estimatedDurationMinutes': estimatedDurationMinutes,
        'format': format,
        'fileSizeFormat': fileSizeFormat,
        'language': language,
        'tags': tags,
        'isOfflineAvailable': isOfflineAvailable,
        'metadataMap': metadataMap,
      };

  factory ContentMetadata.fromJson(Map<String, dynamic> json) =>
      ContentMetadata(
        author: json['author'] as String? ?? 'TITAN Faculty',
        subject: json['subject'] as String? ?? 'General Studies',
        topic: json['topic'] as String? ?? 'General',
        difficultyLevel: json['difficultyLevel'] as String? ?? 'Intermediate',
        estimatedDurationMinutes:
            json['estimatedDurationMinutes'] as int? ?? 15,
        format: json['format'] as String? ?? 'standard',
        fileSizeFormat: json['fileSizeFormat'] as String?,
        language: json['language'] as String? ?? 'en',
        tags: (json['tags'] as List? ?? []).cast<String>(),
        isOfflineAvailable: json['isOfflineAvailable'] as bool? ?? false,
        metadataMap: json['metadataMap'] != null
            ? Map<String, dynamic>.from(json['metadataMap'] as Map)
            : null,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentMetadata &&
          runtimeType == other.runtimeType &&
          author == other.author &&
          subject == other.subject &&
          topic == other.topic &&
          difficultyLevel == other.difficultyLevel &&
          estimatedDurationMinutes == other.estimatedDurationMinutes &&
          format == other.format &&
          fileSizeFormat == other.fileSizeFormat &&
          language == other.language &&
          isOfflineAvailable == other.isOfflineAvailable &&
          _listEquals(tags, other.tags);

  @override
  int get hashCode => Object.hash(
        author,
        subject,
        topic,
        difficultyLevel,
        estimatedDurationMinutes,
        format,
        fileSizeFormat,
        language,
        isOfflineAvailable,
        Object.hashAll(tags),
      );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
