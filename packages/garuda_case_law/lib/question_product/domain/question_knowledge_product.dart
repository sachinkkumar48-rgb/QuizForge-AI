/// QuestionKnowledgeProduct model for the Evidence-Backed Question-Answer
/// Knowledge Product layer (TITAN-KO-015.0 P15).
///
/// A deterministic, immutable, provenance-preserving collection of
/// evidence-backed educational questions for one validated source (a case and
/// its P4 intelligence, or a P12/P13/P14 knowledge product). It is a
/// composition / read-model over existing validated P3–P14 data: it never
/// invents questions, never performs legal research, never infers legal
/// meaning and never gives legal advice. Every question carries traceable
/// provenance and every answer carries traceable evidence (see
/// `P15_QUESTION_KNOWLEDGE_PRODUCT.md`).
library;

import 'package:meta/meta.dart';

import 'legal_question.dart';
import 'question_product_enums.dart';

/// An immutable, evidence-backed question-answer knowledge product.
@immutable
class QuestionKnowledgeProduct {
  /// Fixed marker of this knowledge-product kind.
  static const String questionKind =
      'evidence-backed-question-knowledge-product';

  /// Stable deterministic product ID (e.g. `qa:case:KESAVANANDA`,
  /// `qa:doctrine:BASIC_STRUCTURE`, `qa:topic:amending_power`).
  final String productId;

  /// The kind of validated source the product is built over.
  final QuestionSourceType sourceType;

  /// Canonical source identifier (case ID, doctrine ID, provision key or
  /// topic ID).
  final String sourceId;

  /// Display source name.
  final String sourceName;

  /// The eligible questions, in fixed deterministic order. Missing source
  /// information is represented by an omitted question, never a fabricated one.
  final List<LegalQuestion> questions;

  const QuestionKnowledgeProduct({
    required this.productId,
    required this.sourceType,
    required this.sourceId,
    required this.sourceName,
    required this.questions,
  });

  /// Whether the product carries no eligible questions (an empty product is
  /// never emitted by the service — unknown / question-less sources return
  /// null instead).
  bool get isEmpty => questions.isEmpty;

  /// The question of [id], or null when absent.
  LegalQuestion? questionOf(String id) {
    for (final q in questions) {
      if (q.questionId == id) return q;
    }
    return null;
  }

  /// Unique canonical source identifiers referenced anywhere in the product,
  /// including the source's own ID, sorted.
  ///
  /// Identifiers are the raw canonical keys carried by question references —
  /// case IDs, doctrine IDs, provision keys, holding/issue IDs and evidence
  /// IDs — so this is NOT a list of case IDs. Consumers that need only the
  /// referenced *cases* must filter against the validated corpus via
  /// `QuestionKnowledgeProductService.referencedCaseIds`.
  List<String> get referencedIds {
    final seen = <String>{productId};
    final out = <String>[productId];
    for (final q in questions) {
      for (final r in q.sourceRefs) {
        if (seen.add(r)) out.add(r);
      }
      for (final r in q.answer.evidenceRefs) {
        if (seen.add(r)) out.add(r);
      }
    }
    out.sort();
    return List.unmodifiable(out);
  }

  Map<String, dynamic> toJson() => {
        'questionKind': questionKind,
        'productId': productId,
        'sourceType': sourceType.name,
        'sourceId': sourceId,
        'sourceName': sourceName,
        'questions': questions.map((q) => q.toJson()).toList(),
      };

  factory QuestionKnowledgeProduct.fromJson(Map<String, dynamic> json) =>
      QuestionKnowledgeProduct(
        productId: json['productId'] as String? ?? '',
        sourceType: QuestionSourceType.values.firstWhere(
          (t) => t.name == json['sourceType'],
          orElse: () => QuestionSourceType.caseLaw,
        ),
        sourceId: json['sourceId'] as String? ?? '',
        sourceName: json['sourceName'] as String? ?? '',
        questions: (json['questions'] as List<dynamic>? ?? const [])
            .map((e) =>
                LegalQuestion.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionKnowledgeProduct &&
          productId == other.productId &&
          sourceType == other.sourceType &&
          sourceId == other.sourceId &&
          sourceName == other.sourceName &&
          _listEquals(questions, other.questions);

  @override
  int get hashCode => Object.hash(productId, sourceType, sourceId);

  @override
  String toString() =>
      'QuestionKnowledgeProduct($productId, ${questions.length} questions)';

  static bool _listEquals(List<LegalQuestion> a, List<LegalQuestion> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
