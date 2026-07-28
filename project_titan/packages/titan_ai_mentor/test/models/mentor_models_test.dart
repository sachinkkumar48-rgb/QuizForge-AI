import 'package:flutter_test/flutter_test.dart';
import 'package:titan_ai_mentor/titan_ai_mentor.dart';

void main() {
  group('Mentor Models Unit Tests', () {
    final now = DateTime(2026, 7, 24, 18, 0);

    test('MentorMessage creation and serialization', () {
      final msg = MentorMessage(
        id: 'm_1',
        sender: MentorMessageSender.user,
        content: 'Explain Fundamental Rights',
        timestamp: now,
      );

      expect(msg.id, 'm_1');
      expect(msg.sender, MentorMessageSender.user);
      expect(msg.content, 'Explain Fundamental Rights');

      final json = msg.toJson();
      final restored = MentorMessage.fromJson(json);

      expect(restored.id, msg.id);
      expect(restored.sender, MentorMessageSender.user);
      expect(restored.content, msg.content);
    });

    test('MentorRecommendation creation and copyWith', () {
      final rec = MentorRecommendation(
        id: 'r_1',
        title: 'Revise Polity',
        description: 'Complete 20 PYQs',
        actionType: 'revise',
      );

      expect(rec.title, 'Revise Polity');
      expect(rec.actionType, 'revise');

      final updated = rec.copyWith(targetId: 't_100');
      expect(updated.targetId, 't_100');
      expect(updated.title, rec.title);
    });

    test('MentorContext creation and copyWith', () {
      final ctx = MentorContext(
        userId: 'u_1',
        userName: 'Learner',
        targetExam: 'UPSC CSE',
        weakSubjects: const ['Polity'],
        studyHoursTarget: 8.0,
      );

      expect(ctx.userId, 'u_1');
      expect(ctx.studyHoursTarget, 8.0);
      expect(ctx.weakSubjects, contains('Polity'));

      final updated = ctx.copyWith(studyHoursCompleted: 4.0);
      expect(updated.studyHoursCompleted, 4.0);
      expect(updated.userName, ctx.userName);
    });

    test('MentorSession creation and serialization', () {
      final session = MentorSession(
        id: 's_1',
        userId: 'u_1',
        title: 'Study Session 1',
        createdAt: now,
        updatedAt: now,
      );

      expect(session.id, 's_1');
      expect(session.title, 'Study Session 1');

      final json = session.toJson();
      final restored = MentorSession.fromJson(json);

      expect(restored.id, session.id);
      expect(restored.title, session.title);
    });
  });
}
