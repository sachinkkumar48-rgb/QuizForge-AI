"""
Unit tests for GARUDA AI Learning Profile Engine (LearningProfileService, MasteryCalculator, TopicProgress, WeakTopicDetector, RevisionReadinessCalculator, LearningStatistics).
"""
import pytest
from datetime import datetime, timedelta, timezone
from app.garuda.domain import LearningProfile, TopicMastery
from app.garuda.profile import (
    LearningProfileService,
    LearningStatistics,
    MasteryCalculator,
    RevisionReadinessCalculator,
    TopicProgress,
    WeakTopicDetector,
)


def test_topic_progress_attempt_recording():
    progress = TopicProgress(topic_id="t1", topic_name="Indian Polity")
    assert progress.total_attempts == 0

    progress.record_attempt(is_correct=True, confidence=4)
    assert progress.total_attempts == 1
    assert progress.correct_attempts == 1
    assert progress.accuracy_rate == 1.0
    assert progress.avg_confidence == 4.0

    progress.record_attempt(is_correct=False, confidence=2)
    assert progress.total_attempts == 2
    assert progress.correct_attempts == 1
    assert progress.accuracy_rate == 0.5
    # 0.7 * 4.0 + 0.3 * 2.0 = 3.4
    assert progress.avg_confidence == 3.4


def test_mastery_calculator_deterministic_scoring():
    progress = TopicProgress(topic_id="t1", topic_name="Polity")

    # 3 correct attempts with high confidence (4)
    progress.record_attempt(is_correct=True, confidence=4)
    progress.record_attempt(is_correct=True, confidence=4)
    progress.record_attempt(is_correct=True, confidence=4)

    mastery = MasteryCalculator.calculate(progress)
    # accuracy=1.0, conf=4->1.0, recent=1.0 -> 0.5*1 + 0.3*1 + 0.2*1 = 1.0
    assert mastery == 1.0

    # Add 3 wrong attempts with low confidence (1)
    progress.record_attempt(is_correct=False, confidence=1)
    progress.record_attempt(is_correct=False, confidence=1)
    progress.record_attempt(is_correct=False, confidence=1)

    low_mastery = MasteryCalculator.calculate(progress)
    assert low_mastery < 0.5


def test_weak_and_strong_topic_detectors():
    p1 = TopicProgress(topic_id="t1", topic_name="Polity", mastery_score=0.9)
    p2 = TopicProgress(topic_id="t2", topic_name="History", mastery_score=0.4)
    p3 = TopicProgress(topic_id="t3", topic_name="Geography", mastery_score=0.7)

    progress_map = {"t1": p1, "t2": p2, "t3": p3}

    weak = WeakTopicDetector.detect_weak(progress_map)
    strong = WeakTopicDetector.detect_strong(progress_map)

    assert len(weak) == 1
    assert weak[0].topic_id == "t2"

    assert len(strong) == 1
    assert strong[0].topic_id == "t1"


def test_revision_readiness_calculator():
    now = datetime.now(timezone.utc)
    fresh_progress = TopicProgress(
        topic_id="t1", topic_name="Polity", mastery_score=0.9, last_attempted_at=now
    )
    old_progress = TopicProgress(
        topic_id="t2", topic_name="History", mastery_score=0.3, last_attempted_at=now - timedelta(days=10)
    )

    fresh_readiness = RevisionReadinessCalculator.calculate_readiness(fresh_progress, current_time=now)
    old_readiness = RevisionReadinessCalculator.calculate_readiness(old_progress, current_time=now)

    assert fresh_readiness < old_readiness
    assert RevisionReadinessCalculator.is_overdue(old_progress) is True


def test_learning_profile_service_workflow():
    service = LearningProfileService()

    # Record attempts
    service.record_attempt("u1", "t1", "Polity", is_correct=True, confidence=4)
    service.record_attempt("u1", "t1", "Polity", is_correct=True, confidence=4)
    service.record_attempt("u1", "t2", "History", is_correct=False, confidence=1)

    stats = service.compute_statistics("u1", streak_days=5)
    assert stats.study_streak_days == 5
    assert stats.total_questions_answered == 3
    assert stats.weak_topics_count == 1
    assert stats.strong_topics_count == 1

    revision_queue = service.get_revision_queue("u1")
    assert len(revision_queue) == 2
    # History (weak) should be urgently due first
    assert revision_queue[0].topic_id == "t2"
