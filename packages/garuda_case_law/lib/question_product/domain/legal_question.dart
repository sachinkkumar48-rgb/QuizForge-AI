/// LegalQuestion model for the Evidence-Backed Question-Answer Knowledge
/// Product layer (TITAN-KO-015.0 P15).
///
/// One deterministic, evidence-backed educational question derived from an
/// explicit validated source. Every question carries a stable deterministic
/// [questionId], a deterministic [questionText], its [questionType], the
/// canonical source references that establish it, a [StructuredAnswer]
/// composed only from validated P4/P11–P14 information, a non-empty
/// [provenance] and an explicit educational [framing] (this is historical /
/// educational case-law information, not legal advice). A question is never
/// invented from general knowledge; missing source information means an
/// omitted question, never a fabricated one (see
/// `P15_QUESTION_KNOWLEDGE_PRODUCT.md`).
library;

import 'package:meta/meta.dart';

import 'question_product_enums.dart';
import 'structured_answer.dart';

/// An immutable, evidence-backed educational question.
@immutable
class LegalQuestion {
  /// Stable deterministic question ID (e.g. `qa:case:KESAVANANDA:issue:0`).
  final String questionId;

  /// Deterministic question wording, derived from explicit source data.
  final String questionText;

  /// The kind of question this is.
  final LegalQuestionType questionType;

  /// Canonical identifiers that establish the question. Never empty.
  final List<String> sourceRefs;

  /// The evidence-backed answer, composed from validated P4/P11–P14 data.
  final StructuredAnswer answer;

  /// Provenance of the question content (e.g. `p4:issues`,
  /// `p12:DoctrineKnowledgeProduct`). Never empty.
  final String provenance;

  /// Deterministic educational framing surfaced with the question.
  final String framing;

  const LegalQuestion({
    required this.questionId,
    required this.questionText,
    required this.questionType,
    required this.sourceRefs,
    required this.answer,
    required this.provenance,
    required this.framing,
  })  : assert(sourceRefs.length > 0, 'a question needs source references'),
        assert(provenance.length > 0, 'a question needs provenance'),
        assert(framing.length > 0, 'a question needs framing');

  /// The canonical source case IDs referenced by this question, filtered to
  /// the given validated corpus, sorted and de-duplicated.
  ///
  /// Statement references also carry non-case identifiers (doctrine IDs,
  /// provision keys, evidence IDs); only identifiers that resolve to a
  /// validated corpus case are returned here.
  List<String> referencedCaseIds(Set<String> corpus) {
    final seen = <String>{};
    final out = <String>[];
    for (final id in sourceRefs) {
      if (corpus.contains(id) && seen.add(id)) out.add(id);
    }
    out.sort();
    return List.unmodifiable(out);
  }

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'questionText': questionText,
        'questionType': questionType.name,
        'sourceRefs': sourceRefs,
        'answer': answer.toJson(),
        'provenance': provenance,
        'framing': framing,
      };

  factory LegalQuestion.fromJson(Map<String, dynamic> json) => LegalQuestion(
        questionId: json['questionId'] as String? ?? '',
        questionText: json['questionText'] as String? ?? '',
        questionType: LegalQuestionType.values.firstWhere(
          (t) => t.name == json['questionType'],
          orElse: () => LegalQuestionType.issue,
        ),
        sourceRefs: (json['sourceRefs'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        answer: StructuredAnswer.fromJson(
            Map<String, dynamic>.from(json['answer'] as Map? ?? const {})),
        provenance: json['provenance'] as String? ?? '',
        framing: json['framing'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegalQuestion &&
          questionId == other.questionId &&
          questionText == other.questionText &&
          questionType == other.questionType &&
          _listEquals(sourceRefs, other.sourceRefs) &&
          answer == other.answer &&
          provenance == other.provenance &&
          framing == other.framing;

  @override
  int get hashCode => Object.hash(questionId, questionType, answer);

  @override
  String toString() => 'LegalQuestion($questionId, ${questionType.name})';

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
