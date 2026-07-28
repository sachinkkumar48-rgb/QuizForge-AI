import 'package:titan_academy/titan_academy.dart';

/// Target exam category supported by KMP for multi-domain expansion.
enum ExamCategory {
  upsc,
  bpsc,
  ssc,
  banking,
  railways,
  jee,
  neet,
  universities,
  corporateLearning;

  String get displayName {
    switch (this) {
      case ExamCategory.upsc:
        return 'UPSC Civil Services';
      case ExamCategory.bpsc:
        return 'BPSC State Services';
      case ExamCategory.ssc:
        return 'SSC CGL / CHSL';
      case ExamCategory.banking:
        return 'Banking & IBPS';
      case ExamCategory.railways:
        return 'Railways RRB';
      case ExamCategory.jee:
        return 'IIT JEE Main & Advanced';
      case ExamCategory.neet:
        return 'NEET UG Medical';
      case ExamCategory.universities:
        return 'University Higher Education';
      case ExamCategory.corporateLearning:
        return 'Corporate & Executive Learning';
    }
  }
}

/// Course difficulty level.
enum KmpDifficulty {
  beginner,
  intermediate,
  advanced,
  master;

  String get label {
    switch (this) {
      case KmpDifficulty.beginner:
        return 'Beginner';
      case KmpDifficulty.intermediate:
        return 'Intermediate';
      case KmpDifficulty.advanced:
        return 'Advanced';
      case KmpDifficulty.master:
        return 'Master / Specialization';
    }
  }
}

/// Course metadata for administrative tracking.
class KmpCourseMetadata {
  final String authorId;
  final String authorName;
  final String primaryLanguage;
  final List<String> supportedLanguages;
  final List<String> tags;
  final ExamCategory category;
  final KmpDifficulty difficulty;
  final int estimatedHours;
  final DateTime createdAt;
  final DateTime updatedAt;

  const KmpCourseMetadata({
    required this.authorId,
    required this.authorName,
    this.primaryLanguage = 'English',
    this.supportedLanguages = const ['English', 'Hindi'],
    this.tags = const [],
    this.category = ExamCategory.upsc,
    this.difficulty = KmpDifficulty.intermediate,
    this.estimatedHours = 40,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'authorId': authorId,
        'authorName': authorName,
        'primaryLanguage': primaryLanguage,
        'supportedLanguages': supportedLanguages,
        'tags': tags,
        'category': category.name,
        'difficulty': difficulty.name,
        'estimatedHours': estimatedHours,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory KmpCourseMetadata.fromJson(Map<String, dynamic> json) =>
      KmpCourseMetadata(
        authorId: json['authorId'] as String? ?? 'admin',
        authorName: json['authorName'] as String? ?? 'TITAN Content Team',
        primaryLanguage: json['primaryLanguage'] as String? ?? 'English',
        supportedLanguages: (json['supportedLanguages'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const ['English', 'Hindi'],
        tags: (json['tags'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        category: ExamCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => ExamCategory.upsc,
        ),
        difficulty: KmpDifficulty.values.firstWhere(
          (e) => e.name == json['difficulty'],
          orElse: () => KmpDifficulty.intermediate,
        ),
        estimatedHours: json['estimatedHours'] as int? ?? 40,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.now(),
      );
}

/// Administrative KMP Learning Path entity.
class KmpLearningPath {
  final String id;
  final String title;
  final String description;
  final ExamCategory targetExam;
  final List<String> courseIdsSequence;
  final bool isPublished;

  const KmpLearningPath({
    required this.id,
    required this.title,
    required this.description,
    required this.targetExam,
    required this.courseIdsSequence,
    this.isPublished = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'targetExam': targetExam.name,
        'courseIdsSequence': courseIdsSequence,
        'isPublished': isPublished,
      };

  factory KmpLearningPath.fromJson(Map<String, dynamic> json) =>
      KmpLearningPath(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        targetExam: ExamCategory.values.firstWhere(
          (e) => e.name == json['targetExam'],
          orElse: () => ExamCategory.upsc,
        ),
        courseIdsSequence: (json['courseIdsSequence'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        isPublished: json['isPublished'] as bool? ?? false,
      );
}
