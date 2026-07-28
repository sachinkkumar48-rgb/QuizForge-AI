import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_ingestion_pipeline/titan_ingestion_pipeline.dart';

void main() {
  group('Quality Validation Checklist & Widget Tests', () {
    test('QualityValidationChecklist counts validated items correctly', () {
      const checklist = QualityValidationChecklist(
        accuracyValidated: true,
        completenessValidated: true,
        grammarValidated: true,
      );

      expect(checklist.validatedCount, equals(3));
      expect(checklist.isFullyValidated, isFalse);

      final fullyValidated = checklist.copyWith(
        formattingValidated: true,
        metadataValidated: true,
        referencesValidated: true,
        relationshipsValidated: true,
        learningObjectivesValidated: true,
        difficultyValidated: true,
      );

      expect(fullyValidated.validatedCount, equals(9));
      expect(fullyValidated.isFullyValidated, isTrue);
    });

    testWidgets('QualityValidationWidget renders 9 checklist tiles and scores',
        (tester) async {
      const score = EditorialQualityScore(
        knowledgeQuality: 90.0,
        editorialQuality: 85.0,
        completeness: 88.0,
        readability: 92.0,
        consistency: 89.0,
        overallScore: 88.8,
      );

      const checklist = QualityValidationChecklist(accuracyValidated: true);

      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: QualityValidationWidget(
            checklist: checklist,
            score: score,
          ),
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.text('Knowledge & Editorial Quality Evaluation'),
          findsOneWidget);
      expect(find.text('1/9 Validated'), findsOneWidget);
      expect(find.text('1. Accuracy'), findsOneWidget);
      expect(find.text('9. Difficulty Calibration'), findsOneWidget);
    });
  });
}
