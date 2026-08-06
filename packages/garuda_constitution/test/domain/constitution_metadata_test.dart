import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_constitution/garuda_constitution.dart';

void main() {
  group('ConstitutionMetadata Unit Tests', () {
    test('Default metadata values and dates match constitutional facts', () {
      final metadata = ConstitutionMetadata(
        dateAdopted: DateTime(1949, 11, 26),
        dateEnforced: DateTime(1950, 1, 26),
      );

      expect(metadata.title, equals('Constitution of India'));
      expect(metadata.dateAdopted, equals(DateTime(1949, 11, 26)));
      expect(metadata.dateEnforced, equals(DateTime(1950, 1, 26)));
      expect(metadata.originalArticles, equals(395));
      expect(metadata.currentArticles, equals(448));
      expect(metadata.originalParts, equals(22));
      expect(metadata.currentParts, equals(25));
      expect(metadata.originalSchedules, equals(8));
      expect(metadata.currentSchedules, equals(12));
      expect(metadata.officialSources, isNotEmpty);
    });

    test('Serialization (toJson and fromJson) preserves metadata structure', () {
      final metadata = ConstitutionMetadata(
        dateAdopted: DateTime(1949, 11, 26),
        dateEnforced: DateTime(1950, 1, 26),
      );

      final json = metadata.toJson();
      final restored = ConstitutionMetadata.fromJson(json);

      expect(restored.title, equals(metadata.title));
      expect(restored.originalArticles, equals(metadata.originalArticles));
      expect(restored.originalParts, equals(metadata.originalParts));
      expect(restored.currentParts, equals(metadata.currentParts));
      expect(restored.currentSchedules, equals(metadata.currentSchedules));
      expect(restored, equals(metadata));
    });

    test('copyWith modifies specific fields correctly', () {
      final metadata = ConstitutionMetadata(
        dateAdopted: DateTime(1949, 11, 26),
        dateEnforced: DateTime(1950, 1, 26),
      );

      final updated = metadata.copyWith(currentAmendments: 107);
      expect(updated.currentAmendments, equals(107));
      expect(updated.originalArticles, equals(395));
      expect(updated.currentParts, equals(25));
    });
  });
}
