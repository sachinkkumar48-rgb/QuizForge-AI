import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_upsc/models/question.dart';
import 'package:quizforge_upsc/models/quiz_analytics.dart';
import 'package:quizforge_upsc/models/quiz_attempt.dart';
import 'package:quizforge_upsc/pages/module_explorer_page.dart';
import 'package:quizforge_upsc/plugins/plugins.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PluginRegistry registry;

  setUp(() {
    registry = PluginRegistry();
    registry.clearRegistry();
  });

  group('Plugin System - Core Registry & Lifecycle Tests', () {
    test(
        'Registering module registers all sub-interfaces and sets default active',
        () async {
      final upsc = UpscModule();
      await registry.registerModule(upsc);

      expect(registry.registeredModules.length, equals(1));
      expect(registry.enabledModules.length, equals(1));
      expect(registry.activeModuleId, equals('upsc'));
      expect(registry.activeModule?.name, equals('UPSC Civil Services'));
    });

    test('Multiple module registration and active module switching', () async {
      await registry.registerModule(UpscModule());
      await registry.registerModule(BpscModule());
      await registry.registerModule(SscModule());

      expect(registry.registeredModules.length, equals(3));
      expect(registry.activeModuleId, equals('upsc'));

      registry.setActiveModule('bpsc');
      expect(registry.activeModuleId, equals('bpsc'));
      expect(registry.activeModule?.name, equals('BPSC State PCS'));

      registry.setActiveModule('ssc');
      expect(registry.activeModuleId, equals('ssc'));
      expect(registry.activeModule?.name, equals('SSC CGL / CHSL'));
    });

    test('Enabling and disabling modules updates active module fallback',
        () async {
      await registry.registerModule(UpscModule());
      await registry.registerModule(BpscModule());

      expect(registry.isModuleEnabled('upsc'), isTrue);
      expect(registry.isModuleEnabled('bpsc'), isTrue);

      await registry.disableModule('upsc');
      expect(registry.isModuleEnabled('upsc'), isFalse);
      expect(registry.activeModuleId, equals('bpsc'));
    });

    test('Unregistering module removes it cleanly from registry', () async {
      await registry.registerModule(UpscModule());
      await registry.registerModule(BpscModule());

      await registry.unregisterModule('bpsc');
      expect(registry.getModule('bpsc'), isNull);
      expect(registry.registeredModules.length, equals(1));
    });
  });

  group('Plugin Interface Compliance - All 10 Required Modules', () {
    final modules = <QuizModule>[
      UpscModule(),
      BpscModule(),
      SscModule(),
      EpfoModule(),
      NdaModule(),
      CdsModule(),
      CapfModule(),
      CurrentAffairsModule(),
      VocabularyModule(),
      EssayModule(),
    ];

    for (final module in modules) {
      test(
          'Module "${module.name}" [${module.id}] conforms to all 5 plugin interfaces',
          () async {
        await registry.registerModule(module);

        // 1. Module
        expect(module.id.isNotEmpty, isTrue);
        expect(module.name.isNotEmpty, isTrue);
        expect(module.description.isNotEmpty, isTrue);
        expect(module.version.isNotEmpty, isTrue);
        expect(module.category.isNotEmpty, isTrue);

        // 2. Repository Interface
        final repo = module.repository;
        expect(repo, isNotNull);
        final initialQuestions = await repo.getQuestions();
        expect(initialQuestions, isA<List<Question>>());

        // 3. UI Interface
        final ui = module.ui;
        expect(ui, isNotNull);

        // 4. Importer Interface
        final importer = module.importer;
        expect(importer, isNotNull);
        expect(importer.supportedFormat.isNotEmpty, isTrue);

        // 5. Analytics Interface
        final analytics = module.analytics;
        expect(analytics, isNotNull);
      });
    }
  });

  group('Plugin Data Repository & Importer Contracts', () {
    test('ModuleRepository handles question saving, filtering, and metadata',
        () async {
      final module = BaseQuizModule(
        id: 'test_module',
        name: 'Test Module',
        description: 'Test Module Description',
      );

      final repo = module.repository;
      await repo.saveQuestions([
        Question(
          id: 'q1',
          exam: 'Test Exam',
          year: 2024,
          paper: 'Paper 1',
          subject: 'Polity',
          topic: 'Preamble',
          difficulty: 'Easy',
          question: 'What is the Preamble?',
          options: ['Option A', 'Option B', 'Option C', 'Option D'],
          correctAnswer: 'Option A',
        ),
      ]);

      final questions = await repo.getQuestions(subject: 'Polity');
      expect(questions.length, equals(1));
      expect(questions.first.id, equals('q1'));

      await repo.setModuleData('user_level', 'Advanced');
      final level = await repo.getModuleData('user_level');
      expect(level, equals('Advanced'));
    });

    test('ModuleImporter validates and imports datasets', () async {
      final importer = BaseModuleImporter(moduleId: 'custom_subject');
      final report = await importer.validateDataset('{"questions": []}');
      expect(report.isValid, isTrue);

      final importedCount = await importer.importDataset('{"questions": []}');
      expect(importedCount, equals(1));
    });

    test('ModuleAnalytics calculates metrics and weakness scores', () async {
      final analyticsEngine = BaseModuleAnalytics(moduleId: 'upsc');
      final attempt = QuizAttempt(
        id: 'att_1',
        completedAt: DateTime.now(),
        sourceName: 'Mock Test 1',
        analytics: QuizAnalytics(
          score: 14,
          totalQuestions: 10,
          attempted: 10,
          skipped: 0,
          incorrect: 2,
          accuracy: 80.0,
          performanceLevel: PerformanceLevel.excellent,
          timeSpent: const Duration(minutes: 5),
          remainingTime: Duration.zero,
          totalDuration: const Duration(minutes: 5),
          statusCounts: const {},
        ),
      );

      final metrics = await analyticsEngine.calculateAnalytics([attempt]);
      expect(metrics.totalQuestions, equals(10));
      expect(metrics.attempted, equals(10));
      expect(metrics.accuracy, equals(80.0));

      final weaknessMap =
          await analyticsEngine.getTopicWeaknessScores([attempt]);
      expect(weaknessMap.isNotEmpty, isTrue);

      final cutoffProb =
          await analyticsEngine.estimateCutoffProbability([attempt]);
      expect(cutoffProb, equals(0.8));
    });
  });

  group('Extensibility - Custom External Plugin Registration', () {
    test(
        'Can create and register custom third-party plugin without modifying core engine',
        () async {
      final customModule = BaseQuizModule(
        id: 'ras_pcs',
        name: 'RAS Rajasthan PCS',
        description: 'Rajasthan Public Service Commission Examination',
        category: 'State Services',
        icon: Icons.flag,
        themeColor: Colors.amber,
      );

      await registry.registerModule(customModule);

      expect(registry.getModule('ras_pcs'), isNotNull);
      expect(registry.getModule('ras_pcs')?.name, equals('RAS Rajasthan PCS'));

      final rasModules = registry.getModulesByCategory('State Services');
      expect(rasModules.any((m) => m.id == 'ras_pcs'), isTrue);
    });
  });

  group('Plugin UI Widget Integration Tests', () {
    testWidgets('ModuleExplorerPage renders registered plugins cleanly',
        (tester) async {
      final registry = PluginRegistry();
      await registry.registerModule(UpscModule());
      await registry.registerModule(BpscModule());

      await tester.pumpWidget(
        const MaterialApp(
          home: ModuleExplorerPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Plugin & Module Hub'), findsOneWidget);
      expect(find.text('UPSC Civil Services'), findsWidgets);
      expect(find.text('BPSC State PCS'), findsWidgets);
    });
  });
}
