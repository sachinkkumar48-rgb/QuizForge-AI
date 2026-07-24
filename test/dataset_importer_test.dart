import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_upsc/models/dataset_manifest.dart';
import 'package:quizforge_upsc/models/exam.dart';
import 'package:quizforge_upsc/models/explanation.dart';
import 'package:quizforge_upsc/models/question.dart';
import 'package:quizforge_upsc/repositories/dataset_repository.dart';
import 'package:quizforge_upsc/repositories/exam_repository.dart';
import 'package:quizforge_upsc/repositories/explanation_repository.dart';
import 'package:quizforge_upsc/repositories/question_repository.dart';
import 'package:quizforge_upsc/services/generic_dataset_importer.dart';

class InMemoryExamRepository implements ExamRepository {
  final Map<String, Exam> exams = {};
  final Map<String, Paper> papers = {};

  @override
  Future<List<Exam>> getExams() async => exams.values.toList();
  @override
  Future<Exam?> getExamById(String examId) async => exams[examId];
  @override
  Future<List<Paper>> getPapers({String? examId, int? year}) async {
    return papers.values.where((p) {
      if (examId != null && p.examId != examId) return false;
      if (year != null && p.year != year) return false;
      return true;
    }).toList();
  }

  @override
  Future<List<int>> getAvailableYears({String? examId}) async {
    final list = await getPapers(examId: examId);
    return list.map((p) => p.year).toSet().toList();
  }

  @override
  Future<void> saveExam(Exam exam) async {
    exams[exam.examId] = exam;
  }

  @override
  Future<void> savePaper(Paper paper) async {
    papers[paper.paperId] = paper;
  }

  @override
  Future<void> clear() async {
    exams.clear();
    papers.clear();
  }
}

class InMemoryQuestionRepository implements QuestionRepository {
  final Map<String, Question> questions = {};

  @override
  Future<List<Question>> getAllQuestions() async => questions.values.toList();
  @override
  Future<Question?> getQuestionById(String id) async => questions[id];
  @override
  Future<List<Question>> getQuestionsByPaper(String paperId) async =>
      questions.values.where((q) => q.paper == paperId).toList();
  @override
  Future<List<Question>> getQuestionsByYear(int year, {String? exam}) async =>
      questions.values.where((q) => q.year == year).toList();
  @override
  Future<List<Question>> getQuestionsBySubject(String subject,
          {String? exam}) async =>
      questions.values.where((q) => q.subject == subject).toList();
  @override
  Future<List<Question>> getQuestionsByTopic(String topic,
          {String? exam}) async =>
      questions.values.where((q) => q.topic == topic).toList();
  @override
  Future<List<String>> getSubjects({String? exam}) async =>
      questions.values.map((q) => q.subject).toSet().toList();
  @override
  Future<List<String>> getTopics({String? exam, String? subject}) async =>
      questions.values.map((q) => q.topic).toSet().toList();
  @override
  Future<List<Question>> searchQuestions({
    String? query,
    int? year,
    String? subject,
    String? topic,
    String? difficulty,
    String? exam,
  }) async =>
      getAllQuestions();

  @override
  Future<void> saveQuestion(Question question) async {
    questions[question.id] = question;
  }

  @override
  Future<void> saveQuestionsBatch(List<Question> list) async {
    for (final q in list) {
      questions[q.id] = q;
    }
  }

  @override
  Future<void> clear() async => questions.clear();
}

class InMemoryExplanationRepository implements ExplanationRepository {
  final Map<String, Explanation> explanations = {};

  @override
  Future<List<Explanation>> getExplanations(String questionId) async =>
      explanations.values.where((e) => e.questionId == questionId).toList();

  @override
  Future<Explanation?> getExplanationByType(
      String questionId, String type) async {
    final list = await getExplanations(questionId);
    try {
      return list.firstWhere(
          (e) => e.explanationType.toLowerCase() == type.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveExplanation(Explanation explanation) async {
    explanations[explanation.explanationId] = explanation;
  }

  @override
  Future<void> saveExplanationsBatch(List<Explanation> list) async {
    for (final e in list) {
      explanations[e.explanationId] = e;
    }
  }

  @override
  Future<void> deleteExplanation(String explanationId) async =>
      explanations.remove(explanationId);

  @override
  Future<void> clear() async => explanations.clear();
}

class InMemoryDatasetRepository implements DatasetRepository {
  final Map<String, DatasetManifest> manifests = {};

  @override
  Future<void> saveManifest(DatasetManifest manifest) async {
    manifests[manifest.datasetId] = manifest;
  }

  @override
  Future<DatasetManifest?> getManifest(String datasetId) async =>
      manifests[datasetId];

  @override
  Future<List<DatasetManifest>> getAllManifests() async =>
      manifests.values.toList();

  @override
  Future<void> deleteManifest(String datasetId) async =>
      manifests.remove(datasetId);

  @override
  Future<void> clear() async => manifests.clear();
}

void main() {
  group('Dataset Importer & Versioning Tests', () {
    late InMemoryExamRepository examRepo;
    late InMemoryQuestionRepository questionRepo;
    late InMemoryExplanationRepository explanationRepo;
    late InMemoryDatasetRepository datasetRepo;
    late GenericDatasetImporter importer;

    setUp(() {
      examRepo = InMemoryExamRepository();
      questionRepo = InMemoryQuestionRepository();
      explanationRepo = InMemoryExplanationRepository();
      datasetRepo = InMemoryDatasetRepository();

      importer = GenericDatasetImporter(
        examRepository: examRepo,
        questionRepository: questionRepo,
        explanationRepository: explanationRepo,
        datasetRepository: datasetRepo,
      );
    });

    test('Successfully imports dataset with valid manifest', () async {
      final questionsPayload = [
        {
          "id": "UPSC_PRE_GS1_2025_Q101",
          "exam": "UPSC CSE Prelims",
          "paper": "GS Paper I",
          "year": 2025,
          "subject": "Polity",
          "topic": "Preamble",
          "difficulty": "Easy",
          "question": "What is the Preamble?",
          "options": ["Opt A", "Opt B"],
          "correctAnswer": "Opt A",
          "explanations": [
            {
              "explanationId": "exp_q101_off",
              "explanationType": "Official",
              "content": "Official explanation text",
              "source": "UPSC"
            }
          ]
        }
      ];

      final questionsJson = jsonEncode(questionsPayload);
      final checksum = GenericDatasetImporter.computeChecksum(questionsJson);

      final datasetJson = jsonEncode({
        "manifest": {
          "datasetId": "upsc_prelims_2025_v1",
          "datasetVersion": "1.0.0",
          "schemaVersion": "1.0",
          "exam": "UPSC CSE Prelims",
          "paper": "GS Paper I",
          "language": "English",
          "publisher": "QuizForge AI",
          "checksum": checksum,
          "totalQuestions": 1
        },
        "questions": questionsPayload
      });

      final count = await importer.importDatasetJson(datasetJson);
      expect(count, equals(1));

      // Verify question stored
      final savedQuestion =
          await questionRepo.getQuestionById("UPSC_PRE_GS1_2025_Q101");
      expect(savedQuestion, isNotNull);
      expect(savedQuestion!.question, equals("What is the Preamble?"));

      // Verify explanation stored
      final savedExplanations =
          await explanationRepo.getExplanations("UPSC_PRE_GS1_2025_Q101");
      expect(savedExplanations.length, equals(1));
      expect(
          savedExplanations.first.content, equals("Official explanation text"));

      // Verify dataset manifest stored separately
      final savedManifest =
          await datasetRepo.getManifest("upsc_prelims_2025_v1");
      expect(savedManifest, isNotNull);
      expect(savedManifest!.datasetVersion, equals("1.0.0"));
      expect(savedManifest.totalQuestions, equals(1));
    });

    test('Rejects dataset with unsupported schema version', () async {
      final datasetJson = jsonEncode({
        "manifest": {
          "datasetId": "unsupported_v9",
          "datasetVersion": "1.0.0",
          "schemaVersion": "9.9",
          "exam": "UPSC",
          "paper": "GS",
          "totalQuestions": 0
        },
        "questions": []
      });

      expect(
        () => importer.importDatasetJson(datasetJson),
        throwsA(isA<DatasetValidationException>().having(
          (e) => e.message,
          'message',
          contains('Unsupported schema version'),
        )),
      );
    });

    test(
        'Rejects dataset when totalQuestions count mismatches actual questions',
        () async {
      final datasetJson = jsonEncode({
        "manifest": {
          "datasetId": "mismatch_count_v1",
          "datasetVersion": "1.0.0",
          "schemaVersion": "1.0",
          "exam": "UPSC",
          "paper": "GS",
          "totalQuestions": 100 // Manifest claims 100, but array has only 1
        },
        "questions": [
          {
            "id": "UPSC_PRE_GS1_2025_Q001",
            "question": "Sample Question",
            "options": ["A", "B"],
            "correctAnswer": "A"
          }
        ]
      });

      expect(
        () => importer.importDatasetJson(datasetJson),
        throwsA(isA<DatasetValidationException>().having(
          (e) => e.message,
          'message',
          contains('Question count mismatch'),
        )),
      );
    });

    test('Rejects dataset when checksum verification fails', () async {
      final datasetJson = jsonEncode({
        "manifest": {
          "datasetId": "corrupt_checksum_v1",
          "datasetVersion": "1.0.0",
          "schemaVersion": "1.0",
          "exam": "UPSC",
          "paper": "GS",
          "checksum": "invalid_fake_checksum_hash",
          "totalQuestions": 1
        },
        "questions": [
          {
            "id": "UPSC_PRE_GS1_2025_Q001",
            "question": "Sample Question",
            "options": ["A", "B"],
            "correctAnswer": "A"
          }
        ]
      });

      expect(
        () => importer.importDatasetJson(datasetJson),
        throwsA(isA<DatasetValidationException>().having(
          (e) => e.message,
          'message',
          contains('Dataset checksum mismatch'),
        )),
      );
    });
  });
}
