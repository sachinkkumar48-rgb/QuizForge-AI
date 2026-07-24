import 'package:titan_domain/titan_domain.dart';

/// Exception thrown by the QuizForge AI Application Layer, wrapping infrastructure/domain failures.
class ApplicationException extends RepositoryException {
  final String code;

  const ApplicationException(
    String message, {
    this.code = 'APP_ERROR',
    Object? cause,
    StackTrace? stackTrace,
  }) : super(message, cause, stackTrace);

  @override
  String toString() => 'ApplicationException[$code]: $message';
}
