library;

import 'package:garuda_evidence/garuda_evidence.dart';
import '../domain/entities/enums.dart';
import '../domain/entities/knowledge_node_ref.dart';
import 'link_score_result.dart';

/// Rule-based weighted scoring engine evaluating link confidence.
/// Evaluates:
/// - Exact Object Match (Weight: 1.0)
/// - Article Match (Weight: 0.95)
/// - Case Match (Weight: 0.90)
/// - Act Match (Weight: 0.85)
/// - Keyword Match (Weight: 0.70)
/// - Ontology Match (Weight: 0.65)
/// - Manual Override (Weight: 1.0)
class LinkScoringEngine {
  static LinkScoreResult scoreLink({
    required EvidenceObject evidence,
    required KnowledgeNodeRef targetNode,
    bool isManualOverride = false,
  }) {
    if (isManualOverride) {
      return const LinkScoreResult(
        score: 1.0,
        ruleBreakdown: {'manual_override': 1.0},
        primaryReason: 'Manual Editorial Override',
      );
    }

    final breakdown = <String, double>{};
    final links = evidence.knowledgeObjectLinks;
    final targetIdLower = targetNode.id.toLowerCase();
    final targetNameLower = targetNode.name.toLowerCase();

    // 1. Exact Object Match (1.0)
    if (evidence.id.toLowerCase() == targetIdLower) {
      breakdown['exact_object_match'] = 1.0;
    }

    // 2. Article Match (0.95)
    if (targetNode.nodeType == NodeType.article || targetNode.id.startsWith('Art')) {
      if (links.constitutionArticles.any((a) => a.toLowerCase().contains(targetIdLower) || targetNameLower.contains(a.toLowerCase()))) {
        breakdown['article_match'] = 0.95;
      }
    }

    // 3. Case Match (0.90)
    if (targetNode.nodeType == NodeType.caseLaw || targetNode.id.startsWith('Case')) {
      if (links.caseLaws.any((c) => c.toLowerCase().contains(targetIdLower) || targetNameLower.contains(c.toLowerCase()))) {
        breakdown['case_match'] = 0.90;
      }
    }

    // 4. Act Match (0.85)
    if (targetNode.nodeType == NodeType.act || targetNode.id.startsWith('Act')) {
      if (links.acts.any((act) => act.toLowerCase().contains(targetIdLower) || targetNameLower.contains(act.toLowerCase()))) {
        breakdown['act_match'] = 0.85;
      }
    }

    // 5. Keyword Match (0.70)
    if (evidence.keywords.any((k) => k.toLowerCase() == targetNameLower || targetNameLower.contains(k.toLowerCase()))) {
      breakdown['keyword_match'] = 0.70;
    }

    // 6. Topic / Ontology Match (0.65)
    if (evidence.topic.toLowerCase() == targetNameLower || evidence.category.toLowerCase() == targetNode.category.toLowerCase()) {
      breakdown['ontology_match'] = 0.65;
    }

    if (breakdown.isEmpty) {
      return const LinkScoreResult(
        score: 0.30,
        ruleBreakdown: {'default_fallback': 0.30},
        primaryReason: 'Low general similarity fallback',
      );
    }

    final maxScore = breakdown.values.reduce((a, b) => a > b ? a : b);
    final topRule = breakdown.entries.firstWhere((e) => e.value == maxScore).key;

    return LinkScoreResult(
      score: maxScore,
      ruleBreakdown: breakdown,
      primaryReason: 'Matched rule: $topRule',
    );
  }
}
