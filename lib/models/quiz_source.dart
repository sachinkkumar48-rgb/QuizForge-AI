class QuizSource {
  final String id;
  final String name;
  final String localPath;
  final DateTime importedAt;
  final DateTime? lastOpenedAt;
  final DateTime? lastAttemptedAt;
  final int questionCount;
  final int attemptCount;
  final int fileSize;
  final bool favorite;
  final List<String> tags;
  final int schemaVersion;

  const QuizSource({
    required this.id,
    required this.name,
    required this.localPath,
    required this.importedAt,
    this.lastOpenedAt,
    this.lastAttemptedAt,
    required this.questionCount,
    required this.attemptCount,
    required this.fileSize,
    required this.favorite,
    this.tags = const [],
    this.schemaVersion = 1,
  });

  factory QuizSource.fromJson(Map<String, dynamic> json) {
    return QuizSource(
      id: json['id'] as String,
      name: json['name'] as String,
      localPath: json['localPath'] as String,
      importedAt: DateTime.parse(json['importedAt'] as String),
      lastOpenedAt: json['lastOpenedAt'] != null
          ? DateTime.parse(json['lastOpenedAt'] as String)
          : null,
      lastAttemptedAt: json['lastAttemptedAt'] != null
          ? DateTime.parse(json['lastAttemptedAt'] as String)
          : null,
      questionCount: json['questionCount'] as int,
      attemptCount: json['attemptCount'] as int,
      fileSize: json['fileSize'] as int,
      favorite: json['favorite'] as bool? ?? false,
      tags: List<String>.from(json['tags'] ?? []),
      schemaVersion: json['schemaVersion'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'localPath': localPath,
      'importedAt': importedAt.toIso8601String(),
      'lastOpenedAt': lastOpenedAt?.toIso8601String(),
      'lastAttemptedAt': lastAttemptedAt?.toIso8601String(),
      'questionCount': questionCount,
      'attemptCount': attemptCount,
      'fileSize': fileSize,
      'favorite': favorite,
      'tags': tags,
      'schemaVersion': schemaVersion,
    };
  }

  QuizSource copyWith({
    String? id,
    String? name,
    String? localPath,
    DateTime? importedAt,
    DateTime? lastOpenedAt,
    DateTime? lastAttemptedAt,
    int? questionCount,
    int? attemptCount,
    int? fileSize,
    bool? favorite,
    List<String>? tags,
    int? schemaVersion,
  }) {
    return QuizSource(
      id: id ?? this.id,
      name: name ?? this.name,
      localPath: localPath ?? this.localPath,
      importedAt: importedAt ?? this.importedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      lastAttemptedAt: lastAttemptedAt ?? this.lastAttemptedAt,
      questionCount: questionCount ?? this.questionCount,
      attemptCount: attemptCount ?? this.attemptCount,
      fileSize: fileSize ?? this.fileSize,
      favorite: favorite ?? this.favorite,
      tags: tags ?? this.tags,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }
}
