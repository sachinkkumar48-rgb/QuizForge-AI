import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/dataset_manifest.dart';
import '../models/exam.dart';
import '../models/explanation.dart';
import '../models/question.dart';
import '../models/validation_report.dart';
import '../repositories/dataset_repository.dart';
import '../repositories/exam_repository.dart';
import '../repositories/explanation_repository.dart';
import '../repositories/question_repository.dart';
import 'dataset_validator.dart';

class DatasetValidationException implements Exception {
  final String message;
  final ValidationReport? report;

  DatasetValidationException(this.message, [this.report]);

  @override
  String toString() => 'DatasetValidationException: $message';
}

class GenericDatasetImporter {
  final ExamRepository examRepository;
  final QuestionRepository questionRepository;
  final ExplanationRepository explanationRepository;
  final DatasetRepository? datasetRepository;

  static const String supportedSchemaVersion = '1.0';

  ValidationReport? lastValidationReport;

  GenericDatasetImporter({
    required this.examRepository,
    required this.questionRepository,
    required this.explanationRepository,
    this.datasetRepository,
  });

  /// Compute SHA-256 checksum string for a payload string or object.
  static String computeChecksum(String payload) {
    final bytes = utf8.encode(payload);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Parse, validate, and store structured dataset JSON.
  /// Modes:
  /// - [ImportMode.strict]: Fails and stops on first error.
  /// - [ImportMode.safe]: Skips invalid questions and imports valid questions only.
  Future<int> importDatasetJson(
    String jsonString, {
    ImportMode importMode = ImportMode.safe,
  }) async {
    if (jsonString.trim().isEmpty) {
      throw DatasetValidationException('Empty dataset payload');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(jsonString);
    } catch (e) {
      throw DatasetValidationException('Invalid JSON format: $e');
    }

    if (decoded is List) {
      return _importQuestionList(decoded, jsonString, importMode: importMode);
    } else if (decoded is Map<String, dynamic>) {
      DatasetManifest? manifest;

      if (decoded.containsKey('manifest') && decoded['manifest'] is Map) {
        manifest = DatasetManifest.fromJson(
            Map<String, dynamic>.from(decoded['manifest'] as Map));
      } else if (decoded.containsKey('datasetId')) {
        manifest = DatasetManifest.fromJson(decoded);
      }

      final List rawQuestions = (decoded['questions'] is List)
          ? decoded['questions'] as List
          : const [];

      // Manifest Validation 1: Schema Version
      if (manifest != null &&
          manifest.schemaVersion != supportedSchemaVersion) {
        throw DatasetValidationException(
            'Unsupported schema version: ${manifest.schemaVersion}. Engine requires $supportedSchemaVersion');
      }

      // Manifest Validation 2: Total Questions Count
      if (manifest != null &&
          manifest.totalQuestions > 0 &&
          manifest.totalQuestions != rawQuestions.length) {
        throw DatasetValidationException(
            'Question count mismatch: manifest specified ${manifest.totalQuestions}, but found ${rawQuestions.length}');
      }

      // Manifest Validation 3: Checksum verification
      if (manifest != null &&
          manifest.checksum.isNotEmpty &&
          decoded.containsKey('questions')) {
        final questionsJsonStr = jsonEncode(decoded['questions']);
        final calculatedChecksum = computeChecksum(questionsJsonStr);
        if (manifest.checksum != calculatedChecksum) {
          throw DatasetValidationException(
              'Dataset checksum mismatch. Data may be corrupted or tampered.');
        }
      }

      // Run Detailed Dataset Validator
      final report = DatasetValidator.validateQuestions(rawQuestions);
      lastValidationReport = report;

      if (importMode == ImportMode.strict && report.hasErrors) {
        throw DatasetValidationException(
          'Strict Import Mode failed with ${report.errors.length} error(s).\n${report.generateSummaryText()}',
          report,
        );
      }

      // Parse Exam & Paper
      if (decoded.containsKey('exam')) {
        if (decoded['exam'] is Map) {
          final exam =
              Exam.fromJson(Map<String, dynamic>.from(decoded['exam'] as Map));
          await examRepository.saveExam(exam);
        } else if (decoded['exam'] is String && manifest != null) {
          final examId =
              (decoded['exam'] as String).replaceAll(' ', '_').toUpperCase();
          await examRepository.saveExam(Exam(
            examId: examId,
            code: examId,
            name: decoded['exam'] as String,
            conductingBody: 'Exam Board',
            category: 'Competitive Examination',
          ));
        }
      }

      if (decoded.containsKey('paper') && decoded['paper'] is Map) {
        final paper =
            Paper.fromJson(Map<String, dynamic>.from(decoded['paper'] as Map));
        await examRepository.savePaper(paper);
      }

      // Identify indices of error items to skip in Safe Mode
      final Set<int> errorIndices = report.issues
          .where(
              (i) => i.severity == ValidationSeverity.error && i.index != null)
          .map((i) => i.index!)
          .toSet();

      final List<Question> questionList = [];
      final List<Explanation> explanationList = [];
      int importedCount = 0;

      for (int idx = 0; idx < rawQuestions.length; idx++) {
        if (errorIndices.contains(idx)) {
          continue; // Skip invalid items in Safe Mode
        }

        final raw = rawQuestions[idx];
        final qMap = Map<String, dynamic>.from(raw as Map);
        final question = Question.fromJson(qMap);
        questionList.add(question);
        importedCount++;

        if (qMap.containsKey('explanations') && qMap['explanations'] is List) {
          final List rawExplanations = qMap['explanations'] as List;
          for (final expRaw in rawExplanations) {
            final expMap = Map<String, dynamic>.from(expRaw as Map);
            expMap['questionId'] = question.id;
            explanationList.add(Explanation.fromJson(expMap));
          }
        }
      }

      await questionRepository.saveQuestionsBatch(questionList);
      await explanationRepository.saveExplanationsBatch(explanationList);

      if (manifest != null && datasetRepository != null) {
        await datasetRepository!.saveManifest(manifest);
      }

      return importedCount;
    } else {
      throw DatasetValidationException('Invalid JSON root payload format');
    }
  }

  Future<int> _importQuestionList(
    List rawList,
    String jsonString, {
    ImportMode importMode = ImportMode.safe,
  }) async {
    final report = DatasetValidator.validateQuestions(rawList);
    lastValidationReport = report;

    if (importMode == ImportMode.strict && report.hasErrors) {
      throw DatasetValidationException(
        'Strict Import Mode failed with ${report.errors.length} error(s).\n${report.generateSummaryText()}',
        report,
      );
    }

    final Set<int> errorIndices = report.issues
        .where((i) => i.severity == ValidationSeverity.error && i.index != null)
        .map((i) => i.index!)
        .toSet();

    final List<Question> questions = [];
    final List<Explanation> explanations = [];
    final Set<String> examNames = {};
    int importedCount = 0;

    for (int idx = 0; idx < rawList.length; idx++) {
      if (errorIndices.contains(idx)) continue;

      final item = rawList[idx];
      if (item is Map<String, dynamic>) {
        final q = Question.fromJson(item);
        questions.add(q);
        importedCount++;
        examNames.add(q.exam);

        if (item.containsKey('explanation') && item['explanation'] is Map) {
          final expMap = Map<String, dynamic>.from(item['explanation'] as Map);
          final String officialText = expMap['official'] as String? ?? '';
          final String? aiText = expMap['ai'] as String?;
          final String? editorialText = expMap['custom'] as String?;

          if (officialText.isNotEmpty) {
            explanations.add(Explanation(
              explanationId: '${q.id}_exp_official',
              questionId: q.id,
              explanationType: 'Official UPSC',
              content: officialText,
              source: 'Official UPSC Answer Key',
              author: 'UPSC',
              version: '1.0.0',
              language: 'English',
            ));
          }

          if (aiText != null && aiText.isNotEmpty) {
            explanations.add(Explanation(
              explanationId: '${q.id}_exp_ai',
              questionId: q.id,
              explanationType: 'AI Generated',
              content: aiText,
              source: 'Gemini 1.5 Flash REST API',
              author: 'Gemini AI',
              version: '1.0.0',
              language: 'English',
            ));
          }

          if (editorialText != null && editorialText.isNotEmpty) {
            explanations.add(Explanation(
              explanationId: '${q.id}_exp_editorial',
              questionId: q.id,
              explanationType: 'Editorial',
              content: editorialText,
              source: 'QuizForge Editorial Team',
              author: 'Subject Expert',
              version: '1.0.0',
              language: 'English',
            ));
          }
        }
      }
    }

    for (final examName in examNames) {
      final examId = examName.replaceAll(' ', '_').toUpperCase();
      await examRepository.saveExam(Exam(
        examId: examId,
        code: examId,
        name: examName,
        conductingBody: 'Exam Board',
        category: 'Competitive Examination',
      ));
    }

    await questionRepository.saveQuestionsBatch(questions);
    await explanationRepository.saveExplanationsBatch(explanations);

    if (datasetRepository != null && questions.isNotEmpty) {
      final autoManifest = DatasetManifest(
        datasetId: 'auto_imported_${DateTime.now().millisecondsSinceEpoch}',
        datasetVersion: '1.0.0',
        schemaVersion: '1.0',
        exam: questions.first.exam,
        paper: questions.first.paper,
        totalQuestions: questions.length,
        checksum: computeChecksum(jsonEncode(rawList)),
      );
      await datasetRepository!.saveManifest(autoManifest);
    }

    return importedCount;
  }

  /// Load seed dataset from assets if database is unpopulated.
  Future<void> seedFromAssets(
      {String assetPath = 'assets/pyq_dataset.json'}) async {
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      await importDatasetJson(jsonString);
    } catch (_) {
      // Graceful fallback
    }
  }
}
