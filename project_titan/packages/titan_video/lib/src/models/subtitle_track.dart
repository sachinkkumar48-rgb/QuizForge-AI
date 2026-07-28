import 'package:meta/meta.dart';

/// Immutable domain model representing a subtitle/closed caption track.
@immutable
class SubtitleTrack {
  final String id;
  final String languageCode;
  final String languageName;
  final String srcUri;
  final bool isDefault;

  const SubtitleTrack({
    required this.id,
    required this.languageCode,
    required this.languageName,
    required this.srcUri,
    this.isDefault = false,
  });

  SubtitleTrack copyWith({
    String? id,
    String? languageCode,
    String? languageName,
    String? srcUri,
    bool? isDefault,
  }) {
    return SubtitleTrack(
      id: id ?? this.id,
      languageCode: languageCode ?? this.languageCode,
      languageName: languageName ?? this.languageName,
      srcUri: srcUri ?? this.srcUri,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'languageCode': languageCode,
        'languageName': languageName,
        'srcUri': srcUri,
        'isDefault': isDefault,
      };

  factory SubtitleTrack.fromJson(Map<String, dynamic> json) => SubtitleTrack(
        id: json['id'] as String,
        languageCode: json['languageCode'] as String? ?? 'en',
        languageName: json['languageName'] as String? ?? 'English',
        srcUri: json['srcUri'] as String? ?? '',
        isDefault: json['isDefault'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubtitleTrack &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          languageCode == other.languageCode &&
          languageName == other.languageName &&
          srcUri == other.srcUri &&
          isDefault == other.isDefault;

  @override
  int get hashCode => Object.hash(
        id,
        languageCode,
        languageName,
        srcUri,
        isDefault,
      );
}
