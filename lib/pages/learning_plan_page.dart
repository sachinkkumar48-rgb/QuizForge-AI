import 'package:flutter/material.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

import '../core/di/service_locator_init.dart';
import 'adaptive_practice_page.dart';

/// Production Learner-Facing Personalized Learning Plan Page (P43).
///
/// Exposes the deterministic, closed-loop pedagogical learning plan:
/// - Current Recommended Action with explainable reason ("WHY")
/// - Upcoming Action Sequence in strict topological / pedagogical priority
/// - Start / Resume Action controls connected to execution workflows
/// - Completed Milestones & Spaced Retention Revision
/// - Live Plan Refresh upon practice outcome reconciliation
class LearningPlanPage extends StatefulWidget {
  final PersonalizedLearningPlanService? service;
  final String learnerId;
  final String examId;
  final List<NormalizedQuestion>? corpus;

  const LearningPlanPage({
    super.key,
    this.service,
    this.learnerId = 'learner_titan_active',
    this.examId = 'upsc_prelims_gs1',
    this.corpus,
  });

  @override
  State<LearningPlanPage> createState() => _LearningPlanPageState();
}

class _LearningPlanPageState extends State<LearningPlanPage> {
  late final PersonalizedLearningPlanService _service;
  bool _isLoading = true;
  String? _errorMessage;
  PersonalizedLearningPlan? _plan;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? locate<PersonalizedLearningPlanService>();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final plan = await _service.generatePlan(
        learnerId: widget.learnerId,
        examId: widget.examId,
        corpus: widget.corpus,
      );
      if (mounted) {
        setState(() {
          _plan = plan;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _handleActionExecution(PersonalizedLearningAction action) async {
    if (!action.isExecutable &&
        action.actionType != PlanActionType.takeDiagnostic) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${action.topicName} questions are currently in acquisition. Select another action.',
          ),
          backgroundColor: Colors.blueGrey.shade800,
        ),
      );
      return;
    }

    final isResume = action.actionType == PlanActionType.continueSession;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdaptivePracticePage(
          targetTopic: action.topicName,
          examId: action.examId,
          learnerId: widget.learnerId,
          isResumeMode: isResume,
          resumeSessionId: action.sessionId,
          questionCount:
              action.targetQuestionCount > 0 ? action.targetQuestionCount : 5,
        ),
      ),
    );

    // Closed-loop refresh on return
    if (mounted) {
      _loadPlan();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.alt_route, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text(
              "Personalized Learning Plan",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Plan",
            onPressed: _isLoading ? null : _loadPlan,
          ),
        ],
      ),
      body: _buildBody(theme, colorScheme),
    );
  }

  Widget _buildBody(ThemeData theme, ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              "Synthesizing Personalized Learning Plan...",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 56, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                "Failed to Generate Learning Plan",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadPlan,
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    final plan = _plan;
    if (plan == null || plan.actions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              "No Learning Plan Actions Available",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPlan,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan Overview Card
            _buildPlanOverviewCard(theme, colorScheme, plan),
            const SizedBox(height: 24),

            // Recommended Action Card
            if (plan.recommendedAction != null) ...[
              Text(
                "Current Recommendation",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildRecommendedActionCard(
                theme,
                colorScheme,
                plan.recommendedAction!,
              ),
              const SizedBox(height: 28),
            ],

            // Upcoming Action Sequence
            if (plan.upcomingActions.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Upcoming Learning Sequence",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${plan.upcomingActions.length} Actions",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...plan.upcomingActions.map(
                (act) => _buildUpcomingActionTile(theme, colorScheme, act),
              ),
              const SizedBox(height: 24),
            ],

            // Completed Milestones & Retention Revision
            if (plan.completedActions.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Completed Milestones & Revision",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${plan.completedActions.length} Completed",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...plan.completedActions.map(
                (act) => _buildCompletedActionTile(theme, colorScheme, act),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlanOverviewCard(
    ThemeData theme,
    ColorScheme colorScheme,
    PersonalizedLearningPlan plan,
  ) {
    final progressPercent = (plan.progressPercentage * 100).toInt();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
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
                        plan.examId.toUpperCase().replaceAll('_', ' '),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Plan ID: ${plan.planId}",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "Rev ${plan.stateRevision}",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Curriculum Mastery Progress",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "$progressPercent% (${plan.completedActions.length}/${plan.actions.length} units)",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: plan.progressPercentage,
                minHeight: 10,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedActionCard(
    ThemeData theme,
    ColorScheme colorScheme,
    PersonalizedLearningAction action,
  ) {
    Color accentColor = Colors.deepPurple;
    IconData actionIcon = Icons.bolt;
    String actionBtnLabel = "Start Learning";

    switch (action.actionType) {
      case PlanActionType.continueSession:
        accentColor = Colors.orange.shade700;
        actionIcon = Icons.play_circle_filled;
        actionBtnLabel = "Resume Session";
        break;
      case PlanActionType.takeDiagnostic:
        accentColor = Colors.indigo;
        actionIcon = Icons.radar;
        actionBtnLabel = "Take Diagnostic";
        break;
      case PlanActionType.startRemedialLesson:
        accentColor = Colors.red.shade700;
        actionIcon = Icons.healing;
        actionBtnLabel = "Begin Remediation";
        break;
      case PlanActionType.practiceObjective:
      case PlanActionType.practicePyqs:
        accentColor = Colors.deepPurple;
        actionIcon = Icons.auto_stories;
        actionBtnLabel = "Practice Questions";
        break;
      case PlanActionType.reviewRevision:
        accentColor = Colors.teal;
        actionIcon = Icons.history_edu;
        actionBtnLabel = "Review Mastery";
        break;
    }

    return Card(
      elevation: 4,
      shadowColor: accentColor.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accentColor.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(actionIcon, size: 14, color: accentColor),
                      const SizedBox(width: 6),
                      Text(
                        "TOP PRIORITY RECOMMENDATION",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (action.targetQuestionCount > 0)
                  Text(
                    "${action.targetQuestionCount} PYQs Available",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              action.objectiveTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${action.subjectName} • ${action.topicName}",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // Explainable Reason ("WHY")
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.psychology, size: 20, color: accentColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "WHY THIS ACTION IS RECOMMENDED",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          action.reason,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: action.isExecutable ||
                        action.actionType == PlanActionType.takeDiagnostic
                    ? () => _handleActionExecution(action)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(actionIcon),
                label: Text(
                  actionBtnLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingActionTile(
    ThemeData theme,
    ColorScheme colorScheme,
    PersonalizedLearningAction action,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order index circle
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  "${action.orderIndex}",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          action.reasonCode.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey.shade800,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (action.targetQuestionCount > 0)
                        Text(
                          "${action.targetQuestionCount} PYQs",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    action.objectiveTitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    action.topicName,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    action.reason,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              tooltip: "Start Action",
              onPressed: () => _handleActionExecution(action),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedActionTile(
    ThemeData theme,
    ColorScheme colorScheme,
    PersonalizedLearningAction action,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.green.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.objectiveTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    action.reason,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green.shade900,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _handleActionExecution(action),
              child: const Text("Review"),
            ),
          ],
        ),
      ),
    );
  }
}
