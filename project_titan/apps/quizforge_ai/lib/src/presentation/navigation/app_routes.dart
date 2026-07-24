/// Central route path and route name constants for QuizForge AI.
abstract class AppRoutes {
  static const String splash = 'splash';
  static const String splashPath = '/splash';

  static const String home = 'home';
  static const String homePath = '/';

  static const String importPdf = 'importPdf';
  static const String importPdfPath = '/import-pdf';

  static const String quizLoading = 'quizLoading';
  static const String quizLoadingPath = '/quiz-loading';

  static const String quiz = 'quiz';
  static const String quizPath = '/quiz/:id';

  static const String result = 'result';
  static const String resultPath = '/result/:id';

  static const String settings = 'settings';
  static const String settingsPath = '/settings';

  static const String library = 'library';
  static const String libraryPath = '/library';

  static const String revision = 'revision';
  static const String revisionPath = '/revision';

  static const String about = 'about';
  static const String aboutPath = '/about';

  /// Helper to build dynamic quiz route path.
  static String buildQuizPath(String sessionId) => '/quiz/$sessionId';

  /// Helper to build dynamic result route path.
  static String buildResultPath(String sessionId) => '/result/$sessionId';
}
