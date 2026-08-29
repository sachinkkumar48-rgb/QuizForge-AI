import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/domain/entities/bloom_taxonomy_level.dart';
import 'package:garuda_learning/domain/entities/content_origin.dart';
import 'package:garuda_learning/domain/entities/remedial_lesson.dart';
import 'package:garuda_learning/domain/entities/source_reference.dart';

void main() {
  group('RemedialLesson Entity Tests (TITAN-KO-025.0 P25)', () {
    final fixedDate = DateTime.utc(2026, 8, 28, 10, 0, 0);

    final validSource = SourceReference(
      sourceId: 'src_art_14',
      sourceType: SourceReferenceType.constitution,
      referenceIdentifier: 'Article 14, Constitution of India',
      pageNumber: 12,
    );

    RemedialLesson createLesson({
      String lessonId = 'rem_lo_const_02_v1',
      String objectiveId = 'lo_const_02',
      String title = 'Right to Equality & Reasonable Classification',
      String summary = 'Summary of equality doctrine under Article 14',
      List<String>? learningPoints,
      String explanation =
          'Comprehensive explanation of intelligible differentia.',
      int estimatedMinutes = 15,
      int version = 1,
    }) {
      return RemedialLesson(
        lessonId: lessonId,
        objectiveId: objectiveId,
        title: title,
        summary: summary,
        learningPoints: learningPoints ??
            const ['Intelligible Differentia test', 'Nexus with object sought'],
        explanation: explanation,
        examples: const [
          'Special provisions for women and children under Art 15(3)'
        ],
        misconceptions: const [
          'Equality before law does not mean absolute mathematical equality'
        ],
        sourceReferences: [validSource],
        contentOrigin: ContentOrigin.pedagogicalExplanation,
        estimatedMinutes: estimatedMinutes,
        bloomLevel: BloomTaxonomyLevel.analyze,
        authoredAt: fixedDate,
        version: version,
      );
    }

    test('1. Valid construction with all pedagogical fields', () {
      final lesson = createLesson();

      expect(lesson.lessonId, equals('rem_lo_const_02_v1'));
      expect(lesson.objectiveId, equals('lo_const_02'));
      expect(lesson.title, contains('Right to Equality'));
      expect(lesson.learningPoints, hasLength(2));
      expect(lesson.hasExamples, isTrue);
      expect(lesson.hasMisconceptions, isTrue);
      expect(lesson.hasSourceReferences, isTrue);
      expect(
          lesson.contentOrigin, equals(ContentOrigin.pedagogicalExplanation));
      expect(lesson.estimatedMinutes, equals(15));
      expect(lesson.bloomLevel, equals(BloomTaxonomyLevel.analyze));
      expect(lesson.authoredAt, equals(fixedDate));
    });

    test(
        '2. Rejects empty lessonId, objectiveId, title, summary, or explanation',
        () {
      expect(() => createLesson(lessonId: ' '), throwsArgumentError);
      expect(() => createLesson(objectiveId: ' '), throwsArgumentError);
      expect(() => createLesson(title: ' '), throwsArgumentError);
      expect(() => createLesson(summary: ' '), throwsArgumentError);
      expect(() => createLesson(explanation: ' '), throwsArgumentError);
    });

    test('3. Rejects empty learningPoints list', () {
      expect(
        () => createLesson(learningPoints: const []),
        throwsArgumentError,
      );
    });

    test('4. Rejects invalid estimatedMinutes (< 1 or > 120)', () {
      expect(() => createLesson(estimatedMinutes: 0), throwsArgumentError);
      expect(() => createLesson(estimatedMinutes: 121), throwsArgumentError);
    });

    test('5. Rejects version < 1', () {
      expect(() => createLesson(version: 0), throwsArgumentError);
    });

    test('6. copyWith creates an updated immutable instance', () {
      final original = createLesson();
      final updated = original.copyWith(
        title: 'Updated Equality Principle',
        estimatedMinutes: 20,
        version: 2,
      );

      expect(updated.title, equals('Updated Equality Principle'));
      expect(updated.estimatedMinutes, equals(20));
      expect(updated.version, equals(2));
      expect(updated.lessonId, equals(original.lessonId));
    });

    test('7. JSON serialization and deserialization roundtrip', () {
      final original = createLesson();
      final json = original.toJson();
      final restored = RemedialLesson.fromJson(json);

      expect(restored, equals(original));
      expect(restored.hashCode, equals(original.hashCode));
      expect(restored.summary, equals(original.summary));
      expect(restored.learningPoints, equals(original.learningPoints));
      expect(restored.misconceptions, equals(original.misconceptions));
      expect(restored.sourceReferences, hasLength(1));
      expect(restored.sourceReferences.first.sourceId, equals('src_art_14'));
    });
  });
}
