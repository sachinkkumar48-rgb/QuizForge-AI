import '../concepts/concept_model.dart';
import '../models/question_model.dart';
import '../repositories/concept_repository_interface.dart';
import '../repositories/question_concept_repository_interface.dart';
import '../repository/pyq_repository_interface.dart';

class ConceptSearchResult {
  final List<Concept> concepts;
  final List<Question> questions;
  final List<String> matchingKnowledgeObjectIds;

  const ConceptSearchResult({
    required this.concepts,
    required this.questions,
    required this.matchingKnowledgeObjectIds,
  });
}

class ConceptSearchService {
  final IPYQRepository pyqRepository;
  final IConceptRepository conceptRepository;
  final IQuestionConceptRepository mappingRepository;

  ConceptSearchService({
    required this.pyqRepository,
    required this.conceptRepository,
    required this.mappingRepository,
  });

  /// Unified search across Concepts, Questions, Knowledge Objects, Articles, Cases, Acts, and Keywords.
  Future<ConceptSearchResult> search({
    String? conceptQuery,
    String? questionQuery,
    String? knowledgeObjectId,
    String? article,
    String? caseName,
    String? actName,
    String? keyword,
  }) async {
    final allConcepts = await conceptRepository.getAllConcepts();
    final allQuestions = await pyqRepository.getAllQuestions();

    final matchedConcepts = <Concept>[];
    final matchedQuestions = <Question>[];
    final matchedKOIds = <String>{};

    final kw = keyword?.trim().toLowerCase();

    // 1. Filter Concepts
    for (final concept in allConcepts) {
      bool isMatch = false;

      if (conceptQuery != null &&
          (concept.id.toLowerCase() == conceptQuery.toLowerCase() ||
              concept.name.toLowerCase().contains(conceptQuery.toLowerCase()))) {
        isMatch = true;
      }

      if (knowledgeObjectId != null &&
          concept.knowledgeObjectIds.contains(knowledgeObjectId)) {
        isMatch = true;
        matchedKOIds.add(knowledgeObjectId);
      }

      if (kw != null && kw.isNotEmpty) {
        if (concept.name.toLowerCase().contains(kw) ||
            concept.description.toLowerCase().contains(kw) ||
            concept.aliases.any((a) => a.toLowerCase().contains(kw)) ||
            concept.keywords.any((k) => k.toLowerCase().contains(kw))) {
          isMatch = true;
        }
      }

      if (isMatch) {
        matchedConcepts.add(concept);
        matchedKOIds.addAll(concept.knowledgeObjectIds);
      }
    }

    // 2. Filter Questions
    for (final q in allQuestions) {
      bool isMatch = false;

      if (questionQuery != null &&
          (q.id.toLowerCase() == questionQuery.toLowerCase() ||
              q.originalQuestion.toLowerCase().contains(questionQuery.toLowerCase()))) {
        isMatch = true;
      }

      if (article != null &&
          q.articleLinks.any((a) => a.toLowerCase().contains(article.toLowerCase()))) {
        isMatch = true;
      }

      if (caseName != null &&
          q.caseLinks.any((c) => c.toLowerCase().contains(caseName.toLowerCase()))) {
        isMatch = true;
      }

      if (actName != null &&
          q.actLinks.any((ac) => ac.toLowerCase().contains(actName.toLowerCase()))) {
        isMatch = true;
      }

      if (kw != null && kw.isNotEmpty) {
        if (q.originalQuestion.toLowerCase().contains(kw) ||
            q.garudaExplanation.toLowerCase().contains(kw) ||
            q.tags.any((t) => t.toLowerCase().contains(kw))) {
          isMatch = true;
        }
      }

      if (isMatch) {
        matchedQuestions.add(q);
        matchedKOIds.addAll(q.knowledgeObjectLinks);
      }
    }

    return ConceptSearchResult(
      concepts: matchedConcepts,
      questions: matchedQuestions,
      matchingKnowledgeObjectIds: matchedKOIds.toList(),
    );
  }
}
