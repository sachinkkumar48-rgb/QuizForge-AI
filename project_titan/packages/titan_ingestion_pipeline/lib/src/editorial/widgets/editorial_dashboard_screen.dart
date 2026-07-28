import 'package:flutter/material.dart';

import '../engine/editorial_workflow_engine.dart';
import '../models/editorial_models.dart';

/// Material 3 Editorial Dashboard Screen displaying queues, quality metrics, search, and status filters.
class EditorialDashboardScreen extends StatefulWidget {
  final EditorialWorkflowEngine engine;
  final String currentUserId;
  final EditorialRole currentUserRole;
  final ValueChanged<EditorialAssetRecord>? onSelectRecord;

  const EditorialDashboardScreen({
    super.key,
    required this.engine,
    required this.currentUserId,
    this.currentUserRole = EditorialRole.editor,
    this.onSelectRecord,
  });

  @override
  State<EditorialDashboardScreen> createState() =>
      _EditorialDashboardScreenState();
}

class _EditorialDashboardScreenState extends State<EditorialDashboardScreen> {
  EditorialStatus? _statusFilter;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<EditorialAssetRecord> _records = [];
  EditorialAnalytics _analytics = const EditorialAnalytics(
    totalAssets: 0,
    pendingReviewCount: 0,
    publishedCount: 0,
    rejectedCount: 0,
    archivedCount: 0,
    approvalRatePercentage: 0.0,
    averageQualityScore: 0.0,
    averageReviewTimeMinutes: 0.0,
  );
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final records = await widget.engine.repository
        .getAllRecords(statusFilter: _statusFilter);
    final analytics = await widget.engine.getAnalytics();
    setState(() {
      _records = records;
      _analytics = analytics;
      _isLoading = false;
    });
  }

  List<EditorialAssetRecord> get _filteredRecords {
    if (_searchQuery.trim().isEmpty) return _records;
    final q = _searchQuery.toLowerCase();
    return _records.where((r) {
      final titleMatch = r.assets.lessonTitle.toLowerCase().contains(q);
      final idMatch = r.id.toLowerCase().contains(q);
      final statusMatch = r.status.name.toLowerCase().contains(q);
      return titleMatch || idMatch || statusMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filtered = _filteredRecords;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Editorial & Knowledge Validation Console'),
            Text(
              'User: ${widget.currentUserId} (${widget.currentUserRole.name})',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Analytics & Metric Overview Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 800;
                      return isWide
                          ? Row(
                              children: [
                                Expanded(
                                  child: _buildMetricCard(
                                    context,
                                    title: 'Pending Review',
                                    value: '${_analytics.pendingReviewCount}',
                                    icon: Icons.pending_actions,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildMetricCard(
                                    context,
                                    title: 'Published Assets',
                                    value: '${_analytics.publishedCount}',
                                    icon: Icons.verified_outlined,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildMetricCard(
                                    context,
                                    title: 'Rejected Assets',
                                    value: '${_analytics.rejectedCount}',
                                    icon: Icons.cancel_outlined,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildMetricCard(
                                    context,
                                    title: 'Avg Quality Score',
                                    value:
                                        '${_analytics.averageQualityScore.toStringAsFixed(1)}%',
                                    icon: Icons.auto_awesome,
                                    color: Colors.purple,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildMetricCard(
                                        context,
                                        title: 'Pending Review',
                                        value:
                                            '${_analytics.pendingReviewCount}',
                                        icon: Icons.pending_actions,
                                        color: Colors.orange,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildMetricCard(
                                        context,
                                        title: 'Published Assets',
                                        value: '${_analytics.publishedCount}',
                                        icon: Icons.verified_outlined,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildMetricCard(
                                        context,
                                        title: 'Rejected Assets',
                                        value: '${_analytics.rejectedCount}',
                                        icon: Icons.cancel_outlined,
                                        color: Colors.red,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildMetricCard(
                                        context,
                                        title: 'Avg Quality Score',
                                        value:
                                            '${_analytics.averageQualityScore.toStringAsFixed(1)}%',
                                        icon: Icons.auto_awesome,
                                        color: Colors.purple,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Search Bar & Filters
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText:
                                'Search editorial queue by title or ID...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (val) {
                            setState(() => _searchQuery = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Review Queue & Status Filters',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Filter Chips
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      FilterChip(
                        label: const Text('All Assets'),
                        selected: _statusFilter == null,
                        onSelected: (val) {
                          setState(() => _statusFilter = null);
                          _loadData();
                        },
                      ),
                      FilterChip(
                        label: const Text('Needs Review'),
                        selected: _statusFilter == EditorialStatus.needsReview,
                        onSelected: (val) {
                          setState(() =>
                              _statusFilter = EditorialStatus.needsReview);
                          _loadData();
                        },
                      ),
                      FilterChip(
                        label: const Text('Editor Review'),
                        selected: _statusFilter == EditorialStatus.editorReview,
                        onSelected: (val) {
                          setState(() =>
                              _statusFilter = EditorialStatus.editorReview);
                          _loadData();
                        },
                      ),
                      FilterChip(
                        label: const Text('Senior Approval'),
                        selected:
                            _statusFilter == EditorialStatus.reviewerApproval,
                        onSelected: (val) {
                          setState(() =>
                              _statusFilter = EditorialStatus.reviewerApproval);
                          _loadData();
                        },
                      ),
                      FilterChip(
                        label: const Text('Published'),
                        selected: _statusFilter == EditorialStatus.published,
                        onSelected: (val) {
                          setState(
                              () => _statusFilter = EditorialStatus.published);
                          _loadData();
                        },
                      ),
                      FilterChip(
                        label: const Text('Archived'),
                        selected: _statusFilter == EditorialStatus.archived,
                        onSelected: (val) {
                          setState(
                              () => _statusFilter = EditorialStatus.archived);
                          _loadData();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Record List
                  filtered.isEmpty
                      ? Card(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Center(
                              child: Text(
                                'No assets found matching the filter and search criteria.',
                                style: theme.textTheme.bodyLarge
                                    ?.copyWith(color: colorScheme.outline),
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final record = filtered[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12.0),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      _getStatusColor(record.status)
                                          .withValues(alpha: 0.2),
                                  child: Icon(
                                    _getStatusIcon(record.status),
                                    color: _getStatusColor(record.status),
                                  ),
                                ),
                                title: Text(
                                  record.assets.lessonTitle,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  'Status: ${record.status.label} • Version: ${record.provenance.publishedVersion} • Quality: ${record.qualityScore.overallScore.toStringAsFixed(1)}% • Editor: ${record.provenance.editorId}',
                                ),
                                trailing: ElevatedButton.icon(
                                  icon: const Icon(Icons.rate_review_outlined,
                                      size: 18),
                                  label: const Text('Inspect'),
                                  onPressed: () {
                                    if (widget.onSelectRecord != null) {
                                      widget.onSelectRecord!(record);
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(EditorialStatus status) {
    switch (status) {
      case EditorialStatus.published:
        return Colors.green;
      case EditorialStatus.needsReview:
        return Colors.orange;
      case EditorialStatus.editorReview:
        return Colors.blue;
      case EditorialStatus.reviewerApproval:
        return Colors.purple;
      case EditorialStatus.archived:
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(EditorialStatus status) {
    switch (status) {
      case EditorialStatus.published:
        return Icons.verified;
      case EditorialStatus.needsReview:
        return Icons.rate_review;
      case EditorialStatus.editorReview:
        return Icons.edit;
      case EditorialStatus.reviewerApproval:
        return Icons.verified_user;
      case EditorialStatus.archived:
        return Icons.archive;
      default:
        return Icons.article;
    }
  }
}
