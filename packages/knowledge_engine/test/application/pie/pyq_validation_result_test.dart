import 'package:knowledge_engine/knowledge_engine.dart';
import 'package:test/test.dart';

void main() {
  group('PYQValidationResult Tests', () {
    test('isValid returns true when success is true and errors is empty', () {
      final result = PYQValidationResult(
        success: true,
        warnings: ['Fewer than 4 options'],
        statistics: {'count': 1},
      );

      expect(result.isValid, isTrue);
      expect(result.hasWarnings, isTrue);
      expect(result.hasErrors, isFalse);
    });

    test('isValid returns false when fatal errors exist', () {
      final result = PYQValidationResult(
        success: false,
        errors: ['Question text cannot be empty.'],
      );

      expect(result.isValid, isFalse);
      expect(result.hasErrors, isTrue);
    });

    test('toMap and fromMap achieve full serialization', () {
      final result = PYQValidationResult(
        success: true,
        warnings: ['Warning A'],
        errors: [],
        statistics: {'processed': 10},
      );

      final map = result.toMap();
      final restored = PYQValidationResult.fromMap(map);

      expect(restored, equals(result));
      expect(restored.isValid, isTrue);
      expect(restored.statistics['processed'], equals(10));
    });
  });
}
