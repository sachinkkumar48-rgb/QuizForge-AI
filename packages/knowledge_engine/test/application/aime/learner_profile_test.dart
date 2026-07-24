import 'package:knowledge_engine/knowledge_engine.dart';
import 'package:test/test.dart';

void main() {
  group('LearnerProfile Tests', () {
    test('initializes correctly with default and custom values', () {
      final profile = LearnerProfile(
        learnerId: 'learner-001',
        preferredSubjects: ['Polity', 'Economy'],
        completedTopics: ['Preamble', 'Fundamental Rights'],
        weakTopics: ['Directive Principles', 'Judicial Review'],
        studyHistory: ['k-101', 'k-102'],
        currentGoal: 'UPSC CSE 2026',
      );

      expect(profile.learnerId, equals('learner-001'));
      expect(profile.preferredSubjects, equals(['Polity', 'Economy']));
      expect(
          profile.completedTopics, equals(['Preamble', 'Fundamental Rights']));
      expect(profile.weakTopics,
          equals(['Directive Principles', 'Judicial Review']));
      expect(profile.studyHistory, equals(['k-101', 'k-102']));
      expect(profile.currentGoal, equals('UPSC CSE 2026'));
    });

    test('guarantees immutability of list collections', () {
      final profile = LearnerProfile(
        learnerId: 'learner-002',
        preferredSubjects: ['Geography'],
      );

      expect(() => (profile.preferredSubjects as List).add('History'),
          throwsUnsupportedError);
      expect(() => (profile.weakTopics as List).add('Monsoon'),
          throwsUnsupportedError);
    });

    test('copyWith modifies specified attributes while preserving others', () {
      final original = LearnerProfile(
        learnerId: 'learner-003',
        currentGoal: 'UPSC CSE 2025',
      );

      final copy = original.copyWith(
        weakTopics: ['Ecology'],
        currentGoal: 'UPSC CSE 2026',
      );

      expect(copy.learnerId, equals('learner-003'));
      expect(copy.weakTopics, equals(['Ecology']));
      expect(copy.currentGoal, equals('UPSC CSE 2026'));
    });

    test('toMap and fromMap achieve full serialization', () {
      final profile = LearnerProfile(
        learnerId: 'learner-004',
        preferredSubjects: ['Polity'],
        completedTopics: ['Topic A'],
        weakTopics: ['Topic B'],
        studyHistory: ['hist-1'],
        currentGoal: 'NDA 2025',
      );

      final map = profile.toMap();
      final restored = LearnerProfile.fromMap(map);

      expect(restored, equals(profile));
      expect(restored.learnerId, equals('learner-004'));
      expect(restored.currentGoal, equals('NDA 2025'));
    });
  });
}
