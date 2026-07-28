import 'package:titan_learning_content/titan_learning_content.dart';

/// Supported content authoring file formats.
enum AuthoringFormat {
  pdf,
  docx,
  markdown,
  html,
  video,
  audio,
  images,
  interactive,
  externalResource;

  String get label {
    switch (this) {
      case AuthoringFormat.pdf:
        return 'PDF Document';
      case AuthoringFormat.docx:
        return 'Word Document (DOCX)';
      case AuthoringFormat.markdown:
        return 'Markdown Text';
      case AuthoringFormat.html:
        return 'Rich HTML Content';
      case AuthoringFormat.video:
        return 'Video Asset';
      case AuthoringFormat.audio:
        return 'Audio Stream';
      case AuthoringFormat.images:
        return 'Infographic / Image Asset';
      case AuthoringFormat.interactive:
        return 'Interactive Widget / Simulation';
      case AuthoringFormat.externalResource:
        return 'External URL Resource';
    }
  }
}

/// Publication status.
enum PublicationStatus {
  draft,
  aiGenerated,
  humanReview,
  approved,
  published,
  archived,
}

/// Comprehensive KMP Content Item Model containing required metadata fields.
class KmpAuthoringItem {
  final String id;
  final String title;
  final String description;
  final AuthoringFormat format;
  final String bodyContent;
  final String? resourceUrl;
  final String authorId;
  final String authorName;
  final String? reviewerId;
  final String source;
  final String copyrightNotice;
  final String licence;
  final String version;
  final String language;
  final String difficultyLevel;
  final int estimatedStudyTimeMinutes;
  final List<String> learningObjectives;
  final List<String> prerequisites;
  final List<String> learningOutcomes;
  final bool isAiGenerated;
  final PublicationStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const KmpAuthoringItem({
    required this.id,
    required this.title,
    required this.description,
    required this.format,
    required this.bodyContent,
    this.resourceUrl,
    required this.authorId,
    required this.authorName,
    this.reviewerId,
    this.source = 'TITAN Original',
    this.copyrightNotice = '© 2026 Project TITAN Educational Systems',
    this.licence = 'Proprietary Content License',
    this.version = '1.0.0',
    this.language = 'English',
    this.difficultyLevel = 'Medium',
    this.estimatedStudyTimeMinutes = 30,
    this.learningObjectives = const [],
    this.prerequisites = const [],
    this.learningOutcomes = const [],
    this.isAiGenerated = false,
    this.status = PublicationStatus.draft,
    required this.createdAt,
    required this.updatedAt,
  });

  KmpAuthoringItem copyWith({
    String? title,
    String? description,
    AuthoringFormat? format,
    String? bodyContent,
    String? resourceUrl,
    String? reviewerId,
    String? version,
    PublicationStatus? status,
    DateTime? updatedAt,
  }) {
    return KmpAuthoringItem(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      format: format ?? this.format,
      bodyContent: bodyContent ?? this.bodyContent,
      resourceUrl: resourceUrl ?? this.resourceUrl,
      authorId: authorId,
      authorName: authorName,
      reviewerId: reviewerId ?? this.reviewerId,
      source: source,
      copyrightNotice: copyrightNotice,
      licence: licence,
      version: version ?? this.version,
      language: language,
      difficultyLevel: difficultyLevel,
      estimatedStudyTimeMinutes: estimatedStudyTimeMinutes,
      learningObjectives: learningObjectives,
      prerequisites: prerequisites,
      learningOutcomes: learningOutcomes,
      isAiGenerated: isAiGenerated,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
