import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/domain/entities/remedial_binding.dart';
import 'package:garuda_learning/domain/entities/remedial_lesson.dart';

void main() {
  group('RemedialLessonBinding Entity Tests (TITAN-KO-025.0 P25)', () {
    final fixedDate = DateTime.utc(2026, 8, 28, 10, 0, 0);

    final validLesson = RemedialLesson(
      lessonId: 'rem_lo_const_02_v1',
      objectiveId: 'lo_const_02',
      title: 'Right to Equality',
      summary: 'Summary of Article 14',
      learningPoints: const ['Point 1'],
      explanation: 'Explanation text',
      estimatedMinutes: 10,
      authoredAt: fixedDate,
    );

    test('1. Valid construction with weak-spot trigger and deficiency score',
        () {
      final binding = RemedialLessonBinding(
        bindingId: 'bind_learner1_rem1',
        learnerId: 'learner_100',
        objectiveId: 'lo_const_02',
        lesson: validLesson,
        trigger: RemedialBindingTrigger.weakSpotDiagnostic,
        deficiencyScore: 0.65,
        sourceRecommendationId: 'rec_456',
        boundAt: fixedDate,
      );

      expect(binding.bindingId, equals('bind_learner1_rem1'));
      expect(binding.learnerId, equals('learner_100'));
      expect(binding.objectiveId, equals('lo_const_02'));
      expect(binding.lessonId, equals('rem_lo_const_02_v1'));
      expect(binding.lessonTitle, equals('Right to Equality'));
      expect(
          binding.trigger, equals(RemedialBindingTrigger.weakSpotDiagnostic));
      expect(binding.deficiencyScore, equals(0.65));
      expect(binding.sourceRecommendationId, equals('rec_456'));
      expect(binding.boundAt, equals(fixedDate));
    });

    test('2. Rejects empty bindingId, learnerId, or objectiveId', () {
      expect(
        () => RemedialLessonBinding(
          bindingId: '  ',
          learnerId: 'learner_100',
          objectiveId: 'lo_const_02',
          lesson: validLesson,
          boundAt: fixedDate,
        ),
        throwsArgumentError,
      );

      expect(
        () => RemedialLessonBinding(
          bindingId: 'bind_1',
          learnerId: '  ',
          objectiveId: 'lo_const_02',
          lesson: validLesson,
          boundAt: fixedDate,
        ),
        throwsArgumentError,
      );

      expect(
        () => RemedialLessonBinding(
          bindingId: 'bind_1',
          learnerId: 'learner_100',
          objectiveId: '  ',
          lesson: validLesson,
          boundAt: fixedDate,
        ),
        throwsArgumentError,
      );
    });

    test('3. Rejects invalid deficiencyScore (< 0.0 or > 1.0)', () {
      expect(
        () => RemedialLessonBinding(
          bindingId: 'bind_1',
          learnerId: 'learner_100',
          objectiveId: 'lo_const_02',
          lesson: validLesson,
          deficiencyScore: -0.1,
          boundAt: fixedDate,
        ),
        throwsArgumentError,
      );

      expect(
        () => RemedialLessonBinding(
          bindingId: 'bind_1',
          learnerId: 'learner_100',
          objectiveId: 'lo_const_02',
          lesson: validLesson,
          deficiencyScore: 1.1,
          boundAt: fixedDate,
        ),
        throwsArgumentError,
      );
    });

    test('4. JSON roundtrip preserves binding structure and nested lesson', () {
      final binding = RemedialLessonBinding(
        bindingId: 'bind_test',
        learnerId: 'learner_100',
        objectiveId: 'lo_const_02',
        lesson: validLesson,
        trigger: RemedialBindingTrigger.adaptiveRecommendation,
        deficiencyScore: 0.50,
        sourceRecommendationId: 'rec_abc',
        boundAt: fixedDate,
        metadata: {'notes': 'high priority'},
      );

      final json = binding.toJson();
      final restored = RemedialLessonBinding.fromJson(json);

      expect(restored, equals(binding));
      expect(restored.hashCode, equals(binding.hashCode));
      expect(restored.lesson.lessonId, equals(validLesson.lessonId));
      expect(restored.trigger,
          equals(RemedialBindingTrigger.adaptiveRecommendation));
      expect(restored.metadata['notes'], equals('high priority'));
    });
  });
}
