import 'dart:async';
import 'package:flutter/material.dart';
import 'package:garuda_learning/garuda_learning.dart';

import '../core/di/service_locator_init.dart';
import 'gradebook_page.dart';

/// Assessment & Examination Management Portal (TITAN-KO-049.0 P49).
///
/// Supports two real operational perspectives:
/// 1. Faculty Dashboard: Examination authoring, marks/penalty configuration,
///    timing limits, question selection from real banks, cohort assignment,
///    and cohort compliance/result analytics.
/// 2. Learner View: Available examinations, timed/untimed attempt execution,
///    deterministic answer capture, instant result generation, and performance review.
class AssessmentManagementPage extends StatefulWidget {
  final AssessmentManagementService? service;
  final String initialFacultyId;
  final String initialLearnerId;
  final String? initialCohortId;
  final bool initialIsFaculty;

  const AssessmentManagementPage({
    super.key,
    this.service,
    this.initialFacultyId = 'faculty_admin',
    this.initialLearnerId = 'default_learner',
    this.initialCohortId,
    this.initialIsFaculty = true,
  });

  @override
  State<AssessmentManagementPage> createState() =>
      _AssessmentManagementPageState();
}

class _AssessmentManagementPageState extends State<AssessmentManagementPage> {
  late final AssessmentManagementService _service;
  late bool _isFacultyMode;
  late String _currentFacultyId;
  late String _currentLearnerId;
  String? _selectedCohortId;

  List<Assessment> _facultyAssessments = [];
  List<Assessment> _learnerAssessments = [];
  List<AssessmentResult> _learnerResults = [];

  bool _isLoading = true;
  String? _errorMessage;

  // Active attempt state for learner
  Assessment? _activeAssessment;
  AssessmentAttempt? _activeAttempt;
  int _activeQuestionIndex = 0;
  List<IQuestionEntity> _activeQuestions = [];
  Timer? _countdownTimer;
  Duration? _remainingDuration;

  @override
  void initState() {
    super.initState();
    _isFacultyMode = widget.initialIsFaculty;
    _currentFacultyId = widget.initialFacultyId;
    _currentLearnerId = widget.initialLearnerId;
    _selectedCohortId = widget.initialCohortId;

    try {
      _service = widget.service ?? locate<AssessmentManagementService>();
    } catch (_) {
      _service = AssessmentManagementService(
        repository: InMemoryAssessmentRepository(),
        questionProvider: CaseLawQuestionProvider(),
      );
    }

    _loadData();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isFacultyMode) {
        var assessments =
            await _service.getAssessmentsForFaculty(_currentFacultyId);
        if (assessments.isEmpty) {
          assessments = await _service.repository.listAssessments();
        }
        _facultyAssessments = assessments;
      } else {
        _learnerAssessments = await _service.getAvailableAssessments(
          learnerId: _currentLearnerId,
        );
        _learnerResults =
            await _service.getResultsForLearner(_currentLearnerId);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // If active assessment is being taken by learner
    if (_activeAssessment != null && _activeAttempt != null) {
      return _buildActiveExamView(theme, colorScheme);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Assessments & Exams",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text("Faculty"),
                  icon: Icon(Icons.school, size: 16),
                ),
                ButtonSegment(
                  value: false,
                  label: Text("Learner"),
                  icon: Icon(Icons.person, size: 16),
                ),
              ],
              selected: {_isFacultyMode},
              onSelectionChanged: (set) {
                setState(() {
                  _isFacultyMode = set.first;
                });
                _loadData();
              },
            ),
          ),
          IconButton(
            key: const Key('assessment_gradebook_button'),
            icon: const Icon(Icons.table_chart_outlined),
            tooltip: "Gradebook",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GradebookPage(
                    initialCohortId: _selectedCohortId,
                    initialFacultyId: _currentFacultyId,
                    initialLearnerId: _currentLearnerId,
                    initialIsFaculty: _isFacultyMode,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _loadData,
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  ),
                )
              : _isFacultyMode
                  ? _buildFacultyView(theme, colorScheme)
                  : _buildLearnerView(theme, colorScheme),
      floatingActionButton: _isFacultyMode
          ? FloatingActionButton.extended(
              key: const Key('create_assessment_button'),
              onPressed: _showCreateAssessmentDialog,
              icon: const Icon(Icons.add),
              label: const Text("New Assessment"),
            )
          : null,
    );
  }

  // ---------------------------------------------------------------------------
  // Faculty View
  // ---------------------------------------------------------------------------

  Widget _buildFacultyView(ThemeData theme, ColorScheme colorScheme) {
    if (_facultyAssessments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_outlined,
                  size: 64, color: colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                "No Assessments Found",
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Author a formal assessment, configure marks and duration, and assign to student cohorts.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const Key('create_first_assessment_button'),
                onPressed: _showCreateAssessmentDialog,
                icon: const Icon(Icons.add),
                label: const Text("Create First Assessment"),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _facultyAssessments.length,
      itemBuilder: (context, index) {
        final assessment = _facultyAssessments[index];
        return _buildFacultyAssessmentCard(theme, colorScheme, assessment);
      },
    );
  }

  Widget _buildFacultyAssessmentCard(
    ThemeData theme,
    ColorScheme colorScheme,
    Assessment a,
  ) {
    final statusColor = switch (a.status) {
      AssessmentStatus.draft => Colors.orange,
      AssessmentStatus.published => Colors.green,
      AssessmentStatus.open => Colors.blue,
      AssessmentStatus.closed => Colors.grey,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    a.title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Chip(
                  label: Text(
                    a.status.name.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: statusColor.withValues(alpha: 0.1),
                  side: BorderSide(color: statusColor),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (a.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                a.description,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _infoChip(Icons.quiz_outlined,
                    "${a.questionCount} Questions (${a.totalMarks.toStringAsFixed(0)} marks)"),
                _infoChip(
                    Icons.timer_outlined,
                    a.timingConfig.durationMinutes != null
                        ? "${a.timingConfig.durationMinutes} min"
                        : "Untimed"),
                _infoChip(Icons.calculate_outlined,
                    "${a.marksConfig.marksPerQuestion}m / -${a.marksConfig.negativePenaltyPerQuestion.toStringAsFixed(2)}m"),
                _infoChip(Icons.verified_outlined,
                    "Pass: ${a.marksConfig.passingPercentage.toStringAsFixed(0)}%"),
                if (a.cohortIds.isNotEmpty)
                  _infoChip(Icons.groups_outlined,
                      "Cohorts: ${a.cohortIds.join(', ')}"),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (a.status == AssessmentStatus.draft)
                  FilledButton.tonalIcon(
                    key: Key('publish_assessment_${a.assessmentId}'),
                    icon: const Icon(Icons.publish, size: 16),
                    label: const Text("Publish"),
                    onPressed: () => _publishAssessment(a),
                  ),
                if (a.status == AssessmentStatus.published)
                  OutlinedButton.icon(
                    key: Key('close_assessment_${a.assessmentId}'),
                    icon: const Icon(Icons.lock_outline, size: 16),
                    label: const Text("Close"),
                    onPressed: () => _closeAssessment(a),
                  ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  key: Key('assign_cohort_${a.assessmentId}'),
                  icon: const Icon(Icons.group_add, size: 16),
                  label: const Text("Assign Cohort"),
                  onPressed: () => _showAssignCohortDialog(a),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  key: Key('view_results_${a.assessmentId}'),
                  icon: const Icon(Icons.analytics_outlined, size: 16),
                  label: const Text("Results"),
                  onPressed: () => _showCohortResults(a),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.deepPurple),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Faculty Actions
  // ---------------------------------------------------------------------------

  Future<void> _publishAssessment(Assessment a) async {
    try {
      await _service.publishAssessment(a.assessmentId,
          facultyId: _currentFacultyId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Assessment "${a.title}" published')),
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _closeAssessment(Assessment a) async {
    try {
      await _service.closeAssessment(a.assessmentId,
          facultyId: _currentFacultyId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Assessment "${a.title}" closed')),
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAssignCohortDialog(Assessment a) {
    final cohortController =
        TextEditingController(text: _selectedCohortId ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Assign Cohort: ${a.title}"),
        content: TextField(
          key: const Key('assign_cohort_input'),
          controller: cohortController,
          decoration: const InputDecoration(
            labelText: "Cohort ID",
            hintText: "e.g. cohort_upsc_2026",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          FilledButton(
            key: const Key('confirm_assign_cohort_button'),
            onPressed: () async {
              final cid = cohortController.text.trim();
              if (cid.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await _service.assignCohort(
                  a.assessmentId,
                  cid,
                  facultyId: _currentFacultyId,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Cohort "$cid" assigned')),
                  );
                }
                _loadData();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text("Assign"),
          ),
        ],
      ),
    );
  }

  void _showCreateAssessmentDialog() {
    final titleCtrl =
        TextEditingController(text: "Constitutional Law Assessment");
    final examCtrl = TextEditingController(text: "upsc_prelims_gs1");
    final marksCtrl = TextEditingController(text: "2.0");
    final penaltyCtrl = TextEditingController(text: "0.333");
    final passCtrl = TextEditingController(text: "40.0");
    final durationCtrl = TextEditingController(text: "30");

    final allQuestions = _service.questionProvider.getAllQuestions();
    final selectedQIds = allQuestions.take(5).map((q) => q.id).toSet();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: const Text("Create New Assessment"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  key: const Key('assessment_title_field'),
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: "Assessment Title",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('assessment_exam_field'),
                  controller: examCtrl,
                  decoration: const InputDecoration(
                    labelText: "Exam ID",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('assessment_marks_field'),
                        controller: marksCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Marks/Question",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        key: const Key('assessment_penalty_field'),
                        controller: penaltyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Penalty Ratio",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('assessment_pass_field'),
                        controller: passCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Pass %",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        key: const Key('assessment_duration_field'),
                        controller: durationCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Duration (min)",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  "Selected Questions (${selectedQIds.length})",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: allQuestions.isEmpty
                      ? const Center(child: Text("No questions in provider"))
                      : ListView.builder(
                          itemCount: allQuestions.length,
                          itemBuilder: (c, i) {
                            final q = allQuestions[i];
                            final checked = selectedQIds.contains(q.id);
                            return CheckboxListTile(
                              dense: true,
                              title: Text(q.prompt,
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              value: checked,
                              onChanged: (v) {
                                setDialogState(() {
                                  if (v == true) {
                                    selectedQIds.add(q.id);
                                  } else {
                                    selectedQIds.remove(q.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            FilledButton(
              key: const Key('confirm_create_assessment_button'),
              onPressed: () async {
                final title = titleCtrl.text.trim();
                final exam = examCtrl.text.trim();
                if (title.isEmpty || exam.isEmpty || selectedQIds.isEmpty) {
                  return;
                }
                Navigator.pop(ctx);

                try {
                  final marksPerQ = double.tryParse(marksCtrl.text) ?? 2.0;
                  final penaltyRatio =
                      double.tryParse(penaltyCtrl.text) ?? 0.333;
                  final passPct = double.tryParse(passCtrl.text) ?? 40.0;
                  final durMin = int.tryParse(durationCtrl.text);

                  final newId =
                      'assess_${DateTime.now().millisecondsSinceEpoch}';

                  await _service.createAssessment(
                    assessmentId: newId,
                    title: title,
                    examId: exam,
                    creatorFacultyId: _currentFacultyId,
                    questionIds: selectedQIds.toList(),
                    marksConfig: AssessmentMarksConfig(
                      marksPerQuestion: marksPerQ,
                      negativeMarkRatio: penaltyRatio,
                      passingPercentage: passPct,
                    ),
                    timingConfig: AssessmentTimingConfig(
                      durationMinutes: durMin,
                    ),
                    status: AssessmentStatus.draft,
                    cohortIds:
                        _selectedCohortId != null ? [_selectedCohortId!] : null,
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Assessment "$title" created')),
                    );
                  }
                  _loadData();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text("Create"),
            ),
          ],
        ),
      ),
    );
  }

  void _showCohortResults(Assessment a) async {
    final cohortId = a.cohortIds.isNotEmpty ? a.cohortIds.first : 'all';
    try {
      final summary = await _service.getAssessmentCohortSummary(
        a.assessmentId,
        cohortId,
        facultyId: _currentFacultyId,
      );

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Cohort Results: ${a.title}",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _statCard(
                      "Submissions", "${summary.submittedCount}", Colors.blue),
                  const SizedBox(width: 8),
                  _statCard("Pass", "${summary.passCount}", Colors.green),
                  const SizedBox(width: 8),
                  _statCard("Fail", "${summary.failCount}", Colors.red),
                  const SizedBox(width: 8),
                  _statCard("Avg Score",
                      summary.averageScore.toStringAsFixed(1), Colors.purple),
                ],
              ),
              const SizedBox(height: 16),
              const Text("Learner Submissions:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (summary.results.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text("No learner submissions yet."),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: summary.results.length,
                  itemBuilder: (c, i) {
                    final res = summary.results[i];
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        res.isPassed ? Icons.check_circle : Icons.cancel,
                        color: res.isPassed ? Colors.green : Colors.red,
                      ),
                      title: Text("Learner: ${res.learnerId}"),
                      subtitle: Text(
                          "Score: ${res.score}/${res.maxScore} (${res.percentage.toStringAsFixed(1)}%)"),
                      trailing: Chip(
                        label: Text(res.isPassed ? "PASS" : "FAIL"),
                        backgroundColor: res.isPassed
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error loading results: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Learner View
  // ---------------------------------------------------------------------------

  Widget _buildLearnerView(ThemeData theme, ColorScheme colorScheme) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.assignment), text: "Available Assessments"),
              Tab(icon: Icon(Icons.history), text: "Completed Results"),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildAvailableAssessmentsTab(theme, colorScheme),
                _buildCompletedResultsTab(theme, colorScheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableAssessmentsTab(
      ThemeData theme, ColorScheme colorScheme) {
    if (_learnerAssessments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_turned_in_outlined,
                  size: 64, color: colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                "No Available Assessments",
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "You are all caught up! Assessments assigned by your faculty will appear here.",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _learnerAssessments.length,
      itemBuilder: (context, index) {
        final a = _learnerAssessments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        a.title,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Chip(
                      label: Text("${a.questionCount} Questions"),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                if (a.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(a.description),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  children: [
                    _infoChip(
                        Icons.timer_outlined,
                        a.timingConfig.durationMinutes != null
                            ? "${a.timingConfig.durationMinutes} min"
                            : "Untimed"),
                    _infoChip(Icons.grade_outlined,
                        "Max: ${a.totalMarks.toStringAsFixed(0)} marks"),
                    _infoChip(Icons.check_circle_outline,
                        "Pass: ${a.marksConfig.passingPercentage.toStringAsFixed(0)}%"),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    key: Key('start_assessment_button_${a.assessmentId}'),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text("Start Assessment"),
                    onPressed: () => _startAssessment(a),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompletedResultsTab(ThemeData theme, ColorScheme colorScheme) {
    if (_learnerResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_edu_outlined,
                  size: 64, color: colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                "No Examination Results Yet",
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Complete an assessment to view score analysis and review explanations.",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _learnerResults.length,
      itemBuilder: (context, index) {
        final res = _learnerResults[index];
        final passed = res.isPassed;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Icon(
              passed ? Icons.check_circle : Icons.cancel,
              color: passed ? Colors.green : Colors.red,
              size: 32,
            ),
            title: Text("Assessment: ${res.assessmentId}"),
            subtitle: Text(
                "Score: ${res.score}/${res.maxScore} (${res.percentage.toStringAsFixed(1)}%) • Correct: ${res.correctCount}/${res.attemptedCount}"),
            trailing: Chip(
              label: Text(passed ? "PASSED" : "FAILED",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: passed
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
            ),
            onTap: () => _showResultDetailsDialog(res),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Active Test-Taking View
  // ---------------------------------------------------------------------------

  Future<void> _startAssessment(Assessment a) async {
    try {
      final attempt = await _service.startAttempt(
        assessmentId: a.assessmentId,
        learnerId: _currentLearnerId,
      );

      final questions = <IQuestionEntity>[];
      for (final qId in a.questionIds) {
        final q = _service.questionProvider.getQuestionById(qId);
        if (q != null) questions.add(q);
      }

      setState(() {
        _activeAssessment = a;
        _activeAttempt = attempt;
        _activeQuestions = questions;
        _activeQuestionIndex = 0;
      });

      if (a.timingConfig.durationMinutes != null) {
        final dur = Duration(minutes: a.timingConfig.durationMinutes!);
        final elapsed = DateTime.now().toUtc().difference(attempt.startedAt);
        final remaining = dur - elapsed;
        _remainingDuration = remaining.isNegative ? Duration.zero : remaining;

        _countdownTimer?.cancel();
        _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) return;
          setState(() {
            if (_remainingDuration != null &&
                _remainingDuration!.inSeconds > 0) {
              _remainingDuration =
                  _remainingDuration! - const Duration(seconds: 1);
            } else {
              _countdownTimer?.cancel();
              _submitAttempt();
            }
          });
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Cannot start attempt: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildActiveExamView(ThemeData theme, ColorScheme colorScheme) {
    final a = _activeAssessment!;
    final attempt = _activeAttempt!;
    final totalQ = _activeQuestions.length;
    final currentQ = totalQ > 0 ? _activeQuestions[_activeQuestionIndex] : null;

    final selectedAnswer =
        currentQ != null ? attempt.responses[currentQ.id] : null;

    final timerString = _remainingDuration != null
        ? "${_remainingDuration!.inMinutes}:${(_remainingDuration!.inSeconds % 60).toString().padLeft(2, '0')}"
        : null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _confirmExitExam();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(a.title),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _confirmExitExam,
          ),
          actions: [
            if (timerString != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, size: 16, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(
                      timerString,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        body: currentQ == null
            ? const Center(child: Text("No questions loaded"))
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Question ${_activeQuestionIndex + 1} of $totalQ",
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Answered: ${attempt.answeredCount}/$totalQ",
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value:
                          totalQ > 0 ? (_activeQuestionIndex + 1) / totalQ : 0,
                    ),
                    const SizedBox(height: 16),

                    // Question Card
                    Expanded(
                      child: Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentQ.prompt,
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 8),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: currentQ.options.length,
                                  itemBuilder: (ctx, i) {
                                    final opt = currentQ.options[i];
                                    final isSelected = selectedAnswer == opt;
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      elevation: 0,
                                      color: isSelected
                                          ? colorScheme.primaryContainer
                                              .withValues(alpha: 0.3)
                                          : colorScheme.surface,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: BorderSide(
                                          color: isSelected
                                              ? colorScheme.primary
                                              : Colors.grey.shade300,
                                        ),
                                      ),
                                      child: ListTile(
                                        key: Key('option_${currentQ.id}_$opt'),
                                        leading: Icon(
                                          isSelected
                                              ? Icons.radio_button_checked
                                              : Icons.radio_button_unchecked,
                                          color: isSelected
                                              ? colorScheme.primary
                                              : Colors.grey,
                                        ),
                                        title: Text(opt),
                                        onTap: () {
                                          _recordAnswer(currentQ.id, opt);
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Navigation & Submit
                    Row(
                      children: [
                        if (_activeQuestionIndex > 0)
                          OutlinedButton.icon(
                            key: const Key('prev_question_button'),
                            icon: const Icon(Icons.arrow_back),
                            label: const Text("Previous"),
                            onPressed: () {
                              setState(() => _activeQuestionIndex--);
                            },
                          ),
                        const Spacer(),
                        if (_activeQuestionIndex < totalQ - 1)
                          FilledButton.icon(
                            key: const Key('next_question_button'),
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text("Next"),
                            onPressed: () {
                              setState(() => _activeQuestionIndex++);
                            },
                          )
                        else
                          FilledButton.icon(
                            key: const Key('submit_assessment_button'),
                            icon: const Icon(Icons.check),
                            label: const Text("Submit Exam"),
                            onPressed: _confirmSubmit,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _recordAnswer(String questionId, String answer) async {
    final att = _activeAttempt;
    if (att == null) return;
    try {
      final updated = await _service.recordAnswer(
        attemptId: att.attemptId,
        learnerId: _currentLearnerId,
        questionId: questionId,
        answer: answer,
      );
      setState(() {
        _activeAttempt = updated;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving answer: $e')),
        );
      }
    }
  }

  void _confirmSubmit() {
    final answered = _activeAttempt?.answeredCount ?? 0;
    final total = _activeQuestions.length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Submit Assessment?"),
        content: Text(
            "You have answered $answered of $total questions. Once submitted, your answers cannot be modified."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          FilledButton(
            key: const Key('confirm_submit_button'),
            onPressed: () {
              Navigator.pop(ctx);
              _submitAttempt();
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  void _confirmExitExam() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Leave Assessment?"),
        content: const Text(
            "Your attempt is still in progress. You can resume it before the time expires."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Continue Exam"),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _countdownTimer?.cancel();
              setState(() {
                _activeAssessment = null;
                _activeAttempt = null;
              });
              _loadData();
            },
            child: const Text("Exit"),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAttempt() async {
    final att = _activeAttempt;
    if (att == null) return;
    _countdownTimer?.cancel();

    try {
      final result = await _service.submitAttempt(
        attemptId: att.attemptId,
        learnerId: _currentLearnerId,
      );

      setState(() {
        _activeAssessment = null;
        _activeAttempt = null;
      });

      _loadData();

      if (mounted) {
        _showResultDetailsDialog(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Submission error: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showResultDetailsDialog(AssessmentResult res) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  res.isPassed ? Icons.check_circle : Icons.cancel,
                  color: res.isPassed ? Colors.green : Colors.red,
                  size: 36,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        res.isPassed
                            ? "Assessment Passed!"
                            : "Assessment Failed",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Score: ${res.score}/${res.maxScore} (${res.percentage.toStringAsFixed(1)}%)",
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _statCard("Correct", "${res.correctCount}", Colors.green),
                const SizedBox(width: 8),
                _statCard("Incorrect", "${res.incorrectCount}", Colors.red),
                const SizedBox(width: 8),
                _statCard("Unanswered", "${res.unansweredCount}", Colors.grey),
              ],
            ),
            const SizedBox(height: 16),
            const Text("Question Breakdown:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: res.questionResults.length,
              itemBuilder: (c, i) {
                final qr = res.questionResults[i];
                return ListTile(
                  dense: true,
                  leading: Icon(
                    qr.isCorrect ? Icons.check : Icons.close,
                    color: qr.isCorrect ? Colors.green : Colors.red,
                  ),
                  title: Text("Question ${i + 1} (${qr.questionId})"),
                  subtitle: Text(
                      "Your Answer: ${qr.submittedAnswer ?? '(None)'} | Expected: ${qr.expectedAnswer}\nMarks: ${qr.marksAwarded}"),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  key: const Key('view_in_gradebook_button'),
                  icon: const Icon(Icons.table_chart_outlined),
                  label: const Text("View in Official Gradebook"),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GradebookPage(
                          initialCohortId: _selectedCohortId,
                          initialFacultyId: _currentFacultyId,
                          initialLearnerId: _currentLearnerId,
                          initialIsFaculty: _isFacultyMode,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Close"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
