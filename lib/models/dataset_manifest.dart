class DatasetManifest {
  final String datasetId;
  final String datasetVersion;
  final String schemaVersion;
  final String exam;
  final String paper;
  final String language;
  final String publisher;
  final String? source;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String checksum;
  final int totalQuestions;
  final Map<String, dynamic> metadata;

  DatasetManifest({
    required this.datasetId,
    required this.datasetVersion,
    this.schemaVersion = '1.0',
    required this.exam,
    required this.paper,
    this.language = 'English',
    this.publisher = 'QuizForge AI',
    this.source,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.checksum = '',
    required this.totalQuestions,
    this.metadata = const {},
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory DatasetManifest.fromJson(Map<String, dynamic> json) {
    return DatasetManifest(
      datasetId: json['datasetId'] as String? ?? '',
      datasetVersion: json['datasetVersion'] as String? ?? '1.0.0',
      schemaVersion: json['schemaVersion'] as String? ?? '1.0',
      exam: json['exam'] as String? ?? '',
      paper: json['paper'] as String? ?? '',
      language: json['language'] as String? ?? 'English',
      publisher: json['publisher'] as String? ?? 'QuizForge AI',
      source: json['source'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      checksum: json['checksum'] as String? ?? '',
      totalQuestions: json['totalQuestions'] as int? ?? 0,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'datasetId': datasetId,
      'datasetVersion': datasetVersion,
      'schemaVersion': schemaVersion,
      'exam': exam,
      'paper': paper,
      'language': language,
      'publisher': publisher,
      if (source != null) 'source': source,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'checksum': checksum,
      'totalQuestions': totalQuestions,
      'metadata': metadata,
    };
  }
}
