import 'package:titan_question_bank/titan_question_bank.dart';
import '../../models/knowledge_object.dart';
import '../models/generated_learning_assets.dart';

/// Knowledge Quality Engine for evaluating completeness, structure, readability, and confidence score.
class KnowledgeQualityEngine {
  /// Evaluates a [KnowledgeObject] and its generated assets to assign a [KnowledgeQualityReport].
  KnowledgeQualityReport evaluate({
    required KnowledgeObject obj,
    required List<KmpQuestionItem> questions,
    required List<GeneratedFlashcard> flashcards,
    required SummaryBundle summary,
  }) {
    final issues = <String>[];

    // 1. Completeness Score (0 - 100)
    var completeness = 100.0;
    if (obj.contentBlocks.isEmpty) {
      completeness -= 40.0;
      issues.add('Low completeness: Content blocks are empty.');
    }
    if (obj.concepts.isEmpty) {
      completeness -= 20.0;
      issues.add('Low completeness: No concepts extracted.');
    }
    if (obj.glossary.isEmpty) {
      completeness -= 10.0;
      issues.add('Missing glossary terms.');
    }
    completeness = completeness.clamp(0.0, 100.0);

    // 2. Structure Score (0 - 100)
    var structure = 100.0;
    if (obj.chapter == null && obj.module == null) {
      structure -= 20.0;
      issues.add('Unstructured hierarchy: Missing chapter or module linkage.');
    }
    if (obj.title.trim().isEmpty) {
      structure -= 50.0;
      issues.add('Invalid structure: Blank title.');
    }
    structure = structure.clamp(0.0, 100.0);

    // 3. Readability Score (0 - 100)
    var readability = 85.0;
    if (summary.summary30s.isNotEmpty && summary.detailedSummary.isNotEmpty) {
      readability += 10.0;
    }
    readability = readability.clamp(0.0, 100.0);

    // 4. Metadata Score (0 - 100)
    var metadataScore = 100.0;
    if (obj.metadata.author == 'Unknown') {
      metadataScore -= 15.0;
      issues.add('Unspecified author metadata.');
    }
    metadataScore = metadataScore.clamp(0.0, 100.0);

    // 5. Confidence Score
    final confidence =
        (questions.isNotEmpty && flashcards.isNotEmpty) ? 95.0 : 80.0;

    // Overall Weighted Quality Score
    final overallScore = (completeness * 0.35) +
        (structure * 0.25) +
        (readability * 0.15) +
        (metadataScore * 0.15) +
        (confidence * 0.10);

    return KnowledgeQualityReport(
      sourceKnowledgeObjectId: obj.id,
      score: double.parse(overallScore.toStringAsFixed(1)),
      completenessScore: completeness,
      structureScore: structure,
      readabilityScore: readability,
      metadataScore: metadataScore,
      confidenceScore: confidence,
      qualityIssues: issues,
    );
  }
}
