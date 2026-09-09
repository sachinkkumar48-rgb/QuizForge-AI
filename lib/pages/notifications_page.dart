import 'package:flutter/material.dart';
import 'package:garuda_learning/garuda_learning.dart';

import 'academic_credentials_page.dart';
import 'attendance_management_page.dart';
import 'course_enrollment_page.dart';
import 'gradebook_page.dart';

/// Institutional Notification & Communication Portal (TITAN-KO-054.0 P54).
///
/// Multi-perspective academic communication hub providing:
/// 1. Learner Inbox:
///    - Official notifications across enrollment, assessments, grades, attendance, and credentials.
///    - Unread counting with dynamic notification badge.
///    - Category filtering: All, Unread, Assessments, Grades, Attendance, Credentials.
///    - Interactive actions: Mark Read, Acknowledge, Dismiss, Navigate to source record.
/// 2. Faculty Advisory Desk:
///    - Alerts for academic monitoring intervention signals, grade disputes, and roster updates.
///    - Quick acknowledgment and direct navigation to affected student records.
class NotificationsPage extends StatefulWidget {
  final NotificationService? notificationService;
  final String initialFacultyId;
  final String initialLearnerId;
  final bool initialIsFaculty;
  final String? initialCategory;

  const NotificationsPage({
    super.key,
    this.notificationService,
    this.initialFacultyId = 'faculty_admin',
    this.initialLearnerId = 'default_learner',
    this.initialIsFaculty = false,
    this.initialCategory,
  });

  static NotificationService? _sharedDefaultService;
  static NotificationService get sharedService {
    return _sharedDefaultService ??= NotificationService(
      notificationRepository: InMemoryNotificationRepository(),
    );
  }

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late final NotificationService _notificationService;

  late bool _isFacultyMode;
  late String _currentFacultyId;
  late String _currentLearnerId;

  bool _isLoading = true;
  String? _statusMessage;
  int _unreadCount = 0;
  List<LmsNotification> _notifications = [];

  late TabController _tabController;
  final List<String> _learnerTabs = [
    'All',
    'Unread',
    'Assessments',
    'Grades',
    'Attendance',
    'Credentials'
  ];
  final List<String> _facultyTabs = [
    'All',
    'Unread',
    'Monitoring',
    'Assessments',
    'Grades',
    'Attendance'
  ];

  @override
  void initState() {
    super.initState();
    _isFacultyMode = widget.initialIsFaculty;
    _currentFacultyId = widget.initialFacultyId;
    _currentLearnerId = widget.initialLearnerId;

    _notificationService =
        widget.notificationService ?? NotificationsPage.sharedService;

    final tabs = _isFacultyMode ? _facultyTabs : _learnerTabs;
    _tabController = TabController(length: tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadData();
      }
    });

    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _currentRecipientId =>
      _isFacultyMode ? _currentFacultyId : _currentLearnerId;

  List<String> get _activeTabs => _isFacultyMode ? _facultyTabs : _learnerTabs;

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final recipient = _currentRecipientId;
      _unreadCount =
          await _notificationService.getUnreadCount(recipientId: recipient);

      final currentTab = _activeTabs[_tabController.index].toLowerCase();
      _notifications = await _notificationService.listNotifications(
        recipientId: recipient,
        category: currentTab,
      );
    } catch (e) {
      _statusMessage = 'Error loading notifications: $e';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _switchPerspective(bool isFaculty) {
    if (_isFacultyMode == isFaculty) return;
    setState(() {
      _isFacultyMode = isFaculty;
      _tabController.dispose();
      final tabs = _isFacultyMode ? _facultyTabs : _learnerTabs;
      _tabController = TabController(length: tabs.length, vsync: this);
      _tabController.addListener(() {
        if (!_tabController.indexIsChanging) {
          _loadData();
        }
      });
    });
    _loadData();
  }

  // ---------------------------------------------------------------------------
  // Action Handlers
  // ---------------------------------------------------------------------------

  Future<void> _handleMarkRead(LmsNotification notif) async {
    try {
      await _notificationService.markAsRead(
        notificationId: notif.notificationId,
        recipientId: _currentRecipientId,
      );
      _loadData();
    } catch (e) {
      _showErrorDialog('Error', e.toString());
    }
  }

  Future<void> _handleMarkAllRead() async {
    try {
      final count = await _notificationService.markAllAsRead(
        recipientId: _currentRecipientId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Marked $count notifications as read.')),
      );
      _loadData();
    } catch (e) {
      _showErrorDialog('Error', e.toString());
    }
  }

  Future<void> _handleAcknowledge(LmsNotification notif) async {
    try {
      await _notificationService.acknowledgeNotification(
        notificationId: notif.notificationId,
        recipientId: _currentRecipientId,
      );
      _loadData();
    } catch (e) {
      _showErrorDialog('Error', e.toString());
    }
  }

  Future<void> _handleDismiss(LmsNotification notif) async {
    try {
      await _notificationService.dismissNotification(
        notificationId: notif.notificationId,
        recipientId: _currentRecipientId,
      );
      _loadData();
    } catch (e) {
      _showErrorDialog('Error', e.toString());
    }
  }

  void _navigateToSource(LmsNotification notif) {
    // If not read yet, mark read on click
    if (notif.isUnread) {
      _handleMarkRead(notif);
    }

    Widget? destinationPage;
    final type = notif.sourceEntityType.toLowerCase();

    if (type.contains('enrollment') || type.contains('course')) {
      destinationPage = CourseEnrollmentPage(
        initialFacultyId: _currentFacultyId,
        initialLearnerId: _currentLearnerId,
        initialIsFaculty: _isFacultyMode,
      );
    } else if (type.contains('grade') || type.contains('dispute')) {
      destinationPage = GradebookPage(
        initialFacultyId: _currentFacultyId,
        initialLearnerId: _currentLearnerId,
        initialIsFaculty: _isFacultyMode,
      );
    } else if (type.contains('attendance') ||
        type.contains('intervention') ||
        type.contains('session')) {
      destinationPage = AttendanceManagementPage(
        initialFacultyId: _currentFacultyId,
        initialLearnerId: _currentLearnerId,
        initialIsFaculty: _isFacultyMode,
      );
    } else if (type.contains('transcript') ||
        type.contains('certificate') ||
        type.contains('credential')) {
      destinationPage = AcademicCredentialsPage(
        initialFacultyId: _currentFacultyId,
        initialLearnerId: _currentLearnerId,
        initialIsFaculty: _isFacultyMode,
      );
    }

    if (destinationPage != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => destinationPage!),
      );
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
              ? 'Faculty Academic Notifications'
              : 'My Notifications',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SegmentedButton<bool>(
              key: const Key('notification_perspective_toggle'),
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text('Learner'),
                  icon: Icon(Icons.person_outline, size: 16),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('Faculty'),
                  icon: Icon(Icons.admin_panel_settings_outlined, size: 16),
                ),
              ],
              selected: {_isFacultyMode},
              onSelectionChanged: (set) => _switchPerspective(set.first),
            ),
          ),
          if (_unreadCount > 0)
            IconButton(
              key: const Key('mark_all_read_button'),
              icon: const Icon(Icons.done_all),
              tooltip: 'Mark All as Read',
              onPressed: _handleMarkAllRead,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _activeTabs.map((title) {
            final isUnreadTab = title == 'Unread';
            return Tab(
              child: Row(
                children: [
                  Text(title),
                  if (isUnreadTab && _unreadCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      key: const Key('unread_badge_counter'),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$_unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _statusMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _statusMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _notifications.isEmpty
                  ? _buildEmptyState()
                  : _buildNotificationList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No Notifications',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              _isFacultyMode
                  ? 'No institutional alerts or student updates at this time.'
                  : 'You are all caught up! No pending announcements or updates.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, idx) {
        final notif = _notifications[idx];
        return _buildNotificationCard(notif);
      },
    );
  }

  Widget _buildNotificationCard(LmsNotification notif) {
    Color priorityColor = switch (notif.priority) {
      NotificationPriority.urgent => Colors.red,
      NotificationPriority.high => Colors.orange.shade800,
      NotificationPriority.normal => Colors.blue,
      NotificationPriority.low => Colors.grey,
    };

    final isUnread = notif.isUnread;

    return Card(
      elevation: isUnread ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isUnread ? Colors.blue.shade400 : Colors.grey.shade300,
          width: isUnread ? 1.5 : 1.0,
        ),
      ),
      color:
          isUnread ? Colors.blue.shade50.withValues(alpha: 0.3) : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToSource(notif),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: Type & Priority & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: priorityColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          notif.type.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: priorityColor,
                          ),
                        ),
                      ),
                      if (notif.priority == NotificationPriority.urgent ||
                          notif.priority == NotificationPriority.high) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: priorityColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            notif.priority.name.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  _buildStatusChip(notif.status),
                ],
              ),
              const SizedBox(height: 10),
              // Title
              Text(
                notif.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              // Message
              Text(
                notif.message,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),
              // Footer row: Timestamp & Actions
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 13, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    notif.createdAt.toLocal().toString().split('.').first,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  if (notif.isUnread)
                    TextButton.icon(
                      key: Key('mark_read_button_${notif.notificationId}'),
                      icon: const Icon(Icons.check, size: 14),
                      label: const Text('Mark Read',
                          style: TextStyle(fontSize: 12)),
                      onPressed: () => _handleMarkRead(notif),
                    ),
                  if (!notif.isAcknowledged &&
                      (notif.priority == NotificationPriority.urgent ||
                          notif.type == NotificationType.intervention)) ...[
                    const SizedBox(width: 4),
                    OutlinedButton.icon(
                      key: Key('ack_button_${notif.notificationId}'),
                      icon: const Icon(Icons.thumb_up_outlined, size: 14),
                      label: const Text('Acknowledge',
                          style: TextStyle(fontSize: 12)),
                      onPressed: () => _handleAcknowledge(notif),
                    ),
                  ],
                  const SizedBox(width: 4),
                  IconButton(
                    key: Key('dismiss_button_${notif.notificationId}'),
                    icon: const Icon(Icons.close, size: 16),
                    tooltip: 'Dismiss',
                    onPressed: () => _handleDismiss(notif),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(NotificationStatus status) {
    Color color = switch (status) {
      NotificationStatus.unread => Colors.blue,
      NotificationStatus.read => Colors.grey,
      NotificationStatus.acknowledged => Colors.green,
      NotificationStatus.dismissed => Colors.brown,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
