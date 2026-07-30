import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_upsc/core/utils/app_logger.dart';

void main() {
  group('AppLogger Unit Tests', () {
    test('AppLogger methods execute without throwing errors', () {
      expect(
        () => AppLogger.debug('Debug log message', tag: 'TestTag'),
        returnsNormally,
      );

      expect(
        () => AppLogger.info('Info log message', tag: 'TestTag'),
        returnsNormally,
      );

      expect(
        () => AppLogger.error('Error log message', error: Exception('Test Error'), stackTrace: StackTrace.current, tag: 'TestTag'),
        returnsNormally,
      );
    });
  });
}
