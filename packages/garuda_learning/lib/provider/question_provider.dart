/// Question Provider Architecture (TITAN-KO-026.0 Track 1).
///
/// Clean interface and provider implementations decoupling GARUDA Learning
/// from specific upstream knowledge and exam packages.
library;

import 'package:garuda_case_law/garuda_case_law.dart'
    show QuestionKnowledgeProduct, QuestionKnowledgeProductService;
import 'package:garuda_pyq/models/question_model.dart' as pyq;

import '../adapter/legal_question_adapter.dart';
import '../adapter/pyq_question_adapter.dart';
import '../domain/entities/question_entity.dart';

/// Abstract provider boundary for question sources.
abstract interface class QuestionProvider {
  /// Resolves candidate questions mapped to any of the specified [objectiveIds].
  List<IQuestionEntity> getQuestionsForObjectives(List<String> objectiveIds);

  /// Retrieves all available questions in deterministic order.
  List<IQuestionEntity> getAllQuestions();

  /// Resolves a single question by its unique [questionId], or null if absent.
  IQuestionEntity? getQuestionById(String questionId);
}

/// In-memory question provider for direct question registration and testing.
class InMemoryQuestionProvider implements QuestionProvider {
  final Map<String, IQuestionEntity> _questionsById = {};
  final Map<String, Set<String>> _objectiveToQuestionIds = {};

  InMemoryQuestionProvider([List<IQuestionEntity>? initialQuestions]) {
    if (initialQuestions != null) {
      for (final q in initialQuestions) {
        addQuestion(q);
      }
    }
  }

  void addQuestion(IQuestionEntity question, [List<String>? objectiveIds]) {
    _questionsById[question.id] = question;
    final targets = objectiveIds ?? question.objectiveIds;
    for (final objId in targets) {
      _objectiveToQuestionIds.putIfAbsent(objId, () => {}).add(question.id);
    }
  }

  @override
  List<IQuestionEntity> getQuestionsForObjectives(List<String> objectiveIds) {
    final seen = <String>{};
    final result = <IQuestionEntity>[];
    for (final objId in objectiveIds) {
      final qIds = _objectiveToQuestionIds[objId] ?? const {};
      for (final qId in qIds) {
        if (seen.add(qId)) {
          final q = _questionsById[qId];
          if (q != null) result.add(q);
        }
      }
    }
    result.sort((a, b) => a.id.compareTo(b.id));
    return List.unmodifiable(result);
  }

  @override
  List<IQuestionEntity> getAllQuestions() {
    final list = _questionsById.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return List.unmodifiable(list);
  }

  @override
  IQuestionEntity? getQuestionById(String questionId) =>
      _questionsById[questionId];
}

/// Question provider wrapping P15 [QuestionKnowledgeProductService].
class CaseLawQuestionProvider implements QuestionProvider {
  final QuestionKnowledgeProductService? _service;
  final Map<String, List<String>> _productToObjectiveIds;
  List<QuestionKnowledgeProduct>? _cachedProducts;

  CaseLawQuestionProvider({
    QuestionKnowledgeProductService? questionService,
    Map<String, List<String>>? productToObjectiveIds,
    List<QuestionKnowledgeProduct>? prebuiltProducts,
  })  : _service = questionService ??
            (prebuiltProducts == null
                ? QuestionKnowledgeProductService()
                : null),
        _productToObjectiveIds = productToObjectiveIds ?? const {},
        _cachedProducts = prebuiltProducts;

  List<QuestionKnowledgeProduct> _getProducts() {
    return _cachedProducts ??= _service?.buildAll() ?? const [];
  }

  @override
  List<IQuestionEntity> getQuestionsForObjectives(List<String> objectiveIds) {
    final products = _getProducts();
    final candidateObjIds = objectiveIds.toSet();
    final seenIds = <String>{};
    final out = <IQuestionEntity>[];

    for (final prod in products) {
      final mappedObjIds = _productToObjectiveIds[prod.productId] ?? const [];
      final matchesObjective =
          mappedObjIds.any((id) => candidateObjIds.contains(id));

      for (final q in prod.questions) {
        if (matchesObjective || candidateObjIds.isEmpty) {
          if (seenIds.add(q.questionId)) {
            out.add(LegalQuestionAdapter.fromLegalQuestion(
              q,
              objectiveIds: mappedObjIds,
            ));
          }
        }
      }
    }

    out.sort((a, b) => a.id.compareTo(b.id));
    return List.unmodifiable(out);
  }

  @override
  List<IQuestionEntity> getAllQuestions() {
    final products = _getProducts();
    final seenIds = <String>{};
    final out = <IQuestionEntity>[];

    for (final prod in products) {
      final mappedObjIds = _productToObjectiveIds[prod.productId] ?? const [];
      for (final q in prod.questions) {
        if (seenIds.add(q.questionId)) {
          out.add(LegalQuestionAdapter.fromLegalQuestion(
            q,
            objectiveIds: mappedObjIds,
          ));
        }
      }
    }

    out.sort((a, b) => a.id.compareTo(b.id));
    return List.unmodifiable(out);
  }

  @override
  IQuestionEntity? getQuestionById(String questionId) {
    final products = _getProducts();
    for (final prod in products) {
      for (final q in prod.questions) {
        if (q.questionId == questionId) {
          final mappedObjIds =
              _productToObjectiveIds[prod.productId] ?? const [];
          return LegalQuestionAdapter.fromLegalQuestion(
            q,
            objectiveIds: mappedObjIds,
          );
        }
      }
    }
    return null;
  }
}

/// Question provider wrapping canonical [garuda_pyq.Question] entities.
class PyqQuestionProvider implements QuestionProvider {
  final List<pyq.Question> _pyqQuestions;
  final Map<String, List<String>> _topicOrTagToObjectiveIds;

  PyqQuestionProvider({
    required List<pyq.Question> questions,
    Map<String, List<String>>? topicOrTagToObjectiveIds,
  })  : _pyqQuestions = List.unmodifiable(questions),
        _topicOrTagToObjectiveIds = topicOrTagToObjectiveIds ?? const {};

  @override
  List<IQuestionEntity> getQuestionsForObjectives(List<String> objectiveIds) {
    final targetObjSet = objectiveIds.toSet();
    final seen = <String>{};
    final out = <IQuestionEntity>[];

    for (final q in _pyqQuestions) {
      final mappedObjs = _resolveMappedObjectives(q);
      final isMatch = mappedObjs.any((id) => targetObjSet.contains(id));

      if (isMatch || targetObjSet.isEmpty) {
        if (seen.add(q.id)) {
          out.add(PyqQuestionAdapter.fromPyq(q, objectiveIds: mappedObjs));
        }
      }
    }

    out.sort((a, b) => a.id.compareTo(b.id));
    return List.unmodifiable(out);
  }

  @override
  List<IQuestionEntity> getAllQuestions() {
    final list = _pyqQuestions
        .map((q) => PyqQuestionAdapter.fromPyq(
              q,
              objectiveIds: _resolveMappedObjectives(q),
            ))
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return List.unmodifiable(list);
  }

  @override
  IQuestionEntity? getQuestionById(String questionId) {
    for (final q in _pyqQuestions) {
      if (q.id == questionId) {
        return PyqQuestionAdapter.fromPyq(
          q,
          objectiveIds: _resolveMappedObjectives(q),
        );
      }
    }
    return null;
  }

  List<String> _resolveMappedObjectives(pyq.Question q) {
    final matched = <String>{};

    // Check subject, topic, subtopic
    final keys = [
      q.subject.toLowerCase(),
      q.topic.toLowerCase(),
      if (q.subtopic != null) q.subtopic!.toLowerCase(),
      ...q.tags.map((t) => t.toLowerCase()),
    ];

    for (final k in keys) {
      final objs = _topicOrTagToObjectiveIds[k];
      if (objs != null) matched.addAll(objs);
    }

    return matched.toList()..sort();
  }
}

/// Composite question provider unifying multiple underlying providers deterministically.
class CompositeQuestionProvider implements QuestionProvider {
  final List<QuestionProvider> _providers;

  CompositeQuestionProvider(List<QuestionProvider> providers)
      : _providers = List.unmodifiable(providers);

  @override
  List<IQuestionEntity> getQuestionsForObjectives(List<String> objectiveIds) {
    final seen = <String>{};
    final out = <IQuestionEntity>[];
    for (final p in _providers) {
      for (final q in p.getQuestionsForObjectives(objectiveIds)) {
        if (seen.add(q.id)) {
          out.add(q);
        }
      }
    }
    out.sort((a, b) => a.id.compareTo(b.id));
    return List.unmodifiable(out);
  }

  @override
  List<IQuestionEntity> getAllQuestions() {
    final seen = <String>{};
    final out = <IQuestionEntity>[];
    for (final p in _providers) {
      for (final q in p.getAllQuestions()) {
        if (seen.add(q.id)) {
          out.add(q);
        }
      }
    }
    out.sort((a, b) => a.id.compareTo(b.id));
    return List.unmodifiable(out);
  }

  @override
  IQuestionEntity? getQuestionById(String questionId) {
    for (final p in _providers) {
      final q = p.getQuestionById(questionId);
      if (q != null) return q;
    }
    return null;
  }
}
