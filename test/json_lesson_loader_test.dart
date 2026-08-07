import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_upsc/features/learning/data/json_lesson_loader.dart';
import 'package:quizforge_upsc/features/learning/data/lesson_repository.dart';
import 'package:quizforge_upsc/features/learning/models/lesson_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('JsonLessonLoader & LessonRepository', () {
    test('JsonLessonLoader loads lesson JSON asset directly', () async {
      final loader = JsonLessonLoader();
      final lesson = await loader.loadLesson('POL.FR.001');

      expect(lesson.id, equals('POL.FR.001'));
      expect(lesson.steps.length, equals(7));
    });

    test('loadLesson loads POL.FR.001 and deserializes all step types correctly', () async {
      final repository = LessonRepository();
      final lesson = await repository.getLessonById('POL.FR.001');

      expect(lesson.id, equals('POL.FR.001'));
      expect(lesson.title, equals('Why Fundamental Rights?'));
      expect(lesson.subject, equals('Indian Polity'));
      expect(lesson.estimatedTime, equals('15 Minutes'));
      expect(lesson.steps.length, equals(7));

      // 1. Story step
      final storyStep = lesson.steps[0];
      expect(storyStep.type, equals(StepType.story));
      expect(storyStep.story?.storyTitle, equals('Life Without Fundamental Rights'));
      expect(storyStep.mentorMessage, contains("Would you feel secure"));

      // 2. Concept step
      final conceptStep = lesson.steps[1];
      expect(conceptStep.type, equals(StepType.concept));
      expect(conceptStep.concept?.title, equals('What are Fundamental Rights?'));

      // 3. Concept step 2
      final conceptStep2 = lesson.steps[2];
      expect(conceptStep2.type, equals(StepType.concept));
      expect(conceptStep2.concept?.title, equals('Why were Fundamental Rights included?'));

      // 4. Example step
      final exampleStep = lesson.steps[3];
      expect(exampleStep.type, equals(StepType.example));
      expect(exampleStep.example?.scenario, contains('university student'));

      // 5. Quiz step
      final quizStep = lesson.steps[4];
      expect(quizStep.type, equals(StepType.quiz));
      expect(quizStep.quiz?.question, contains('which Part of the Indian Constitution'));
      expect(quizStep.quiz?.correctIndex, equals(1));

      // 6. Revision step
      final revisionStep = lesson.steps[5];
      expect(revisionStep.type, equals(StepType.revision));
      expect(revisionStep.revision?.keyPoints.length, equals(5));

      // 7. Completion step
      final completionStep = lesson.steps[6];
      expect(completionStep.type, equals(StepType.completion));
      expect(completionStep.completion?.progressPercentage, equals(100));
    });

    test('LessonModel.fromJson manual deserialization test', () {
      final jsonMap = {
        'id': 'TEST.001',
        'title': 'Test Title',
        'subject': 'Test Subject',
        'estimatedTime': '5 Minutes',
        'steps': [
          {
            'id': 'step-1',
            'type': 'story',
            'story': {
              'storyTitle': 'Title',
              'storyContent': 'Content',
              'reflectionQuestion': 'Question?'
            }
          }
        ]
      };

      final lesson = LessonModel.fromJson(jsonMap);
      expect(lesson.id, equals('TEST.001'));
      expect(lesson.steps.first.type, equals(StepType.story));
      expect(lesson.steps.first.story?.storyTitle, equals('Title'));
    });
  });
}
