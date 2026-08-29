import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/domain/entities/content_origin.dart';

void main() {
  group('ContentOrigin Enum Tests (TITAN-KO-025.0 P25)', () {
    test('1. Enum contains all 4 distinct epistemic origin categories', () {
      expect(ContentOrigin.values, hasLength(4));
      expect(ContentOrigin.values, contains(ContentOrigin.sourceFact));
      expect(
          ContentOrigin.values, contains(ContentOrigin.pedagogicalExplanation));
      expect(ContentOrigin.values, contains(ContentOrigin.aiGenerated));
      expect(ContentOrigin.values, contains(ContentOrigin.userProvided));
    });

    test(
        '2. Safety properties accurately categorize authoritative vs synthetic content',
        () {
      expect(ContentOrigin.sourceFact.isAuthoritativeSource, isTrue);
      expect(ContentOrigin.sourceFact.isSynthetic, isFalse);

      expect(ContentOrigin.aiGenerated.isAuthoritativeSource, isFalse);
      expect(ContentOrigin.aiGenerated.isSynthetic, isTrue);

      expect(ContentOrigin.pedagogicalExplanation.isHumanEditorial, isTrue);
      expect(
          ContentOrigin.pedagogicalExplanation.isAuthoritativeSource, isFalse);

      expect(ContentOrigin.userProvided.isAuthoritativeSource, isFalse);
      expect(ContentOrigin.userProvided.isSynthetic, isFalse);
    });

    test('3. displayName returns clear, non-ambiguous labels', () {
      expect(ContentOrigin.sourceFact.displayName,
          equals('Authoritative Source Fact'));
      expect(ContentOrigin.aiGenerated.displayName,
          equals('AI-Generated Content'));
    });

    test('4. JSON serialization and fallback deserialization', () {
      expect(ContentOrigin.fromJson('sourceFact'),
          equals(ContentOrigin.sourceFact));
      expect(ContentOrigin.fromJson('aiGenerated'),
          equals(ContentOrigin.aiGenerated));
      expect(ContentOrigin.fromJson('unknown_value'),
          equals(ContentOrigin.pedagogicalExplanation));
      expect(ContentOrigin.fromJson(null),
          equals(ContentOrigin.pedagogicalExplanation));
      expect(ContentOrigin.sourceFact.toJson(), equals('sourceFact'));
    });
  });
}
