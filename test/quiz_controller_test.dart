import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_upsc/controllers/quiz_controller.dart';
import 'package:quizforge_upsc/controllers/quiz_generation_state.dart';
import 'package:quizforge_upsc/core/di/service_locator_init.dart';
import 'package:quizforge_upsc/domain/usecases/generate_quiz_usecase.dart';
import 'package:quizforge_upsc/models/quiz_model.dart';
import 'package:titan_core/titan_core.dart';

class MockGenerateQuizUseCase implements GenerateQuizUseCase {
  final QuizModel? returnModel;
  final Exception? throwException;

  MockGenerateQuizUseCase({this.returnModel, this.throwException});

  @override
  Future<QuizModel> execute(
    PlatformFile pdf, {
    int questionCount = 10,
    void Function(String message)? onProgress,
  }) async {
    onProgress?.call("Mock progress step");
    if (throwException != null) {
      throw throwException!;
    }
    return returnModel ??
        QuizModel(
          id: 'mock_quiz_id',
          sourceName: pdf.name,
          questions: const [],
        );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuizController DI & State Unit Tests', () {
    tearDown(() {
      TitanServiceLocator.instance.reset();
    });

    test('Verification: QuizController initializes with idle state', () {
      final mockUseCase = MockGenerateQuizUseCase();
      final controller = QuizController(generateQuizUseCase: mockUseCase);

      expect(controller.state.status, equals(QuizGenerationStatus.idle));
      expect(controller.state.isIdle, isTrue);
    });

    test('Verification: QuizController resolves via DI setupServiceLocator',
        () {
      setupServiceLocator();
      final controller = locate<QuizController>();

      expect(controller, isNotNull);
      expect(controller.state.isIdle, isTrue);
    });

    test(
        'Verification: Successful quiz generation transitions through generating and success states',
        () async {
      final mockPdf = PlatformFile(name: 'doc.pdf', size: 100);
      final expectedQuiz =
          QuizModel(id: 'q1', sourceName: 'doc.pdf', questions: const []);
      final mockUseCase = MockGenerateQuizUseCase(returnModel: expectedQuiz);
      final controller = QuizController(generateQuizUseCase: mockUseCase);

      final stateHistory = <QuizGenerationStatus>[];
      controller.addListener(() {
        stateHistory.add(controller.state.status);
      });

      final result = await controller.generateQuiz(mockPdf, questionCount: 5);

      expect(result.id, equals('q1'));
      expect(controller.state.isSuccess, isTrue);
      expect(controller.state.quizModel, equals(expectedQuiz));
      expect(stateHistory, contains(QuizGenerationStatus.generating));
      expect(stateHistory.last, equals(QuizGenerationStatus.success));
    });

    test(
        'Verification: API Key error properly categorizes isApiKeyError boolean',
        () async {
      final mockPdf = PlatformFile(name: 'doc.pdf', size: 100);
      final mockUseCase = MockGenerateQuizUseCase(
        throwException: Exception("Invalid API Key provided for Gemini AI"),
      );
      final controller = QuizController(generateQuizUseCase: mockUseCase);

      try {
        await controller.generateQuiz(mockPdf);
      } catch (_) {}

      expect(controller.state.isError, isTrue);
      expect(controller.state.isApiKeyError, isTrue);
      expect(controller.state.message, contains("Invalid API Key"));
    });

    test('Verification: resetState returns state to idle', () {
      final controller =
          QuizController(generateQuizUseCase: MockGenerateQuizUseCase());
      controller.resetState();
      expect(controller.state.isIdle, isTrue);
    });
  });
}
