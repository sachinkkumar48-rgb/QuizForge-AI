import 'package:test/test.dart';
import 'package:titan_ai_mentor/titan_ai_mentor.dart';

void main() {
  group('ContextBuilder Tests', () {
    test('assembles context across 12 TITAN subsystems with custom suppliers',
        () async {
      final builder = ContextBuilder(
        identitySupplier: (_) =>
            {'userName': 'Aspirant', 'targetExam': 'UPSC CSE 2026'},
        learningProfileSupplier: (_) => {
          'weakSubjects': ['Polity', 'Economy'],
          'strongSubjects': ['Geography'],
        },
        recommendationSupplier: (_) => 'Preamble',
        revisionSupplier: (_) => 5,
        plannerSupplier: (_) => {'target': 8.0, 'completed': 4.0},
        dashboardSupplier: (_) => {'accuracyRate': 82.5},
        notesSupplier: (_) => ['Note on Fundamental Rights'],
        recentSessionsSupplier: (_) => ['Session 1: Polity'],
        searchSupplier: (_) => ['Basic Structure'],
        conversationHistorySupplier: (_) => [
          {'role': 'user', 'content': 'Hi'},
          {'role': 'assistant', 'content': 'Hello!'},
        ],
      );

      final ctx = await builder.buildContext(userId: 'u1', userName: 'Default');

      expect(ctx.userName, equals('Aspirant'));
      expect(ctx.targetExam, equals('UPSC CSE 2026'));
      expect(ctx.weakSubjects, contains('Polity'));
      expect(ctx.recommendedTopic, equals('Preamble'));
      expect(ctx.pendingRevisionsCount, equals(5));
      expect(ctx.studyHoursTarget, equals(8.0));
      expect(ctx.accuracyRate, equals(82.5));

      final modules = ctx.metadata['assembledModules'] as List;
      expect(modules, contains('Identity'));
      expect(modules, contains('Learning Profile'));
      expect(modules, contains('Notes'));
      expect(modules, contains('Conversation History'));
    });
  });
}
