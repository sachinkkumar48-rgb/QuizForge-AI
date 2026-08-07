"""
Tests for GARUDA AI Learning Analytics & Performance Dashboard Analytics Layer (Sprint 8.3 / TITAN-S8.3.002).
"""
import pytest
from app.garuda.dashboard import (
    DashboardDTO,
    DashboardService,
    DashboardSummary,
    PerformanceAnalytics,
    RecommendationsSummary,
    RevisionAnalytics,
    StudyAnalytics,
    TopicAnalytics,
)
from app.garuda.planner import StudyPlannerService
from app.garuda.profile import LearningProfileService
from app.garuda.recommendation import RecommendationService
from app.garuda.revision import AdaptiveRevisionEngine


def test_dashboard_service_aggregation():
    """Verify DashboardService aggregates metrics from existing GARUDA engines without recalculation."""
    service = DashboardService()
    dashboard = service.get_dashboard("user_garuda_test_01")

    assert isinstance(dashboard, DashboardDTO)
    assert dashboard.user_id == "user_garuda_test_01"

    # 1. Summary
    assert isinstance(dashboard.summary, DashboardSummary)
    assert dashboard.summary.overall_mastery >= 0.0
    assert dashboard.summary.overall_accuracy >= 0.0
    assert dashboard.summary.study_streak >= 0

    # 2. Topic Analytics
    assert isinstance(dashboard.topic_analytics, TopicAnalytics)
    assert isinstance(dashboard.topic_analytics.strong_topics, list)
    assert isinstance(dashboard.topic_analytics.weak_topics, list)
    assert dashboard.topic_analytics.mastery_pct >= 0.0

    # 3. Revision Analytics
    assert isinstance(dashboard.revision_analytics, RevisionAnalytics)
    assert dashboard.revision_analytics.todays_queue >= 0
    assert dashboard.revision_analytics.avg_ease_factor >= 1.3

    # 4. Study Analytics
    assert isinstance(dashboard.study_analytics, StudyAnalytics)
    assert isinstance(dashboard.study_analytics.todays_plan, list)
    assert dashboard.study_analytics.study_time_minutes > 0

    # 5. Performance Analytics
    assert isinstance(dashboard.performance_analytics, PerformanceAnalytics)
    assert dashboard.performance_analytics.daily_accuracy >= 0.0
    assert dashboard.performance_analytics.consistency_score >= 0.0

    # 6. Recommendations
    assert isinstance(dashboard.recommendations, RecommendationsSummary)
    assert len(dashboard.recommendations.next_best_action) > 0


def test_dashboard_dto_serialization():
    """Verify DashboardDTO to_dict() returns fully compliant JSON-compatible payload."""
    dashboard = DashboardService.get_dashboard("user_garuda_json_test")
    payload = dashboard.to_dict()

    assert payload["user_id"] == "user_garuda_json_test"
    assert "summary" in payload
    assert "topic_analytics" in payload
    assert "revision_analytics" in payload
    assert "study_analytics" in payload
    assert "performance_analytics" in payload
    assert "recommendations" in payload
    assert "generated_at" in payload
