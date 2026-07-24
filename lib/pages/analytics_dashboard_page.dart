import 'package:flutter/material.dart';
import '../controllers/analytics_controller.dart';
import '../models/analytics_engine_models.dart';
import '../models/pyq_question_model.dart';
import '../widgets/analytics_dashboard_cards.dart';

/// Comprehensive Analytics Dashboard Page displaying learning insights,
/// confidence-weighted weak area detection, performance trends, and export options.
class AnalyticsDashboardPage extends StatefulWidget {
  final List<PyqQuestionModel> questions;
  final AnalyticsController? controller;

  const AnalyticsDashboardPage({
    super.key,
    required this.questions,
    this.controller,
  });

  @override
  State<AnalyticsDashboardPage> createState() => _AnalyticsDashboardPageState();
}

class _AnalyticsDashboardPageState extends State<AnalyticsDashboardPage> {
  late final AnalyticsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? AnalyticsController();
    _controller.loadAnalytics(widget.questions);
  }

  @override
  Widget build(BuildContext context) {
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

                        // 1. Dashboard Cards
                        AnalyticsDashboardCards(insights: insights),

                        const SizedBox(height: 24),

                        // 2. Weak Area Detection with Confidence Levels
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

                        // 3. Performance Trend Snapshots
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
