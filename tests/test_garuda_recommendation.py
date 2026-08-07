"""
Unit tests for GARUDA AI Recommendation Engine (RecommendationService, RecommendationRule, NextBestActionCalculator).
"""
import pytest
from datetime import datetime, timedelta, timezone
from app.garuda.profile import LearningStatistics, TopicProgress
from app.garuda.recommendation import (
    MaintainStreakRule,
    NextBestActionCalculator,
    OverdueRevisionRule,
    PracticeQuizRule,
    RecommendationPriority,
    RecommendationReason,
    RecommendationService,
    RecommendationType,
    ReinforceStrongRule,
    TakeBreakRule,
    WeakTopicRevisionRule,
)


def test_weak_topic_revision_rule():
    rule = WeakTopicRevisionRule()
    stats = LearningStatistics()

    p_weak = TopicProgress(topic_id="t1", topic_name="Indian History", mastery_score=0.35)
    p_strong = TopicProgress(topic_id="t2", topic_name="Polity", mastery_score=0.85)
    progress_map = {"t1": p_weak, "t2": p_strong}

    rec = rule.evaluate("u1", stats, progress_map)
    assert rec is not None
    assert rec.rec_type == RecommendationType.REVISE_WEAK
    assert rec.priority == RecommendationPriority.CRITICAL
    assert rec.target_topic_id == "t1"
    assert rec.reason == RecommendationReason.WEAK_TOPIC_REVISION


def test_overdue_revision_rule():
    rule = OverdueRevisionRule()
    stats = LearningStatistics()
    now = datetime.now(timezone.utc)

    p_overdue = TopicProgress(topic_id="t_overdue", topic_name="Geography", mastery_score=0.5, last_attempted_at=now - timedelta(days=15))
    progress_map = {"t_overdue": p_overdue}

    rec = rule.evaluate("u1", stats, progress_map)
    assert rec is not None
    assert rec.rec_type == RecommendationType.REVIEW_INCORRECT
    assert rec.priority == RecommendationPriority.HIGH
    assert rec.target_topic_id == "t_overdue"


def test_take_break_rule():
    rule = TakeBreakRule()
    stats_heavy = LearningStatistics(total_questions_answered=60)
    stats_light = LearningStatistics(total_questions_answered=10)

    rec_break = rule.evaluate("u1", stats_heavy, {})
    assert rec_break is not None
    assert rec_break.rec_type == RecommendationType.TAKE_BREAK

    rec_no_break = rule.evaluate("u1", stats_light, {})
    assert rec_no_break is None


def test_next_best_action_calculator_prioritization():
    calc = NextBestActionCalculator()
    stats = LearningStatistics(study_streak_days=4, total_questions_answered=10)

    p1 = TopicProgress(topic_id="t1", topic_name="Polity", mastery_score=0.30)  # Weak (CRITICAL)
    p2 = TopicProgress(topic_id="t2", topic_name="History", mastery_score=0.70)  # Moderate (PRACTICE_QUIZ MEDIUM)
    progress_map = {"t1": p1, "t2": p2}

    recs = calc.compute_recommendations("u1", stats, progress_map)
    assert len(recs) >= 2
    # First recommendation must be the CRITICAL weak topic revision
    assert recs[0].priority == RecommendationPriority.CRITICAL
    assert recs[0].target_topic_id == "t1"

    nba = calc.calculate_nba("u1", stats, progress_map)
    assert nba.id == recs[0].id


def test_recommendation_service_daily_recommendation():
    service = RecommendationService()
    stats = LearningStatistics(study_streak_days=3)
    now = datetime.now(timezone.utc)

    p_overdue = TopicProgress(topic_id="t1", topic_name="Science", mastery_score=0.4, last_attempted_at=now - timedelta(days=20))
    progress_map = {"t1": p_overdue}

    daily = service.generate_daily_recommendation("u1", stats, progress_map)
    assert daily.streak_days == 3
    assert daily.total_due_revisions == 1
    assert daily.next_best_action is not None
    assert len(daily.recommendations) > 0
