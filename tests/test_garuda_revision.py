"""
Unit tests for GARUDA AI Adaptive Revision Engine (RevisionItem, RevisionScheduler, AdaptiveRevisionEngine, RevisionSession).
"""
import pytest
from datetime import datetime, timedelta, timezone
from app.garuda.profile import TopicProgress
from app.garuda.revision import (
    AdaptiveRevisionEngine,
    RevisionItem,
    RevisionItemType,
    RevisionPriority,
    RevisionQueue,
    RevisionScheduler,
    RevisionSession,
)


def test_revision_scheduler_sm2_success_flow():
    now = datetime.now(timezone.utc)
    item = RevisionItem(
        item_id="rev_1",
        topic_id="t1",
        topic_name="Polity Article 21",
        item_type=RevisionItemType.QUESTION,
        priority=RevisionPriority.HIGH,
        due_date=now,
    )

    # First successful review (quality = 5)
    updated1 = RevisionScheduler.schedule_next(item, quality=5, review_time=now)
    assert updated1.repetitions == 1
    assert updated1.interval_days == 1
    assert updated1.ease_factor >= 2.5
    assert updated1.due_date > now

    # Second successful review (quality = 4)
    updated2 = RevisionScheduler.schedule_next(updated1, quality=4, review_time=now)
    assert updated2.repetitions == 2
    assert updated2.interval_days == 6

    # Third successful review (quality = 4)
    updated3 = RevisionScheduler.schedule_next(updated2, quality=4, review_time=now)
    assert updated3.repetitions == 3
    assert updated3.interval_days > 6


def test_revision_scheduler_failure_resets_repetitions():
    now = datetime.now(timezone.utc)
    item = RevisionItem(
        item_id="rev_2",
        topic_id="t2",
        topic_name="History 1857",
        item_type=RevisionItemType.FLASHCARD,
        priority=RevisionPriority.HIGH,
        due_date=now,
        repetitions=4,
        interval_days=20,
        ease_factor=2.4,
    )

    # Failed review (quality = 1)
    failed_item = RevisionScheduler.schedule_next(item, quality=1, review_time=now)
    assert failed_item.repetitions == 0
    assert failed_item.interval_days == 1
    assert failed_item.ease_factor < 2.4


def test_adaptive_revision_engine_queue_building_and_sorting():
    now = datetime.now(timezone.utc)

    # Weak & overdue topic
    p_weak_overdue = TopicProgress(topic_id="t_weak", topic_name="Weak Topic", mastery_score=0.35, last_attempted_at=now - timedelta(days=10))
    # Moderate topic
    p_mod = TopicProgress(topic_id="t_mod", topic_name="Moderate Topic", mastery_score=0.75, last_attempted_at=now - timedelta(days=1))
    # Strong topic
    p_strong = TopicProgress(topic_id="t_strong", topic_name="Strong Topic", mastery_score=0.90, last_attempted_at=now)

    progress_map = {"t_mod": p_mod, "t_weak": p_weak_overdue, "t_strong": p_strong}

    queue = AdaptiveRevisionEngine.build_revision_queue("u1", progress_map, daily_limit=10, current_time=now)
    assert queue.total_due == 3
    assert len(queue.items) == 3

    # Weak & overdue topic must be at the top of the queue (URGENT priority)
    assert queue.items[0].topic_id == "t_weak"
    assert queue.items[0].priority == RevisionPriority.URGENT


def test_adaptive_revision_engine_daily_limit_truncation():
    now = datetime.now(timezone.utc)
    progress_map = {}
    for i in range(25):
        tid = f"t_{i}"
        progress_map[tid] = TopicProgress(topic_id=tid, topic_name=f"Topic {i}", mastery_score=0.5, last_attempted_at=now)

    queue = AdaptiveRevisionEngine.build_revision_queue("u1", progress_map, daily_limit=15, current_time=now)
    assert queue.total_due == 25
    assert len(queue.items) == 15


def test_revision_session_workflow():
    now = datetime.now(timezone.utc)
    item1 = RevisionItem(item_id="i1", topic_id="t1", topic_name="Polity", item_type=RevisionItemType.QUESTION, priority=RevisionPriority.HIGH, due_date=now)
    item2 = RevisionItem(item_id="i2", topic_id="t2", topic_name="History", item_type=RevisionItemType.FLASHCARD, priority=RevisionPriority.MEDIUM, due_date=now)

    queue = RevisionQueue(queue_id="q1", user_id="u1", items=[item1, item2], total_due=2)
    session = AdaptiveRevisionEngine.create_revision_session("u1", queue)

    assert session.is_completed() is False
    assert len(session.items_to_review) == 2
    assert len(session.completed_items) == 0

    # Review item1
    session = AdaptiveRevisionEngine.record_item_review(session, "i1", quality=4)
    assert len(session.items_to_review) == 1
    assert len(session.completed_items) == 1
    assert session.completed_items[0].item_id == "i1"

    # Review item2
    session = AdaptiveRevisionEngine.record_item_review(session, "i2", quality=5)
    assert session.is_completed() is True
    assert len(session.items_to_review) == 0
