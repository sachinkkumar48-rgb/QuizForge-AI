import 'package:garuda_pyq/garuda_pyq.dart' hide CoverageReport;
import 'coverage_filter.dart';
import 'coverage_metrics.dart';

/// Business logic calculator for GARUDA Editorial Coverage Dashboard.
class CoverageCalculator {
  static const int minYear = 1995;
  static const int maxYear = 2026;

  static const List<String> standardSubjects = [
    'Polity',
    'History',
    'Geography',
    'Economy',
    'Environment',
    'Science & Technology',
    'Art & Culture',
    'IR',
    'Security',
    'Ethics',
  ];

  static const Map<String, List<String>> standardTopicsBySubject = {
    'Polity': [
      'Fundamental Rights',
      'DPSP',
      'Parliament',
      'Judiciary',
      'Federalism',
      'Emergency',
      'Amendments',
      'Panchayati Raj',
      'Election Commission',
      'Constitutional Bodies',
      'Statutory Bodies',
    ],
    'History': [
      'Ancient India',
      'Medieval India',
      'Modern Freedom Struggle',
      'Post-Independence',
    ],
    'Geography': [
      'Physical Geography',
      'Indian Geography',
      'World Geography',
      'Climatology',
    ],
    'Economy': [
      'Fiscal Policy',
      'Monetary Policy & Banking',
      'Inflation & Growth',
      'External Sector',
    ],
    'Environment': [
      'Biodiversity',
      'Climate Change',
      'Conservation & Acts',
      'Pollution',
    ],
  };

  /// Calculates a complete CoverageReport from a list of questions given a CoverageFilter.
  static CoverageReport calculateReport(
    List<Question> allQuestions, {
    CoverageFilter filter = const CoverageFilter(),
  }) {
    final filteredQuestions = filter.isEmpty
        ? allQuestions
        : allQuestions.where((q) => filter.matches(q)).toList();

    final nationalOverview = _calculateNationalOverview(filteredQuestions);
    final examCoverage = _calculateExamCoverage(filteredQuestions);
    final subjectCoverage = _calculateSubjectCoverage(filteredQuestions);
    final topicCoverage = _calculateTopicCoverage(filteredQuestions);
    final yearMatrix = _calculateYearMatrix(filteredQuestions);
    final editorialQueue = _calculateEditorialQueue(filteredQuestions);
    final knowledgeGraph = _calculateKnowledgeGraph(filteredQuestions);
    final qualityDashboard = _calculateQualityDashboard(filteredQuestions);

    return CoverageReport(
      appliedFilter: filter,
      generatedAt: DateTime.now(),
      nationalOverview: nationalOverview,
      examCoverage: examCoverage,
      subjectCoverage: subjectCoverage,
      topicCoverage: topicCoverage,
      yearMatrix: yearMatrix,
      editorialQueue: editorialQueue,
      knowledgeGraph: knowledgeGraph,
      qualityDashboard: qualityDashboard,
    );
  }

  // 1. National Overview
  static NationalOverviewMetrics _calculateNationalOverview(List<Question> questions) {
    final total = questions.length;
    if (total == 0) {
      return const NationalOverviewMetrics(
        totalQuestions: 0,
        verifiedQuestions: 0,
        publishedQuestions: 0,
        goldQuestions: 0,
        silverQuestions: 0,
        bronzeQuestions: 0,
        draftQuestions: 0,
        coveragePercentage: 0.0,
      );
    }

    int verified = 0;
    int published = 0;
    int gold = 0;
    int silver = 0;
    int bronze = 0;
    int draft = 0;

    for (final q in questions) {
      if (_isVerified(q)) verified++;
      if (q.editorialStatus == EditorialStatus.published) published++;

      final tier = CoverageFilter.computeQualityTier(q);
      switch (tier) {
        case QualityTier.gold:
          gold++;
          break;
        case QualityTier.silver:
          silver++;
          break;
        case QualityTier.bronze:
          bronze++;
          break;
        case QualityTier.draft:
          draft++;
          break;
      }
    }

    final coveragePct = (verified / total) * 100.0;

    return NationalOverviewMetrics(
      totalQuestions: total,
      verifiedQuestions: verified,
      publishedQuestions: published,
      goldQuestions: gold,
      silverQuestions: silver,
      bronzeQuestions: bronze,
      draftQuestions: draft,
      coveragePercentage: double.parse(coveragePct.toStringAsFixed(1)),
    );
  }

  // 2. Exam Coverage
  static List<ExamCoverageItem> _calculateExamCoverage(List<Question> questions) {
    // Map initial supported exams
    final examMap = <String, SupportedExam>{};
    for (final e in SupportedExam.initialExams) {
      examMap[e.id.toLowerCase()] = e;
      examMap[e.code.toLowerCase()] = e;
    }

    // Group questions by examId
    final grouped = <String, List<Question>>{};
    for (final q in questions) {
      final key = q.examId.toLowerCase();
      grouped.putIfAbsent(key, () => []).add(q);
    }

    // Ensure all standard initial exams are present in report list
    final resultList = <ExamCoverageItem>[];

    final handledExams = <String>{};

    for (final exam in SupportedExam.initialExams) {
      final key = exam.id.toLowerCase();
      handledExams.add(key);
      handledExams.add(exam.code.toLowerCase());

      final examQuestions = grouped[key] ?? grouped[exam.code.toLowerCase()] ?? [];

      final imported = examQuestions.length;
      final verified = examQuestions.where(_isVerified).length;
      final published = examQuestions.where((q) => q.editorialStatus == EditorialStatus.published).length;

      final years = examQuestions.map((q) => q.year).where((y) => y >= minYear && y <= maxYear).toSet();
      final yearsCovered = years.length;
      const totalSpanYears = (maxYear - minYear + 1);
      final yearsMissing = totalSpanYears - yearsCovered;

      final pct = imported == 0 ? 0.0 : (verified / imported) * 100.0;

      resultList.add(ExamCoverageItem(
        examId: exam.id,
        examName: exam.fullName,
        code: exam.code,
        yearsCovered: yearsCovered,
        yearsMissing: yearsMissing,
        questionsImported: imported,
        questionsVerified: verified,
        questionsPublished: published,
        coveragePercentage: double.parse(pct.toStringAsFixed(1)),
      ));
    }

    // Add any remaining dynamic/custom exams from question dataset
    grouped.forEach((key, examQuestions) {
      if (!handledExams.contains(key)) {
        final examName = key.toUpperCase();
        final imported = examQuestions.length;
        final verified = examQuestions.where(_isVerified).length;
        final published = examQuestions.where((q) => q.editorialStatus == EditorialStatus.published).length;

        final years = examQuestions.map((q) => q.year).where((y) => y >= minYear && y <= maxYear).toSet();
        final yearsCovered = years.length;
        final yearsMissing = (maxYear - minYear + 1) - yearsCovered;
        final pct = imported == 0 ? 0.0 : (verified / imported) * 100.0;

        resultList.add(ExamCoverageItem(
          examId: key,
          examName: examName,
          code: examName,
          yearsCovered: yearsCovered,
          yearsMissing: yearsMissing,
          questionsImported: imported,
          questionsVerified: verified,
          questionsPublished: published,
          coveragePercentage: double.parse(pct.toStringAsFixed(1)),
        ));
      }
    });

    return resultList;
  }

  // 3. Subject Coverage
  static List<SubjectCoverageItem> _calculateSubjectCoverage(List<Question> questions) {
    final grouped = <String, List<Question>>{};
    for (final q in questions) {
      final key = _normalizeSubject(q.subject);
      grouped.putIfAbsent(key, () => []).add(q);
    }

    final resultList = <SubjectCoverageItem>[];
    final handled = <String>{};

    for (final subj in standardSubjects) {
      handled.add(subj.toLowerCase());
      final subjQuestions = grouped[subj.toLowerCase()] ?? [];

      final imported = subjQuestions.length;
      final verified = subjQuestions.where(_isVerified).length;
      final mapped = subjQuestions.where(_isMapped).length;
      final published = subjQuestions.where((q) => q.editorialStatus == EditorialStatus.published).length;
      final remaining = imported - published;
      final pct = imported == 0 ? 0.0 : (verified / imported) * 100.0;

      resultList.add(SubjectCoverageItem(
        subject: subj,
        imported: imported,
        verified: verified,
        mapped: mapped,
        published: published,
        remaining: remaining,
        coveragePercentage: double.parse(pct.toStringAsFixed(1)),
      ));
    }

    // Dynamic subjects
    grouped.forEach((key, subjQuestions) {
      if (!handled.contains(key)) {
        final displaySubject = key.isEmpty ? 'General' : _capitalize(key);
        final imported = subjQuestions.length;
        final verified = subjQuestions.where(_isVerified).length;
        final mapped = subjQuestions.where(_isMapped).length;
        final published = subjQuestions.where((q) => q.editorialStatus == EditorialStatus.published).length;
        final remaining = imported - published;
        final pct = imported == 0 ? 0.0 : (verified / imported) * 100.0;

        resultList.add(SubjectCoverageItem(
          subject: displaySubject,
          imported: imported,
          verified: verified,
          mapped: mapped,
          published: published,
          remaining: remaining,
          coveragePercentage: double.parse(pct.toStringAsFixed(1)),
        ));
      }
    });

    return resultList;
  }

  // 4. Topic Coverage
  static List<TopicCoverageItem> _calculateTopicCoverage(List<Question> questions) {
    final topicMap = <String, Map<String, List<Question>>>{}; // Subject -> Topic -> List<Question>

    for (final q in questions) {
      final subjKey = _normalizeSubject(q.subject);
      final topicKey = q.topic.trim();
      topicMap.putIfAbsent(subjKey, () => {}).putIfAbsent(topicKey, () => []).add(q);
    }

    final resultList = <TopicCoverageItem>[];

    // Standard subjects & topics
    standardTopicsBySubject.forEach((subj, topics) {
      final subjKey = subj.toLowerCase();
      final subjTopicsMap = topicMap[subjKey] ?? {};

      for (final top in topics) {
        final topQuestions = subjTopicsMap[top] ??
            subjTopicsMap.entries
                .firstWhere(
                  (e) => e.key.toLowerCase() == top.toLowerCase(),
                  orElse: () => const MapEntry('', []),
                )
                .value;

        final count = topQuestions.length;
        final verified = topQuestions.where(_isVerified).length;
        final pct = count == 0 ? 0.0 : (verified / count) * 100.0;
        final missing = count - verified;

        resultList.add(TopicCoverageItem(
          subject: subj,
          topic: top,
          questions: count,
          coveragePercentage: double.parse(pct.toStringAsFixed(1)),
          missing: missing,
        ));
      }
    });

    // Add remaining custom topics found in questions dataset
    topicMap.forEach((subjKey, topicsInSubj) {
      final displaySubj = _capitalize(subjKey);
      topicsInSubj.forEach((topicName, qList) {
        if (topicName.isNotEmpty) {
          final isAlreadyAdded = resultList.any((t) =>
              t.subject.toLowerCase() == subjKey.toLowerCase() &&
              t.topic.toLowerCase() == topicName.toLowerCase());

          if (!isAlreadyAdded) {
            final count = qList.length;
            final verified = qList.where(_isVerified).length;
            final pct = count == 0 ? 0.0 : (verified / count) * 100.0;
            final missing = count - verified;

            resultList.add(TopicCoverageItem(
              subject: displaySubj,
              topic: topicName,
              questions: count,
              coveragePercentage: double.parse(pct.toStringAsFixed(1)),
              missing: missing,
            ));
          }
        }
      });
    });

    return resultList;
  }

  // 5. Year Matrix
  static List<YearMatrixItem> _calculateYearMatrix(List<Question> questions) {
    final yearMap = <int, List<Question>>{};
    for (final q in questions) {
      if (q.year >= minYear && q.year <= maxYear) {
        yearMap.putIfAbsent(q.year, () => []).add(q);
      }
    }

    final resultList = <YearMatrixItem>[];
    for (int y = minYear; y <= maxYear; y++) {
      final yearQuestions = yearMap[y] ?? [];
      final total = yearQuestions.length;
      final verified = yearQuestions.where(_isVerified).length;

      YearCoverageStatus status;
      if (total == 0) {
        status = YearCoverageStatus.missing;
      } else if (verified == total && verified > 0) {
        status = YearCoverageStatus.complete;
      } else {
        status = YearCoverageStatus.partial;
      }

      resultList.add(YearMatrixItem(
        year: y,
        status: status,
        totalQuestions: total,
        verifiedQuestions: verified,
      ));
    }

    return resultList;
  }

  // 6. Editorial Queue
  static EditorialQueueMetrics _calculateEditorialQueue(List<Question> questions) {
    int pendingVerification = 0;
    int pendingMapping = 0;
    int pendingReview = 0;
    int pendingPublication = 0;
    int rejected = 0;
    int flagged = 0;

    for (final q in questions) {
      if (q.verificationStatus.toLowerCase() == 'pending' ||
          q.verificationStatus.toLowerCase() == 'unverified' ||
          q.editorialStatus == EditorialStatus.verificationPending ||
          q.editorialStatus == EditorialStatus.ocrPending) {
        pendingVerification++;
      }

      if (q.editorialStatus == EditorialStatus.imported ||
          q.editorialStatus == EditorialStatus.ocrPending ||
          (q.conceptsTested.isEmpty && q.coreConcepts.isEmpty)) {
        pendingMapping++;
      }

      if (q.editorialReviews.isEmpty ||
          q.editorialStatus == EditorialStatus.conceptTagged ||
          q.editorialStatus == EditorialStatus.knowledgeLinked) {
        pendingReview++;
      }

      if (q.editorialStatus == EditorialStatus.readyForPublication) {
        pendingPublication++;
      }

      if (q.editorialReviews.any((r) => r.status.toLowerCase() == 'rejected')) {
        rejected++;
      }

      if (q.tags.any((t) =>
          t.toLowerCase().contains('flag') ||
          t.toLowerCase().contains('review') ||
          t.toLowerCase().contains('issue'))) {
        flagged++;
      }
    }

    return EditorialQueueMetrics(
      pendingVerification: pendingVerification,
      pendingMapping: pendingMapping,
      pendingReview: pendingReview,
      pendingPublication: pendingPublication,
      rejected: rejected,
      flagged: flagged,
    );
  }

  // 7. Knowledge Graph Status
  static KnowledgeGraphMetrics _calculateKnowledgeGraph(List<Question> questions) {
    int questionsLinked = 0;
    int articlesLinked = 0;
    int actsLinked = 0;
    int casesLinked = 0;
    int committeesLinked = 0;
    int reportsLinked = 0;
    int currentAffairsLinked = 0;
    int knowledgeObjectsLinked = 0;
    int conceptsLinked = 0;
    int microConceptsLinked = 0;

    for (final q in questions) {
      final hasAnyLink = q.knowledgeObjectLinks.isNotEmpty ||
          q.articleLinks.isNotEmpty ||
          q.actLinks.isNotEmpty ||
          q.caseLinks.isNotEmpty ||
          q.committeeLinks.isNotEmpty ||
          q.reportLinks.isNotEmpty ||
          q.currentAffairsLinks.isNotEmpty ||
          q.conceptsTested.isNotEmpty ||
          q.coreConcepts.isNotEmpty;

      if (hasAnyLink) questionsLinked++;

      articlesLinked += q.articleLinks.length;
      actsLinked += q.actLinks.length;
      casesLinked += q.caseLinks.length;
      committeesLinked += q.committeeLinks.length;
      reportsLinked += q.reportLinks.length;
      currentAffairsLinked += q.currentAffairsLinks.length;
      knowledgeObjectsLinked += q.knowledgeObjectLinks.length;
      conceptsLinked += (q.conceptsTested.length + q.coreConcepts.length);
      microConceptsLinked += q.microConcepts.length;
    }

    return KnowledgeGraphMetrics(
      questionsLinked: questionsLinked,
      articlesLinked: articlesLinked,
      actsLinked: actsLinked,
      casesLinked: casesLinked,
      committeesLinked: committeesLinked,
      reportsLinked: reportsLinked,
      currentAffairsLinked: currentAffairsLinked,
      knowledgeObjectsLinked: knowledgeObjectsLinked,
      conceptsLinked: conceptsLinked,
      microConceptsLinked: microConceptsLinked,
    );
  }

  // 8. Quality Dashboard
  static QualityDashboardMetrics _calculateQualityDashboard(List<Question> questions) {
    final total = questions.length;
    if (total == 0) {
      return const QualityDashboardMetrics(
        trapAnalysisPercentage: 0.0,
        learningObjectivesPercentage: 0.0,
        conceptMappingPercentage: 0.0,
        editorialReviewPercentage: 0.0,
        knowledgeLinksPercentage: 0.0,
        evidenceLinksPercentage: 0.0,
      );
    }

    int trapCount = 0;
    int loCount = 0;
    int conceptCount = 0;
    int reviewCount = 0;
    int linkCount = 0;
    int evidenceCount = 0;

    for (final q in questions) {
      if (q.trap != null) trapCount++;
      if (q.learningObjectives != null) loCount++;
      if (q.conceptsTested.isNotEmpty || q.coreConcepts.isNotEmpty) conceptCount++;
      if (q.editorialReviews.isNotEmpty || _isVerified(q)) reviewCount++;
      if (q.knowledgeObjectLinks.isNotEmpty ||
          q.articleLinks.isNotEmpty ||
          q.actLinks.isNotEmpty ||
          q.caseLinks.isNotEmpty) {
        linkCount++;
      }
      if (q.source.publisher.isNotEmpty || q.source.url != null) {
        evidenceCount++;
      }
    }

    return QualityDashboardMetrics(
      trapAnalysisPercentage: double.parse(((trapCount / total) * 100).toStringAsFixed(1)),
      learningObjectivesPercentage: double.parse(((loCount / total) * 100).toStringAsFixed(1)),
      conceptMappingPercentage: double.parse(((conceptCount / total) * 100).toStringAsFixed(1)),
      editorialReviewPercentage: double.parse(((reviewCount / total) * 100).toStringAsFixed(1)),
      knowledgeLinksPercentage: double.parse(((linkCount / total) * 100).toStringAsFixed(1)),
      evidenceLinksPercentage: double.parse(((evidenceCount / total) * 100).toStringAsFixed(1)),
    );
  }

  // Helper utilities
  static bool _isVerified(Question q) {
    return q.verificationStatus.toLowerCase() == 'verified' ||
        q.editorialStatus == EditorialStatus.verified ||
        q.editorialStatus == EditorialStatus.answerVerified ||
        q.editorialStatus == EditorialStatus.readyForPublication ||
        q.editorialStatus == EditorialStatus.mapped ||
        q.editorialStatus == EditorialStatus.published;
  }

  static bool _isMapped(Question q) {
    return q.editorialStatus == EditorialStatus.mapped ||
        q.editorialStatus == EditorialStatus.conceptTagged ||
        q.conceptsTested.isNotEmpty ||
        q.coreConcepts.isNotEmpty;
  }

  static String _normalizeSubject(String s) {
    final lower = s.trim().toLowerCase();
    if (lower.contains('polity') || lower.contains('constitution')) return 'polity';
    if (lower.contains('hist')) return 'history';
    if (lower.contains('geog')) return 'geography';
    if (lower.contains('econ')) return 'economy';
    if (lower.contains('env')) return 'environment';
    if (lower.contains('sci') || lower.contains('tech')) return 'science & technology';
    if (lower.contains('art') || lower.contains('cult')) return 'art & culture';
    if (lower.contains('ir') || lower.contains('international')) return 'ir';
    if (lower.contains('sec')) return 'security';
    if (lower.contains('ethic')) return 'ethics';
    return lower;
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
