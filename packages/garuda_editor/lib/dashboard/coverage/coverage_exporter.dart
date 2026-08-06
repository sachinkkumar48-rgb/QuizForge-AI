import 'dart:convert';
import 'coverage_metrics.dart';

/// Exporter service for GARUDA Editorial Coverage Dashboard.
class CoverageExporter {
  /// Export CoverageReport to CSV format.
  static String exportToCsv(CoverageReport report) {
    final buffer = StringBuffer();

    // Header & Meta
    buffer.writeln('# GARUDA EDITORIAL COVERAGE REPORT');
    buffer.writeln('# Generated At,${report.generatedAt.toIso8601String()}');
    buffer.writeln();

    // 1. National Overview
    buffer.writeln('--- NATIONAL OVERVIEW ---');
    buffer.writeln('Total Questions,Verified Questions,Published Questions,Gold,Silver,Bronze,Draft,Coverage %');
    final n = report.nationalOverview;
    buffer.writeln('${n.totalQuestions},${n.verifiedQuestions},${n.publishedQuestions},${n.goldQuestions},${n.silverQuestions},${n.bronzeQuestions},${n.draftQuestions},${n.coveragePercentage}%');
    buffer.writeln();

    // 2. Exam Coverage
    buffer.writeln('--- EXAM COVERAGE ---');
    buffer.writeln('Exam Code,Exam Name,Years Covered,Years Missing,Imported,Verified,Published,Coverage %');
    for (final e in report.examCoverage) {
      final safeName = _cleanCsv(e.examName);
      buffer.writeln('${e.code},"$safeName",${e.yearsCovered},${e.yearsMissing},${e.questionsImported},${e.questionsVerified},${e.questionsPublished},${e.coveragePercentage}%');
    }
    buffer.writeln();

    // 3. Subject Coverage
    buffer.writeln('--- SUBJECT COVERAGE ---');
    buffer.writeln('Subject,Imported,Verified,Mapped,Published,Remaining,Coverage %');
    for (final s in report.subjectCoverage) {
      buffer.writeln('${s.subject},${s.imported},${s.verified},${s.mapped},${s.published},${s.remaining},${s.coveragePercentage}%');
    }
    buffer.writeln();

    // 4. Topic Coverage
    buffer.writeln('--- TOPIC COVERAGE ---');
    buffer.writeln('Subject,Topic,Questions,Coverage %,Missing');
    for (final t in report.topicCoverage) {
      final safeTopic = _cleanCsv(t.topic);
      buffer.writeln('${t.subject},"$safeTopic",${t.questions},${t.coveragePercentage}%,${t.missing}');
    }
    buffer.writeln();

    // 5. Year Matrix
    buffer.writeln('--- YEAR MATRIX ---');
    buffer.writeln('Year,Status,Total Questions,Verified Questions');
    for (final y in report.yearMatrix) {
      buffer.writeln('${y.year},${y.status.name},${y.totalQuestions},${y.verifiedQuestions}');
    }
    buffer.writeln();

    // 6. Editorial Queue
    buffer.writeln('--- EDITORIAL QUEUE ---');
    buffer.writeln('Pending Verification,Pending Mapping,Pending Review,Pending Publication,Rejected,Flagged');
    final q = report.editorialQueue;
    buffer.writeln('${q.pendingVerification},${q.pendingMapping},${q.pendingReview},${q.pendingPublication},${q.rejected},${q.flagged}');
    buffer.writeln();

    // 7. Knowledge Graph Status
    buffer.writeln('--- KNOWLEDGE GRAPH STATUS ---');
    buffer.writeln('Metric,Count');
    final k = report.knowledgeGraph;
    buffer.writeln('Questions Linked,${k.questionsLinked}');
    buffer.writeln('Articles Linked,${k.articlesLinked}');
    buffer.writeln('Acts Linked,${k.actsLinked}');
    buffer.writeln('Cases Linked,${k.casesLinked}');
    buffer.writeln('Committees Linked,${k.committeesLinked}');
    buffer.writeln('Reports Linked,${k.reportsLinked}');
    buffer.writeln('Current Affairs Linked,${k.currentAffairsLinked}');
    buffer.writeln('Knowledge Objects Linked,${k.knowledgeObjectsLinked}');
    buffer.writeln('Concepts Linked,${k.conceptsLinked}');
    buffer.writeln('Micro Concepts Linked,${k.microConceptsLinked}');
    buffer.writeln();

    // 8. Quality Dashboard
    buffer.writeln('--- QUALITY DASHBOARD ---');
    buffer.writeln('Dimension,Completion %');
    final qual = report.qualityDashboard;
    buffer.writeln('Trap Analysis,${qual.trapAnalysisPercentage}%');
    buffer.writeln('Learning Objectives,${qual.learningObjectivesPercentage}%');
    buffer.writeln('Concept Mapping,${qual.conceptMappingPercentage}%');
    buffer.writeln('Editorial Review,${qual.editorialReviewPercentage}%');
    buffer.writeln('Knowledge Links,${qual.knowledgeLinksPercentage}%');
    buffer.writeln('Evidence Links,${qual.evidenceLinksPercentage}%');

    return buffer.toString();
  }

  /// Export CoverageReport to JSON string.
  static String exportToJson(CoverageReport report) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(report.toJson());
  }

  /// Export CoverageReport to Markdown Summary format.
  static String exportToMarkdown(CoverageReport report) {
    final buffer = StringBuffer();
    final n = report.nationalOverview;

    buffer.writeln('# 🛡️ GARUDA Editorial Coverage Dashboard Summary');
    buffer.writeln('_Generated on ${report.generatedAt.toLocal().toString().split('.')[0]}_');
    buffer.writeln();

    buffer.writeln('## 1. National Overview');
    buffer.writeln('| Total Questions | Verified Questions | Published Questions | Coverage % | Gold | Silver | Bronze | Draft |');
    buffer.writeln('|---|---|---|---|---|---|---|---|');
    buffer.writeln('| ${n.totalQuestions} | ${n.verifiedQuestions} | ${n.publishedQuestions} | **${n.coveragePercentage}%** | ${n.goldQuestions} | ${n.silverQuestions} | ${n.bronzeQuestions} | ${n.draftQuestions} |');
    buffer.writeln();

    buffer.writeln('## 2. Exam Coverage');
    buffer.writeln('| Exam Code | Exam Name | Years Covered | Years Missing | Imported | Verified | Published | Coverage % |');
    buffer.writeln('|---|---|---|---|---|---|---|---|');
    for (final e in report.examCoverage) {
      buffer.writeln('| `${e.code}` | ${e.examName} | ${e.yearsCovered} | ${e.yearsMissing} | ${e.questionsImported} | ${e.questionsVerified} | ${e.questionsPublished} | **${e.coveragePercentage}%** |');
    }
    buffer.writeln();

    buffer.writeln('## 3. Subject Coverage');
    buffer.writeln('| Subject | Imported | Verified | Mapped | Published | Remaining | Coverage % |');
    buffer.writeln('|---|---|---|---|---|---|---|');
    for (final s in report.subjectCoverage) {
      buffer.writeln('| ${s.subject} | ${s.imported} | ${s.verified} | ${s.mapped} | ${s.published} | ${s.remaining} | **${s.coveragePercentage}%** |');
    }
    buffer.writeln();

    buffer.writeln('## 4. Topic Coverage (Sample)');
    buffer.writeln('| Subject | Topic | Questions | Missing | Coverage % |');
    buffer.writeln('|---|---|---|---|---|');
    for (final t in report.topicCoverage) {
      buffer.writeln('| ${t.subject} | ${t.topic} | ${t.questions} | ${t.missing} | ${t.coveragePercentage}% |');
    }
    buffer.writeln();

    buffer.writeln('## 5. Year Matrix Overview (1995-2026)');
    final missingYears = report.yearMatrix.where((y) => y.status == YearCoverageStatus.missing).map((y) => y.year).toList();
    final partialYears = report.yearMatrix.where((y) => y.status == YearCoverageStatus.partial).map((y) => y.year).toList();
    final completeYears = report.yearMatrix.where((y) => y.status == YearCoverageStatus.complete).map((y) => y.year).toList();

    buffer.writeln('- **Complete Years (${completeYears.length}):** ${completeYears.isEmpty ? "None" : completeYears.join(", ")}');
    buffer.writeln('- **Partial Years (${partialYears.length}):** ${partialYears.isEmpty ? "None" : partialYears.join(", ")}');
    buffer.writeln('- **Missing Years (${missingYears.length}):** ${missingYears.isEmpty ? "None" : missingYears.join(", ")}');
    buffer.writeln();

    buffer.writeln('## 6. Editorial Queue');
    final q = report.editorialQueue;
    buffer.writeln('- **Pending Verification:** ${q.pendingVerification}');
    buffer.writeln('- **Pending Mapping:** ${q.pendingMapping}');
    buffer.writeln('- **Pending Review:** ${q.pendingReview}');
    buffer.writeln('- **Pending Publication:** ${q.pendingPublication}');
    buffer.writeln('- **Rejected:** ${q.rejected}');
    buffer.writeln('- **Flagged:** ${q.flagged}');
    buffer.writeln();

    buffer.writeln('## 7. Knowledge Graph Status');
    final k = report.knowledgeGraph;
    buffer.writeln('| Metric | Count |');
    buffer.writeln('|---|---|');
    buffer.writeln('| Questions Linked | ${k.questionsLinked} |');
    buffer.writeln('| Articles Linked | ${k.articlesLinked} |');
    buffer.writeln('| Acts Linked | ${k.actsLinked} |');
    buffer.writeln('| Cases Linked | ${k.casesLinked} |');
    buffer.writeln('| Committees Linked | ${k.committeesLinked} |');
    buffer.writeln('| Reports Linked | ${k.reportsLinked} |');
    buffer.writeln('| Current Affairs Linked | ${k.currentAffairsLinked} |');
    buffer.writeln('| Knowledge Objects Linked | ${k.knowledgeObjectsLinked} |');
    buffer.writeln('| Concepts Linked | ${k.conceptsLinked} |');
    buffer.writeln('| Micro Concepts Linked | ${k.microConceptsLinked} |');
    buffer.writeln();

    buffer.writeln('## 8. Quality Dashboard');
    final qual = report.qualityDashboard;
    buffer.writeln('| Dimension | Completion % |');
    buffer.writeln('|---|---|');
    buffer.writeln('| Trap Analysis | ${qual.trapAnalysisPercentage}% |');
    buffer.writeln('| Learning Objectives | ${qual.learningObjectivesPercentage}% |');
    buffer.writeln('| Concept Mapping | ${qual.conceptMappingPercentage}% |');
    buffer.writeln('| Editorial Review | ${qual.editorialReviewPercentage}% |');
    buffer.writeln('| Knowledge Links | ${qual.knowledgeLinksPercentage}% |');
    buffer.writeln('| Evidence Links | ${qual.evidenceLinksPercentage}% |');

    return buffer.toString();
  }

  static String _cleanCsv(String text) {
    return text.replaceAll('"', '""');
  }
}
