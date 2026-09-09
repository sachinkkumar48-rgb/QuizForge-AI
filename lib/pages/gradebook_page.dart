import 'package:flutter/material.dart';
import 'package:garuda_learning/garuda_learning.dart';

import '../core/di/service_locator_init.dart';
import 'academic_credentials_page.dart';

/// Faculty Gradebook, Grade Publishing, and Grade Dispute/Override Portal (TITAN-KO-050.0 P50).
///
/// Supports two operational perspectives:
/// 1. Faculty Perspective:
///    - Comprehensive cohort grade matrix (Learners x Assessments).
///    - Summary statistics: pass rate, average score, grade distributions (A, B, C, D, F).
///    - Granular publication controls: single-entry, assessment-wide, and cohort-wide.
///    - Grade override workflow: mandatory rationale, actor identity, and audit logging.
///    - Grade dispute resolution queue: review, accept with override, or reject with reason.
///    - Full compliance audit trail.
///
/// 2. Learner Perspective:
///    - Official published grades view (unpublished results strictly hidden).
///    - Final scores, percentages, and letter grades according to institutional grading policy.
///    - Formal grade dispute submission with required justification.
///    - Real-time dispute tracking (open, under_review, resolved, rejected).
class GradebookPage extends StatefulWidget {
  final GradebookService? gradebookService;
  final AssessmentManagementService? assessmentService;
  final String initialFacultyId;
  final String initialLearnerId;
  final String? initialCohortId;
  final bool initialIsFaculty;

  const GradebookPage({
    super.key,
    this.gradebookService,
    this.assessmentService,
    this.initialFacultyId = 'faculty_admin',
    this.initialLearnerId = 'default_learner',
    this.initialCohortId,
    this.initialIsFaculty = true,
  });

  static GradebookService? _sharedDefaultService;
  static GradebookService get sharedService =>
      _sharedDefaultService ??= GradebookService(
        repository: InMemoryGradebookRepository(),
      );

  @override
  State<GradebookPage> createState() => _GradebookPageState();
}

class _GradebookPageState extends State<GradebookPage>
    with SingleTickerProviderStateMixin {
  late final GradebookService _gradebookService;
  late bool _isFacultyMode;
  late String _currentFacultyId;
  late String _currentLearnerId;
  late String _selectedCohortId;

  bool _isLoading = true;
  String? _errorMessage;
  TabController? _facultyTabController;

  CohortGradebook? _cohortGradebook;
  List<GradeDispute> _disputes = [];
  List<GradeAuditRecord> _auditRecords = [];
  List<GradebookEntry> _learnerOfficialGrades = [];
  Map<String, GradeDispute> _learnerDisputesMap = {};

  @override
  void initState() {
    super.initState();
    _isFacultyMode = widget.initialIsFaculty;
    _currentFacultyId = widget.initialFacultyId;
    _currentLearnerId = widget.initialLearnerId;
    _selectedCohortId = widget.initialCohortId ?? 'cohort_default';

    _facultyTabController = TabController(length: 3, vsync: this);

    try {
      _gradebookService = widget.gradebookService ?? locate<GradebookService>();
    } catch (_) {
      _gradebookService =
          widget.gradebookService ?? GradebookPage.sharedService;
    }

    _loadData();
  }

  @override
  void dispose() {
    _facultyTabController?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isFacultyMode) {
        _cohortGradebook = await _gradebookService.getCohortGradebook(
          _selectedCohortId,
          facultyId: _currentFacultyId,
        );
        _disputes = await _gradebookService.getDisputesForCohort(
          _selectedCohortId,
          facultyId: _currentFacultyId,
        );
        _auditRecords = await _gradebookService.getAuditTrailForCohort(
          _selectedCohortId,
          facultyId: _currentFacultyId,
        );
      } else {
        _learnerOfficialGrades =
            await _gradebookService.getOfficialGradesForLearner(
          _currentLearnerId,
          cohortId: _selectedCohortId,
        );

        final disputes = await _gradebookService.getDisputesForLearner(
          _currentLearnerId,
        );
        _learnerDisputesMap = {
          for (final d in disputes) d.assessmentId: d,
        };
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

    return Scaffold(
      key: const Key('gradebook_page_scaffold'),
      appBar: AppBar(
        title: Text(
          _isFacultyMode
              ? "Faculty Gradebook & Publishing"
              : "My Official Grades",
          style: const TextStyle(fontWeight: FontWeight.bold),
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
            key: const Key('open_credentials_button'),
            icon: const Icon(Icons.workspace_premium_outlined),
            tooltip: "Transcripts & Certificates",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AcademicCredentialsPage(
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
            tooltip: "Refresh Gradebook",
            onPressed: _loadData,
          ),
        ],
        bottom: _isFacultyMode
            ? TabBar(
                controller: _facultyTabController,
                tabs: [
                  const Tab(
                    key: Key('gradebook_matrix_tab'),
                    icon: Icon(Icons.table_chart_outlined),
                    text: "Grade Matrix",
                  ),
                  Tab(
                    key: const Key('disputes_tab_button'),
                    icon: Badge(
                      isLabelVisible: _disputes
                          .any((d) => d.status == GradeDisputeStatus.open),
                      label: Text(
                          '${_disputes.where((d) => d.status == GradeDisputeStatus.open).length}'),
                      child: const Icon(Icons.gavel_outlined),
                    ),
                    text: "Disputes",
                  ),
                  const Tab(
                    key: Key('audit_trail_tab'),
                    icon: Icon(Icons.history_edu_outlined),
                    text: "Audit Trail",
                  ),
                ],
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView(theme)
              : _isFacultyMode
                  ? _buildFacultyView(theme, colorScheme)
                  : _buildLearnerView(theme, colorScheme),
    );
  }

  Widget _buildErrorView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text("Error loading gradebook data",
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(_errorMessage ?? '',
                style: const TextStyle(color: Colors.black54),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Faculty View & Tabs
  // ---------------------------------------------------------------------------

  Widget _buildFacultyView(ThemeData theme, ColorScheme colorScheme) {
    return TabBarView(
      controller: _facultyTabController,
      children: [
        _buildMatrixTab(theme, colorScheme),
        _buildDisputesTab(theme, colorScheme),
        _buildAuditTab(theme, colorScheme),
      ],
    );
  }

  Widget _buildMatrixTab(ThemeData theme, ColorScheme colorScheme) {
    final gradebook = _cohortGradebook;
    if (gradebook == null || gradebook.enrolledLearners.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.table_chart_outlined,
                  size: 64, color: colorScheme.outline),
              const SizedBox(height: 16),
              Text("No Gradebook Entries",
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                "Once learners complete assessment attempts and evaluations finish, marks appear here.",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final summary = gradebook.summary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cohort Summary KPI Cards
          Row(
            children: [
              _kpiCard(
                "Enrolled Learners",
                "${summary.enrolledLearnersCount}",
                Icons.people,
                Colors.indigo,
              ),
              const SizedBox(width: 8),
              _kpiCard(
                "Assessments",
                "${gradebook.assessments.length}",
                Icons.assignment,
                Colors.blue,
              ),
              const SizedBox(width: 8),
              _kpiCard(
                "Pass Rate",
                "${summary.passRatePercentage.toStringAsFixed(1)}%",
                Icons.check_circle_outline,
                summary.passRatePercentage >= 50.0
                    ? Colors.green
                    : Colors.orange,
              ),
              const SizedBox(width: 8),
              _kpiCard(
                "Average Score",
                "${summary.averageScorePercentage.toStringAsFixed(1)}%",
                Icons.analytics_outlined,
                Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Grade Distribution & Cohort Publish Actions
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        const Text("Grade Distribution: ",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        ...summary.gradeDistribution.entries.map((e) => Chip(
                              label: Text("${e.key}: ${e.value}"),
                              visualDensity: VisualDensity.compact,
                            )),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    key: const Key('publish_all_button'),
                    icon: const Icon(Icons.publish),
                    label: const Text("Publish All Cohort Grades"),
                    onPressed: _confirmPublishAllCohortGrades,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Assessment columns banner & actions
          Wrap(
            spacing: 8,
            children: gradebook.assessments.map((a) {
              return ActionChip(
                key: Key('publish_assessment_button_${a.assessmentId}'),
                avatar: const Icon(Icons.publish, size: 16),
                label: Text("Publish ${a.title}"),
                onPressed: () =>
                    _confirmPublishAssessment(a.assessmentId, a.title),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Matrix Data Table
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                ),
                columns: [
                  const DataColumn(
                      label: Text("Learner ID",
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  const DataColumn(
                      label: Text("Overall %",
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  const DataColumn(
                      label: Text("Status",
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  ...gradebook.assessments.map(
                    (a) => DataColumn(
                      label: Text(
                        a.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
                rows: gradebook.enrolledLearners.map((learnerId) {
                  final learnerRow = gradebook.learnerSummaries[learnerId];
                  return DataRow(
                    cells: [
                      DataCell(Text(learnerId,
                          style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(learnerRow != null
                          ? "${learnerRow.averagePercentage.toStringAsFixed(1)}%"
                          : "-")),
                      DataCell(
                        Chip(
                          label: Text(
                              learnerRow?.isPassing == true ? "PASS" : "FAIL"),
                          backgroundColor: learnerRow?.isPassing == true
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      ...gradebook.assessments.map((a) {
                        final entry =
                            gradebook.matrix[learnerId]?[a.assessmentId];
                        return DataCell(
                            _buildMatrixCell(entry, learnerId, a.assessmentId));
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixCell(
    GradebookEntry? entry,
    String learnerId,
    String assessmentId,
  ) {
    if (entry == null) {
      return const Text("-", style: TextStyle(color: Colors.black26));
    }

    final isPublished = entry.isPublished;
    final isOverridden = entry.isOverridden;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "${(entry.finalScore ?? 0.0).toStringAsFixed(1)} / ${entry.maxScore.toStringAsFixed(0)}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isOverridden ? Colors.deepPurple : Colors.black87,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: entry.isPassed
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    entry.letterGrade ?? '-',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color:
                          entry.isPassed ? Colors.green[800] : Colors.red[800],
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  isPublished ? "PUBLISHED" : "UNPUBLISHED",
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isPublished ? Colors.green : Colors.orange,
                  ),
                ),
                if (isOverridden) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.edit_note,
                      size: 12, color: Colors.deepPurple),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 16),
          onSelected: (val) {
            if (val == 'publish') {
              _publishSingleEntry(entry.entryId);
            } else if (val == 'override') {
              _showOverrideDialog(entry);
            }
          },
          itemBuilder: (ctx) => [
            if (!isPublished)
              PopupMenuItem(
                key: Key('publish_entry_button_${learnerId}_$assessmentId'),
                value: 'publish',
                child: const Row(
                  children: [
                    Icon(Icons.publish, size: 16, color: Colors.green),
                    SizedBox(width: 8),
                    Text("Publish"),
                  ],
                ),
              ),
            PopupMenuItem(
              key: Key('override_button_${learnerId}_$assessmentId'),
              value: 'override',
              child: const Row(
                children: [
                  Icon(Icons.edit, size: 16, color: Colors.deepPurple),
                  SizedBox(width: 8),
                  Text("Override Grade"),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Disputes Tab
  // ---------------------------------------------------------------------------

  Widget _buildDisputesTab(ThemeData theme, ColorScheme colorScheme) {
    if (_disputes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.gavel_outlined, size: 64, color: colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                "No Grade Disputes",
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "When learners contest published marks, formal dispute tickets will appear here for review.",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _disputes.length,
      itemBuilder: (context, index) {
        final dispute = _disputes[index];
        final statusColor = switch (dispute.status) {
          GradeDisputeStatus.open => Colors.orange,
          GradeDisputeStatus.underReview => Colors.blue,
          GradeDisputeStatus.resolved => Colors.green,
          GradeDisputeStatus.rejected => Colors.red,
        };

        return Card(
          key: Key('dispute_item_${dispute.disputeId}'),
          margin: const EdgeInsets.only(bottom: 12),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Dispute: ${dispute.assessmentId}",
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                              "Learner: ${dispute.learnerId} • Entry: ${dispute.entryId}",
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text(
                        dispute.status.name.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      backgroundColor: statusColor.withValues(alpha: 0.1),
                      side: BorderSide(color: statusColor),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Learner Justification:",
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: colorScheme.primary),
                ),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 4, bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(dispute.reason),
                ),
                if (dispute.resolutionNotes != null) ...[
                  Text(
                    "Faculty Resolution Notes:",
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.secondary),
                  ),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 4, bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(dispute.resolutionNotes!),
                  ),
                ],
                if (dispute.status == GradeDisputeStatus.open ||
                    dispute.status == GradeDisputeStatus.underReview) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (dispute.status == GradeDisputeStatus.open)
                          OutlinedButton(
                            onPressed: () => _markDisputeUnderReview(dispute),
                            child: const Text("Mark Under Review"),
                          ),
                        OutlinedButton(
                          key:
                              Key('reject_dispute_button_${dispute.disputeId}'),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red),
                          onPressed: () => _showRejectDisputeDialog(dispute),
                          child: const Text("Reject Dispute"),
                        ),
                        FilledButton.icon(
                          key: Key(
                              'resolve_dispute_button_${dispute.disputeId}'),
                          icon: const Icon(Icons.check),
                          label: const Text("Accept & Override"),
                          onPressed: () =>
                              _showResolveWithOverrideDialog(dispute),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Audit Trail Tab
  // ---------------------------------------------------------------------------

  Widget _buildAuditTab(ThemeData theme, ColorScheme colorScheme) {
    if (_auditRecords.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_edu_outlined,
                  size: 64, color: colorScheme.outline),
              const SizedBox(height: 16),
              Text("Audit Trail Empty",
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                "All grade publications, overrides, and dispute resolutions will generate tamper-evident audit records here.",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _auditRecords.length,
      itemBuilder: (context, index) {
        final audit = _auditRecords[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  _auditActionColor(audit.action).withValues(alpha: 0.1),
              child: Icon(_auditActionIcon(audit.action),
                  color: _auditActionColor(audit.action)),
            ),
            title: Text(
              "${audit.action.name.toUpperCase()} • ${audit.entryId}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            subtitle: Text(
              "Actor: ${audit.performedBy} • Reason: ${audit.reason}\n${audit.timestamp.toIso8601String()}",
              style: const TextStyle(fontSize: 11),
            ),
          ),
        );
      },
    );
  }

  IconData _auditActionIcon(GradeAuditAction action) {
    return switch (action) {
      GradeAuditAction.created => Icons.add_circle_outline,
      GradeAuditAction.published ||
      GradeAuditAction.gradePublished ||
      GradeAuditAction.bulkPublished =>
        Icons.publish,
      GradeAuditAction.unpublished ||
      GradeAuditAction.gradeUnpublished =>
        Icons.unpublished_outlined,
      GradeAuditAction.overridden ||
      GradeAuditAction.gradeOverridden =>
        Icons.edit_note,
      GradeAuditAction.disputed ||
      GradeAuditAction.disputeOpened ||
      GradeAuditAction.disputeUnderReview =>
        Icons.gavel,
      GradeAuditAction.disputeResolved => Icons.done_all,
      GradeAuditAction.disputeRejected => Icons.cancel,
    };
  }

  Color _auditActionColor(GradeAuditAction action) {
    return switch (action) {
      GradeAuditAction.created => Colors.blue,
      GradeAuditAction.published ||
      GradeAuditAction.gradePublished ||
      GradeAuditAction.bulkPublished =>
        Colors.green,
      GradeAuditAction.unpublished ||
      GradeAuditAction.gradeUnpublished =>
        Colors.orange,
      GradeAuditAction.overridden ||
      GradeAuditAction.gradeOverridden =>
        Colors.deepPurple,
      GradeAuditAction.disputed ||
      GradeAuditAction.disputeOpened ||
      GradeAuditAction.disputeUnderReview =>
        Colors.amber[800]!,
      GradeAuditAction.disputeResolved => Colors.teal,
      GradeAuditAction.disputeRejected => Colors.red,
    };
  }

  // ---------------------------------------------------------------------------
  // Learner View
  // ---------------------------------------------------------------------------

  Widget _buildLearnerView(ThemeData theme, ColorScheme colorScheme) {
    if (_learnerOfficialGrades.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.workspace_premium_outlined,
                  size: 64, color: colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                "No Official Published Grades",
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Grades are officially published by your faculty after quality review. Completed evaluations awaiting publication will appear here once released.",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _learnerOfficialGrades.length,
      itemBuilder: (context, index) {
        final entry = _learnerOfficialGrades[index];
        final passed = entry.isPassed;
        final existingDispute = _learnerDisputesMap[entry.assessmentId];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: passed
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      child: Icon(
                        passed ? Icons.check_circle : Icons.cancel,
                        color: passed ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Assessment: ${entry.assessmentId}",
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text("Cohort: ${entry.cohortId}",
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text(
                        entry.letterGrade ?? '-',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: passed ? Colors.green[800] : Colors.red[800],
                        ),
                      ),
                      backgroundColor: passed
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _learnerMetric(
                      "Official Score",
                      "${(entry.finalScore ?? 0.0).toStringAsFixed(1)} / ${entry.maxScore.toStringAsFixed(0)}",
                      colorScheme.primary,
                    ),
                    _learnerMetric(
                      "Percentage",
                      "${(entry.finalPercentage ?? 0.0).toStringAsFixed(1)}%",
                      passed ? Colors.green : Colors.red,
                    ),
                    _learnerMetric(
                      "Result",
                      passed ? "PASSED" : "FAILED",
                      passed ? Colors.green : Colors.red,
                    ),
                  ],
                ),
                if (entry.isOverridden) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 14, color: Colors.deepPurple),
                        const SizedBox(width: 6),
                        Text(
                          "Grade updated by faculty override (Original: ${(entry.originalScore ?? 0.0).toStringAsFixed(1)})",
                          style: const TextStyle(
                              fontSize: 11, color: Colors.deepPurple),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (existingDispute != null)
                      Chip(
                        avatar: const Icon(Icons.gavel, size: 14),
                        label: Text(
                            "Dispute: ${existingDispute.status.name.toUpperCase()}"),
                        backgroundColor: Colors.amber.withValues(alpha: 0.1),
                      )
                    else
                      const SizedBox.shrink(),
                    if (existingDispute == null)
                      FilledButton.tonalIcon(
                        key: Key('dispute_button_${entry.assessmentId}'),
                        icon: const Icon(Icons.help_outline, size: 16),
                        label: const Text("Dispute Grade"),
                        onPressed: () => _showSubmitDisputeDialog(entry),
                      )
                    else if (existingDispute.status ==
                        GradeDisputeStatus.resolved)
                      const Text("Resolved with revision",
                          style: TextStyle(color: Colors.green, fontSize: 12))
                    else if (existingDispute.status ==
                        GradeDisputeStatus.rejected)
                      const Text("Dispute rejected",
                          style: TextStyle(color: Colors.red, fontSize: 12))
                    else
                      const Text("Under faculty review",
                          style: TextStyle(color: Colors.orange, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _learnerMetric(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.black54)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Faculty Operational Actions
  // ---------------------------------------------------------------------------

  Future<void> _publishSingleEntry(String entryId) async {
    try {
      await _gradebookService.publishGrade(
        entryId,
        facultyId: _currentFacultyId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Grade published successfully")),
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Publication failed: $e"),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmPublishAssessment(
      String assessmentId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Publish All: $title"),
        content: const Text(
          "This will officially release grades for all evaluated learners for this assessment. Learners will immediately see their final marks.",
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          FilledButton(
            key: const Key('confirm_publish_assessment_button'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Publish Now"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final count = await _gradebookService.publishAssessmentGrades(
          _selectedCohortId,
          assessmentId,
          facultyId: _currentFacultyId,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Published $count grades for $title")),
          );
        }
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Bulk publish error: $e"),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _confirmPublishAllCohortGrades() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Publish All Cohort Grades"),
        content: const Text(
          "Are you sure you want to publish ALL evaluated assessment grades across this entire cohort? All learners will see their official results.",
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          FilledButton(
            key: const Key('confirm_publish_all_button'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Publish All"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final count = await _gradebookService.publishCohortGrades(
          _selectedCohortId,
          facultyId: _currentFacultyId,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Successfully published $count cohort grades")),
          );
        }
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Publish failed: $e"),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showOverrideDialog(GradebookEntry entry) {
    final scoreCtrl = TextEditingController(text: entry.finalScore.toString());
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Override Grade: ${entry.learnerId}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Original Score: ${entry.originalScore} / ${entry.maxScore}"),
            const SizedBox(height: 12),
            TextField(
              key: const Key('override_score_field'),
              controller: scoreCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "New Final Score",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('override_reason_field'),
              controller: reasonCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: "Mandatory Rationale",
                hintText: "State academic justification for score adjustment",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          FilledButton(
            key: const Key('confirm_override_button'),
            onPressed: () async {
              final newScore = double.tryParse(scoreCtrl.text.trim());
              final reason = reasonCtrl.text.trim();

              if (newScore == null || reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Score and reason are required")),
                );
                return;
              }

              Navigator.pop(ctx);
              try {
                await _gradebookService.applyGradeOverride(
                  entry.entryId,
                  newScore: newScore,
                  reason: reason,
                  facultyId: _currentFacultyId,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Grade override applied successfully")),
                  );
                }
                _loadData();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text("Override failed: $e"),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text("Apply Override"),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dispute Resolution Actions
  // ---------------------------------------------------------------------------

  Future<void> _markDisputeUnderReview(GradeDispute dispute) async {
    try {
      await _gradebookService.reviewDispute(
        dispute.disputeId,
        facultyId: _currentFacultyId,
      );
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Review action failed: $e"),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showResolveWithOverrideDialog(GradeDispute dispute) {
    final scoreCtrl = TextEditingController();
    final reasonCtrl = TextEditingController(
        text: "Correction based on learner dispute review");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Resolve Dispute with Override"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('dispute_resolution_score_field'),
              controller: scoreCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "New Adjusted Score",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('dispute_resolution_reason_field'),
              controller: reasonCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: "Resolution Rationale",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          FilledButton(
            key: const Key('confirm_resolve_dispute_button'),
            onPressed: () async {
              final newScore = double.tryParse(scoreCtrl.text.trim());
              final reason = reasonCtrl.text.trim();
              if (newScore == null || reason.isEmpty) return;

              Navigator.pop(ctx);
              try {
                await _gradebookService.resolveDisputeWithOverride(
                  dispute.disputeId,
                  newScore: newScore,
                  rationale: reason,
                  facultyId: _currentFacultyId,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Dispute resolved with grade override")),
                  );
                }
                _loadData();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text("Resolution failed: $e"),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text("Resolve & Apply"),
          ),
        ],
      ),
    );
  }

  void _showRejectDisputeDialog(GradeDispute dispute) {
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reject Dispute"),
        content: TextField(
          key: const Key('dispute_rejection_reason_field'),
          controller: reasonCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: "Mandatory Rejection Rationale",
            hintText: "Explain why the original evaluation stands",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          FilledButton(
            key: const Key('confirm_reject_dispute_button'),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final reason = reasonCtrl.text.trim();
              if (reason.isEmpty) return;

              Navigator.pop(ctx);
              try {
                await _gradebookService.rejectDispute(
                  dispute.disputeId,
                  rationale: reason,
                  facultyId: _currentFacultyId,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Dispute rejected")),
                  );
                }
                _loadData();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text("Rejection failed: $e"),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text("Reject Dispute"),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Learner Dispute Submission
  // ---------------------------------------------------------------------------

  void _showSubmitDisputeDialog(GradebookEntry entry) {
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Dispute Official Grade"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Assessment: ${entry.assessmentId}"),
            Text(
                "Current Grade: ${entry.finalScore}/${entry.maxScore} (${entry.letterGrade})"),
            const SizedBox(height: 12),
            TextField(
              key: const Key('dispute_reason_field'),
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Reason for Dispute",
                hintText:
                    "Provide specific details on question or marking discrepancies",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          FilledButton(
            key: const Key('submit_dispute_button'),
            onPressed: () async {
              final reason = reasonCtrl.text.trim();
              if (reason.isEmpty) return;

              Navigator.pop(ctx);
              try {
                await _gradebookService.createDispute(
                  learnerId: _currentLearnerId,
                  entryId: entry.entryId,
                  assessmentId: entry.assessmentId,
                  reason: reason,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Dispute ticket submitted to faculty")),
                  );
                }
                _loadData();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text("Dispute failed: $e"),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text("Submit Dispute"),
          ),
        ],
      ),
    );
  }
}
