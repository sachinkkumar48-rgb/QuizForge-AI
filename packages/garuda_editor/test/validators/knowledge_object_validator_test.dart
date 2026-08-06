import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_editor/garuda_editor.dart';

void main() {
  group('KnowledgeObjectValidator Unit Tests', () {
    final now = DateTime.now();

    test('Valid Knowledge Object should pass validation', () {
      final ko = KnowledgeObject(
        id: 'KO-VALID-01',
        title: 'Valid Title Here',
        subject: 'Polity',
        topic: 'Constitutional Rights',
        summary: 'Executive Summary text',
        content: 'Content Body text',
        createdAt: now,
        updatedAt: now,
      );

      final res = KnowledgeObjectValidator.validate(ko);
      expect(res.isValid, isTrue);
      expect(res.errors, isEmpty);
    });

    test('Invalid Knowledge Object with empty fields should fail validation', () {
      final invalid = KnowledgeObject(
        id: '',
        title: 'A', // too short
        subject: '',
        topic: '',
        summary: '',
        content: '',
        createdAt: now,
        updatedAt: now,
      );

      final res = KnowledgeObjectValidator.validate(invalid);
      expect(res.isValid, isFalse);
      expect(res.errors.length, greaterThanOrEqualTo(5));
      expect(res.errors.any((e) => e.field == 'title'), isTrue);
      expect(res.errors.any((e) => e.field == 'subject'), isTrue);
    });
  });
}
