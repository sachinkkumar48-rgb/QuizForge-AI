/// Multi-Exam PYQ Intelligence Foundation (Project TITAN - P29).
///
/// Provides a structured, deterministic, offline-first intelligence layer
/// for multiple national and state examinations (UPSC, BPSC, SSC, Banking, Railways).
///
/// Core Capabilities:
/// 1. Generic multi-exam identity and extensible exam registry.
/// 2. Deterministic, content-addressable question identity.
/// 3. Normalization pipeline handling whitespace, prefix-stripping, and multilingual text.
/// 4. Verifiable source provenance tracking.
/// 5. $O(N)$ index-based deduplication with language variant preservation.
/// 6. Composable multi-dimensional filtering with zero cross-exam leakage.
/// 7. Explicit curriculum objective mapping into P17 Learning Objectives.
/// 8. Corpus-level distribution and coverage analytics (zero learner inference).
/// 9. Evidence-based historical trend analysis without speculative predictions.
library;

import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';

import '../models/answer_model.dart';
import '../models/option_model.dart';
import '../models/question_model.dart' as pyq;
import '../models/source_model.dart';

// ============================================================================
// 1. MULTI-EXAM PROFILES & REGISTRY
// ============================================================================

/// Operational support tiers for examinations in Project TITAN.
enum ExamSupportTier {
  /// Exam identifier and basic metadata recognized in registry.
  registered,

  /// Exam pattern, subjects, and paper structure defined.
  available,

  /// PYQ questions ingested, parsed, and indexed for retrieval.
  indexed,

  /// Full curriculum objective mapping and longitudinal intelligence active.
  fullySupported,
}

/// Generic examination profile representing national or state level tests.
@immutable
class ExamProfile {
  /// Canonical lowercase identifier (e.g. 'upsc', 'bpsc', 'ssc', 'banking', 'railways').
  final String examId;

  /// Full human-readable display name.
  final String displayName;

  /// Conducting body or agency (e.g. 'UPSC', 'BPSC', 'Staff Selection Commission').
  final String organization;

  /// Country or state jurisdiction.
  final String country;

  /// Recognized subjects in this exam syllabus.
  final List<String> subjects;

  /// Supported historical years with verified question papers.
  final List<int> supportedYears;

  /// Current operational readiness tier.
  final ExamSupportTier tier;

  /// Additional exam metadata.
  final Map<String, dynamic> metadata;

  ExamProfile({
    required String examId,
    required this.displayName,
    required this.organization,
    this.country = 'India',
    required List<String> subjects,
    required List<int> supportedYears,
    this.tier = ExamSupportTier.registered,
    Map<String, dynamic>? metadata,
  })  : examId = examId.trim().toLowerCase(),
        subjects = List.unmodifiable(subjects),
        supportedYears = List.unmodifiable([...supportedYears]..sort()),
        metadata = Map.unmodifiable(metadata ?? const <String, dynamic>{}) {
    if (examId.trim().isEmpty) {
      throw ArgumentError('examId cannot be blank');
    }
    if (displayName.trim().isEmpty) {
      throw ArgumentError('displayName cannot be blank');
    }
  }

  bool get isIndexedOrBetter =>
      tier == ExamSupportTier.indexed || tier == ExamSupportTier.fullySupported;

  bool get isFullySupported => tier == ExamSupportTier.fullySupported;

  ExamProfile copyWith({
    String? displayName,
    String? organization,
    String? country,
    List<String>? subjects,
    List<int>? supportedYears,
    ExamSupportTier? tier,
    Map<String, dynamic>? metadata,
  }) {
    return ExamProfile(
      examId: examId,
      displayName: displayName ?? this.displayName,
      organization: organization ?? this.organization,
      country: country ?? this.country,
      subjects: subjects ?? this.subjects,
      supportedYears: supportedYears ?? this.supportedYears,
      tier: tier ?? this.tier,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'examId': examId,
        'displayName': displayName,
        'organization': organization,
        'country': country,
        'subjects': subjects,
        'supportedYears': supportedYears,
        'tier': tier.name,
        'metadata': metadata,
      };

  factory ExamProfile.fromJson(Map<String, dynamic> json) {
    final tierName = json['tier'] as String?;
    final tier = ExamSupportTier.values.firstWhere(
      (e) => e.name == tierName,
      orElse: () => ExamSupportTier.registered,
    );
    return ExamProfile(
      examId: json['examId'] as String,
      displayName: json['displayName'] as String,
      organization: json['organization'] as String? ?? '',
      country: json['country'] as String? ?? 'India',
      subjects: List<String>.from(json['subjects'] as List? ?? []),
      supportedYears: List<int>.from(json['supportedYears'] as List? ?? []),
      tier: tier,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExamProfile &&
          runtimeType == other.runtimeType &&
          examId == other.examId;

  @override
  int get hashCode => examId.hashCode;

  @override
  String toString() => 'ExamProfile($examId: $displayName [${tier.name}])';
}

/// Deterministic registry of supported examinations.
class ExamRegistry {
  final Map<String, ExamProfile> _exams = {};

  ExamRegistry({List<ExamProfile>? initialProfiles}) {
    if (initialProfiles != null) {
      for (final profile in initialProfiles) {
        registerExam(profile);
      }
    } else {
      _loadCanonicalDefaults();
    }
  }

  void _loadCanonicalDefaults() {
    registerExam(ExamProfile(
      examId: 'upsc',
      displayName: 'UPSC Civil Services Examination',
      organization: 'Union Public Service Commission',
      country: 'India',
      subjects: const [
        'Polity',
        'History',
        'Geography',
        'Economy',
        'Environment',
        'Science & Tech',
        'Current Affairs',
        'General Studies'
      ],
      supportedYears: List.generate(31, (i) => 1995 + i), // 1995 to 2025
      tier: ExamSupportTier.fullySupported,
      metadata: const {
        'stages': ['Prelims', 'Mains', 'Interview'],
        'defaultPaper': 'GS1',
      },
    ));

    registerExam(ExamProfile(
      examId: 'bpsc',
      displayName: 'Bihar Public Service Commission CCE',
      organization: 'Bihar Public Service Commission',
      country: 'India',
      subjects: const [
        'General Studies',
        'State History & Culture',
        'Indian Polity',
        'Economy',
        'Geography'
      ],
      supportedYears: const [2018, 2019, 2020, 2021, 2022, 2023, 2024],
      tier: ExamSupportTier.indexed,
      metadata: const {
        'state': 'Bihar',
        'stages': ['Prelims', 'Mains'],
      },
    ));

    registerExam(ExamProfile(
      examId: 'ssc',
      displayName: 'SSC Combined Graduate Level',
      organization: 'Staff Selection Commission',
      country: 'India',
      subjects: const [
        'General Awareness',
        'Reasoning',
        'Quantitative Aptitude',
        'English Comprehension'
      ],
      supportedYears: const [2020, 2021, 2022, 2023, 2024],
      tier: ExamSupportTier.available,
      metadata: const {
        'tiers': ['Tier-1', 'Tier-2'],
      },
    ));

    registerExam(ExamProfile(
      examId: 'banking',
      displayName: 'IBPS & SBI Probationary Officer Examination',
      organization: 'Institute of Banking Personnel Selection',
      country: 'India',
      subjects: const [
        'Banking Awareness',
        'General Economy',
        'Quantitative Aptitude',
        'Reasoning Ability'
      ],
      supportedYears: const [2021, 2022, 2023, 2024],
      tier: ExamSupportTier.available,
      metadata: const {
        'type': 'Banking & Financial',
      },
    ));

    registerExam(ExamProfile(
      examId: 'railways',
      displayName: 'RRB Non-Technical Popular Categories (NTPC)',
      organization: 'Railway Recruitment Control Board',
      country: 'India',
      subjects: const [
        'General Awareness',
        'Mathematics',
        'General Intelligence & Reasoning'
      ],
      supportedYears: const [2019, 2020, 2021, 2022, 2023, 2024],
      tier: ExamSupportTier.registered,
      metadata: const {
        'department': 'Indian Railways',
      },
    ));
  }

  void registerExam(ExamProfile profile) {
    _exams[profile.examId] = profile;
  }

  ExamProfile? getExam(String examId) {
    return _exams[examId.trim().toLowerCase()];
  }

  bool isRegistered(String examId) {
    return _exams.containsKey(examId.trim().toLowerCase());
  }

  List<ExamProfile> getExamsByTier(ExamSupportTier tier) {
    return _exams.values.where((e) => e.tier == tier).toList()
      ..sort((a, b) => a.examId.compareTo(b.examId));
  }

  List<ExamProfile> get allExams {
    final list = _exams.values.toList();
    list.sort((a, b) => a.examId.compareTo(b.examId));
    return List.unmodifiable(list);
  }

  int get count => _exams.length;
}

// ============================================================================
// 2. SOURCE PROVENANCE
// ============================================================================

/// Immutable provenance record linking a PYQ question to primary source documentation.
@immutable
class PyqSourceReference {
  final String sourceId;
  final String
      sourceType; // 'officialPdf', 'officialKey', 'publicArchive', 'editorial'
  final String sourceTitle;
  final String? sourceUrl;
  final String publisher;
  final DateTime retrievedAt;
  final String checksum; // SHA-256 integrity hash
  final Map<String, dynamic> metadata;

  PyqSourceReference({
    required String sourceId,
    required this.sourceType,
    required this.sourceTitle,
    this.sourceUrl,
    required this.publisher,
    required DateTime retrievedAt,
    required this.checksum,
    Map<String, dynamic>? metadata,
  })  : sourceId = sourceId.trim(),
        retrievedAt = retrievedAt.toUtc(),
        metadata = Map.unmodifiable(metadata ?? const <String, dynamic>{}) {
    if (this.sourceId.isEmpty) {
      throw ArgumentError('sourceId cannot be blank');
    }
  }

  factory PyqSourceReference.official({
    required String examId,
    required int year,
    required String paper,
    String? url,
    String? publisher,
    String? checksum,
    DateTime? retrievedAt,
  }) {
    final cleanExam = examId.trim().toUpperCase();
    final cleanPaper = paper.trim().replaceAll(' ', '_');
    final sId = 'SRC_${cleanExam}_${year}_$cleanPaper';
    return PyqSourceReference(
      sourceId: sId,
      sourceType: 'officialPdf',
      sourceTitle: '$cleanExam $year $paper Official Examination Document',
      sourceUrl: url,
      publisher: publisher ?? '$cleanExam Examination Authority',
      retrievedAt: retrievedAt ?? DateTime.utc(2026, 1, 1),
      checksum: checksum ?? sha256.convert(utf8.encode(sId)).toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'sourceId': sourceId,
        'sourceType': sourceType,
        'sourceTitle': sourceTitle,
        'sourceUrl': sourceUrl,
        'publisher': publisher,
        'retrievedAt': retrievedAt.toIso8601String(),
        'checksum': checksum,
        'metadata': metadata,
      };

  factory PyqSourceReference.fromJson(Map<String, dynamic> json) {
    return PyqSourceReference(
      sourceId: json['sourceId'] as String,
      sourceType: json['sourceType'] as String? ?? 'officialPdf',
      sourceTitle: json['sourceTitle'] as String? ?? 'Past Examination Source',
      sourceUrl: json['sourceUrl'] as String?,
      publisher: json['publisher'] as String? ?? 'Official Agency',
      retrievedAt: DateTime.parse(json['retrievedAt'] as String),
      checksum: json['checksum'] as String? ?? '',
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  QuestionSource toQuestionSource() {
    SourceType st;
    switch (sourceType) {
      case 'officialPdf':
        st = SourceType.officialPdf;
        break;
      case 'officialKey':
        st = SourceType.officialWebsite;
        break;
      case 'publicArchive':
        st = SourceType.verifiedArchive;
        break;
      default:
        st = SourceType.editorialEntry;
    }
    return QuestionSource(
      sourceType: st,
      url: sourceUrl,
      publisher: publisher,
      retrievedDate: retrievedAt,
      checksum: checksum,
    );
  }
}

// ============================================================================
// 3. DETERMINISTIC QUESTION IDENTITY
// ============================================================================

/// Stable, content-addressable question identity generator.
///
/// Invariants:
/// - Survives application restarts, reindexes, repeated ingestion, and imports.
/// - Never depends on list or array position.
/// - Uses content hash of (examId, year, paper, language, normalizedQuestionText).
class DeterministicQuestionId {
  static String generate({
    required String examId,
    required int year,
    required String paper,
    required String normalizedQuestionText,
    String language = 'en',
    int? questionNumber,
  }) {
    final cleanExam = examId.trim().toUpperCase();
    final cleanPaper =
        paper.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '_');
    final cleanLang = language.trim().toLowerCase();
    final cleanText = normalizedQuestionText.trim().toLowerCase();

    final rawForHash = '$cleanExam|$year|$cleanPaper|$cleanLang|$cleanText';
    final hash =
        sha256.convert(utf8.encode(rawForHash)).toString().substring(0, 10);

    final qNumPart = questionNumber != null
        ? '_Q${questionNumber.toString().padLeft(3, '0')}'
        : '';

    return 'PYQ_${cleanExam}_${year}_$cleanPaper${qNumPart}_$hash';
  }
}

// ============================================================================
// 4. NORMALIZATION PIPELINE & AUTHORITATIVE REPRESENTATION
// ============================================================================

/// Permissive raw question payload for ingestion.
class RawQuestionInput {
  final String? rawId;
  final String examId;
  final int year;
  final String paper;
  final String? stage;
  final int? questionNumber;
  final String? subject;
  final String? topic;
  final String? subtopic;
  final String questionText;
  final dynamic options; // List<String> or Map<String, String> or List<Map>
  final String correctAnswer;
  final String? officialAnswer;
  final String? explanation;
  final String? difficulty;
  final String? language;
  final PyqSourceReference? source;
  final List<String>? tags;
  final List<String>? objectiveIds;
  final Map<String, dynamic>? metadata;

  const RawQuestionInput({
    this.rawId,
    required this.examId,
    required this.year,
    required this.paper,
    this.stage,
    this.questionNumber,
    this.subject,
    this.topic,
    this.subtopic,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    this.officialAnswer,
    this.explanation,
    this.difficulty,
    this.language,
    this.source,
    this.tags,
    this.objectiveIds,
    this.metadata,
  });
}

/// Authoritative normalized question representation in Project TITAN.
@immutable
class NormalizedQuestion {
  final String id;
  final String examId;
  final int year;
  final String paper;
  final String stage;
  final int questionNumber;
  final String subject;
  final String topic;
  final String? subtopic;
  final String normalizedText;
  final String originalText;
  final List<Option> options;
  final Answer officialAnswer;
  final String explanation;
  final String difficulty;
  final String language;
  final PyqSourceReference source;
  final List<String> tags;
  final List<String> objectiveIds;
  final Map<String, dynamic> metadata;

  NormalizedQuestion({
    required this.id,
    required String examId,
    required this.year,
    required String paper,
    String? stage,
    this.questionNumber = 1,
    String? subject,
    String? topic,
    this.subtopic,
    required this.normalizedText,
    required this.originalText,
    required List<Option> options,
    required this.officialAnswer,
    this.explanation = '',
    this.difficulty = 'Medium',
    this.language = 'en',
    required this.source,
    List<String>? tags,
    List<String>? objectiveIds,
    Map<String, dynamic>? metadata,
  })  : examId = examId.trim().toLowerCase(),
        paper = paper.trim(),
        stage = stage ?? 'Prelims',
        subject = subject?.trim().isNotEmpty == true
            ? subject!.trim()
            : 'General Studies',
        topic = topic?.trim().isNotEmpty == true ? topic!.trim() : 'General',
        options = List.unmodifiable(options),
        tags = List.unmodifiable(tags ?? const []),
        objectiveIds = List.unmodifiable(objectiveIds ?? const []),
        metadata = Map.unmodifiable(metadata ?? const {});

  /// Converts this normalized question to the existing [pyq.Question] domain entity.
  pyq.Question toPyqQuestion() {
    final mergedTags = {...tags, ...objectiveIds}.toList()..sort();
    return pyq.Question(
      id: id,
      questionNumber: questionNumber,
      examId: examId,
      year: year,
      stage: stage,
      paper: paper,
      subject: subject,
      topic: topic,
      subtopic: subtopic,
      originalQuestion: normalizedText,
      options: options,
      officialAnswer: officialAnswer,
      garudaExplanation: explanation,
      difficulty: difficulty,
      language: language,
      source: source.toQuestionSource(),
      conceptsTested: mergedTags,
      tags: mergedTags,
    );
  }

  factory NormalizedQuestion.fromPyqQuestion(
    pyq.Question q, {
    List<String>? objectiveIds,
  }) {
    final sourceRef = PyqSourceReference(
      sourceId: 'SRC_${q.examId.toUpperCase()}_${q.year}_${q.paper}',
      sourceType: q.source.sourceType.name,
      sourceTitle: '${q.examId.toUpperCase()} ${q.year} ${q.paper} Source',
      sourceUrl: q.source.url,
      publisher: q.source.publisher,
      retrievedAt: q.source.retrievedDate,
      checksum: q.source.checksum,
    );

    return NormalizedQuestion(
      id: q.id,
      examId: q.examId,
      year: q.year,
      paper: q.paper,
      stage: q.stage,
      questionNumber: q.questionNumber,
      subject: q.subject,
      topic: q.topic,
      subtopic: q.subtopic,
      normalizedText: q.originalQuestion,
      originalText: q.originalQuestion,
      options: q.options,
      officialAnswer: q.officialAnswer,
      explanation: q.garudaExplanation,
      difficulty: q.difficulty,
      language: q.language,
      source: sourceRef,
      tags: q.tags,
      objectiveIds: objectiveIds ?? const [],
    );
  }

  /// First correct option key (e.g. 'A').
  String get correctOption => officialAnswer.correctOptionKeys.isNotEmpty
      ? officialAnswer.correctOptionKeys.first
      : 'A';

  Map<String, dynamic> toJson() => {
        'id': id,
        'examId': examId,
        'year': year,
        'paper': paper,
        'stage': stage,
        'questionNumber': questionNumber,
        'subject': subject,
        'topic': topic,
        'subtopic': subtopic,
        'normalizedText': normalizedText,
        'originalText': originalText,
        'options': options.map((o) => o.toJson()).toList(),
        'officialAnswer': officialAnswer.toJson(),
        'explanation': explanation,
        'difficulty': difficulty,
        'language': language,
        'source': source.toJson(),
        'tags': tags,
        'objectiveIds': objectiveIds,
        'metadata': metadata,
      };

  factory NormalizedQuestion.fromJson(Map<String, dynamic> json) {
    final optionsList = (json['options'] as List? ?? [])
        .map((o) => Option.fromJson(Map<String, dynamic>.from(o as Map)))
        .toList();

    final answerJson = json['officialAnswer'];
    final Answer ans;
    if (answerJson is Map) {
      ans = Answer.fromJson(Map<String, dynamic>.from(answerJson));
    } else {
      final key = answerJson?.toString() ?? 'A';
      ans = Answer(correctOptionKeys: [key]);
    }

    final sourceJson = json['source'];
    final PyqSourceReference src;
    if (sourceJson is Map) {
      src = PyqSourceReference.fromJson(Map<String, dynamic>.from(sourceJson));
    } else {
      src = PyqSourceReference.official(
        examId: json['examId'] as String? ?? 'upsc',
        year: json['year'] as int? ?? 2024,
        paper: json['paper'] as String? ?? 'GS1',
      );
    }

    return NormalizedQuestion(
      id: json['id'] as String,
      examId: json['examId'] as String,
      year: json['year'] as int,
      paper: json['paper'] as String,
      stage: json['stage'] as String? ?? 'Prelims',
      questionNumber: json['questionNumber'] as int? ?? 1,
      subject: json['subject'] as String?,
      topic: json['topic'] as String?,
      subtopic: json['subtopic'] as String?,
      normalizedText: json['normalizedText'] as String,
      originalText:
          json['originalText'] as String? ?? json['normalizedText'] as String,
      options: optionsList,
      officialAnswer: ans,
      explanation: json['explanation'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? 'Medium',
      language: json['language'] as String? ?? 'en',
      source: src,
      tags: List<String>.from(json['tags'] as List? ?? []),
      objectiveIds: List<String>.from(json['objectiveIds'] as List? ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }
}

/// Normalization pipeline cleaning raw question payloads into canonical representations.
class PyqNormalizationPipeline {
  /// Cleans and normalizes question text:
  /// - Strips question number prefixes (e.g. "Q1.", "1)", "Question 12:", "Q. 5 -")
  /// - Collapses multiple spaces, tabs, and newlines into single spaces.
  /// - Preserves Devanagari and international Unicode scripts.
  static String normalizeQuestionText(String rawText) {
    var text = rawText.trim();
    // Strip leading question prefixes
    text = text.replaceAll(
        RegExp(
            r'^(?:(?:Q(?:uestion)?\.?|प्रश्न)?\s*\d+[\.\:\)\-]?|\d+[\.\)\-])\s*',
            caseSensitive: false),
        '');
    // Consolidate whitespace
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text;
  }

  /// Normalizes options into a list of [Option] entities.
  static List<Option> normalizeOptions(dynamic rawOptions) {
    final result = <Option>[];
    if (rawOptions is List) {
      for (int i = 0; i < rawOptions.length; i++) {
        final item = rawOptions[i];
        final defaultKey = String.fromCharCode(65 + i); // 'A', 'B', 'C', 'D'
        if (item is String) {
          var optText = item.trim();
          var optKey = defaultKey;
          // Check if option starts with (a), A., 1., D -, etc.
          final match = RegExp(r'^\(?([A-Da-d1-4])\)?(?:\s*[-.:]\s*|\s+)(.*)$')
              .firstMatch(optText);
          if (match != null) {
            final rawKey = match.group(1)!;
            optKey = _standardizeOptionKey(rawKey);
            optText = match.group(2)!.trim();
          }
          result.add(Option(
            key: optKey,
            text: optText.replaceAll(RegExp(r'\s+'), ' ').trim(),
          ));
        } else if (item is Option) {
          result.add(item);
        } else if (item is Map) {
          final key = item['key']?.toString() ?? defaultKey;
          final text = item['text']?.toString() ?? '';
          result.add(Option(
            key: _standardizeOptionKey(key),
            text: text.replaceAll(RegExp(r'\s+'), ' ').trim(),
          ));
        }
      }
    } else if (rawOptions is Map) {
      final entries = rawOptions.entries.toList()
        ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
      for (final entry in entries) {
        result.add(Option(
          key: _standardizeOptionKey(entry.key.toString()),
          text: entry.value.toString().replaceAll(RegExp(r'\s+'), ' ').trim(),
        ));
      }
    }

    if (result.isEmpty) {
      throw ArgumentError('Normalized options list cannot be empty');
    }
    return List.unmodifiable(result);
  }

  static String _standardizeOptionKey(String key) {
    final k = key.trim().toUpperCase();
    switch (k) {
      case '1':
        return 'A';
      case '2':
        return 'B';
      case '3':
        return 'C';
      case '4':
        return 'D';
      default:
        return k.isNotEmpty ? k.substring(0, 1) : 'A';
    }
  }

  /// Normalizes a single raw question input.
  static NormalizedQuestion normalize(
    RawQuestionInput input, {
    PyqSourceReference? fallbackSource,
  }) {
    if (input.questionText.trim().isEmpty) {
      throw ArgumentError('questionText cannot be blank');
    }
    if (input.examId.trim().isEmpty) {
      throw ArgumentError('examId cannot be blank');
    }

    final normalizedText = normalizeQuestionText(input.questionText);
    final options = normalizeOptions(input.options);

    final cleanAnswerKey =
        _standardizeOptionKey(input.officialAnswer ?? input.correctAnswer);
    final answer = Answer(
      correctOptionKeys: [cleanAnswerKey],
      descriptiveAnswer: input.explanation,
    );

    final source = input.source ??
        fallbackSource ??
        PyqSourceReference.official(
          examId: input.examId,
          year: input.year,
          paper: input.paper,
        );

    final lang = (input.language != null && input.language!.trim().isNotEmpty)
        ? input.language!.trim().toLowerCase()
        : 'en';

    final id = input.rawId?.trim().isNotEmpty == true
        ? input.rawId!.trim()
        : DeterministicQuestionId.generate(
            examId: input.examId,
            year: input.year,
            paper: input.paper,
            normalizedQuestionText: normalizedText,
            language: lang,
            questionNumber: input.questionNumber,
          );

    return NormalizedQuestion(
      id: id,
      examId: input.examId,
      year: input.year,
      paper: input.paper,
      stage: input.stage ?? 'Prelims',
      questionNumber: input.questionNumber ?? 1,
      subject: input.subject,
      topic: input.topic,
      subtopic: input.subtopic,
      normalizedText: normalizedText,
      originalText: input.questionText,
      options: options,
      officialAnswer: answer,
      explanation: input.explanation ?? '',
      difficulty: input.difficulty ?? 'Medium',
      language: lang,
      source: source,
      tags: input.tags ?? const [],
      objectiveIds: input.objectiveIds ?? const [],
      metadata: input.metadata,
    );
  }

  /// Batch normalizes raw question inputs.
  static List<NormalizedQuestion> normalizeBatch(
    List<RawQuestionInput> inputs, {
    PyqSourceReference? fallbackSource,
  }) {
    return inputs
        .map((i) => normalize(i, fallbackSource: fallbackSource))
        .toList();
  }
}

// ============================================================================
// 5. DETERMINISTIC DEDUPLICATION
// ============================================================================

/// Result of duplicate evaluation on a batch of incoming questions.
class DuplicateReport {
  final NormalizedQuestion duplicate;
  final String originalId;
  final String reason;

  const DuplicateReport({
    required this.duplicate,
    required this.originalId,
    required this.reason,
  });
}

class DuplicateDetectionResult {
  final List<NormalizedQuestion> uniqueQuestions;
  final List<DuplicateReport> duplicates;

  const DuplicateDetectionResult({
    required this.uniqueQuestions,
    required this.duplicates,
  });

  int get uniqueCount => uniqueQuestions.length;
  int get duplicateCount => duplicates.length;
}

/// $O(N)$ index-based deterministic duplicate detector.
///
/// Rules:
/// 1. Same exam + year + paper + normalized question text + language = DUPLICATE.
/// 2. Translation variants (e.g. Hindi vs English for same question) have DIFFERENT
///    languages ('en' vs 'hi') and are NOT treated as duplicates!
/// 3. Source provenance remains recoverable.
class DeterministicDuplicateDetector {
  static String makeSignature(NormalizedQuestion q) {
    return '${q.examId}|${q.year}|${q.paper.toLowerCase()}|${q.language}|${q.normalizedText.toLowerCase()}';
  }

  static DuplicateDetectionResult filterDuplicates({
    required List<NormalizedQuestion> existingCorpus,
    required List<NormalizedQuestion> incoming,
  }) {
    final seenSignatures = <String, String>{}; // signature -> first seen id
    final seenIds = <String>{};

    for (final q in existingCorpus) {
      seenIds.add(q.id);
      seenSignatures[makeSignature(q)] = q.id;
    }

    final unique = <NormalizedQuestion>[];
    final duplicates = <DuplicateReport>[];

    for (final q in incoming) {
      final sig = makeSignature(q);

      if (seenIds.contains(q.id)) {
        duplicates.add(DuplicateReport(
          duplicate: q,
          originalId: q.id,
          reason: 'Identical question ID collision (${q.id})',
        ));
        continue;
      }

      if (seenSignatures.containsKey(sig)) {
        final origId = seenSignatures[sig]!;
        duplicates.add(DuplicateReport(
          duplicate: q,
          originalId: origId,
          reason:
              'Normalized content duplicate of $origId in ${q.examId.toUpperCase()} ${q.year} [${q.language}]',
        ));
        continue;
      }

      seenIds.add(q.id);
      seenSignatures[sig] = q.id;
      unique.add(q);
    }

    return DuplicateDetectionResult(
      uniqueQuestions: List.unmodifiable(unique),
      duplicates: List.unmodifiable(duplicates),
    );
  }
}

// ============================================================================
// 6. COMPOSABLE MULTI-EXAM FILTERING
// ============================================================================

/// Criteria for querying the multi-exam PYQ corpus.
class PyqFilterCriteria {
  final String? examId;
  final int? year;
  final int? minYear;
  final int? maxYear;
  final String? paper;
  final String? subject;
  final String? topic;
  final String? language;
  final String? difficulty;
  final String? objectiveId;
  final String? keyword;

  const PyqFilterCriteria({
    this.examId,
    this.year,
    this.minYear,
    this.maxYear,
    this.paper,
    this.subject,
    this.topic,
    this.language,
    this.difficulty,
    this.objectiveId,
    this.keyword,
  });

  bool matches(NormalizedQuestion q) {
    if (examId != null && q.examId != examId!.trim().toLowerCase()) {
      return false;
    }
    if (year != null && q.year != year) {
      return false;
    }
    if (minYear != null && q.year < minYear!) {
      return false;
    }
    if (maxYear != null && q.year > maxYear!) {
      return false;
    }
    if (paper != null &&
        q.paper.trim().toLowerCase() != paper!.trim().toLowerCase()) {
      return false;
    }
    if (subject != null &&
        q.subject.trim().toLowerCase() != subject!.trim().toLowerCase()) {
      return false;
    }
    if (topic != null &&
        q.topic.trim().toLowerCase() != topic!.trim().toLowerCase()) {
      return false;
    }
    if (language != null &&
        q.language.trim().toLowerCase() != language!.trim().toLowerCase()) {
      return false;
    }
    if (difficulty != null &&
        q.difficulty.trim().toLowerCase() != difficulty!.trim().toLowerCase()) {
      return false;
    }
    if (objectiveId != null && !q.objectiveIds.contains(objectiveId)) {
      return false;
    }
    if (keyword != null && keyword!.trim().isNotEmpty) {
      final kw = keyword!.trim().toLowerCase();
      final inText = q.normalizedText.toLowerCase().contains(kw);
      final inSubject = q.subject.toLowerCase().contains(kw);
      final inTopic = q.topic.toLowerCase().contains(kw);
      final inTags = q.tags.any((t) => t.toLowerCase().contains(kw));
      if (!inText && !inSubject && !inTopic && !inTags) {
        return false;
      }
    }
    return true;
  }
}

/// Filtering engine executing composable queries over question lists.
class PyqFilterEngine {
  static List<NormalizedQuestion> filter(
    List<NormalizedQuestion> questions,
    PyqFilterCriteria criteria,
  ) {
    final matched = questions.where(criteria.matches).toList();
    matched.sort((a, b) => a.id.compareTo(b.id));
    return List.unmodifiable(matched);
  }
}

// ============================================================================
// 7. CURRICULUM OBJECTIVE MAPPING
// ============================================================================

/// Explicit mapper associating PYQs to P17 Curriculum [LearningObjective] IDs.
///
/// Invariants:
/// - No competing curriculum hierarchy is created.
/// - Explicit mapping only; unmapped questions remain unmapped without fabrication.
class CurriculumObjectiveMapper {
  final Map<String, List<String>> _questionToObjectives = {};
  final Map<String, List<String>> _topicToObjectives =
      {}; // examId:topic -> [objId]

  CurriculumObjectiveMapper({
    Map<String, List<String>>? directMappings,
    Map<String, List<String>>? topicMappings,
  }) {
    if (directMappings != null) {
      _questionToObjectives.addAll(directMappings);
    }
    if (topicMappings != null) {
      _topicToObjectives.addAll(topicMappings);
    }
  }

  void mapQuestionToObjective(String questionId, String objectiveId) {
    final list = _questionToObjectives.putIfAbsent(questionId, () => []);
    if (!list.contains(objectiveId)) {
      list.add(objectiveId);
    }
  }

  void mapTopicToObjective({
    required String examId,
    required String topic,
    required String objectiveId,
  }) {
    final key = '${examId.toLowerCase()}:${topic.toLowerCase()}';
    final list = _topicToObjectives.putIfAbsent(key, () => []);
    if (!list.contains(objectiveId)) {
      list.add(objectiveId);
    }
  }

  List<String> resolveObjectives(NormalizedQuestion q) {
    final resolved = <String>{};

    // 1. Direct explicit question mappings
    final direct = _questionToObjectives[q.id];
    if (direct != null) resolved.addAll(direct);

    // 2. Embedded question objectiveIds
    resolved.addAll(q.objectiveIds);

    // 3. Topic mappings for this exam
    final topicKey = '${q.examId}:${q.topic.toLowerCase()}';
    final topicMapped = _topicToObjectives[topicKey];
    if (topicMapped != null) resolved.addAll(topicMapped);

    final out = resolved.toList()..sort();
    return List.unmodifiable(out);
  }

  NormalizedQuestion applyMapping(NormalizedQuestion q) {
    final objs = resolveObjectives(q);
    if (objs.length == q.objectiveIds.length &&
        objs.every(q.objectiveIds.contains)) {
      return q;
    }
    return NormalizedQuestion(
      id: q.id,
      examId: q.examId,
      year: q.year,
      paper: q.paper,
      stage: q.stage,
      questionNumber: q.questionNumber,
      subject: q.subject,
      topic: q.topic,
      subtopic: q.subtopic,
      normalizedText: q.normalizedText,
      originalText: q.originalText,
      options: q.options,
      officialAnswer: q.officialAnswer,
      explanation: q.explanation,
      difficulty: q.difficulty,
      language: q.language,
      source: q.source,
      tags: q.tags,
      objectiveIds: objs,
      metadata: q.metadata,
    );
  }
}

// ============================================================================
// 8. PYQ CORPUS INTELLIGENCE (ANALYTICS)
// ============================================================================

/// Corpus-level intelligence analytics.
///
/// Invariants:
/// - Pure corpus-level distribution and coverage metric.
/// - Strictly zero learner ability or mastery inference.
@immutable
class CorpusAnalytics {
  final int totalQuestions;
  final Map<String, int> examDistribution;
  final Map<int, int> yearDistribution;
  final Map<String, int> subjectDistribution;
  final Map<String, int> topicDistribution;
  final Map<String, int> objectiveDistribution;
  final int mappedToObjectivesCount;
  final double objectiveCoveragePercentage;
  final List<String> topCoveredObjectives;
  final List<String> unmappedObjectives;

  const CorpusAnalytics({
    required this.totalQuestions,
    required this.examDistribution,
    required this.yearDistribution,
    required this.subjectDistribution,
    required this.topicDistribution,
    required this.objectiveDistribution,
    required this.mappedToObjectivesCount,
    required this.objectiveCoveragePercentage,
    required this.topCoveredObjectives,
    required this.unmappedObjectives,
  });

  Map<String, dynamic> toJson() => {
        'totalQuestions': totalQuestions,
        'examDistribution': examDistribution,
        'yearDistribution':
            yearDistribution.map((k, v) => MapEntry(k.toString(), v)),
        'subjectDistribution': subjectDistribution,
        'topicDistribution': topicDistribution,
        'objectiveDistribution': objectiveDistribution,
        'mappedToObjectivesCount': mappedToObjectivesCount,
        'objectiveCoveragePercentage': objectiveCoveragePercentage,
        'topCoveredObjectives': topCoveredObjectives,
        'unmappedObjectives': unmappedObjectives,
      };
}

/// Analyzer computing deterministic corpus statistics.
class PyqCorpusIntelligence {
  static CorpusAnalytics analyze(
    List<NormalizedQuestion> questions, {
    List<String> frameworkObjectiveIds = const [],
  }) {
    if (questions.isEmpty) {
      return CorpusAnalytics(
        totalQuestions: 0,
        examDistribution: const {},
        yearDistribution: const {},
        subjectDistribution: const {},
        topicDistribution: const {},
        objectiveDistribution: const {},
        mappedToObjectivesCount: 0,
        objectiveCoveragePercentage: 0.0,
        topCoveredObjectives: const [],
        unmappedObjectives: frameworkObjectiveIds,
      );
    }

    final examDist = <String, int>{};
    final yearDist = <int, int>{};
    final subjectDist = <String, int>{};
    final topicDist = <String, int>{};
    final objDist = <String, int>{};
    int mappedCount = 0;

    for (final q in questions) {
      examDist[q.examId] = (examDist[q.examId] ?? 0) + 1;
      yearDist[q.year] = (yearDist[q.year] ?? 0) + 1;
      subjectDist[q.subject] = (subjectDist[q.subject] ?? 0) + 1;
      topicDist[q.topic] = (topicDist[q.topic] ?? 0) + 1;

      if (q.objectiveIds.isNotEmpty) {
        mappedCount++;
        for (final obj in q.objectiveIds) {
          objDist[obj] = (objDist[obj] ?? 0) + 1;
        }
      }
    }

    // Top covered objectives
    final sortedObjs = objDist.entries.toList()
      ..sort((a, b) {
        final cmp = b.value.compareTo(a.value);
        if (cmp != 0) return cmp;
        return a.key.compareTo(b.key);
      });
    final topCovered = sortedObjs.take(10).map((e) => e.key).toList();

    // Coverage against framework
    final unmapped = <String>[];
    double coveragePct = 0.0;
    if (frameworkObjectiveIds.isNotEmpty) {
      final coveredSet = objDist.keys.toSet();
      for (final id in frameworkObjectiveIds) {
        if (!coveredSet.contains(id)) {
          unmapped.add(id);
        }
      }
      final coveredCount = frameworkObjectiveIds.length - unmapped.length;
      coveragePct = (coveredCount / frameworkObjectiveIds.length) * 100.0;
    } else {
      coveragePct =
          questions.isNotEmpty ? (mappedCount / questions.length) * 100.0 : 0.0;
    }

    return CorpusAnalytics(
      totalQuestions: questions.length,
      examDistribution: Map.unmodifiable(examDist),
      yearDistribution: Map.unmodifiable(yearDist),
      subjectDistribution: Map.unmodifiable(subjectDist),
      topicDistribution: Map.unmodifiable(topicDist),
      objectiveDistribution: Map.unmodifiable(objDist),
      mappedToObjectivesCount: mappedCount,
      objectiveCoveragePercentage: coveragePct,
      topCoveredObjectives: List.unmodifiable(topCovered),
      unmappedObjectives: List.unmodifiable(unmapped),
    );
  }
}

// ============================================================================
// 9. HISTORICAL TREND ANALYSIS
// ============================================================================

/// Evidence-based insight describing a topic's historical frequency.
@immutable
class TopicTrendInsight {
  final String topic;
  final int totalCount;
  final int recentCount;
  final double recentRatio;
  final String evidenceStatement;

  const TopicTrendInsight({
    required this.topic,
    required this.totalCount,
    required this.recentCount,
    required this.recentRatio,
    required this.evidenceStatement,
  });

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'totalCount': totalCount,
        'recentCount': recentCount,
        'recentRatio': recentRatio,
        'evidenceStatement': evidenceStatement,
      };
}

/// Historical trend summary for an exam.
@immutable
class TrendReport {
  final String examId;
  final Map<String, Map<int, int>> topicFrequencyByYear;
  final Map<String, Map<int, int>> objectiveFrequencyByYear;
  final List<TopicTrendInsight> topicInsights;

  const TrendReport({
    required this.examId,
    required this.topicFrequencyByYear,
    required this.objectiveFrequencyByYear,
    required this.topicInsights,
  });

  Map<String, dynamic> toJson() => {
        'examId': examId,
        'topicFrequencyByYear': topicFrequencyByYear.map(
          (topic, yearMap) =>
              MapEntry(topic, yearMap.map((k, v) => MapEntry(k.toString(), v))),
        ),
        'objectiveFrequencyByYear': objectiveFrequencyByYear.map(
          (obj, yearMap) =>
              MapEntry(obj, yearMap.map((k, v) => MapEntry(k.toString(), v))),
        ),
        'topicInsights': topicInsights.map((i) => i.toJson()).toList(),
      };
}

/// Deterministic trend analyzer.
///
/// Invariants:
/// - Never makes predictions ("This topic will appear in next exam").
/// - Uses historical evidence language ("appeared frequently", "has recent activity").
class PyqTrendAnalyzer {
  static TrendReport analyzeTrends({
    required List<NormalizedQuestion> questions,
    required String examId,
    int recentYearsWindow = 3,
    int? referenceYear,
  }) {
    final examQuestions = questions
        .where((q) => q.examId == examId.trim().toLowerCase())
        .toList();

    if (examQuestions.isEmpty) {
      return TrendReport(
        examId: examId,
        topicFrequencyByYear: const {},
        objectiveFrequencyByYear: const {},
        topicInsights: const [],
      );
    }

    final maxYear =
        referenceYear ?? examQuestions.map((q) => q.year).reduce(math.max);
    final cutoffYear = maxYear - recentYearsWindow + 1;

    final topicYearMap = <String, Map<int, int>>{};
    final objYearMap = <String, Map<int, int>>{};
    final topicTotal = <String, int>{};
    final topicRecent = <String, int>{};

    for (final q in examQuestions) {
      // Topic frequency by year
      final tMap = topicYearMap.putIfAbsent(q.topic, () => {});
      tMap[q.year] = (tMap[q.year] ?? 0) + 1;
      topicTotal[q.topic] = (topicTotal[q.topic] ?? 0) + 1;
      if (q.year >= cutoffYear) {
        topicRecent[q.topic] = (topicRecent[q.topic] ?? 0) + 1;
      }

      // Objective frequency by year
      for (final obj in q.objectiveIds) {
        final oMap = objYearMap.putIfAbsent(obj, () => {});
        oMap[q.year] = (oMap[q.year] ?? 0) + 1;
      }
    }

    // Generate insights
    final insights = <TopicTrendInsight>[];
    for (final entry in topicTotal.entries) {
      final topic = entry.key;
      final total = entry.value;
      final recent = topicRecent[topic] ?? 0;
      final ratio = total > 0 ? recent / total : 0.0;

      String statement;
      if (recent > 0 && ratio >= 0.5) {
        statement =
            '$topic appeared frequently in recent examinations ($recent in last $recentYearsWindow years, total: $total; has recent historical activity).';
      } else if (recent > 0) {
        statement =
            '$topic has consistent historical representation ($total total questions with recent appearances).';
      } else {
        statement =
            '$topic appeared in earlier historical examination papers ($total total questions).';
      }

      insights.add(TopicTrendInsight(
        topic: topic,
        totalCount: total,
        recentCount: recent,
        recentRatio: ratio,
        evidenceStatement: statement,
      ));
    }

    insights.sort((a, b) {
      final cmp = b.recentCount.compareTo(a.recentCount);
      if (cmp != 0) return cmp;
      return b.totalCount.compareTo(a.totalCount);
    });

    return TrendReport(
      examId: examId,
      topicFrequencyByYear: Map.unmodifiable(topicYearMap),
      objectiveFrequencyByYear: Map.unmodifiable(objYearMap),
      topicInsights: List.unmodifiable(insights),
    );
  }
}

// ============================================================================
// 10. MULTI-EXAM PYQ INTELLIGENCE SERVICE (HIGH-LEVEL FACADE)
// ============================================================================

/// Authoritative coordinator for multi-exam PYQ corpus intelligence.
class MultiExamPyqIntelligenceService {
  final ExamRegistry registry;
  final CurriculumObjectiveMapper objectiveMapper;
  final Map<String, NormalizedQuestion> _corpus = {};

  MultiExamPyqIntelligenceService({
    ExamRegistry? registry,
    CurriculumObjectiveMapper? objectiveMapper,
    List<NormalizedQuestion>? initialQuestions,
  })  : registry = registry ?? ExamRegistry(),
        objectiveMapper = objectiveMapper ?? CurriculumObjectiveMapper() {
    if (initialQuestions != null) {
      for (final q in initialQuestions) {
        final mapped = this.objectiveMapper.applyMapping(q);
        _corpus[mapped.id] = mapped;
      }
    }
  }

  int get totalQuestionsCount => _corpus.length;

  List<NormalizedQuestion> getAllQuestions() {
    final list = _corpus.values.toList();
    list.sort((a, b) => a.id.compareTo(b.id));
    return List.unmodifiable(list);
  }

  NormalizedQuestion? getQuestionById(String id) => _corpus[id];

  /// Ingests, normalizes, deduplicates, and maps raw question inputs into the corpus.
  DuplicateDetectionResult ingestRawQuestions(
    List<RawQuestionInput> rawQuestions, {
    PyqSourceReference? defaultSource,
  }) {
    final normalized = PyqNormalizationPipeline.normalizeBatch(
      rawQuestions,
      fallbackSource: defaultSource,
    );

    final mapped = normalized.map(objectiveMapper.applyMapping).toList();

    final result = DeterministicDuplicateDetector.filterDuplicates(
      existingCorpus: _corpus.values.toList(),
      incoming: mapped,
    );

    for (final q in result.uniqueQuestions) {
      _corpus[q.id] = q;
    }

    return result;
  }

  /// Queries the corpus using composable criteria.
  List<NormalizedQuestion> getQuestions(PyqFilterCriteria criteria) {
    return PyqFilterEngine.filter(_corpus.values.toList(), criteria);
  }

  /// Retrieves questions explicitly mapped to a learning objective.
  List<NormalizedQuestion> getQuestionsForObjective(
    String objectiveId, {
    String? examId,
  }) {
    return getQuestions(PyqFilterCriteria(
      objectiveId: objectiveId,
      examId: examId,
    ));
  }

  /// Computes corpus intelligence analytics.
  CorpusAnalytics getCorpusAnalytics({
    String? examId,
    List<String> frameworkObjectiveIds = const [],
  }) {
    final pool = examId != null
        ? _corpus.values
            .where((q) => q.examId == examId.trim().toLowerCase())
            .toList()
        : _corpus.values.toList();

    return PyqCorpusIntelligence.analyze(
      pool,
      frameworkObjectiveIds: frameworkObjectiveIds,
    );
  }

  /// Computes historical trend analysis.
  TrendReport getTrendAnalysis({
    required String examId,
    int recentYearsWindow = 3,
    int? referenceYear,
  }) {
    return PyqTrendAnalyzer.analyzeTrends(
      questions: _corpus.values.toList(),
      examId: examId,
      recentYearsWindow: recentYearsWindow,
      referenceYear: referenceYear,
    );
  }

  /// Exports a serializable JSON snapshot of the indexed corpus.
  Map<String, dynamic> exportSnapshot() => {
        'corpus': _corpus.values.map((q) => q.toJson()).toList(),
      };

  /// Restores corpus from a serialized JSON snapshot.
  void restoreSnapshot(Map<String, dynamic> snapshot) {
    final list = (snapshot['corpus'] as List? ?? [])
        .map((e) =>
            NormalizedQuestion.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    _corpus.clear();
    for (final q in list) {
      _corpus[q.id] = q;
    }
  }

  /// Clears the in-memory corpus.
  void clear() {
    _corpus.clear();
  }
}
