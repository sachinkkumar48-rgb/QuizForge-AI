import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:garuda_learning/garuda_learning.dart';

import '../controllers/analytics_controller.dart';
import '../core/di/service_locator_init.dart';
import '../models/analytics_engine_models.dart';
import '../models/pyq_question_model.dart';
import '../widgets/analytics_dashboard_cards.dart';

/// Comprehensive Analytics Dashboard Page displaying learning insights,
/// authoritative performance metrics, confidence-weighted weak area detection,
/// mastery distribution, and chronological trends (P46).
class AnalyticsDashboardPage extends StatefulWidget {
  final List<PyqQuestionModel> questions;
  final AnalyticsController? controller;
  final LearnerAnalyticsReport? initialReport;
  final LearnerAnalyticsService? analyticsService;
  final String? learnerId;
  final String? examId;

  const AnalyticsDashboardPage({
    super.key,
    this.questions = const [],
    this.controller,
    this.initialReport,
    this.analyticsService,
    this.learnerId,
    this.examId,
  });

  @override
  State<AnalyticsDashboardPage> createState() => _AnalyticsDashboardPageState();
}

class _AnalyticsDashboardPageState extends State<AnalyticsDashboardPage> {
  late final AnalyticsController _controller;
  LearnerAnalyticsReport? _authoritativeReport;
  bool _isLoadingAuthoritative = false;
  String _authoritativeError = '';

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? AnalyticsController();

    if (widget.initialReport != null) {
      _authoritativeReport = widget.initialReport;
    } else if (widget.analyticsService != null || widget.questions.isEmpty) {
      _loadAuthoritativeReport();
    } else {
      _controller.loadAnalytics(widget.questions);
    }
  }

  Future<void> _loadAuthoritativeReport() async {
    setState(() {
      _isLoadingAuthoritative = true;
      _authoritativeError = '';
    });

    try {
      final service = widget.analyticsService ?? _resolveAnalyticsService();
      final learnerId = widget.learnerId ?? 'default_learner';
      final examId = widget.examId ?? 'upsc_prelims_gs1';

      final report = await service.computeLearnerReport(
        learnerId: learnerId,
        examId: examId,
      );

      if (mounted) {
        setState(() {
          _authoritativeReport = report;
          _isLoadingAuthoritative = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _authoritativeError = e.toString().replaceAll('Exception: ', '');
          _isLoadingAuthoritative = false;
        });
      }
    }
  }

  LearnerAnalyticsService _resolveAnalyticsService() {
    CurriculumService curriculumService;
    try {
      curriculumService = locate<CurriculumService>();
    } catch (_) {
      curriculumService = CurriculumService(
        framework: CurriculumSeedData.buildUpscConstitutionalLawFramework(),
      );
    }

    AuthoritativeLearningStateRecoveryService? authRecoveryService;
    try {
      authRecoveryService = locate<AuthoritativeLearningStateRecoveryService>();
    } catch (_) {}

    SessionCheckpointRepository? checkpointRepo;
    try {
      checkpointRepo = locate<SessionCheckpointRepository>();
    } catch (_) {}

    final masteryService = MasteryProgressionService(
      curriculumService: curriculumService,
      authRecoveryService: authRecoveryService ??
          AuthoritativeLearningStateRecoveryService(
            repository: InMemoryAuthoritativeLearningStateRepository(),
          ),
      checkpointRepository:
          checkpointRepo ?? InMemorySessionCheckpointRepository(),
    );

    return LearnerAnalyticsService(
      curriculumService: curriculumService,
      masteryService: masteryService,
      authRecoveryService: authRecoveryService,
      checkpointRepository: checkpointRepo,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_authoritativeReport != null ||
        _isLoadingAuthoritative ||
        _authoritativeError.isNotEmpty) {
      return _buildAuthoritativeView(context);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final insights = _controller.insights;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Learning Analytics Engine'),
            actions: [
              IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Export Report',
                onPressed:
                    insights == null ? null : () => _showExportModal(context),
              ),
            ],
          ),
          body: _controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : insights == null
                  ? Center(
                      child: Text(_controller.errorMessage.isNotEmpty
                          ? _controller.errorMessage
                          : 'No analytics data available.'),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        Text(
                          'Performance Overview',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        AnalyticsDashboardCards(insights: insights),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Icon(Icons.psychology,
                                color: Colors.deepOrange),
                            const SizedBox(width: 8),
                            Text(
                              'Weak Area Detection & Confidence',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (insights.weakAreaInsights.isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child:
                                  Text('No weak areas detected! Great work.'),
                            ),
                          )
                        else
                          ...insights.weakAreaInsights.map((insight) {
                            return Card(
                              elevation: 1,
                              margin: const EdgeInsets.only(bottom: 8.0),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getConfidenceColor(
                                          insight.confidenceLevel)
                                      .withAlpha(40),
                                  child: Icon(
                                    Icons.warning_amber,
                                    color: _getConfidenceColor(
                                        insight.confidenceLevel),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${insight.dimension.toUpperCase()}: ${insight.name}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Chip(
                                      label: Text(
                                        '${insight.accuracyPercent.toStringAsFixed(1)}%',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      backgroundColor: Colors.red.shade100,
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                        'Confidence: ${insight.confidenceLevel.label}'),
                                    Text(
                                        'Recommendation: ${insight.recommendation}'),
                                  ],
                                ),
                              ),
                            );
                          }),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Icon(Icons.trending_up, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              'Historical Snapshots & Trends',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.add_a_photo),
                              tooltip: 'Capture Snapshot',
                              onPressed: () async {
                                await _controller.captureSnapshot();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Performance snapshot captured!')),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_controller.historicalSnapshots.isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child:
                                  Text('No historical snapshots captured yet.'),
                            ),
                          )
                        else
                          ..._controller.historicalSnapshots.reversed
                              .take(5)
                              .map((snap) {
                            return Card(
                              elevation: 1,
                              margin: const EdgeInsets.only(bottom: 8.0),
                              child: ListTile(
                                leading: const Icon(Icons.camera_alt,
                                    color: Colors.blue),
                                title: Text(
                                  'Accuracy: ${snap.overallAccuracy.toStringAsFixed(1)}% • ${snap.currentStreak} Day Streak',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  'Date: ${snap.timestamp.toLocal().toString().split('.').first}\nWeak: ${snap.weakSubjects.join(', ')}',
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
        );
      },
    );
  }

  Widget _buildAuthoritativeView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Analytics Engine'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Analytics',
            onPressed: _loadAuthoritativeReport,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export Report',
            onPressed: _authoritativeReport == null
                ? null
                : () => _displayExportedContent(
                      context,
                      'Analytics Report JSON',
                      const JsonEncoder.withIndent('  ')
                          .convert(_authoritativeReport!.toJson()),
                    ),
          ),
        ],
      ),
      body: _isLoadingAuthoritative
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Computing Authoritative Learning Analytics...'),
                ],
              ),
            )
          : _authoritativeError.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Analytics Calculation Failure',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(_authoritativeError,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadAuthoritativeReport,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _authoritativeReport == null || _authoritativeReport!.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.insights,
                                size: 64, color: Colors.deepPurple),
                            const SizedBox(height: 16),
                            Text(
                              'No Learning Activity Recorded',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Start adaptive practice or PYQs to generate authoritative performance reports and weak area insights.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        Text(
                          'Performance Overview',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        _buildAuthoritativeSummaryCards(context),
                        const SizedBox(height: 24),
                        _buildMasteryDistributionSection(context),
                        const SizedBox(height: 24),
                        _buildAuthoritativeWeakAreasSection(context),
                        const SizedBox(height: 24),
                        _buildCurriculumPerformanceSection(context),
                        const SizedBox(height: 24),
                        _buildAuthoritativeTrendsSection(context),
                        if (_authoritativeReport!.facultySummary != null &&
                            _authoritativeReport!
                                    .facultySummary!.totalContentItems >
                                0) ...[
                          const SizedBox(height: 24),
                          _buildFacultySection(context),
                        ],
                        const SizedBox(height: 32),
                      ],
                    ),
    );
  }

  Widget _buildAuthoritativeSummaryCards(BuildContext context) {
    final summary = _authoritativeReport!.summary;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Overall Accuracy',
                value: '${summary.accuracyPercentage.toStringAsFixed(1)}%',
                subtitle:
                    '${summary.correctCount}/${summary.totalAttempts} correct',
                icon: Icons.track_changes,
                color: summary.accuracy >= 0.7 ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: "Today's Progress",
                value: '${summary.completionPercentage.toStringAsFixed(0)}%',
                subtitle:
                    '${summary.objectivesMastered}/${summary.totalObjectives} mastered',
                icon: Icons.flag,
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Current Streak',
                value: '${summary.currentStreak} Days',
                subtitle: summary.lastActiveAt != null
                    ? 'Active: ${summary.lastActiveAt!.toLocal().toString().split(' ').first}'
                    : 'No activity yet',
                icon: Icons.local_fire_department,
                color: Colors.deepOrange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Remediation Targets',
                value: '${summary.objectivesNeedingRemediation}',
                subtitle: 'Objectives needing support',
                icon: Icons.healing,
                color: summary.objectivesNeedingRemediation > 0
                    ? Colors.red
                    : Colors.blueGrey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMasteryDistributionSection(BuildContext context) {
    final dist = _authoritativeReport!.masteryDistribution;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.pie_chart, color: Colors.deepPurple),
            const SizedBox(width: 8),
            Text(
              'Mastery Distribution',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: dist.entries.map((entry) {
            final color = _getStageColor(entry.key);
            return Chip(
              avatar: CircleAvatar(
                backgroundColor: color,
                radius: 6,
              ),
              label: Text(
                '${entry.key.displayName}: ${entry.value}',
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
              backgroundColor: color.withAlpha(25),
              side: BorderSide(color: color.withAlpha(80)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAuthoritativeWeakAreasSection(BuildContext context) {
    final weakAreas = _authoritativeReport!.weakAreas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.psychology, color: Colors.deepOrange),
            const SizedBox(width: 8),
            Text(
              'Weak Area Detection & Confidence',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (weakAreas.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No weak areas detected! Great work.'),
            ),
          )
        else
          ...weakAreas.map((weak) {
            return Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 8.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: weak.isRemediationRequired
                      ? Colors.red.shade300
                      : Colors.orange.shade200,
                ),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: weak.isRemediationRequired
                      ? Colors.red.shade100
                      : Colors.orange.shade100,
                  child: Icon(
                    weak.isRemediationRequired
                        ? Icons.warning_amber
                        : Icons.info_outline,
                    color:
                        weak.isRemediationRequired ? Colors.red : Colors.orange,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${weak.dimension.toUpperCase()}: ${weak.name}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Chip(
                      label: Text(
                        '${weak.accuracyPercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: Colors.red.shade100,
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                        'Stage: ${weak.stage.displayName} • ${weak.attempts} attempts'),
                    Text('Recommendation: ${weak.recommendedAction}',
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildCurriculumPerformanceSection(BuildContext context) {
    final subjects = _authoritativeReport!.subjects;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.account_tree, color: Colors.teal),
            const SizedBox(width: 8),
            Text(
              'Curriculum Performance Drilldown',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...subjects.map((subj) {
          return Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 8),
            child: ExpansionTile(
              leading: const Icon(Icons.menu_book, color: Colors.teal),
              title: Text(
                subj.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Accuracy: ${subj.accuracyPercentage.toStringAsFixed(1)}% • ${subj.questionsAttempted} attempts • ${subj.objectivesMastered}/${subj.totalObjectives} mastered',
              ),
              children: subj.topics.map((topic) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: ExpansionTile(
                    leading: const Icon(Icons.topic, size: 20),
                    title: Text(topic.title),
                    subtitle: Text(
                      'Accuracy: ${topic.accuracyPercentage.toStringAsFixed(1)}% • ${topic.questionsAttempted} attempts',
                    ),
                    children: topic.objectives.map((obj) {
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          obj.stage.isMastered
                              ? Icons.check_circle
                              : obj.stage.isStruggling
                                  ? Icons.error
                                  : Icons.circle_outlined,
                          size: 16,
                          color: _getStageColor(obj.stage),
                        ),
                        title: Text(obj.title),
                        subtitle: Text(
                          '${obj.attempts} attempts • ${obj.accuracyPercentage.toStringAsFixed(0)}% accuracy',
                        ),
                        trailing: Chip(
                          label: Text(
                            obj.stage.displayName,
                            style: const TextStyle(fontSize: 10),
                          ),
                          backgroundColor:
                              _getStageColor(obj.stage).withAlpha(30),
                        ),
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAuthoritativeTrendsSection(BuildContext context) {
    final trends = _authoritativeReport!.performanceTrends;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.trending_up, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              'Historical Snapshots & Trends',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (trends.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                  'No historical snapshots captured yet. Complete practice drills to see trends.'),
            ),
          )
        else
          ...trends.reversed.take(5).map((snap) {
            return Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 8.0),
              child: ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: Text(
                  'Accuracy: ${(snap.cumulativeAccuracy * 100).toStringAsFixed(1)}% • ${snap.cumulativeAttempts} Cumulative Attempts',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Date: ${snap.timestamp.toLocal().toString().split('.').first}\nRecent session: ${snap.attempts} questions (${(snap.accuracy * 100).toStringAsFixed(0)}%)',
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildFacultySection(BuildContext context) {
    final fac = _authoritativeReport!.facultySummary!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.school, color: Colors.indigo),
            const SizedBox(width: 8),
            Text(
              'Faculty Content Operations',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSubMetric('Total Managed', '${fac.totalContentItems}'),
                _buildSubMetric('Published', '${fac.publishedCount}'),
                _buildSubMetric('Questions', '${fac.totalQuestions}'),
                _buildSubMetric(
                    'Remedial Lessons', '${fac.totalRemedialLessons}'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubMetric(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Color _getStageColor(ProgressionStage stage) {
    switch (stage) {
      case ProgressionStage.mastered:
        return Colors.green;
      case ProgressionStage.improving:
        return Colors.teal;
      case ProgressionStage.learning:
        return Colors.blue;
      case ProgressionStage.insufficientEvidence:
        return Colors.amber;
      case ProgressionStage.remediationRequired:
        return Colors.red;
      case ProgressionStage.regressed:
        return Colors.deepOrange;
      case ProgressionStage.notStarted:
        return Colors.grey;
    }
  }

  Color _getConfidenceColor(ConfidenceLevel level) {
    switch (level) {
      case ConfidenceLevel.high:
        return Colors.red;
      case ConfidenceLevel.medium:
        return Colors.orange;
      case ConfidenceLevel.low:
        return Colors.grey;
    }
  }

  void _showExportModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Learning Insights',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.code, color: Colors.blue),
              title: const Text('Export JSON Data'),
              subtitle:
                  const Text('Structured JSON for raw analytics integration'),
              onTap: () {
                Navigator.pop(context);
                _displayExportedContent(
                    context, 'JSON Export', _controller.exportJson());
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Export CSV Report'),
              subtitle: const Text('Spreadsheet compatible CSV table format'),
              onTap: () {
                Navigator.pop(context);
                _displayExportedContent(
                    context, 'CSV Export', _controller.exportCsv());
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.picture_as_pdf, color: Colors.deepOrange),
              title: const Text('Export Text / PDF Summary'),
              subtitle:
                  const Text('Printable formatted learning report summary'),
              onTap: () {
                Navigator.pop(context);
                _displayExportedContent(context, 'PDF / Text Summary',
                    _controller.exportPdfReport());
              },
            ),
          ],
        ),
      ),
    );
  }

  void _displayExportedContent(
      BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: SingleChildScrollView(
            child: SelectableText(
              content,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
