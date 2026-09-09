import 'package:flutter/material.dart';
import 'package:garuda_learning/garuda_learning.dart';

import 'course_enrollment_page.dart';

/// Institutional Attendance & Academic Engagement Management Portal (TITAN-KO-053.0 P53).
///
/// Multi-perspective portal delivering:
/// 1. Learner Perspective ("My Attendance"):
///    - Authoritative attendance percentage and policy threshold compliance (COMPLIANT vs AT RISK).
///    - Deterministic breakdown: Present, Late (weighted 0.5), Absent, Excused (excluded from denom).
///    - Attendance history timeline with verified dates, statuses, and faculty remarks.
/// 2. Faculty / Administrative Perspective:
///    - Course session lifecycle: Schedule -> Open -> Record -> Finalize -> Lockout.
///    - Enrolled active roster gating (strictly excludes withdrawn/cancelled learners).
///    - Fast roster marking sheet with duplicate protection and in-place updates.
///    - Post-finalization authorized correction workflow requiring documented justification.
///    - Real-time early-warning Academic Monitoring & Intervention Signal desk:
///      Non-disciplinary alerts (low attendance, at-risk classification) with
///      acknowledgement and documented resolution workflows.
class AttendanceManagementPage extends StatefulWidget {
  final AttendanceService? attendanceService;
  final EnrollmentService? enrollmentService;
  final String initialFacultyId;
  final String initialLearnerId;
  final String? initialCourseId;
  final String? initialCohortId;
  final bool initialIsFaculty;

  const AttendanceManagementPage({
    super.key,
    this.attendanceService,
    this.enrollmentService,
    this.initialFacultyId = 'faculty_admin',
    this.initialLearnerId = 'default_learner',
    this.initialCourseId,
    this.initialCohortId,
    this.initialIsFaculty = true,
  });

  static AttendanceService? _sharedDefaultAttendanceService;
  static AttendanceService get sharedService {
    return _sharedDefaultAttendanceService ??= AttendanceService(
      attendanceRepository: InMemoryAttendanceRepository(),
      enrollmentRepository:
          CourseEnrollmentPage.sharedService.enrollmentRepository,
      cohortRepository: CourseEnrollmentPage.sharedService.cohortRepository,
    );
  }

  @override
  State<AttendanceManagementPage> createState() =>
      _AttendanceManagementPageState();
}

class _AttendanceManagementPageState extends State<AttendanceManagementPage>
    with SingleTickerProviderStateMixin {
  late final AttendanceService _attendanceService;
  late final EnrollmentService _enrollmentService;

  late bool _isFacultyMode;
  late String _currentFacultyId;
  late String _currentLearnerId;
  String? _selectedCourseId;

  bool _isLoading = true;
  String? _statusMessage;
  TabController? _tabController;

  // Faculty State
  List<Course> _allCourses = [];
  List<AttendanceSession> _sessions = [];
  List<AcademicInterventionSignal> _signals = [];

  // Learner State
  LearnerAttendanceSummary? _learnerSummary;
  List<Enrollment> _learnerEnrollments = [];

  @override
  void initState() {
    super.initState();
    _isFacultyMode = widget.initialIsFaculty;
    _currentFacultyId = widget.initialFacultyId;
    _currentLearnerId = widget.initialLearnerId;
    _selectedCourseId = widget.initialCourseId;

    _attendanceService =
        widget.attendanceService ?? AttendanceManagementPage.sharedService;
    _enrollmentService =
        widget.enrollmentService ?? CourseEnrollmentPage.sharedService;

    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      _allCourses = await _enrollmentService.listCourses();
      if (_allCourses.isEmpty) {
        await _seedInitialCourses();
        _allCourses = await _enrollmentService.listCourses();
      }

      if (_selectedCourseId == null ||
          !_allCourses.any((c) => c.courseId == _selectedCourseId)) {
        _selectedCourseId = _allCourses.first.courseId;
      }

      if (_isFacultyMode) {
        if (_selectedCourseId != null) {
          _sessions = await _attendanceService.listSessionsForCourse(
            courseId: _selectedCourseId!,
          );
          _signals = await _attendanceService.listSignals(
            courseId: _selectedCourseId!,
          );
        }
      } else {
        _learnerEnrollments = await _enrollmentService.getLearnerEnrollments(
          learnerId: _currentLearnerId,
        );
        if (_selectedCourseId != null) {
          try {
            _learnerSummary =
                await _attendanceService.getLearnerAttendanceSummary(
              learnerId: _currentLearnerId,
              courseId: _selectedCourseId!,
            );
          } catch (_) {
            _learnerSummary = null;
          }
        }
      }
    } catch (e) {
      _statusMessage = 'Error loading attendance data: $e';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _seedInitialCourses() async {
    await _enrollmentService.createCourse(
      courseId: 'course_const_law_101',
      title: 'Constitutional Law Foundations',
      description:
          'Core concepts of constitutional principles and fundamental rights.',
      examId: 'clat_pg_2026',
      facultyId: _currentFacultyId,
    );
  }

  // ---------------------------------------------------------------------------
  // Action Handlers
  // ---------------------------------------------------------------------------

  Future<void> _handleCreateSession() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime sessionDate = DateTime.now();
    int duration = 60;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Schedule Course Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('session_title_input'),
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Session Title / Topic',
                hintText: 'e.g. Lecture 4: Article 21 & Due Process',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description / Agenda (Optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('confirm_create_session_button'),
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Schedule'),
          ),
        ],
      ),
    );

    if (confirmed == true && _selectedCourseId != null) {
      try {
        await _attendanceService.createSession(
          courseId: _selectedCourseId!,
          title: titleController.text.trim(),
          description: descController.text.trim(),
          scheduledAt: sessionDate,
          durationMinutes: duration,
          facultyId: _currentFacultyId,
        );
        _loadData();
      } catch (e) {
        _showErrorDialog('Failed to Create Session', e.toString());
      }
    }
  }

  Future<void> _handleOpenSession(AttendanceSession session) async {
    try {
      await _attendanceService.openSession(
        sessionId: session.sessionId,
        actorId: _currentFacultyId,
      );
      _loadData();
    } catch (e) {
      _showErrorDialog('Error Opening Session', e.toString());
    }
  }

  Future<void> _handleCancelSession(AttendanceSession session) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cancel Session: ${session.title}'),
        content: TextField(
          key: const Key('cancel_session_reason_input'),
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Cancellation Reason',
            hintText: 'e.g. University Holiday, Faculty Sickness',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Back'),
          ),
          ElevatedButton(
            key: const Key('confirm_cancel_session_button'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Confirm Cancel',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _attendanceService.cancelSession(
          sessionId: session.sessionId,
          actorId: _currentFacultyId,
          reason: reasonController.text.trim(),
        );
        _loadData();
      } catch (e) {
        _showErrorDialog('Cancellation Failed', e.toString());
      }
    }
  }

  Future<void> _handleFinalizeSession(AttendanceSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finalize Attendance Session'),
        content: Text(
          'Finalizing locks attendance records for "${session.title}". '
          'Any subsequent edits will require a formal correction with documented justification.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('confirm_finalize_session_button'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Finalize & Lock'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _attendanceService.finalizeSession(
          sessionId: session.sessionId,
          actorId: _currentFacultyId,
        );
        _loadData();
      } catch (e) {
        _showErrorDialog('Finalization Failed', e.toString());
      }
    }
  }

  Future<void> _handleManageRoster(AttendanceSession session) async {
    final isClosed = session.isClosed;
    final roster = await _attendanceService.getEnrolledRoster(
      courseId: session.courseId,
      cohortId: session.cohortId,
    );

    final existingRecords =
        await _attendanceService.attendanceRepository.listAttendanceForSession(
      sessionId: session.sessionId,
    );
    final recordMap = {for (final r in existingRecords) r.learnerId: r};

    // Working copy of statuses
    final statusMap = <String, AttendanceStatus>{};
    final remarksMap = <String, String>{};
    for (final enr in roster) {
      statusMap[enr.learnerId] =
          recordMap[enr.learnerId]?.status ?? AttendanceStatus.present;
      remarksMap[enr.learnerId] = recordMap[enr.learnerId]?.remarks ?? '';
    }

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (ctx, scroll) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.title,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Course: ${session.courseId} • Status: ${session.status.name.toUpperCase()}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    if (isClosed)
                      Chip(
                        label: const Text('FINALIZED (LOCKED)'),
                        backgroundColor: Colors.grey.shade200,
                      ),
                  ],
                ),
                const Divider(),
                if (roster.isEmpty)
                  const Expanded(
                    child: Center(
                      child:
                          Text('No active enrolled learners in this course.'),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      controller: scroll,
                      itemCount: roster.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (ctx, idx) {
                        final learner = roster[idx];
                        final currentStatus = statusMap[learner.learnerId] ??
                            AttendanceStatus.present;
                        final rec = recordMap[learner.learnerId];

                        return ListTile(
                          title: Text(
                            learner.learnerId,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (rec != null && rec.corrections.isNotEmpty)
                                Text(
                                  'Corrected: ${rec.corrections.length} time(s)',
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.amber),
                                ),
                              if (isClosed)
                                Text(
                                  'Status: ${currentStatus.name.toUpperCase()}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                            ],
                          ),
                          trailing: isClosed
                              ? ElevatedButton.icon(
                                  key: Key(
                                      'correct_attendance_button_${learner.learnerId}'),
                                  icon: const Icon(Icons.edit_note, size: 16),
                                  label: const Text('Correct'),
                                  onPressed: () => _handleCorrectAttendance(
                                      rec, learner.learnerId),
                                )
                              : DropdownButton<AttendanceStatus>(
                                  key: Key(
                                      'status_dropdown_${learner.learnerId}'),
                                  value: currentStatus,
                                  items: AttendanceStatus.values.map((s) {
                                    return DropdownMenuItem(
                                      value: s,
                                      child: Text(s.name.toUpperCase()),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setSheetState(() {
                                        statusMap[learner.learnerId] = val;
                                      });
                                    }
                                  },
                                ),
                        );
                      },
                    ),
                  ),
                if (!isClosed && roster.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      key: const Key('save_roster_button'),
                      onPressed: () async {
                        try {
                          for (final entry in statusMap.entries) {
                            await _attendanceService.recordAttendance(
                              sessionId: session.sessionId,
                              learnerId: entry.key,
                              status: entry.value,
                              actorId: _currentFacultyId,
                              remarks: remarksMap[entry.key],
                            );
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                          _loadData();
                        } catch (e) {
                          _showErrorDialog(
                              'Error Saving Attendance', e.toString());
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Save Attendance Roster'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleCorrectAttendance(
      AttendanceRecord? record, String learnerId) async {
    if (record == null) {
      _showErrorDialog(
          'Correction Error', 'No existing record found to correct.');
      return;
    }

    final reasonController = TextEditingController();
    AttendanceStatus newStatus = record.status == AttendanceStatus.present
        ? AttendanceStatus.late
        : AttendanceStatus.present;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text('Correct Attendance: $learnerId'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current Status: ${record.status.name.toUpperCase()}'),
              const SizedBox(height: 12),
              DropdownButtonFormField<AttendanceStatus>(
                key: const Key('correction_status_dropdown'),
                initialValue: newStatus,
                decoration:
                    const InputDecoration(labelText: 'New Corrected Status'),
                items: AttendanceStatus.values.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(s.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (s) {
                  if (s != null) {
                    setDlgState(() => newStatus = s);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('correction_reason_input'),
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Mandatory Correction Justification',
                  hintText:
                      'e.g. Physical attendance sheet verifies on-time presence',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              key: const Key('confirm_correction_button'),
              onPressed: () {
                if (reasonController.text.trim().isNotEmpty) {
                  Navigator.pop(ctx, true);
                }
              },
              child: const Text('Submit Correction'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await _attendanceService.correctFinalizedAttendance(
          attendanceId: record.attendanceId,
          newStatus: newStatus,
          actorId: _currentFacultyId,
          reason: reasonController.text.trim(),
        );
        _loadData();
      } catch (e) {
        _showErrorDialog('Correction Failed', e.toString());
      }
    }
  }

  Future<void> _handleAcknowledgeSignal(
      AcademicInterventionSignal signal) async {
    try {
      await _attendanceService.acknowledgeSignal(
        signalId: signal.signalId,
        actorId: _currentFacultyId,
      );
      _loadData();
    } catch (e) {
      _showErrorDialog('Acknowledgement Failed', e.toString());
    }
  }

  Future<void> _handleResolveSignal(AcademicInterventionSignal signal) async {
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Resolve Intervention: ${signal.learnerId}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Alert: ${signal.description}'),
            const SizedBox(height: 12),
            TextField(
              key: const Key('signal_resolution_notes_input'),
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Documented Follow-up / Counseling Notes',
                hintText:
                    'e.g. Conducted academic counseling; student agreed to makeup assignments',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('confirm_resolve_signal_button'),
            onPressed: () {
              if (notesController.text.trim().isNotEmpty) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Resolve Alert'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _attendanceService.resolveSignal(
          signalId: signal.signalId,
          actorId: _currentFacultyId,
          notes: notesController.text.trim(),
        );
        _loadData();
      } catch (e) {
        _showErrorDialog('Resolution Failed', e.toString());
      }
    }
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
  // Build Methods
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isFacultyMode
              ? 'Faculty Attendance & Academic Monitoring'
              : 'My Academic Attendance',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SegmentedButton<bool>(
              key: const Key('attendance_faculty_toggle'),
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
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
        bottom: _isFacultyMode
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.event_note), text: 'Sessions & Roster'),
                  Tab(icon: Icon(Icons.insights), text: 'Academic Monitoring'),
                ],
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isFacultyMode
              ? _buildFacultyView()
              : _buildLearnerView(),
      floatingActionButton: _isFacultyMode && _tabController?.index == 0
          ? FloatingActionButton.extended(
              key: const Key('create_session_button'),
              onPressed: _handleCreateSession,
              icon: const Icon(Icons.add),
              label: const Text('New Session'),
            )
          : null,
    );
  }

  // ---------------------------------------------------------------------------
  // Faculty View
  // ---------------------------------------------------------------------------

  Widget _buildFacultyView() {
    return Column(
      children: [
        _buildCourseSelectorHeader(),
        if (_statusMessage != null)
          Container(
            color: Colors.amber.shade100,
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            child: Text(_statusMessage!,
                style: const TextStyle(color: Colors.brown)),
          ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSessionsTab(),
              _buildMonitoringTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCourseSelectorHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.3),
      child: Row(
        children: [
          const Icon(Icons.menu_book, size: 18),
          const SizedBox(width: 8),
          const Text('Active Course:',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedCourseId,
              items: _allCourses.map((c) {
                return DropdownMenuItem(
                  value: c.courseId,
                  child: Text('${c.title} (${c.courseId})',
                      overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (cid) {
                if (cid != null) {
                  setState(() => _selectedCourseId = cid);
                  _loadData();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsTab() {
    if (_sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No attendance sessions scheduled for this course.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _handleCreateSession,
              icon: const Icon(Icons.add),
              label: const Text('Schedule First Session'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _sessions.length,
      itemBuilder: (ctx, idx) {
        final sess = _sessions[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: sess.isClosed
                  ? Colors.grey.shade400
                  : sess.isOpen
                      ? Colors.green.shade400
                      : Colors.blue.shade200,
            ),
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
                        sess.title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    _buildSessionStatusBadge(sess.status),
                  ],
                ),
                if (sess.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    sess.description,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Scheduled: ${sess.scheduledAt.toLocal().toString().split('.').first}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const Spacer(),
                    Text(
                      '${sess.durationMinutes} min',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (sess.isScheduled) ...[
                      OutlinedButton.icon(
                        key: Key('cancel_session_button_${sess.sessionId}'),
                        icon: const Icon(Icons.cancel_outlined, size: 16),
                        label: const Text('Cancel'),
                        onPressed: () => _handleCancelSession(sess),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        key: Key('open_session_button_${sess.sessionId}'),
                        icon: const Icon(Icons.play_arrow, size: 16),
                        label: const Text('Open Attendance'),
                        onPressed: () => _handleOpenSession(sess),
                      ),
                    ] else if (sess.isOpen) ...[
                      OutlinedButton.icon(
                        key: Key('cancel_session_button_${sess.sessionId}'),
                        icon: const Icon(Icons.cancel_outlined, size: 16),
                        label: const Text('Cancel'),
                        onPressed: () => _handleCancelSession(sess),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        key: Key('record_roster_button_${sess.sessionId}'),
                        icon: const Icon(Icons.check_box_outlined, size: 16),
                        label: const Text('Record Attendance'),
                        onPressed: () => _handleManageRoster(sess),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        key: Key('finalize_session_button_${sess.sessionId}'),
                        icon: const Icon(Icons.lock_outline, size: 16),
                        label: const Text('Finalize'),
                        onPressed: () => _handleFinalizeSession(sess),
                      ),
                    ] else if (sess.isClosed) ...[
                      OutlinedButton.icon(
                        key: Key('view_roster_button_${sess.sessionId}'),
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text('View Roster & Correct'),
                        onPressed: () => _handleManageRoster(sess),
                      ),
                    ] else if (sess.isCancelled) ...[
                      Text(
                        'Cancelled session (excluded from metrics)',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic),
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

  Widget _buildMonitoringTab() {
    final openSignals = _signals.where((s) => s.isOpen).toList();
    final ackSignals = _signals.where((s) => s.isAcknowledged).toList();
    final resolvedSignals = _signals.where((s) => s.isResolved).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Metric Overview Cards
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Open Alerts',
                value: '${openSignals.length}',
                color: openSignals.isNotEmpty ? Colors.red : Colors.green,
                icon: Icons.warning_amber_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Acknowledged',
                value: '${ackSignals.length}',
                color: Colors.amber,
                icon: Icons.assignment_late_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Resolved',
                value: '${resolvedSignals.length}',
                color: Colors.blue,
                icon: Icons.task_alt,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Academic Early-Warning Intervention Signals',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Non-disciplinary advisory signals to support timely faculty guidance.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        if (_signals.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                  'No intervention signals generated. All learners compliant.'),
            ),
          )
        else
          ..._signals.map((sig) => _buildSignalCard(sig)),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(title,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSignalCard(AcademicInterventionSignal sig) {
    Color badgeColor = Colors.grey;
    if (sig.isOpen) badgeColor = Colors.red;
    if (sig.isAcknowledged) badgeColor = Colors.amber;
    if (sig.isResolved) badgeColor = Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: badgeColor.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 4),
                    Text(
                      sig.learnerId,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    sig.status.name.toUpperCase(),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: badgeColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(sig.description, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            Text(
              'Metric: ${sig.triggerValue.toStringAsFixed(1)}% (Threshold: ${sig.thresholdValue.toStringAsFixed(1)}%)',
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600),
            ),
            if (sig.resolutionNotes != null &&
                sig.resolutionNotes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Resolution Notes: ${sig.resolutionNotes}',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade900,
                      fontStyle: FontStyle.italic),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (sig.isOpen)
                  OutlinedButton.icon(
                    key: Key('ack_signal_button_${sig.signalId}'),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Acknowledge'),
                    onPressed: () => _handleAcknowledgeSignal(sig),
                  ),
                if (sig.isOpen || sig.isAcknowledged) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    key: Key('resolve_signal_button_${sig.signalId}'),
                    icon: const Icon(Icons.done_all, size: 16),
                    label: const Text('Resolve Alert'),
                    onPressed: () => _handleResolveSignal(sig),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionStatusBadge(AttendanceSessionStatus status) {
    Color color = switch (status) {
      AttendanceSessionStatus.scheduled => Colors.blue,
      AttendanceSessionStatus.open => Colors.green,
      AttendanceSessionStatus.closed => Colors.grey,
      AttendanceSessionStatus.cancelled => Colors.red,
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

  // ---------------------------------------------------------------------------
  // Learner View
  // ---------------------------------------------------------------------------

  Widget _buildLearnerView() {
    if (_learnerEnrollments.isEmpty && _learnerSummary == null) {
      return const Center(
        child: Text('No enrolled courses or attendance records found.'),
      );
    }

    final summary = _learnerSummary;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCourseSelectorHeader(),
        const SizedBox(height: 16),
        if (summary == null)
          const Center(
              child: Text('No finalized attendance sessions recorded yet.'))
        else ...[
          // Overview Card
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${summary.attendancePercentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: summary.meetsAttendanceThreshold
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          const Text(
                            'Authoritative Attendance Rate',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      Chip(
                        label: Text(
                          summary.meetsAttendanceThreshold
                              ? 'COMPLIANT'
                              : 'AT RISK',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        backgroundColor: summary.meetsAttendanceThreshold
                            ? Colors.green
                            : Colors.red,
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryStatItem('Sessions',
                          '${summary.totalSessionsFinalized}', Colors.black87),
                      _buildSummaryStatItem(
                          'Present', '${summary.presentCount}', Colors.green),
                      _buildSummaryStatItem('Late (0.5x)',
                          '${summary.lateCount}', Colors.amber.shade800),
                      _buildSummaryStatItem(
                          'Absent', '${summary.absentCount}', Colors.red),
                      _buildSummaryStatItem(
                          'Excused', '${summary.excusedCount}', Colors.blue),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Recent Session Attendance History',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (summary.recentRecords.isEmpty)
            const Text('No recent attendance records to display.',
                style: TextStyle(color: Colors.grey))
          else
            ...summary.recentRecords.map((rec) => _buildLearnerRecordTile(rec)),
        ],
      ],
    );
  }

  Widget _buildSummaryStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildLearnerRecordTile(AttendanceRecord rec) {
    Color statusColor = switch (rec.status) {
      AttendanceStatus.present => Colors.green,
      AttendanceStatus.late => Colors.amber.shade800,
      AttendanceStatus.absent => Colors.red,
      AttendanceStatus.excused => Colors.blue,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.15),
          child: Icon(
            rec.status == AttendanceStatus.present
                ? Icons.check
                : Icons.event_available,
            color: statusColor,
            size: 20,
          ),
        ),
        title: Text(
          'Session: ${rec.sessionId}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date: ${rec.sessionDate.toLocal().toString().split('.').first}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            if (rec.remarks != null && rec.remarks!.isNotEmpty)
              Text('Note: ${rec.remarks}',
                  style: const TextStyle(
                      fontSize: 11, fontStyle: FontStyle.italic)),
          ],
        ),
        trailing: Chip(
          label: Text(
            rec.status.name.toUpperCase(),
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
          ),
          backgroundColor: statusColor.withValues(alpha: 0.1),
        ),
      ),
    );
  }
}
