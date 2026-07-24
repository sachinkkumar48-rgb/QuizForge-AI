import '../../exceptions/application_exception.dart';

/// Central presentation localization dictionary and user-friendly error string mapper.
abstract class AppLocalization {
  // App General Strings
  static const String appTitle = 'QuizForge AI';
  static const String appSubtitle =
      'AI-Powered UPSC Quiz Generator & Practice Engine';

  // Navigation Titles
  static const String navHome = 'Home';
  static const String navImportPdf = 'Import PDF';
  static const String navQuizLoading = 'Generating Quiz';
  static const String navQuiz = 'Quiz Session';
  static const String navResult = 'Result Summary';
  static const String navSettings = 'Settings';
  static const String navAbout = 'About';

  // Buttons & Actions
  static const String btnStartQuiz = 'Start Quiz';
  static const String btnImportPdf = 'Select PDF Document';
  static const String btnSubmitAnswer = 'Submit Answer';
  static const String btnNextQuestion = 'Next Question';
  static const String btnCompleteQuiz = 'Finish Session';
  static const String btnRetry = 'Try Again';
  static const String btnBackToHome = 'Return to Home';

  // Empty State Messages
  static const String emptyQuizTitle = 'No Active Quiz';
  static const String emptyQuizSubtitle =
      'Import a PDF document to generate your first AI practice quiz.';

  // Error Resolution
  /// Converts any error object (including [ApplicationException]) into a user-friendly message.
  static String formatErrorMessage(Object? error) {
    if (error is ApplicationException) {
      switch (error.code) {
        case 'PDF_ERROR':
          return 'Unable to process the PDF document. Please ensure it is a valid, unencrypted file.';
        case 'AI_QUIZ_GEN_ERROR':
          return 'Quiz generation encountered an issue with AI services. Please try again.';
        case 'QUIZ_SESSION_ERROR':
          return 'An error occurred during the quiz session. Please restart your quiz session.';
        case 'SESSION_NOT_FOUND':
          return 'Requested quiz session was not found.';
        case 'QUIZ_NOT_FOUND':
          return 'Target quiz content could not be located.';
        default:
          return error.message;
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
