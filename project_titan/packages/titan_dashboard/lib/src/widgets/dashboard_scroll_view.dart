import 'package:flutter/material.dart';

import '../orchestrator/unified_dashboard_state.dart';
import 'achievement_card.dart';
import 'analytics_card.dart';
import 'assessment_card.dart';
import 'ai_tutor_card.dart';
import 'continue_learning_card.dart';
import 'journey_card.dart';
import 'quick_actions_card.dart';
import 'recommendation_card.dart';
import 'revision_card.dart';
import 'today_focus_card.dart';
import 'upcoming_events_card.dart';
import 'welcome_header.dart';

/// Responsive Scroll View displaying all 12 dashboard sections across Mobile, Tablet, and Desktop breakpoints.
class DashboardScrollView extends StatelessWidget {
  final UnifiedDashboardState state;
  final Function(String route)? onActionTap;
  final VoidCallback? onRefresh;

  const DashboardScrollView({
    super.key,
    required this.state,
    this.onActionTap,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width >= 1024) {
          return _buildDesktopLayout(context);
        } else if (width >= 600) {
          return _buildTabletLayout(context);
        } else {
          return _buildMobileLayout(context);
        }
      },
    );
  }

  // Mobile Layout (Single Column)
  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WelcomeHeader(headerData: state.header),
          const SizedBox(height: 12),
          QuickActionsCard(onActionSelected: onActionTap),
          const SizedBox(height: 12),
          TodayFocusCard(
            focusData: state.todayFocus,
            onStartTap: () => onActionTap?.call('/planner'),
          ),
          const SizedBox(height: 12),
          ContinueLearningCard(
            data: state.continueLearning,
            onContinueTap: () => onActionTap?.call('/learning'),
          ),
          const SizedBox(height: 12),
          RevisionCard(
            data: state.revisionDue,
            onReviseTap: () => onActionTap?.call('/revision'),
          ),
          const SizedBox(height: 12),
          AITutorCard(
            data: state.aiTutor,
            onAskTutorTap: () => onActionTap?.call('/tutor'),
          ),
          const SizedBox(height: 12),
          RecommendationCard(
            data: state.recommendations,
            onItemTap: (item) => onActionTap?.call(item.actionUrl),
          ),
          const SizedBox(height: 12),
          JourneyCard(
            data: state.journey,
            onJourneyTap: () => onActionTap?.call('/journey'),
          ),
          const SizedBox(height: 12),
          AssessmentCard(
            data: state.assessmentReadiness,
            onTakeAssessmentTap: () => onActionTap?.call('/assessment'),
          ),
          const SizedBox(height: 12),
          AnalyticsCard(
            data: state.weeklyAnalytics,
            onAnalyticsTap: () => onActionTap?.call('/analytics'),
          ),
          const SizedBox(height: 12),
          UpcomingEventsCard(
            data: state.upcomingEvents,
            onEventTap: (event) => onActionTap?.call('/events'),
          ),
          const SizedBox(height: 12),
          AchievementCard(
            data: state.achievements,
            onAchievementsTap: () => onActionTap?.call('/achievements'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Tablet Layout (Two Columns)
  Widget _buildTabletLayout(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          WelcomeHeader(headerData: state.header),
          const SizedBox(height: 16),
          QuickActionsCard(onActionSelected: onActionTap),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    TodayFocusCard(
                      focusData: state.todayFocus,
                      onStartTap: () => onActionTap?.call('/planner'),
                    ),
                    const SizedBox(height: 16),
                    ContinueLearningCard(
                      data: state.continueLearning,
                      onContinueTap: () => onActionTap?.call('/learning'),
                    ),
                    const SizedBox(height: 16),
                    AITutorCard(
                      data: state.aiTutor,
                      onAskTutorTap: () => onActionTap?.call('/tutor'),
                    ),
                    const SizedBox(height: 16),
                    JourneyCard(
                      data: state.journey,
                      onJourneyTap: () => onActionTap?.call('/journey'),
                    ),
                    const SizedBox(height: 16),
                    UpcomingEventsCard(
                      data: state.upcomingEvents,
                      onEventTap: (event) => onActionTap?.call('/events'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    RevisionCard(
                      data: state.revisionDue,
                      onReviseTap: () => onActionTap?.call('/revision'),
                    ),
                    const SizedBox(height: 16),
                    AssessmentCard(
                      data: state.assessmentReadiness,
                      onTakeAssessmentTap: () =>
                          onActionTap?.call('/assessment'),
                    ),
                    const SizedBox(height: 16),
                    RecommendationCard(
                      data: state.recommendations,
                      onItemTap: (item) => onActionTap?.call(item.actionUrl),
                    ),
                    const SizedBox(height: 16),
                    AnalyticsCard(
                      data: state.weeklyAnalytics,
                      onAnalyticsTap: () => onActionTap?.call('/analytics'),
                    ),
                    const SizedBox(height: 16),
                    AchievementCard(
                      data: state.achievements,
                      onAchievementsTap: () =>
                          onActionTap?.call('/achievements'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Desktop Layout (Three Columns)
  Widget _buildDesktopLayout(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          WelcomeHeader(headerData: state.header),
          const SizedBox(height: 20),
          QuickActionsCard(onActionSelected: onActionTap),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column 1: Core Daily Focus & Learning
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    TodayFocusCard(
                      focusData: state.todayFocus,
                      onStartTap: () => onActionTap?.call('/planner'),
                    ),
                    const SizedBox(height: 20),
                    ContinueLearningCard(
                      data: state.continueLearning,
                      onContinueTap: () => onActionTap?.call('/learning'),
                    ),
                    const SizedBox(height: 20),
                    UpcomingEventsCard(
                      data: state.upcomingEvents,
                      onEventTap: (event) => onActionTap?.call('/events'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Column 2: Revision & AI Tutor
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    RevisionCard(
                      data: state.revisionDue,
                      onReviseTap: () => onActionTap?.call('/revision'),
                    ),
                    const SizedBox(height: 20),
                    AITutorCard(
                      data: state.aiTutor,
                      onAskTutorTap: () => onActionTap?.call('/tutor'),
                    ),
                    const SizedBox(height: 20),
                    RecommendationCard(
                      data: state.recommendations,
                      onItemTap: (item) => onActionTap?.call(item.actionUrl),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Column 3: Readiness, Journey, Analytics & Achievements
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    AssessmentCard(
                      data: state.assessmentReadiness,
                      onTakeAssessmentTap: () =>
                          onActionTap?.call('/assessment'),
                    ),
                    const SizedBox(height: 20),
                    JourneyCard(
                      data: state.journey,
                      onJourneyTap: () => onActionTap?.call('/journey'),
                    ),
                    const SizedBox(height: 20),
                    AnalyticsCard(
                      data: state.weeklyAnalytics,
                      onAnalyticsTap: () => onActionTap?.call('/analytics'),
                    ),
                    const SizedBox(height: 20),
                    AchievementCard(
                      data: state.achievements,
                      onAchievementsTap: () =>
                          onActionTap?.call('/achievements'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
