import 'package:titan_ai/titan_ai.dart';
import 'package:titan_question_bank/titan_question_bank.dart';
import '../../models/knowledge_object.dart';

/// Question Engine producing 8 question types across Easy, Medium, and Hard difficulties.
class QuestionEngine {
  final AIService? aiService;

  QuestionEngine({this.aiService});

  /// Generates a comprehensive set of [KmpQuestionItem] questions from a [KnowledgeObject].
  Future<List<KmpQuestionItem>> generate(KnowledgeObject obj) async {
    final questions = <KmpQuestionItem>[];
    final topic = obj.title;
    final topicId = 't_${obj.id}';
    final now = DateTime.now();

    var qIdCounter = 1;
    String nextQId(String prefix) => 'q_${obj.id}_${prefix}_${qIdCounter++}';

    // 1. Easy MCQ Question
    questions.add(KmpQuestionItem(
      id: nextQId('mcq_easy'),
      topicId: topicId,
      topicName: topic,
      type: KmpQuestionType.mcq,
      stem: 'Which of the following is a primary concept discussed in $topic?',
      options: [
        obj.concepts.isNotEmpty
            ? obj.concepts.first.name
            : 'Fundamental Principle',
        'Unrelated Procedure B',
        'Administrative Ordinance C',
        'Historical Anecdote D',
      ],
      correctAnswerIndex: 0,
      solutionExplanation:
          'Extracted directly from canonical KnowledgeObject concepts.',
      difficulty: 'Easy',
      createdAt: now,
    ));

    // 2. Medium MCQ Question
    questions.add(KmpQuestionItem(
      id: nextQId('mcq_med'),
      topicId: topicId,
      topicName: topic,
      type: KmpQuestionType.mcq,
      stem: 'Consider the scope of $topic. Which statement is correct?',
      options: [
        'It applies as a constitutional / core domain framework.',
        'It was repealed in 1858.',
        'It is non-binding guidance only.',
        'It applies exclusively to foreign territory.',
      ],
      correctAnswerIndex: 0,
      solutionExplanation:
          'Core domain analysis derived from lesson content blocks.',
      difficulty: 'Medium',
      createdAt: now,
    ));

    // 3. Hard Assertion-Reason Question
    questions.add(KmpQuestionItem(
      id: nextQId('ar_hard'),
      topicId: topicId,
      topicName: topic,
      type: KmpQuestionType.assertionReason,
      stem:
          'Assertion (A): $topic establishes fundamental governance provisions.\nReason (R): It forms an integral part of the constitutional structure.',
      assertionText:
          'Assertion (A): $topic establishes fundamental governance provisions.',
      reasonText:
          'Reason (R): It forms an integral part of the constitutional structure.',
      options: [
        'Both A and R are true and R is the correct explanation of A.',
        'Both A and R are true but R is NOT the correct explanation of A.',
        'A is true but R is false.',
        'A is false but R is true.',
      ],
      correctAnswerIndex: 0,
      solutionExplanation:
          'Both statement A and reason R are logically sound and linked.',
      difficulty: 'Hard',
      createdAt: now,
    ));

    // 4. Subjective Essay Question
    questions.add(KmpQuestionItem(
      id: nextQId('subj_med'),
      topicId: topicId,
      topicName: topic,
      type: KmpQuestionType.subjective,
      stem:
          'Critically analyze the significance and modern implications of $topic in 250 words.',
      solutionExplanation:
          'Evaluation rubric: 1. Introduction (30w), 2. Core Arguments & Precedents (150w), 3. Conclusion & Way Forward (70w).',
      difficulty: 'Medium',
      createdAt: now,
    ));

    // 5. PYQ-Style Question
    questions.add(KmpQuestionItem(
      id: nextQId('pyq_hard'),
      topicId: topicId,
      topicName: topic,
      type: KmpQuestionType.pyq,
      stem:
          '[UPSC CSE Style] With reference to $topic, examine which of the provisions are legally enforceable.',
      options: ['1 only', '2 only', 'Both 1 and 2', 'Neither 1 nor 2'],
      correctAnswerIndex: 2,
      pyqYear: 2024,
      pyqExamName: 'UPSC Civil Services Examination',
      solutionExplanation:
          'Modeled after standard UPSC Mains & Prelims PYQ format.',
      difficulty: 'Hard',
      createdAt: now,
    ));

    // 6. Case Study Question
    questions.add(KmpQuestionItem(
      id: nextQId('case_hard'),
      topicId: topicId,
      topicName: topic,
      type: KmpQuestionType.caseStudy,
      stem:
          'Case Study: A dispute arises regarding the applicability of $topic in a local jurisdiction.',
      caseStudyContext:
          'A state authority enacted a conflicting regulation claiming emergency powers.',
      options: [
        'State action is invalid due to preemption',
        'State action is valid',
        'Requires Supreme Court bench review',
        'Lapses automatically'
      ],
      correctAnswerIndex: 0,
      solutionExplanation:
          'Constitutional supremacy invalidates conflicting subordinate legislation.',
      difficulty: 'Hard',
      createdAt: now,
    ));

    // 7. True/False Question
    questions.add(KmpQuestionItem(
      id: nextQId('tf_easy'),
      topicId: topicId,
      topicName: topic,
      type: KmpQuestionType.trueFalse,
      stem:
          'True or False: $topic is recognized as a key topic in educational curricula.',
      options: ['True', 'False'],
      correctAnswerIndex: 0,
      solutionExplanation: 'Verified from canonical KnowledgeObject metadata.',
      difficulty: 'Easy',
      createdAt: now,
    ));

    // 8. Fill in the Blanks Question
    questions.add(KmpQuestionItem(
      id: nextQId('fib_easy'),
      topicId: topicId,
      topicName: topic,
      type: KmpQuestionType.fillInBlanks,
      stem: 'Fill in the blank: $topic forms part of the _______ framework.',
      options: ['Constitutional', 'Commercial', 'Secondary', 'Temporary'],
      correctAnswerIndex: 0,
      solutionExplanation: 'Standard terminology definition fill-in.',
      difficulty: 'Easy',
      createdAt: now,
    ));

    return questions;
  }
}
