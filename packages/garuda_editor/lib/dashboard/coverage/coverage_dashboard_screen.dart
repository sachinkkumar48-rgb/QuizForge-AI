import 'package:flutter/material.dart';
import 'package:garuda_pyq/garuda_pyq.dart' hide CoverageReport;
import 'coverage_calculator.dart';
import 'coverage_exporter.dart';
import 'coverage_filter.dart';
import 'coverage_metrics.dart';

/// GARUDA Editorial Coverage Dashboard Screen for Editors.
class CoverageDashboardScreen extends StatefulWidget {
  final IPYQRepository repository;

  const CoverageDashboardScreen({
    super.key,
    required this.repository,
  });

  @override
  State<CoverageDashboardScreen> createState() => _CoverageDashboardScreenState();
}

class _CoverageDashboardScreenState extends State<CoverageDashboardScreen> {
  CoverageFilter _filter = const CoverageFilter();
  List<Question> _allQuestions = [];
  bool _isLoading = true;
  CoverageReport? _report;
  String _selectedSubjectForTopic = 'Polity';

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    final questions = await widget.repository.getAllQuestions();
    setState(() {
      _allQuestions = questions;
      _report = CoverageCalculator.calculateReport(questions, filter: _filter);
      _isLoading = false;
    });
  }

  void _updateFilter(CoverageFilter newFilter) {
    setState(() {
      _filter = newFilter;
      _report = CoverageCalculator.calculateReport(_allQuestions, filter: _filter);
    });
  }

  void _resetFilter() {
    setState(() {
      _filter = const CoverageFilter();
      _report = CoverageCalculator.calculateReport(_allQuestions, filter: _filter);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final report = _report!;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.dashboard_customize, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'GARUDA Editorial Coverage Dashboard',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Real-time National PYQ Repository Analysis • Desktop First',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Repository Data',
            onPressed: _loadQuestions,
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            key: const Key('export_button'),
            onPressed: () => _showExportDialog(context, report),
            icon: const Icon(Icons.download),
            label: const Text('Export Dashboard'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 9: Filters Bar
            _buildFiltersSection(theme),
            const SizedBox(height: 24),

            // Section 1: National Overview
            _buildNationalOverviewSection(theme, report.nationalOverview),
            const SizedBox(height: 32),

            // Section 2: Exam Coverage
            _buildExamCoverageSection(theme, report.examCoverage),
            const SizedBox(height: 32),

            // Section 3: Subject Coverage
            _buildSubjectCoverageSection(theme, report.subjectCoverage),
            const SizedBox(height: 32),

            // Section 4: Topic Coverage
            _buildTopicCoverageSection(theme, report.topicCoverage),
            const SizedBox(height: 32),

            // Section 5: Year Matrix
            _buildYearMatrixSection(theme, report.yearMatrix),
            const SizedBox(height: 32),

            // Section 6: Editorial Queue
            _buildEditorialQueueSection(theme, report.editorialQueue),
            const SizedBox(height: 32),

            // Section 7: Knowledge Graph Status
            _buildKnowledgeGraphSection(theme, report.knowledgeGraph),
            const SizedBox(height: 32),

            // Section 8: Quality Dashboard
            _buildQualityDashboardSection(theme, report.qualityDashboard),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 9: FILTERS
  // ---------------------------------------------------------------------------
  Widget _buildFiltersSection(ThemeData theme) {
    const examOptions = SupportedExam.initialExams;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.filter_list, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Editorial Filters',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (!_filter.isEmpty)
                  TextButton.icon(
                    key: const Key('reset_filters_button'),
                    onPressed: _resetFilter,
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Reset All Filters'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Exam Filter
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    key: const Key('filter_exam_dropdown'),
                    initialValue: _filter.examId,
                    decoration: const InputDecoration(
                      labelText: 'Exam',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Exams')),
                      ...examOptions.map((e) => DropdownMenuItem(
                            value: e.id,
                            child: Text(e.code),
                          )),
                    ],
                    onChanged: (val) => _updateFilter(_filter.copyWith(examId: val, clearExam: val == null)),
                  ),
                ),

                // Year Filter
                SizedBox(
                  width: 120,
                  child: DropdownButtonFormField<int>(
                    isExpanded: true,
                    key: const Key('filter_year_dropdown'),
                    initialValue: _filter.year,
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Years')),
                      ...List.generate(32, (i) => 1995 + i).reversed.map((y) => DropdownMenuItem(
                            value: y,
                            child: Text('$y'),
                          )),
                    ],
                    onChanged: (val) => _updateFilter(_filter.copyWith(year: val, clearYear: val == null)),
                  ),
                ),

                // Subject Filter
                SizedBox(
                  width: 170,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    key: const Key('filter_subject_dropdown'),
                    initialValue: _filter.subject,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Subjects')),
                      ...CoverageCalculator.standardSubjects.map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s),
                          )),
                    ],
                    onChanged: (val) => _updateFilter(_filter.copyWith(subject: val, clearSubject: val == null)),
                  ),
                ),

                // Difficulty Filter
                SizedBox(
                  width: 130,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    key: const Key('filter_difficulty_dropdown'),
                    initialValue: _filter.difficulty,
                    decoration: const InputDecoration(
                      labelText: 'Difficulty',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All Levels')),
                      DropdownMenuItem(value: 'Easy', child: Text('Easy')),
                      DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'Hard', child: Text('Hard')),
                    ],
                    onChanged: (val) => _updateFilter(_filter.copyWith(difficulty: val, clearDifficulty: val == null)),
                  ),
                ),

                // Editorial Status Filter
                SizedBox(
                  width: 190,
                  child: DropdownButtonFormField<EditorialStatus>(
                    isExpanded: true,
                    key: const Key('filter_status_dropdown'),
                    initialValue: _filter.editorialStatus,
                    decoration: const InputDecoration(
                      labelText: 'Editorial Status',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Statuses')),
                      ...EditorialStatus.values.map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.label),
                          )),
                    ],
                    onChanged: (val) => _updateFilter(_filter.copyWith(editorialStatus: val, clearEditorialStatus: val == null)),
                  ),
                ),

                // Confidence Tier Filter
                SizedBox(
                  width: 140,
                  child: DropdownButtonFormField<QualityTier>(
                    isExpanded: true,
                    key: const Key('filter_tier_dropdown'),
                    initialValue: _filter.confidenceTier,
                    decoration: const InputDecoration(
                      labelText: 'Quality Tier',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Tiers')),
                      ...QualityTier.values.map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.label),
                          )),
                    ],
                    onChanged: (val) => _updateFilter(_filter.copyWith(confidenceTier: val, clearConfidenceTier: val == null)),
                  ),
                ),

                // Language Filter
                SizedBox(
                  width: 130,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    key: const Key('filter_language_dropdown'),
                    initialValue: _filter.language,
                    decoration: const InputDecoration(
                      labelText: 'Language',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All')),
                      DropdownMenuItem(value: 'en', child: Text('English (en)')),
                      DropdownMenuItem(value: 'hi', child: Text('Hindi (hi)')),
                    ],
                    onChanged: (val) => _updateFilter(_filter.copyWith(language: val, clearLanguage: val == null)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 1: NATIONAL OVERVIEW
  // ---------------------------------------------------------------------------
  Widget _buildNationalOverviewSection(ThemeData theme, NationalOverviewMetrics n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, '1. National Overview', Icons.public, 'Total Questions, Verified, Published, Tiers & Coverage %'),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 900;
            return GridView.count(
              crossAxisCount: isDesktop ? 4 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              childAspectRatio: isDesktop ? 2.1 : 1.6,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _OverviewMetricTile(
                  title: 'Total Questions',
                  value: '${n.totalQuestions}',
                  subtitle: 'National Repository Count',
                  icon: Icons.library_books,
                  color: Colors.blueAccent,
                ),
                _OverviewMetricTile(
                  title: 'Verified Questions',
                  value: '${n.verifiedQuestions}',
                  subtitle: 'Accuracy & Key Confirmed',
                  icon: Icons.verified,
                  color: Colors.teal,
                ),
                _OverviewMetricTile(
                  title: 'Published Questions',
                  value: '${n.publishedQuestions}',
                  subtitle: 'Live in Production',
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                ),
                _OverviewMetricTile(
                  title: 'National Coverage',
                  value: '${n.coveragePercentage}%',
                  subtitle: 'Verified Completion Ratio',
                  icon: Icons.pie_chart,
                  color: Colors.deepPurple,
                  progress: n.coveragePercentage / 100.0,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quality Tiers Breakdown',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _TierBadge(label: 'Gold', count: n.goldQuestions, color: Colors.amber.shade700, icon: Icons.workspace_premium),
                    const SizedBox(width: 16),
                    _TierBadge(label: 'Silver', count: n.silverQuestions, color: Colors.blueGrey, icon: Icons.military_tech),
                    const SizedBox(width: 16),
                    _TierBadge(label: 'Bronze', count: n.bronzeQuestions, color: Colors.brown.shade400, icon: Icons.stars),
                    const SizedBox(width: 16),
                    _TierBadge(label: 'Draft', count: n.draftQuestions, color: Colors.orange.shade800, icon: Icons.drafts),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 2: EXAM COVERAGE
  // ---------------------------------------------------------------------------
  Widget _buildExamCoverageSection(ThemeData theme, List<ExamCoverageItem> exams) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, '2. Exam Coverage', Icons.assignment, 'Coverage across central, defense, regulatory, and state PSC exams'),
        const SizedBox(height: 16),
        Card(
          child: SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
              columnSpacing: 20,
              headingRowHeight: 44,
              dataRowMinHeight: 48,
              columns: const [
                DataColumn(label: Text('Exam', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Code', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Years Covered', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                DataColumn(label: Text('Years Missing', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                DataColumn(label: Text('Imported', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                DataColumn(label: Text('Verified', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                DataColumn(label: Text('Published', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                DataColumn(label: Text('Coverage %', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: exams.map((e) {
                return DataRow(
                  cells: [
                    DataCell(Text(e.examName, style: const TextStyle(fontWeight: FontWeight.w500))),
                    DataCell(Chip(label: Text(e.code, style: const TextStyle(fontSize: 12)), padding: EdgeInsets.zero)),
                    DataCell(Text('${e.yearsCovered}')),
                    DataCell(Text('${e.yearsMissing}', style: TextStyle(color: e.yearsMissing > 0 ? Colors.orange.shade800 : Colors.green))),
                    DataCell(Text('${e.questionsImported}')),
                    DataCell(Text('${e.questionsVerified}')),
                    DataCell(Text('${e.questionsPublished}')),
                    DataCell(
                      Row(
                        children: [
                          SizedBox(
                            width: 60,
                            child: LinearProgressIndicator(
                              value: e.coveragePercentage / 100.0,
                              backgroundColor: theme.colorScheme.surfaceContainerHighest,
                              color: e.coveragePercentage >= 80 ? Colors.green : (e.coveragePercentage >= 40 ? Colors.amber : Colors.redAccent),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${e.coveragePercentage}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 3: SUBJECT COVERAGE
  // ---------------------------------------------------------------------------
  Widget _buildSubjectCoverageSection(ThemeData theme, List<SubjectCoverageItem> subjects) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, '3. Subject Coverage', Icons.menu_book, 'Status across core GS and optional syllabus domains'),
        const SizedBox(height: 16),
        Card(
          child: SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text('Subject', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Imported', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                DataColumn(label: Text('Verified', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                DataColumn(label: Text('Mapped', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                DataColumn(label: Text('Published', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                DataColumn(label: Text('Remaining', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                DataColumn(label: Text('Coverage %', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: subjects.map((s) {
                return DataRow(
                  cells: [
                    DataCell(Text(s.subject, style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text('${s.imported}')),
                    DataCell(Text('${s.verified}')),
                    DataCell(Text('${s.mapped}')),
                    DataCell(Text('${s.published}')),
                    DataCell(Text('${s.remaining}', style: TextStyle(color: s.remaining > 0 ? Colors.deepOrange : Colors.green))),
                    DataCell(
                      Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: LinearProgressIndicator(
                              value: s.coveragePercentage / 100.0,
                              backgroundColor: theme.colorScheme.surfaceContainerHighest,
                              color: s.coveragePercentage >= 75 ? Colors.teal : Colors.indigo,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${s.coveragePercentage}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 4: TOPIC COVERAGE
  // ---------------------------------------------------------------------------
  Widget _buildTopicCoverageSection(ThemeData theme, List<TopicCoverageItem> topics) {
    const subjectsAvailable = CoverageCalculator.standardSubjects;

    final filteredTopics = topics.where((t) =>
        t.subject.toLowerCase() == _selectedSubjectForTopic.toLowerCase() ||
        _selectedSubjectForTopic == 'All').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildSectionHeader(theme, '4. Topic Coverage', Icons.account_tree, 'Micro-level breakdown by topic & subtopic'),
            DropdownButton<String>(
              value: _selectedSubjectForTopic,
              items: ['All', ...subjectsAvailable].map((s) => DropdownMenuItem(value: s, child: Text('Subject: $s'))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedSubjectForTopic = val);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredTopics.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = filteredTopics[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text('${index + 1}', style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontSize: 12)),
                ),
                title: Text('${item.subject} → ${item.topic}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Row(
                  children: [
                    Text('Questions: ${item.questions}'),
                    const SizedBox(width: 16),
                    Text('Missing: ${item.missing}', style: TextStyle(color: item.missing > 0 ? Colors.red : Colors.green)),
                  ],
                ),
                trailing: SizedBox(
                  width: 180,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 80,
                        child: LinearProgressIndicator(
                          value: item.coveragePercentage / 100.0,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          color: item.coveragePercentage >= 80 ? Colors.green : Colors.amber.shade700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${item.coveragePercentage}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 5: YEAR MATRIX
  // ---------------------------------------------------------------------------
  Widget _buildYearMatrixSection(ThemeData theme, List<YearMatrixItem> matrix) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, '5. Year Matrix (1995 - 2026)', Icons.calendar_month, 'Heatmap of paper coverage per annual exam cycle'),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _HeatmapLegendItem(label: 'Missing (0)', color: Colors.grey.shade300),
                    const SizedBox(width: 16),
                    _HeatmapLegendItem(label: 'Partial', color: Colors.amber.shade400),
                    const SizedBox(width: 16),
                    _HeatmapLegendItem(label: 'Complete (Verified)', color: Colors.green.shade500),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: matrix.map((item) {
                    Color tileColor;
                    Color textColor = Colors.black;
                    switch (item.status) {
                      case YearCoverageStatus.missing:
                        tileColor = Colors.grey.shade200;
                        textColor = Colors.grey.shade600;
                        break;
                      case YearCoverageStatus.partial:
                        tileColor = Colors.amber.shade300;
                        break;
                      case YearCoverageStatus.complete:
                        tileColor = Colors.green.shade400;
                        textColor = Colors.white;
                        break;
                    }

                    return Tooltip(
                      message: 'Year ${item.year}: ${item.verifiedQuestions}/${item.totalQuestions} verified',
                      child: Container(
                        width: 72,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                        decoration: BoxDecoration(
                          color: tileColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${item.year}',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.verifiedQuestions}/${item.totalQuestions}',
                              style: TextStyle(fontSize: 11, color: textColor.withValues(alpha: 0.85)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 6: EDITORIAL QUEUE
  // ---------------------------------------------------------------------------
  Widget _buildEditorialQueueSection(ThemeData theme, EditorialQueueMetrics q) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, '6. Editorial Queue', Icons.queue, 'Action items requiring editor intervention'),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 900;
            return GridView.count(
              crossAxisCount: isDesktop ? 3 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              childAspectRatio: isDesktop ? 2.2 : 1.6,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _QueueCard(title: 'Pending Verification', count: q.pendingVerification, icon: Icons.pending_actions, color: Colors.amber.shade800),
                _QueueCard(title: 'Pending Mapping', count: q.pendingMapping, icon: Icons.alt_route, color: Colors.blueAccent),
                _QueueCard(title: 'Pending Review', count: q.pendingReview, icon: Icons.rate_review, color: Colors.purple),
                _QueueCard(title: 'Pending Publication', count: q.pendingPublication, icon: Icons.publish, color: Colors.teal),
                _QueueCard(title: 'Rejected Entries', count: q.rejected, icon: Icons.cancel, color: Colors.redAccent),
                _QueueCard(title: 'Flagged Entries', count: q.flagged, icon: Icons.flag, color: Colors.deepOrange),
              ],
            );
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 7: KNOWLEDGE GRAPH STATUS
  // ---------------------------------------------------------------------------
  Widget _buildKnowledgeGraphSection(ThemeData theme, KnowledgeGraphMetrics k) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, '7. Knowledge Graph Status', Icons.hub, 'Entities, legal articles, cases, and knowledge links'),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Wrap(
              spacing: 24,
              runSpacing: 20,
              children: [
                _GraphMetricChip(label: 'Questions Linked', count: k.questionsLinked, icon: Icons.link),
                _GraphMetricChip(label: 'Articles Linked', count: k.articlesLinked, icon: Icons.gavel),
                _GraphMetricChip(label: 'Acts Linked', count: k.actsLinked, icon: Icons.balance),
                _GraphMetricChip(label: 'Cases Linked', count: k.casesLinked, icon: Icons.account_balance),
                _GraphMetricChip(label: 'Committees Linked', count: k.committeesLinked, icon: Icons.groups),
                _GraphMetricChip(label: 'Reports Linked', count: k.reportsLinked, icon: Icons.description),
                _GraphMetricChip(label: 'Current Affairs Linked', count: k.currentAffairsLinked, icon: Icons.newspaper),
                _GraphMetricChip(label: 'Knowledge Objects', count: k.knowledgeObjectsLinked, icon: Icons.extension),
                _GraphMetricChip(label: 'Concepts Linked', count: k.conceptsLinked, icon: Icons.lightbulb),
                _GraphMetricChip(label: 'Micro Concepts', count: k.microConceptsLinked, icon: Icons.grain),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 8: QUALITY DASHBOARD
  // ---------------------------------------------------------------------------
  Widget _buildQualityDashboardSection(ThemeData theme, QualityDashboardMetrics q) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, '8. Quality Dashboard', Icons.high_quality, 'Completeness of editorial enrichments & trap analysis'),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _QualityProgressRow(label: 'Trap Analysis', pct: q.trapAnalysisPercentage, color: Colors.orange.shade700),
                const SizedBox(height: 16),
                _QualityProgressRow(label: 'Learning Objectives', pct: q.learningObjectivesPercentage, color: Colors.blue),
                const SizedBox(height: 16),
                _QualityProgressRow(label: 'Concept Mapping', pct: q.conceptMappingPercentage, color: Colors.purple),
                const SizedBox(height: 16),
                _QualityProgressRow(label: 'Editorial Review', pct: q.editorialReviewPercentage, color: Colors.teal),
                const SizedBox(height: 16),
                _QualityProgressRow(label: 'Knowledge Links', pct: q.knowledgeLinksPercentage, color: Colors.indigo),
                const SizedBox(height: 16),
                _QualityProgressRow(label: 'Evidence Links', pct: q.evidenceLinksPercentage, color: Colors.green),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Section Header helper
  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon, String subtitle) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 24),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 10: EXPORT DIALOG
  // ---------------------------------------------------------------------------
  void _showExportDialog(BuildContext context, CoverageReport report) {
    showDialog(
      context: context,
      builder: (context) {
        return DefaultTabController(
          length: 3,
          child: AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.ios_share),
                SizedBox(width: 10),
                Text('Export Coverage Dashboard'),
              ],
            ),
            content: SizedBox(
              width: 700,
              height: 450,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'CSV Export'),
                      Tab(text: 'JSON Export'),
                      Tab(text: 'Markdown Summary'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _ExportCodePreview(content: CoverageExporter.exportToCsv(report)),
                        _ExportCodePreview(content: CoverageExporter.exportToJson(report)),
                        _ExportCodePreview(content: CoverageExporter.exportToMarkdown(report)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// UI SUBCOMPONENTS
// -----------------------------------------------------------------------------
class _OverviewMetricTile extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double? progress;

  const _OverviewMetricTile({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                if (progress != null) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: progress, color: color),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _TierBadge({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text('$label: $count', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
    );
  }
}

class _HeatmapLegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _HeatmapLegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _QueueCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  const _QueueCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$count',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
                  ),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GraphMetricChip extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;

  const _GraphMetricChip({required this.label, required this.count, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _QualityProgressRow extends StatelessWidget {
  final String label;
  final double pct;
  final Color color;

  const _QualityProgressRow({required this.label, required this.pct, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 160,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct / 100.0,
              minHeight: 12,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 60,
          child: Text('$pct%', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ),
      ],
    );
  }
}

class _ExportCodePreview extends StatelessWidget {
  final String content;

  const _ExportCodePreview({required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SelectableText(
        content,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.greenAccent),
      ),
    );
  }
}
