import 'package:knowledge_engine/knowledge_engine.dart';
import 'package:test/test.dart';

void main() {
  group('CurrentAffairsValidationResult Tests', () {
    test('isValid returns true when success is true and errors is empty', () {
      final result = CurrentAffairsValidationResult(
        success: true,
        warnings: ['Blank summary'],
        statistics: {'count': 1},
      );

      expect(result.isValid, isTrue);
      expect(result.hasWarnings, isTrue);
      expect(result.hasErrors, isFalse);
    });

    test('isValid returns false when fatal errors exist', () {
      final result = CurrentAffairsValidationResult(
        success: false,
        errors: ['Item id cannot be empty.'],
      );

      expect(result.isValid, isFalse);
      expect(result.hasErrors, isTrue);
    });

    test('toMap and fromMap achieve full serialization', () {
      final result = CurrentAffairsValidationResult(
        success: true,
        warnings: ['Warning 1'],
        errors: [],
        statistics: {'processed': 5},
      );

      final map = result.toMap();
      final restored = CurrentAffairsValidationResult.fromMap(map);

      expect(restored, equals(result));
      expect(restored.isValid, isTrue);
      expect(restored.statistics['processed'], equals(5));
    });

    test('copyWith modifies specific fields correctly', () {
      final original = CurrentAffairsValidationResult(
        success: true,
        warnings: ['W1'],
      );

      final copy = original.copyWith(
        errors: ['E1'],
        success: false,
      );

      expect(copy.success, isFalse);
      expect(copy.warnings, equals(['W1']));
      expect(copy.errors, equals(['E1']));
    });
  });
}
