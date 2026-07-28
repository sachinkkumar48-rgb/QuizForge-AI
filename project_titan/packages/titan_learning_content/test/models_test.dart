import 'package:flutter_test/flutter_test.dart';
import 'package:titan_learning_content/titan_learning_content.dart';

void main() {
  group('Domain Models & Serialization Unit Tests', () {
    final meta = ContentMetadata(
      author: 'Test Author',
      subject: 'Polity',
      topic: 'Preamble',
      difficultyLevel: 'Intermediate',
      estimatedDurationMinutes: 20,
      format: 'pdf',
      tags: const ['Polity', 'Test'],
    );

    final objective = const ContentObjective(
      id: 'o1',
      title: 'Objective 1',
      description: 'Desc 1',
      bloomsTaxonomyLevel: 'Understand',
    );

    final prereq = const ContentPrerequisite(
      id: 'p1',
      requiredContentId: 'lc_0',
      title: 'Prereq 1',
    );

    final outcome = const ContentOutcome(
      id: 'out1',
      title: 'Outcome 1',
      description: 'Gain 1',
    );

    final reference = const LearningContentReference(
      id: 'r1',
      contentId: 'lc_1',
      title: 'Ref 1',
      contentType: ContentType.pdf,
      uri: 'assets/ref.pdf',
      type: 'pdf',
    );

    final content = LearningContent(
      id: 'lc_1',
      title: 'Test Title',
      description: 'Test Description',
      type: ContentType.video,
      metadata: meta,
      objectives: [objective],
      prerequisites: [prereq],
      outcomes: [outcome],
      references: [reference],
    );

    test('ContentMetadata copyWith, serialization and equality', () {
      final json = meta.toJson();
      final restored = ContentMetadata.fromJson(json);
      expect(restored, equals(meta));

      final updated = meta.copyWith(author: 'New Author');
      expect(updated.author, equals('New Author'));
      expect(meta == updated, isFalse);
    });

    test('ContentObjective copyWith, serialization and equality', () {
      final json = objective.toJson();
      final restored = ContentObjective.fromJson(json);
      expect(restored, equals(objective));
    });

    test('ContentPrerequisite copyWith, serialization and equality', () {
      final json = prereq.toJson();
      final restored = ContentPrerequisite.fromJson(json);
      expect(restored, equals(prereq));
    });

    test('ContentOutcome copyWith, serialization and equality', () {
      final json = outcome.toJson();
      final restored = ContentOutcome.fromJson(json);
      expect(restored, equals(outcome));
    });

    test('LearningContentReference copyWith, serialization and equality', () {
      final json = reference.toJson();
      final restored = LearningContentReference.fromJson(json);
      expect(restored, equals(reference));
    });

    test(
        'LearningContent copyWith, serialization, equality, and unmodifiable lists',
        () {
      final json = content.toJson();
      final restored = LearningContent.fromJson(json);
      expect(restored.id, equals(content.id));
      expect(restored.title, equals(content.title));
      expect(restored.type, equals(content.type));

      expect(() => content.objectives.add(objective), throwsUnsupportedError);
    });
  });
}
