import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_upsc/features/learning/controllers/lesson_player_controller.dart';
import 'package:quizforge_upsc/features/learning/data/json_lesson_loader.dart';
import 'package:quizforge_upsc/features/learning/data/lesson_repository.dart';
import 'package:quizforge_upsc/features/learning/models/lesson_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('POL.FR.002 Gold Standard Integration Tests', () {
    final repository = LessonRepository();
    final loader = JsonLessonLoader();

    test('Manifest lists POL.FR.001 and POL.FR.002 correctly', () async {
      final manifest = await repository.getLessonManifest();
      expect(manifest.length, greaterThanOrEqualTo(2));

      final polFr002Entry = manifest.firstWhere(
        (e) => e['id'] == 'POL.FR.002',
        orElse: () => {},
      );
      expect(polFr002Entry['id'], equals('POL.FR.002'));
      expect(polFr002Entry['title'], contains('Articles 12 & 13'));
    });

    test('JsonLessonLoader loads and parses POL.FR.002 correctly', () async {
      final lesson = await loader.loadLesson('POL.FR.002');

      expect(lesson.id, equals('POL.FR.002'));
      expect(lesson.title, equals('Articles 12 & 13: Definition of State & Judicial Review'));
      expect(lesson.subject, equals('Indian Polity'));
      expect(lesson.estimatedTime, equals('20 Minutes'));
      expect(lesson.steps.length, equals(7));
    });

    test('LessonRepository fetches POL.FR.002 with all 7 step types validated', () async {
      final lesson = await repository.getLessonById('POL.FR.002');

      // Step 1: Story
      final step1 = lesson.steps[0];
      expect(step1.id, equals('step-1'));
      expect(step1.type, equals(StepType.story));
      expect(step1.story?.storyTitle, equals('Who is the State?'));
      expect(step1.mentorMessage, contains('who can violate your Fundamental Rights'));
      expect(step1.reflectionQuestion, contains('government-funded university'));

      // Step 2: Concept (Article 12)
      final step2 = lesson.steps[1];
      expect(step2.id, equals('step-2'));
      expect(step2.type, equals(StepType.concept));
      expect(step2.concept?.title, equals('Article 12: Definition of State'));
      expect(step2.mentorHint, contains('protect individuals against State action'));
      expect(step2.concept?.upscTip, contains('Judiciary in its judicial capacity'));

      // Step 3: Concept (Article 13)
      final step3 = lesson.steps[2];
      expect(step3.id, equals('step-3'));
      expect(step3.type, equals(StepType.concept));
      expect(step3.concept?.title, equals('Article 13: Laws Inconsistent with Fundamental Rights'));
      expect(step3.concept?.keyPoint, contains('paramountcy of Fundamental Rights'));

      // Step 4: Example (Doctrine of Severability)
      final step4 = lesson.steps[3];
      expect(step4.id, equals('step-4'));
      expect(step4.type, equals(StepType.example));
      expect(step4.example?.scenario, contains('Parliament passes a law'));
      expect(step4.example?.takeaway, contains('invalidate only the unconstitutional portion'));

      // Step 5: Quiz
      final step5 = lesson.steps[4];
      expect(step5.id, equals('step-5'));
      expect(step5.type, equals(StepType.quiz));
      expect(step5.quiz?.question, contains('Articles 12 and 13'));
      expect(step5.quiz?.correctIndex, equals(1));
      expect(step5.quiz?.explanation, contains('Statement 2 is CORRECT'));

      // Step 6: Revision
      final step6 = lesson.steps[5];
      expect(step6.id, equals('step-6'));
      expect(step6.type, equals(StepType.revision));
      expect(step6.revision?.title, equals('Summary: Articles 12 & 13'));
      expect(step6.revision?.keyPoints.length, equals(5));

      // Step 7: Completion
      final step7 = lesson.steps[6];
      expect(step7.id, equals('step-7'));
      expect(step7.type, equals(StepType.completion));
      expect(step7.completion?.title, equals('Lesson Completed!'));
      expect(step7.completion?.progressPercentage, equals(100));
    });

    test('LessonPlayerController step navigation and completion progress', () async {
      final controller = LessonPlayerController(repository: repository);
      await controller.loadLesson('POL.FR.002');

      expect(controller.lesson?.id, equals('POL.FR.002'));
      expect(controller.currentStep, equals(1));
      expect(controller.totalSteps, equals(7));
      expect(controller.hasPrevious, isFalse);
      expect(controller.hasNext, isTrue);

      // Advance through all steps
      for (int i = 0; i < 6; i++) {
        controller.nextStep();
      }

      expect(controller.currentStep, equals(7));
      expect(controller.hasNext, isFalse);
      expect(controller.completionPercentage, equals(100));
    });
  });
}
