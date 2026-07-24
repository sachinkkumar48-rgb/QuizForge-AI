class Exam {
  final String examId;
  final String code;
  final String name;
  final String conductingBody;
  final String category;
  final Map<String, dynamic> metadata;

  Exam({
    required this.examId,
    required this.code,
    required this.name,
    required this.conductingBody,
    required this.category,
    this.metadata = const {},
  });

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      examId: json['examId'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      conductingBody: json['conductingBody'] as String? ?? '',
      category: json['category'] as String? ?? '',
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'examId': examId,
      'code': code,
      'name': name,
      'conductingBody': conductingBody,
      'category': category,
      'metadata': metadata,
    };
  }
}

class Paper {
  final String paperId;
  final String examId;
  final String paperName;
  final int year;
  final int totalQuestions;
  final int durationMinutes;
  final double maxMarks;
  final double negativeMarkingFactor;

  Paper({
    required this.paperId,
    required this.examId,
    required this.paperName,
    required this.year,
    required this.totalQuestions,
    required this.durationMinutes,
    required this.maxMarks,
    required this.negativeMarkingFactor,
  });

  factory Paper.fromJson(Map<String, dynamic> json) {
    return Paper(
      paperId: json['paperId'] as String? ?? '',
      examId: json['examId'] as String? ?? '',
      paperName: json['paperName'] as String? ?? '',
      year: json['year'] as int? ?? 2024,
      totalQuestions: json['totalQuestions'] as int? ?? 100,
      durationMinutes: json['durationMinutes'] as int? ?? 120,
      maxMarks: (json['maxMarks'] as num?)?.toDouble() ?? 200.0,
      negativeMarkingFactor:
          (json['negativeMarkingFactor'] as num?)?.toDouble() ?? 0.66,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paperId': paperId,
      'examId': examId,
      'paperName': paperName,
      'year': year,
      'totalQuestions': totalQuestions,
      'durationMinutes': durationMinutes,
      'maxMarks': maxMarks,
      'negativeMarkingFactor': negativeMarkingFactor,
    };
  }
}
