import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_upsc/domain/usecases/generate_quiz_usecase.dart';
import 'package:quizforge_upsc/models/quiz_model.dart';
import 'package:quizforge_upsc/repositories/titan_quiz_repository.dart';

class MockTitanQuizRepoForUseCase implements TitanQuizRepository {
  final QuizModel? returnModel;
  final Exception? throwException;

  MockTitanQuizRepoForUseCase({this.returnModel, this.throwException});

  @override
  Future<QuizModel> generateQuiz(
    PlatformFile pdf, {
    int questionCount = 10,
    void Function(String message)? onProgress,
  }) async {
    onProgress?.call("UseCase progress log");
    if (throwException != null) throw throwException!;
    return returnModel ??
        QuizModel(
            id: 'usecase_quiz', sourceName: pdf.name, questions: const []);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GenerateQuizUseCase Unit Tests', () {
    test(
        'Verification: GenerateQuizUseCase delegates execution to TitanQuizRepository',
        () async {
      final expectedModel =
          QuizModel(id: 'uc_1', sourceName: 'test.pdf', questions: const []);
      final mockRepo = MockTitanQuizRepoForUseCase(returnModel: expectedModel);
      final useCase = GenerateQuizUseCaseImpl(repository: mockRepo);

      final pdf = PlatformFile(name: 'test.pdf', size: 50);
      final progressLog = <String>[];

      final result = await useCase.execute(
        pdf,
        questionCount: 10,
        onProgress: (msg) => progressLog.add(msg),
      );

      expect(result.id, equals('uc_1'));
      expect(progressLog, contains('UseCase progress log'));
    });

    test('Verification: GenerateQuizUseCase propagates errors from repository',
        () async {
      final mockRepo = MockTitanQuizRepoForUseCase(
        throwException: Exception("Repository failure"),
      );
      final useCase = GenerateQuizUseCaseImpl(repository: mockRepo);
      final pdf = PlatformFile(name: 'err.pdf', size: 10);

      expect(
        () => useCase.execute(pdf),
        throwsA(isA<Exception>()),
      );
    });
  });
}
