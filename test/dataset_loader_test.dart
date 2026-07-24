import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_upsc/models/validation_report.dart';
import 'package:quizforge_upsc/services/dataset_loader.dart';
import 'package:quizforge_upsc/services/generic_dataset_importer.dart';

import 'dataset_importer_test.dart'; // Re-use in-memory repository implementations

class MockAssetBundle extends AssetBundle {
  final Map<String, String> assets;

  MockAssetBundle(this.assets);

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key == 'AssetManifest.json') {
      final Map<String, List<String>> manifest = {};
      for (final k in assets.keys) {
        manifest[k] = [k];
      }
      return jsonEncode(manifest);
    }
    if (assets.containsKey(key)) {
      return assets[key]!;
    }
    throw Exception('Asset $key not found');
  }

  @override
  Future<ByteData> load(String key) async {
    final str = await loadString(key);
    final bytes = utf8.encode(str);
    return ByteData.view(Uint8List.fromList(bytes).buffer);
  }
}

void main() {
  group('DatasetLoader Discovery, Validation & Loading Tests', () {
    late InMemoryExamRepository examRepo;
    late InMemoryQuestionRepository questionRepo;
    late InMemoryExplanationRepository explanationRepo;
    late InMemoryDatasetRepository datasetRepo;
    late GenericDatasetImporter importer;

    late Map<String, String> mockAssetMap;
    late MockAssetBundle mockBundle;
    late DatasetLoader loader;

    setUp(() {
      examRepo = InMemoryExamRepository();
      questionRepo = InMemoryQuestionRepository();
      explanationRepo = InMemoryExplanationRepository();
      datasetRepo = InMemoryDatasetRepository();

      importer = GenericDatasetImporter(
        examRepository: examRepo,
        questionRepository: questionRepo,
        explanationRepository: explanationRepo,
        datasetRepository: datasetRepo,
      );

      mockAssetMap = {
        'assets/datasets/upsc/prelims/gs1/2025/dataset.json': jsonEncode({
          "manifest": {
            "datasetId": "upsc_prelims_gs1_2025",
            "datasetVersion": "1.0.0",
            "schemaVersion": "1.0",
            "exam": "UPSC CSE Prelims",
            "paper": "GS Paper I",
            "totalQuestions": 1
          },
          "questions": [
            {
              "id": "UPSC_PRE_GS1_2025_Q001",
              "year": 2025,
              "exam": "UPSC CSE Prelims",
              "paper": "GS Paper 1",
              "subject": "Polity",
              "topic": "Preamble",
              "difficulty": "Medium",
              "question": "Question 2025",
              "options": ["A", "B"],
              "correctAnswer": "A"
            }
          ]
        }),
        'assets/datasets/upsc/prelims/gs1/2024/dataset.json': jsonEncode({
          "manifest": {
            "datasetId": "upsc_prelims_gs1_2024",
            "datasetVersion": "1.0.0",
            "schemaVersion": "1.0",
            "exam": "UPSC CSE Prelims",
            "paper": "GS Paper I",
            "totalQuestions": 1
          },
          "questions": [
            {
              "id": "UPSC_PRE_GS1_2024_Q001",
              "year": 2024,
              "exam": "UPSC CSE Prelims",
              "paper": "GS Paper 1",
              "subject": "Economy",
              "topic": "Banking",
              "difficulty": "Hard",
              "question": "Question 2024",
              "options": ["Opt 1", "Opt 2"],
              "correctAnswer": "Opt 1"
            }
          ]
        }),
        'assets/datasets/bpsc/70th/dataset.json': jsonEncode({
          "manifest": {
            "datasetId": "bpsc_70th_prelims",
            "datasetVersion": "1.0.0",
            "schemaVersion": "1.0",
            "exam": "BPSC CCE",
            "paper": "General Studies",
            "totalQuestions": 1
          },
          "questions": [
            {
              "id": "BPSC_PRE_GS_2024_Q001",
              "year": 2024,
              "exam": "BPSC CCE",
              "paper": "General Studies",
              "subject": "History",
              "topic": "Bihar",
              "difficulty": "Medium",
              "question": "Question BPSC",
              "options": ["Ans A", "Ans B"],
              "correctAnswer": "Ans A"
            }
          ]
        }),
      };

      mockBundle = MockAssetBundle(mockAssetMap);
      loader = DatasetLoader(importer: importer, assetBundle: mockBundle);
    });

    test(
        'Discovers all dataset asset paths dynamically without hardcoded paths',
        () async {
      final paths = await loader.discoverDatasetAssetPaths();
      expect(paths.length, equals(3));
      expect(paths,
          contains('assets/datasets/upsc/prelims/gs1/2025/dataset.json'));
      expect(paths,
          contains('assets/datasets/upsc/prelims/gs1/2024/dataset.json'));
      expect(paths, contains('assets/datasets/bpsc/70th/dataset.json'));
    });

    test('Discovers manifests metadata without performing database writes',
        () async {
      final manifests = await loader.discoverManifests();
      expect(manifests.length, equals(3));

      final ids = manifests.map((m) => m.datasetId).toList();
      expect(ids, contains('upsc_prelims_gs1_2025'));
      expect(ids, contains('upsc_prelims_gs1_2024'));
      expect(ids, contains('bpsc_70th_prelims'));

      // Ensure no database writes occurred during manifest discovery
      final questions = await questionRepo.getAllQuestions();
      expect(questions, isEmpty);
    });

    test('Loads, validates, and imports all discovered datasets', () async {
      final totalImported = await loader.loadAndImportAllDiscovered();
      expect(totalImported, equals(3));

      final savedQuestions = await questionRepo.getAllQuestions();
      expect(savedQuestions.length, equals(3));

      expect(await questionRepo.getQuestionById('UPSC_PRE_GS1_2025_Q001'),
          isNotNull);
      expect(await questionRepo.getQuestionById('UPSC_PRE_GS1_2024_Q001'),
          isNotNull);
      expect(await questionRepo.getQuestionById('BPSC_PRE_GS_2024_Q001'),
          isNotNull);

      // Verify dataset manifests stored
      final manifests = await datasetRepo.getAllManifests();
      expect(manifests.length, equals(3));
    });

    test('Version & Schema compatibility check during loading', () async {
      mockAssetMap['assets/datasets/incompatible/dataset.json'] = jsonEncode({
        "manifest": {
          "datasetId": "incompatible_dataset",
          "datasetVersion": "1.0.0",
          "schemaVersion": "99.0", // Unsupported schema
          "exam": "Unknown Exam",
          "paper": "Paper 1",
          "totalQuestions": 0
        },
        "questions": []
      });

      expect(
        () => loader.loadAndImportAsset(
          'assets/datasets/incompatible/dataset.json',
          importMode: ImportMode.strict,
        ),
        throwsA(isA<DatasetValidationException>().having(
          (e) => e.message,
          'message',
          contains('Unsupported schema version'),
        )),
      );
    });
  });
}
