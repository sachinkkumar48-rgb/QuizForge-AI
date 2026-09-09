import 'package:flutter/material.dart';
import 'package:garuda_learning/garuda_learning.dart';

import '../core/di/service_locator_init.dart';
import 'adaptive_practice_page.dart';
import 'assessment_management_page.dart';
import 'gradebook_page.dart';
import 'academic_credentials_page.dart';
import 'attendance_management_page.dart';
import 'course_enrollment_page.dart';

/// Institutional Cohort Management & Assignment Distribution Portal (TITAN-KO-048.0 P48).
///
/// Supports two real operational perspectives:
/// 1. Faculty Dashboard: Cohort overview, assignment authoring/distribution, compliance monitoring,
///    and weak-area analytics drilldown.
/// 2. Learner View: "My Cohorts" & "My Assignments" tracking upcoming deadlines, completion status,
///    and launching active practice drills.
class CohortManagementPage extends StatefulWidget {
  final CohortAssignmentService? cohortService;
  final String initialFacultyId;
  final String initialLearnerId;
  final bool initialIsFaculty;

  const CohortManagementPage({
    super.key,
    this.cohortService,
    this.initialFacultyId = 'faculty_admin',
    this.initialLearnerId = 'default_learner',
    this.initialIsFaculty = true,
  });

  @override
  State<CohortManagementPage> createState() => _CohortManagementPageState();
}

class _CohortManagementPageState extends State<CohortManagementPage>
    with SingleTickerProviderStateMixin {
  late final CohortAssignmentService _service;
  late bool _isFacultyMode;
  late String _currentFacultyId;
  late String _currentLearnerId;

  List<Cohort> _cohorts = [];
  Cohort? _selectedCohort;
  CohortSummary? _cohortSummary;
  List<CohortAssignment> _assignments = [];
  List<CohortAssignment> _learnerAssignments = [];
  Map<String, CohortLearnerProgress> _learnerProgressMap = {};

  bool _isLoading = true;
  String? _statusMessage;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _isFacultyMode = widget.initialIsFaculty;
    _currentFacultyId = widget.initialFacultyId;
    _currentLearnerId = widget.initialLearnerId;

    _tabController = TabController(length: 4, vsync: this);

    try {
      _service = widget.cohortService ?? locate<CohortAssignmentService>();
    } catch (_) {
      _service = CohortAssignmentService(
        cohortRepository: InMemoryCohortRepository(),
      );
    }

    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      if (_isFacultyMode) {
        var cohorts = await _service.getCohortsForFaculty(_currentFacultyId);
        if (cohorts.isEmpty) {
          // If no cohorts exist for this faculty, list all active cohorts
          cohorts = await _service.listCohorts(status: CohortStatus.active);
        }

        _cohorts = cohorts;
        if (_cohorts.isNotEmpty) {
          _selectedCohort = _cohorts.firstWhere(
            (c) => c.cohortId == _selectedCohort?.cohortId,
            orElse: () => _cohorts.first,
          );
          _cohortSummary =
              await _service.computeCohortSummary(_selectedCohort!.cohortId);
          _assignments =
              await _service.getAssignmentsForCohort(_selectedCohort!.cohortId);
        } else {
          _selectedCohort = null;
          _cohortSummary = null;
          _assignments = [];
        }
      } else {
        // Learner Mode
        _cohorts = await _service.getCohortsForLearner(_currentLearnerId);
        _learnerAssignments =
            await _service.getAssignmentsForLearner(_currentLearnerId);

        _learnerProgressMap.clear();
        for (final a in _learnerAssignments) {
          try {
            final prog = await _service.getLearnerAssignmentProgress(
              a.assignmentId,
              _currentLearnerId,
            );
            _learnerProgressMap[a.assignmentId] = prog;
          } catch (_) {}
        }
      }
    } catch (e) {
      _statusMessage = 'Error loading data: $e';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isFacultyMode
              ? "Institutional Cohort Dashboard"
              : "My Cohorts & Assignments",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
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
            key: const Key('cohort_assessments_button'),
            icon: const Icon(Icons.assignment_turned_in_outlined),
            tooltip: "Cohort Assessments",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AssessmentManagementPage(
                    initialCohortId: _selectedCohort?.cohortId,
                    initialIsFaculty: _isFacultyMode,
                  ),
                ),
              );
            },
          ),
          IconButton(
            key: const Key('cohort_gradebook_button'),
            icon: const Icon(Icons.table_chart_outlined),
            tooltip: "Cohort Gradebook",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GradebookPage(
                    initialCohortId: _selectedCohort?.cohortId,
                    initialFacultyId: _currentFacultyId,
                    initialLearnerId: _currentLearnerId,
                    initialIsFaculty: _isFacultyMode,
                  ),
                ),
              );
            },
          ),
          IconButton(
            key: const Key('cohort_credentials_button'),
            icon: const Icon(Icons.workspace_premium_outlined),
            tooltip: "Transcripts & Certificates",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AcademicCredentialsPage(
                    initialCohortId: _selectedCohort?.cohortId,
                    initialFacultyId: _currentFacultyId,
                  ),
                ),
              );
            },
          ),
          IconButton(
            key: const Key('cohort_enrollment_button'),
            icon: const Icon(Icons.how_to_reg_outlined),
            tooltip: "Course Enrollment",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CourseEnrollmentPage(
                    initialCohortId: _selectedCohort?.cohortId,
                    initialFacultyId: _currentFacultyId,
                    initialLearnerId: _currentLearnerId,
                    initialIsFaculty: _isFacultyMode,
                  ),
                ),
              );
            },
          ),
          IconButton(
            key: const Key('cohort_attendance_button'),
            icon: const Icon(Icons.co_present_outlined),
            tooltip: "Attendance & Monitoring",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AttendanceManagementPage(
                    initialCohortId: _selectedCohort?.cohortId,
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
        bottom: _isFacultyMode && _selectedCohort != null
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(icon: Icon(Icons.assignment), text: "Assignments"),
                  Tab(icon: Icon(Icons.group), text: "Members"),
                  Tab(
                      icon: Icon(Icons.check_circle_outline),
                      text: "Compliance"),
                  Tab(icon: Icon(Icons.analytics_outlined), text: "Analytics"),
                ],
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isFacultyMode
              ? _buildFacultyView(theme, colorScheme)
              : _buildLearnerView(theme, colorScheme),
      floatingActionButton: _isFacultyMode && _selectedCohort != null
          ? FloatingActionButton.extended(
              onPressed: _showCreateAssignmentDialog,
              icon: const Icon(Icons.add_task),
              label: const Text("New Assignment"),
            )
          : null,
    );
  }

  // ---------------------------------------------------------------------------
  // Faculty View
  // ---------------------------------------------------------------------------

  Widget _buildFacultyView(ThemeData theme, ColorScheme colorScheme) {
    if (_cohorts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.groups_outlined, size: 64, color: colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                "No Institutional Cohorts Found",
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Create a student batch or class cohort to distribute assignments and track compliance.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _showCreateCohortDialog,
                icon: const Icon(Icons.add),
                label: const Text("Create First Cohort"),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Cohort Selector Bar & Quick Stats
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          child: Row(
            children: [
              const Icon(Icons.class_outlined, size: 20),
              const SizedBox(width: 8),
              Text(
                "Active Cohort:",
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedCohort?.cohortId,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: _cohorts.map((c) {
                    return DropdownMenuItem(
                      value: c.cohortId,
                      child: Text(
                        "${c.name} (${c.learnerCount} learners)",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                  onChanged: (newId) {
                    if (newId != null) {
                      setState(() {
                        _selectedCohort =
                            _cohorts.firstWhere((c) => c.cohortId == newId);
                      });
                      _loadData();
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: "New Cohort",
                onPressed: _showCreateCohortDialog,
              ),
            ],
          ),
        ),

        // Summary Metric Cards
        if (_cohortSummary != null) _buildCohortMetricCards(theme, colorScheme),

        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAssignmentsTab(theme, colorScheme),
              _buildMembersTab(theme, colorScheme),
              _buildComplianceTab(theme, colorScheme),
              _buildAnalyticsTab(theme, colorScheme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCohortMetricCards(ThemeData theme, ColorScheme colorScheme) {
    final s = _cohortSummary!;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _metricCard(
              "Learners", "${s.totalLearners}", Icons.people, Colors.blue),
          const SizedBox(width: 8),
          _metricCard(
              "Active", "${s.activeLearners}", Icons.trending_up, Colors.teal),
          const SizedBox(width: 8),
          _metricCard(
              "Completion",
              "${(s.completionRate * 100).toStringAsFixed(1)}%",
              Icons.check_circle,
              Colors.green),
          const SizedBox(width: 8),
          _metricCard(
              "Overdue", "${s.overdueCount}", Icons.warning_amber, Colors.red),
        ],
      ),
    );
  }

  Widget _metricCard(
      String label, String value, IconData icon, MaterialColor color) {
    return Expanded(
      child: Card(
        elevation: 0,
        color: color.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color.shade700),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color.shade900,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 10, color: color.shade700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tabs: Assignments, Members, Compliance, Analytics
  // ---------------------------------------------------------------------------

  Widget _buildAssignmentsTab(ThemeData theme, ColorScheme colorScheme) {
    if (_assignments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined,
                size: 48, color: colorScheme.outline),
            const SizedBox(height: 12),
            const Text("No assignments created for this cohort yet."),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _showCreateAssignmentDialog,
              child: const Text("Create Assignment"),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _assignments.length,
      itemBuilder: (ctx, idx) {
        final a = _assignments[idx];
        final isPublished = a.status == CohortAssignmentStatus.published;
        final isClosed = a.status == CohortAssignmentStatus.closed;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        a.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _statusBadge(a.status),
                  ],
                ),
                if (a.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(a.description,
                      style: TextStyle(
                          fontSize: 12, color: colorScheme.onSurfaceVariant)),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.track_changes,
                        size: 14, color: colorScheme.primary),
                    const SizedBox(width: 4),
                    Text("Target: ${a.targetId}",
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Icon(Icons.event, size: 14, color: colorScheme.outline),
                    const SizedBox(width: 4),
                    Text(
                      "Due: ${a.dueDate.toLocal().toString().split('.').first}",
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!isPublished && !isClosed)
                      FilledButton.icon(
                        icon: const Icon(Icons.publish, size: 14),
                        label: const Text("Publish"),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                        ),
                        onPressed: () async {
                          await _service.publishAssignment(
                            a.assignmentId,
                            facultyId: _currentFacultyId,
                          );
                          _loadData();
                        },
                      ),
                    if (isPublished) ...[
                      OutlinedButton.icon(
                        icon: const Icon(Icons.lock_outline, size: 14),
                        label: const Text("Close"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                        ),
                        onPressed: () async {
                          await _service.closeAssignment(
                            a.assignmentId,
                            facultyId: _currentFacultyId,
                          );
                          _loadData();
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMembersTab(ThemeData theme, ColorScheme colorScheme) {
    final learners = _selectedCohort?.learnerIds.toList() ?? [];
    learners.sort();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Enrolled Learners (${learners.length})",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.person_add, size: 16),
                label: const Text("Add Learner"),
                onPressed: _showAddLearnerDialog,
              ),
            ],
          ),
        ),
        Expanded(
          child: learners.isEmpty
              ? const Center(child: Text("No learners enrolled yet."))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: learners.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, idx) {
                    final lid = learners[idx];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(lid.characters.first.toUpperCase()),
                      ),
                      title: Text(lid,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text("Status: Active"),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.red),
                        tooltip: "Remove from cohort",
                        onPressed: () async {
                          await _service.removeLearner(
                            _selectedCohort!.cohortId,
                            lid,
                            requesterId: _currentFacultyId,
                          );
                          _loadData();
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildComplianceTab(ThemeData theme, ColorScheme colorScheme) {
    if (_cohortSummary == null || _cohortSummary!.assignmentSummaries.isEmpty) {
      return const Center(child: Text("No assignment compliance data yet."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _cohortSummary!.assignmentSummaries.length,
      itemBuilder: (ctx, idx) {
        final summary = _cohortSummary!.assignmentSummaries[idx];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      summary.assignment.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${summary.completedCount}/${summary.totalAssigned} Completed (${(summary.completionRate * 100).toStringAsFixed(1)}%)",
                      style: TextStyle(
                          fontSize: 12,
                          color: summary.completionRate >= 0.7
                              ? Colors.green
                              : Colors.orange),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: summary.completionRate,
                  backgroundColor: Colors.grey.shade200,
                  color: Colors.green,
                ),
                const SizedBox(height: 10),
                // Learner compliance table
                ...summary.learnerProgressList.map((lp) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(lp.learnerId,
                            style: const TextStyle(fontSize: 13)),
                        _learnerStatusBadge(lp.status),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsTab(ThemeData theme, ColorScheme colorScheme) {
    final s = _cohortSummary;
    if (s == null) {
      return const Center(child: Text("No analytics available."));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Cohort Weak Spots & Remediation",
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (s.weakAreas.isEmpty)
            const Text("No critical weak areas identified across this cohort.")
          else ...[
            const Text(
              "The following learning objectives show low accuracy or high non-compliance:",
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            ...s.weakAreas.map((w) {
              return Card(
                color: Colors.amber.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.amber.shade300),
                ),
                child: ListTile(
                  leading: const Icon(Icons.warning, color: Colors.amber),
                  title: Text(w,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text(
                      "Remediation Recommended: Assign targeted diagnostic or remedial practice drill."),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Learner View
  // ---------------------------------------------------------------------------

  Widget _buildLearnerView(ThemeData theme, ColorScheme colorScheme) {
    if (_learnerAssignments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.task_alt, size: 64, color: colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                "No Assignments Due",
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "You are all caught up on assignments for your enrolled cohorts!",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _learnerAssignments.length,
      itemBuilder: (ctx, idx) {
        final a = _learnerAssignments[idx];
        final prog = _learnerProgressMap[a.assignmentId];
        final status = prog?.status ?? CohortLearnerProgressStatus.notStarted;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        a.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _learnerStatusBadge(status),
                  ],
                ),
                if (a.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(a.description,
                      style: TextStyle(
                          fontSize: 13, color: colorScheme.onSurfaceVariant)),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.track_changes,
                        size: 14, color: colorScheme.primary),
                    const SizedBox(width: 4),
                    Text("Target: ${a.targetId}",
                        style: const TextStyle(fontSize: 12)),
                    const Spacer(),
                    Icon(Icons.event, size: 14, color: colorScheme.outline),
                    const SizedBox(width: 4),
                    Text(
                      "Due: ${a.dueDate.toLocal().toString().split('.').first}",
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      prog != null
                          ? "Attempts: ${prog.attempts} | Acc: ${(prog.accuracy * 100).toStringAsFixed(1)}%"
                          : "Not started",
                      style: TextStyle(
                          fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                    FilledButton.icon(
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: Text(
                          status == CohortLearnerProgressStatus.completed
                              ? "Practice Again"
                              : "Start Assignment"),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdaptivePracticePage(
                              targetTopic: a.targetId,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Dialogs: Create Cohort, Add Learner, Create Assignment
  // ---------------------------------------------------------------------------

  void _showCreateCohortDialog() {
    final idCtrl = TextEditingController(
        text: 'cohort_upsc_${DateTime.now().millisecondsSinceEpoch % 1000}');
    final nameCtrl = TextEditingController(text: 'UPSC 2026 Batch A');
    final descCtrl =
        TextEditingController(text: 'Prelims 2026 General Studies Batch');

    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text("Create New Cohort"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: idCtrl,
              decoration: const InputDecoration(labelText: "Cohort ID"),
            ),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Cohort Name"),
            ),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: "Description"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isNotEmpty) {
                await _service.createCohort(
                  cohortId: idCtrl.text.trim(),
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  examId: 'upsc_prelims_gs1',
                  primaryFacultyId: _currentFacultyId,
                );
                if (mounted) Navigator.pop(dCtx);
                _loadData();
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  void _showAddLearnerDialog() {
    final idCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text("Enroll Learner"),
        content: TextField(
          controller: idCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: "Learner ID",
            hintText: "e.g. learner_101",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () async {
              if (idCtrl.text.trim().isNotEmpty && _selectedCohort != null) {
                await _service.addLearner(
                  _selectedCohort!.cohortId,
                  idCtrl.text.trim(),
                  requesterId: _currentFacultyId,
                );
                if (mounted) Navigator.pop(dCtx);
                _loadData();
              }
            },
            child: const Text("Enroll"),
          ),
        ],
      ),
    );
  }

  void _showCreateAssignmentDialog() {
    final titleCtrl = TextEditingController(text: 'Fundamental Rights Drill');
    final targetCtrl = TextEditingController(text: 'pol_lo_art21');
    final descCtrl =
        TextEditingController(text: 'Complete mastery practice on Article 21.');

    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text("Create Cohort Assignment"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: "Title"),
              ),
              TextField(
                controller: targetCtrl,
                decoration: const InputDecoration(
                  labelText: "Target Objective / Topic",
                  hintText: "e.g. pol_lo_art21 or Fundamental Rights",
                ),
              ),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: "Instructions"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isNotEmpty &&
                  targetCtrl.text.trim().isNotEmpty &&
                  _selectedCohort != null) {
                await _service.createAssignment(
                  assignmentId:
                      'assign_${DateTime.now().millisecondsSinceEpoch % 10000}',
                  cohortId: _selectedCohort!.cohortId,
                  title: titleCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  targetId: targetCtrl.text.trim(),
                  assignedByFacultyId: _currentFacultyId,
                  dueDate: DateTime.now().toUtc().add(const Duration(days: 3)),
                  status: CohortAssignmentStatus.published,
                );
                if (mounted) Navigator.pop(dCtx);
                _loadData();
              }
            },
            child: const Text("Create & Publish"),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(CohortAssignmentStatus status) {
    final color = switch (status) {
      CohortAssignmentStatus.published => Colors.green,
      CohortAssignmentStatus.draft => Colors.orange,
      CohortAssignmentStatus.closed => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.name.toUpperCase(),
        style:
            TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _learnerStatusBadge(CohortLearnerProgressStatus status) {
    final (color, label) = switch (status) {
      CohortLearnerProgressStatus.completed => (Colors.green, "COMPLETED"),
      CohortLearnerProgressStatus.inProgress => (Colors.orange, "IN PROGRESS"),
      CohortLearnerProgressStatus.overdue => (Colors.red, "OVERDUE"),
      CohortLearnerProgressStatus.notStarted => (Colors.grey, "NOT STARTED"),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
