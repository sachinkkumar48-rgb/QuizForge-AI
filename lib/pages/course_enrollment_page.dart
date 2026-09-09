import 'package:flutter/material.dart';
import 'package:garuda_learning/garuda_learning.dart';

import 'academic_credentials_page.dart';
import 'attendance_management_page.dart';
import 'cohort_management_page.dart';
import 'content_learning_path_page.dart';

/// Institutional Course Registration & Learner Enrollment Management Portal (TITAN-KO-052.0 P52).
///
/// Multi-persona portal providing:
/// 1. Learner Perspective ("My Courses"):
///    - Enrolled courses list, lifecycle status badges (ACTIVE, PENDING, SUSPENDED, WITHDRAWN, COMPLETED).
///    - Access control indicator (Full, Read-Only, Blocked).
///    - Course launch into learning pathways with real-time access gating.
/// 2. Faculty / Administrative Perspective:
///    - Course catalog & cohort enrollment matrix.
///    - Eligibility & prerequisite checks.
///    - Strict state transitions: Activate, Suspend, Reactivate, Withdraw, Cancel, Complete.
///    - Mandatory justification prompts for suspension, withdrawal, and cancellation.
///    - Resilient bulk cohort enrollment with individual success/failure reporting.
///    - Immutable lifecycle audit trail inspection.
class CourseEnrollmentPage extends StatefulWidget {
  final EnrollmentService? enrollmentService;
  final CohortAssignmentService? cohortService;
  final String initialFacultyId;
  final String initialLearnerId;
  final String? initialCohortId;
  final String? initialCourseId;
  final bool initialIsFaculty;

  const CourseEnrollmentPage({
    super.key,
    this.enrollmentService,
    this.cohortService,
    this.initialFacultyId = 'faculty_admin',
    this.initialLearnerId = 'default_learner',
    this.initialCohortId,
    this.initialCourseId,
    this.initialIsFaculty = true,
  });

  static EnrollmentService? _sharedDefaultService;
  static EnrollmentService get sharedService =>
      _sharedDefaultService ??= EnrollmentService(
        enrollmentRepository: InMemoryEnrollmentRepository(),
        cohortRepository: InMemoryCohortRepository(),
      );

  @override
  State<CourseEnrollmentPage> createState() => _CourseEnrollmentPageState();
}

class _CourseEnrollmentPageState extends State<CourseEnrollmentPage>
    with SingleTickerProviderStateMixin {
  late final EnrollmentService _enrollmentService;
  late final CohortAssignmentService _cohortService;

  late bool _isFacultyMode;
  late String _currentFacultyId;
  late String _currentLearnerId;
  String? _selectedCourseId;
  String? _selectedCohortId;

  bool _isLoading = true;
  String? _statusMessage;
  TabController? _tabController;

  // Faculty state
  List<Course> _allCourses = [];
  List<Cohort> _availableCohorts = [];
  List<Enrollment> _courseEnrollments = [];
  List<EnrollmentAuditRecord> _selectedAuditTrail = [];

  // Learner state
  List<Enrollment> _learnerEnrollments = [];
  Map<String, CourseAccessDecision> _accessDecisions = {};

  @override
  void initState() {
    super.initState();
    _isFacultyMode = widget.initialIsFaculty;
    _currentFacultyId = widget.initialFacultyId;
    _currentLearnerId = widget.initialLearnerId;
    _selectedCourseId = widget.initialCourseId;
    _selectedCohortId = widget.initialCohortId;

    _tabController = TabController(length: 3, vsync: this);

    _enrollmentService =
        widget.enrollmentService ?? CourseEnrollmentPage.sharedService;
    _cohortService = widget.cohortService ??
        CohortAssignmentService(
          cohortRepository: InMemoryCohortRepository(),
        );

    _loadData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Ensure seed courses exist if repo is empty
      final existingCourses = await _enrollmentService.listCourses();
      if (existingCourses.isEmpty) {
        await _seedInitialCourses();
      }

      _allCourses = await _enrollmentService.listCourses();
      if (_allCourses.isNotEmpty && _selectedCourseId == null) {
        _selectedCourseId = _allCourses.first.courseId;
      }

      if (_isFacultyMode) {
        _availableCohorts =
            await _cohortService.listCohorts(status: CohortStatus.active);
        if (_availableCohorts.isNotEmpty && _selectedCohortId == null) {
          _selectedCohortId = _availableCohorts.first.cohortId;
        }

        if (_selectedCourseId != null) {
          _courseEnrollments = await _enrollmentService.getCourseEnrollments(
            courseId: _selectedCourseId!,
          );
        }
      } else {
        _learnerEnrollments = await _enrollmentService.getLearnerEnrollments(
          learnerId: _currentLearnerId,
        );
        final decisions = <String, CourseAccessDecision>{};
        for (final enr in _learnerEnrollments) {
          decisions[enr.courseId] = await _enrollmentService.checkCourseAccess(
            learnerId: _currentLearnerId,
            courseId: enr.courseId,
          );
        }
        _accessDecisions = decisions;
      }
    } catch (e) {
      _statusMessage = 'Error loading enrollment data: $e';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _seedInitialCourses() async {
    await _enrollmentService.createCourse(
      courseId: 'course_const_law_101',
      title: 'Constitutional Law & Governance Foundations',
      description:
          'Foundational principles of fundamental rights, judicial review, and federal structure.',
      examId: 'clat_pg_2026',
      facultyId: _currentFacultyId,
      estimatedHours: 45,
    );

    await _enrollmentService.createCourse(
      courseId: 'course_adv_const_law_201',
      title: 'Advanced Constitutional Jurisprudence & Writs',
      description:
          'Comparative constitutional doctrines and landmark supreme court precedents.',
      examId: 'clat_pg_2026',
      facultyId: _currentFacultyId,
      prerequisiteCourseIds: ['course_const_law_101'],
      estimatedHours: 60,
    );

    await _enrollmentService.createCourse(
      courseId: 'course_upsc_gs1_polity',
      title: 'UPSC GS1: Indian Polity & Governance',
      description:
          'Comprehensive static syllabus for UPSC Civil Services preliminary examination.',
      examId: 'upsc_prelims_gs1',
      facultyId: _currentFacultyId,
      estimatedHours: 80,
    );
  }

  // ---------------------------------------------------------------------------
  // Action Handlers
  // ---------------------------------------------------------------------------

  Future<void> _handleRegisterLearner() async {
    final learnerController = TextEditingController();
    String? selectedCourse = _selectedCourseId;
    String? selectedCohort;
    bool autoActivate = true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Enroll Learner in Course'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  key: const Key('enroll_learner_id_input'),
                  controller: learnerController,
                  decoration: const InputDecoration(
                    labelText: 'Learner ID',
                    hintText: 'e.g. learner_001',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: const Key('enroll_course_dropdown'),
                  value: selectedCourse,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Target Course',
                    border: OutlineInputBorder(),
                  ),
                  items: _allCourses.map((c) {
                    return DropdownMenuItem(
                      value: c.courseId,
                      child: Text(
                        c.title,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setDlgState(() => selectedCourse = val),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCohort,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Cohort (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('(None)')),
                    ..._availableCohorts.map((c) {
                      return DropdownMenuItem(
                        value: c.cohortId,
                        child: Text(c.name),
                      );
                    }),
                  ],
                  onChanged: (val) => setDlgState(() => selectedCohort = val),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Auto-Activate Enrollment'),
                  subtitle:
                      const Text('Active immediately without pending review'),
                  value: autoActivate,
                  onChanged: (val) => setDlgState(() => autoActivate = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              key: const Key('confirm_enroll_button'),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enroll'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true &&
        learnerController.text.trim().isNotEmpty &&
        selectedCourse != null) {
      try {
        await _enrollmentService.registerLearner(
          learnerId: learnerController.text.trim(),
          courseId: selectedCourse!,
          cohortId: selectedCohort,
          actorId: _currentFacultyId,
          actorRole: 'faculty',
          autoActivate: autoActivate,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Learner "${learnerController.text.trim()}" enrolled successfully.'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadData();
      } catch (e) {
        _showErrorDialog('Enrollment Failed', e.toString());
      }
    }
  }

  Future<void> _handleBulkEnroll() async {
    if (_availableCohorts.isEmpty) {
      _showErrorDialog('No Cohorts Available',
          'Please create an institutional cohort first.');
      return;
    }

    String? targetCourse = _selectedCourseId;
    String? targetCohort =
        _selectedCohortId ?? _availableCohorts.first.cohortId;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Bulk Enroll Institutional Cohort'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                key: const Key('bulk_course_dropdown'),
                value: targetCourse,
                decoration: const InputDecoration(
                  labelText: 'Target Course',
                  border: OutlineInputBorder(),
                ),
                items: _allCourses.map((c) {
                  return DropdownMenuItem(
                    value: c.courseId,
                    child: Text(c.title, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) => setDlgState(() => targetCourse = val),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: const Key('bulk_cohort_dropdown'),
                value: targetCohort,
                decoration: const InputDecoration(
                  labelText: 'Source Cohort',
                  border: OutlineInputBorder(),
                ),
                items: _availableCohorts.map((c) {
                  return DropdownMenuItem(
                    value: c.cohortId,
                    child: Text('${c.name} (${c.learnerIds.length} learners)'),
                  );
                }).toList(),
                onChanged: (val) => setDlgState(() => targetCohort = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              key: const Key('confirm_bulk_enroll_button'),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Execute Bulk Enrollment'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && targetCourse != null && targetCohort != null) {
      try {
        final result = await _enrollmentService.bulkEnrollCohort(
          courseId: targetCourse!,
          cohortId: targetCohort!,
          actorId: _currentFacultyId,
          actorRole: 'faculty',
          autoActivate: true,
        );

        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(result.isFullSuccess
                  ? 'Bulk Enrollment Complete'
                  : 'Bulk Enrollment Summary'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Attempted: ${result.totalAttempted}'),
                  Text('Successfully Enrolled: ${result.successCount}',
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold)),
                  if (result.hasFailures) ...[
                    const SizedBox(height: 8),
                    Text('Failed Enrollments: ${result.failureCount}',
                        style: const TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Failure Details:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(
                      height: 120,
                      child: ListView(
                        children: result.failedLearnerIds.entries.map((e) {
                          return ListTile(
                            dense: true,
                            title: Text(e.key),
                            subtitle: Text(e.value,
                                style: const TextStyle(color: Colors.red)),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          );
        }
        _loadData();
      } catch (e) {
        _showErrorDialog('Bulk Enrollment Error', e.toString());
      }
    }
  }

  Future<void> _handleLifecycleTransition({
    required Enrollment enrollment,
    required String action,
  }) async {
    final reasonController = TextEditingController();
    bool requiresReason =
        action == 'suspend' || action == 'withdraw' || action == 'cancel';

    if (requiresReason) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
              '${action.toUpperCase()} Enrollment: ${enrollment.learnerId}'),
          content: TextField(
            key: const Key('transition_reason_input'),
            controller: reasonController,
            decoration: InputDecoration(
              labelText: 'Mandatory Justification / Reason',
              hintText:
                  'Provide regulatory or academic reason for this change...',
              border: const OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              key: const Key('confirm_transition_button'),
              onPressed: () {
                if (reasonController.text.trim().isNotEmpty) {
                  Navigator.pop(ctx, true);
                }
              },
              child: Text('Confirm ${action.toUpperCase()}'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    try {
      switch (action) {
        case 'activate':
          await _enrollmentService.activateEnrollment(
            enrollmentId: enrollment.enrollmentId,
            actorId: _currentFacultyId,
          );
          break;
        case 'suspend':
          await _enrollmentService.suspendEnrollment(
            enrollmentId: enrollment.enrollmentId,
            actorId: _currentFacultyId,
            reason: reasonController.text.trim(),
          );
          break;
        case 'reactivate':
          await _enrollmentService.reactivateEnrollment(
            enrollmentId: enrollment.enrollmentId,
            actorId: _currentFacultyId,
          );
          break;
        case 'withdraw':
          await _enrollmentService.withdrawLearner(
            enrollmentId: enrollment.enrollmentId,
            actorId: _currentFacultyId,
            reason: reasonController.text.trim(),
          );
          break;
        case 'cancel':
          await _enrollmentService.cancelEnrollment(
            enrollmentId: enrollment.enrollmentId,
            actorId: _currentFacultyId,
            reason: reasonController.text.trim(),
          );
          break;
        case 'complete':
          await _enrollmentService.markCompletion(
            enrollmentId: enrollment.enrollmentId,
            actorId: _currentFacultyId,
          );
          break;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enrollment status updated to "$action" successfully.'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } catch (e) {
      _showErrorDialog('Transition Failed', e.toString());
    }
  }

  Future<void> _viewAuditTrail(Enrollment enrollment) async {
    final trail = await _enrollmentService.getAuditTrail(
      enrollmentId: enrollment.enrollmentId,
    );

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (ctx, scroll) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Audit Trail: ${enrollment.learnerId} (${enrollment.courseId})',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: trail.isEmpty
                    ? const Center(child: Text('No audit events recorded.'))
                    : ListView.separated(
                        controller: scroll,
                        itemCount: trail.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (_, idx) {
                          final record = trail[idx];
                          return ListTile(
                            leading: Icon(
                              _auditActionIcon(record.action),
                              color: _auditActionColor(record.action),
                            ),
                            title: Text(
                                '${record.action.name.toUpperCase()} by ${record.actorId}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (record.previousStatus != null)
                                  Text(
                                      '${record.previousStatus!.name} -> ${record.newStatus?.name ?? ""}'),
                                if (record.reason != null &&
                                    record.reason!.isNotEmpty)
                                  Text('Reason: ${record.reason}',
                                      style: const TextStyle(
                                          fontStyle: FontStyle.italic)),
                                Text(
                                    record.timestamp
                                        .toLocal()
                                        .toString()
                                        .split('.')
                                        .first,
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI Builders
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isFacultyMode
              ? 'Course Enrollment & Access Control'
              : 'My Enrolled Courses',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SegmentedButton<bool>(
              key: const Key('enrollment_faculty_toggle'),
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Faculty'),
                  icon: Icon(Icons.admin_panel_settings_outlined, size: 16),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Learner'),
                  icon: Icon(Icons.person_outline, size: 16),
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
            key: const Key('attendance_management_nav_button'),
            icon: const Icon(Icons.co_present_outlined),
            tooltip: 'Attendance & Engagement',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => AttendanceManagementPage(
                    attendanceService: AttendanceManagementPage.sharedService,
                    enrollmentService: _enrollmentService,
                    initialFacultyId: _currentFacultyId,
                    initialLearnerId: _currentLearnerId,
                    initialCourseId: _selectedCourseId,
                    initialCohortId: _selectedCohortId,
                    initialIsFaculty: _isFacultyMode,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
        bottom: _isFacultyMode
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(
                      icon: Icon(Icons.people_alt_outlined),
                      text: 'Enrollments'),
                  Tab(
                      icon: Icon(Icons.menu_book_outlined),
                      text: 'Course Catalog'),
                  Tab(icon: Icon(Icons.history), text: 'Audit Logs'),
                ],
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isFacultyMode
              ? _buildFacultyView()
              : _buildLearnerView(),
      floatingActionButton: _isFacultyMode
          ? FloatingActionButton.extended(
              key: const Key('enroll_learner_button'),
              onPressed: _handleRegisterLearner,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Enroll Learner'),
            )
          : null,
    );
  }

  Widget _buildLearnerView() {
    if (_learnerEnrollments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No course enrollments found for "$_currentLearnerId".',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                // Quick self-registration demo for first course
                if (_allCourses.isNotEmpty) {
                  try {
                    await _enrollmentService.registerLearner(
                      learnerId: _currentLearnerId,
                      courseId: _allCourses.first.courseId,
                      actorId: _currentLearnerId,
                      actorRole: 'learner',
                      autoActivate: true,
                    );
                    _loadData();
                  } catch (e) {
                    _showErrorDialog('Self-Enrollment Error', e.toString());
                  }
                }
              },
              child: const Text('Enroll in Constitutional Law 101'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      key: const Key('learner_courses_list'),
      padding: const EdgeInsets.all(16),
      itemCount: _learnerEnrollments.length,
      itemBuilder: (ctx, idx) {
        final enr = _learnerEnrollments[idx];
        final decision = _accessDecisions[enr.courseId];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
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
                        enr.courseTitle ?? enr.courseId,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    _statusChip(enr.status),
                  ],
                ),
                const SizedBox(height: 8),
                if (enr.cohortId != null)
                  Text('Cohort: ${enr.cohortId}',
                      style: const TextStyle(color: Colors.grey)),
                Text(
                    'Enrolled: ${enr.enrolledAt.toLocal().toString().split(' ').first}',
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                // Access Banner
                if (decision != null) _accessBanner(decision),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      key: Key('launch_course_${enr.courseId}'),
                      onPressed: decision != null && decision.isAllowed
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ContentLearningPathPage(
                                    learnerId: _currentLearnerId,
                                    enrollmentService: _enrollmentService,
                                    courseId: enr.courseId,
                                  ),
                                ),
                              );
                            }
                          : null,
                      icon: Icon(
                        decision?.accessType == CourseAccessType.readOnly
                            ? Icons.visibility
                            : Icons.play_arrow,
                      ),
                      label: Text(
                        decision?.accessType == CourseAccessType.readOnly
                            ? 'Review Past Materials'
                            : 'Enter Course',
                      ),
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

  Widget _buildFacultyView() {
    return TabBarView(
      controller: _tabController,
      children: [
        // Tab 1: Enrollments Management
        _buildEnrollmentsManagementTab(),
        // Tab 2: Course Catalog
        _buildCourseCatalogTab(),
        // Tab 3: System Audit Trail
        _buildSystemAuditTab(),
      ],
    );
  }

  Widget _buildEnrollmentsManagementTab() {
    return Column(
      children: [
        // Course and Cohort Selectors
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: const Key('course_selector'),
                  value: _selectedCourseId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Select Course',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _allCourses.map((c) {
                    return DropdownMenuItem(
                      value: c.courseId,
                      child: Text(c.title, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedCourseId = val);
                    _loadData();
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                key: const Key('bulk_enroll_button'),
                onPressed: _handleBulkEnroll,
                icon: const Icon(Icons.group_add),
                label: const Text('Bulk Enroll Cohort'),
              ),
            ],
          ),
        ),
        // Enrolled learners list
        Expanded(
          child: _courseEnrollments.isEmpty
              ? Center(
                  child: Text(
                    'No learners enrolled in course "$_selectedCourseId".',
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _courseEnrollments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) {
                    final enr = _courseEnrollments[idx];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.person,
                                        color: Colors.blueGrey),
                                    const SizedBox(width: 8),
                                    Text(
                                      enr.learnerId,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                _statusChip(enr.status),
                              ],
                            ),
                            if (enr.cohortId != null) ...[
                              const SizedBox(height: 4),
                              Text('Cohort: ${enr.cohortId}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ],
                            if (enr.statusReason != null) ...[
                              const SizedBox(height: 4),
                              Text('Reason: ${enr.statusReason}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic)),
                            ],
                            const SizedBox(height: 8),
                            // Action buttons per status
                            Wrap(
                              spacing: 8,
                              children: [
                                if (enr.status == EnrollmentStatus.pending) ...[
                                  OutlinedButton(
                                    key: Key('activate_${enr.learnerId}'),
                                    onPressed: () => _handleLifecycleTransition(
                                      enrollment: enr,
                                      action: 'activate',
                                    ),
                                    child: const Text('Activate'),
                                  ),
                                  OutlinedButton(
                                    key: Key('cancel_${enr.learnerId}'),
                                    onPressed: () => _handleLifecycleTransition(
                                      enrollment: enr,
                                      action: 'cancel',
                                    ),
                                    child: const Text('Cancel'),
                                  ),
                                ],
                                if (enr.status == EnrollmentStatus.active) ...[
                                  OutlinedButton(
                                    key: Key('complete_${enr.learnerId}'),
                                    onPressed: () => _handleLifecycleTransition(
                                      enrollment: enr,
                                      action: 'complete',
                                    ),
                                    child: const Text('Mark Complete'),
                                  ),
                                  OutlinedButton(
                                    key: Key('suspend_${enr.learnerId}'),
                                    onPressed: () => _handleLifecycleTransition(
                                      enrollment: enr,
                                      action: 'suspend',
                                    ),
                                    child: const Text('Suspend'),
                                  ),
                                  OutlinedButton(
                                    key: Key('withdraw_${enr.learnerId}'),
                                    onPressed: () => _handleLifecycleTransition(
                                      enrollment: enr,
                                      action: 'withdraw',
                                    ),
                                    child: const Text('Withdraw'),
                                  ),
                                ],
                                if (enr.status ==
                                    EnrollmentStatus.suspended) ...[
                                  OutlinedButton(
                                    key: Key('reactivate_${enr.learnerId}'),
                                    onPressed: () => _handleLifecycleTransition(
                                      enrollment: enr,
                                      action: 'reactivate',
                                    ),
                                    child: const Text('Reactivate'),
                                  ),
                                  OutlinedButton(
                                    key: Key('withdraw_${enr.learnerId}'),
                                    onPressed: () => _handleLifecycleTransition(
                                      enrollment: enr,
                                      action: 'withdraw',
                                    ),
                                    child: const Text('Withdraw'),
                                  ),
                                ],
                                TextButton.icon(
                                  key: Key('audit_${enr.learnerId}'),
                                  onPressed: () => _viewAuditTrail(enr),
                                  icon:
                                      const Icon(Icons.receipt_long, size: 16),
                                  label: const Text('Audit Trail'),
                                ),
                              ],
                            ),
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

  Widget _buildCourseCatalogTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allCourses.length,
      itemBuilder: (ctx, idx) {
        final course = _allCourses[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(course.title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.description),
                const SizedBox(height: 4),
                Text(
                    'Exam Context: ${course.examId} | Hours: ${course.estimatedHours}h',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                if (course.prerequisiteCourseIds.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                      'Prerequisites: ${course.prerequisiteCourseIds.join(", ")}',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.blueGrey)),
                ],
              ],
            ),
            trailing: course.isActive
                ? const Chip(
                    label: Text('ACTIVE'), backgroundColor: Colors.greenAccent)
                : const Chip(
                    label: Text('ARCHIVED'), backgroundColor: Colors.grey),
          ),
        );
      },
    );
  }

  Widget _buildSystemAuditTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user_outlined,
                size: 48, color: Colors.blueGrey),
            const SizedBox(height: 12),
            const Text(
              'Audit Trail Inspection',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select any enrolled learner in the "Enrollments" tab to review their complete, immutable lifecycle transition log.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helper Widgets
  // ---------------------------------------------------------------------------

  Widget _statusChip(EnrollmentStatus status) {
    Color bg;
    Color fg = Colors.white;
    switch (status) {
      case EnrollmentStatus.active:
        bg = Colors.green;
        break;
      case EnrollmentStatus.pending:
        bg = Colors.orange;
        break;
      case EnrollmentStatus.completed:
        bg = Colors.blue;
        break;
      case EnrollmentStatus.suspended:
        bg = Colors.deepOrange;
        break;
      case EnrollmentStatus.withdrawn:
        bg = Colors.blueGrey;
        break;
      case EnrollmentStatus.cancelled:
        bg = Colors.red;
        break;
    }
    return Chip(
      label: Text(status.name.toUpperCase(),
          style:
              TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 11)),
      backgroundColor: bg,
      padding: EdgeInsets.zero,
    );
  }

  Widget _accessBanner(CourseAccessDecision decision) {
    Color bg;
    IconData icon;
    String title;
    switch (decision.accessType) {
      case CourseAccessType.full:
        bg = Colors.green.shade50;
        icon = Icons.check_circle_outline;
        title = 'Full Course Access Active';
        break;
      case CourseAccessType.readOnly:
        bg = Colors.blue.shade50;
        icon = Icons.visibility_outlined;
        title = 'Read-Only Historical Review';
        break;
      case CourseAccessType.blocked:
        bg = Colors.red.shade50;
        icon = Icons.lock_outline;
        title = 'Access Blocked: ${decision.reason ?? "Course unavailable"}';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  IconData _auditActionIcon(EnrollmentAuditAction action) {
    switch (action) {
      case EnrollmentAuditAction.created:
        return Icons.add_circle_outline;
      case EnrollmentAuditAction.activated:
        return Icons.check_circle_outline;
      case EnrollmentAuditAction.suspended:
        return Icons.pause_circle_outline;
      case EnrollmentAuditAction.reactivated:
        return Icons.play_circle_outline;
      case EnrollmentAuditAction.withdrawn:
        return Icons.exit_to_app;
      case EnrollmentAuditAction.cancelled:
        return Icons.cancel_outlined;
      case EnrollmentAuditAction.completed:
        return Icons.school;
      case EnrollmentAuditAction.bulkEnrolled:
        return Icons.groups_outlined;
    }
  }

  Color _auditActionColor(EnrollmentAuditAction action) {
    switch (action) {
      case EnrollmentAuditAction.created:
      case EnrollmentAuditAction.activated:
      case EnrollmentAuditAction.reactivated:
        return Colors.green;
      case EnrollmentAuditAction.suspended:
        return Colors.deepOrange;
      case EnrollmentAuditAction.withdrawn:
      case EnrollmentAuditAction.cancelled:
        return Colors.red;
      case EnrollmentAuditAction.completed:
        return Colors.blue;
      case EnrollmentAuditAction.bulkEnrolled:
        return Colors.teal;
    }
  }
}
