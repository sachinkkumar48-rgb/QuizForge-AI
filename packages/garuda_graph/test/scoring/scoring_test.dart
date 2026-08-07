import 'package:garuda_evidence/garuda_evidence.dart';
import 'package:garuda_graph/garuda_graph.dart';
import 'package:test/test.dart';

void main() {
  group('LinkScoringEngine Tests', () {
    final now = DateTime.now();

    final evidence = EvidenceObject(
      id: 'EV-SC-01',
      title: 'Supreme Court ruling on Right to Privacy Article 21',
      sourceName: 'Supreme Court Judgments',
      sourceType: EvidenceSourceType.judiciary,
      authority: const EvidenceAuthority(
        id: 'sc',
        name: 'Supreme Court',
        type: EvidenceSourceType.judiciary,
        jurisdiction: 'India',
      ),
      publicationDate: now,
      retrievedDate: now,
      category: 'Polity',
      subject: 'Polity',
      topic: 'Right to Privacy',
      subtopic: 'Article 21',
      keywords: const ['Article 21', 'Privacy'],
      language: 'en',
      summary: 'SC interprets Article 21 to include fundamental right to privacy.',
      originalUrl: 'https://sci.gov.in/01.pdf',
      knowledgeObjectLinks: const KnowledgeObjectLinks(
        constitutionArticles: ['Art-21'],
        caseLaws: ['Puttaswamy v. Union of India'],
      ),
      createdAt: now,
      updatedAt: now,
    );

    test('Article match should receive weight 0.95', () {
      const artNode = KnowledgeNodeRef(
        id: 'Art-21',
        name: 'Article 21 Protection of life and personal liberty',
        nodeType: NodeType.article,
        category: 'Polity',
      );

      final score = LinkScoringEngine.scoreLink(
        evidence: evidence,
        targetNode: artNode,
      );

      expect(score.score, equals(0.95));
      expect(score.ruleBreakdown, contains('article_match'));
    });

    test('Manual override should return score 1.0', () {
      const targetNode = KnowledgeNodeRef(
        id: 'CustomNode',
        name: 'Custom Topic',
        nodeType: NodeType.topic,
      );

      final score = LinkScoringEngine.scoreLink(
        evidence: evidence,
        targetNode: targetNode,
        isManualOverride: true,
      );

      expect(score.score, equals(1.0));
      expect(score.primaryReason, contains('Manual Editorial Override'));
    });
  });
}
