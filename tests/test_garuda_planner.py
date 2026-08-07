"""
Unit tests for GARUDA AI Smart Study Planner (StudyTask, DailySchedule, StudyPlan, WeeklyPlanner, StudyPlannerService).
"""
import pytest
from datetime import datetime, timezone
from app.garuda.planner import (
    DailySchedule,
    RevisionFirstTimeAllocationStrategy,
    StudyPlan,
    StudyPlanGenerator,
    StudyPlannerService,
    StudyTask,
    TaskPriority,
    TaskType,
    WeeklyPlanner,
)
from app.garuda.profile import TopicProgress
from app.garuda.recommendation import (
    DailyStudyRecommendation,
    Recommendation,
    RecommendationPriority,
    RecommendationReason,
    RecommendationType,
)
from app.garuda.revision import (
    RevisionItem,
    RevisionItemType,
    RevisionPriority as RevPriority,
    RevisionQueue,
)


def test_study_task_and_daily_schedule():
    schedule = DailySchedule(date_str="2026-08-01")
    t1 = StudyTask(
        task_id="t1",
        task_type=TaskType.REVISION,
        title="Spaced Revision: Polity",
        description="Review Article 14",
        duration_minutes=15,
        priority=TaskPriority.HIGH,
    )
    t2 = StudyTask(
        task_id="t2",
        task_type=TaskType.LEARNING,
        title="Learn History",
        description="Study 1857 Revolt",
        duration_minutes=25,
        priority=TaskPriority.MEDIUM,
    )

    schedule.add_task(t1)
    schedule.add_task(t2)

    assert schedule.total_study_minutes == 40
    assert schedule.revision_minutes == 15
    assert schedule.learning_minutes == 25
    assert len(schedule.tasks) == 2


def test_revision_first_time_allocation_strategy():
    strategy = RevisionFirstTimeAllocationStrategy()
    rev_item = RevisionItem(
        item_id="r1",
        topic_id="t1",
        topic_name="Polity",
        item_type=RevisionItemType.QUESTION,
        priority=RevPriority.HIGH,
        due_date=datetime.now(timezone.utc),
    )
    rev_queue = RevisionQueue(queue_id="q1", user_id="u1", items=[rev_item], total_due=1)

    nba = Recommendation(
        id="rec1",
        rec_type=RecommendationType.LEARN_NEW,
        title="Learn Geography",
        description="Study Monsoon system",
        priority=RecommendationPriority.HIGH,
        reason=RecommendationReason.NEW_LEARNING,
        confidence_score=0.8,
        target_topic_id="t_geo",
    )
    daily_rec = DailyStudyRecommendation(
        next_best_action=nba, recommendations=[nba], total_due_revisions=1, streak_days=2
    )

    schedule = strategy.allocate_time(
        date_str="2026-08-01",
        daily_budget_minutes=120,
        revision_queue=rev_queue,
        daily_recommendation=daily_rec,
        progress_map={},
    )

    assert schedule.total_study_minutes > 0
    assert schedule.revision_minutes == 15
    assert schedule.learning_minutes == 25
    assert schedule.quiz_minutes == 15
    assert len(schedule.tasks) >= 3


def test_weekly_planner_7_day_schedule():
    planner = WeeklyPlanner()
    rev_queue = RevisionQueue(queue_id="q1", user_id="u1", items=[], total_due=0)
    nba = Recommendation(
        id="rec1",
        rec_type=RecommendationType.LEARN_NEW,
        title="Learn Science",
        description="Physics fundamentals",
        priority=RecommendationPriority.MEDIUM,
        reason=RecommendationReason.NEW_LEARNING,
        confidence_score=0.7,
    )
    daily_rec = DailyStudyRecommendation(
        next_best_action=nba, recommendations=[nba], total_due_revisions=0, streak_days=1
    )

    now = datetime.now(timezone.utc)
    schedules = planner.build_weekly_schedule(
        user_id="u1",
        start_date=now,
        daily_budget_minutes=90,
        revision_queue=rev_queue,
        daily_recommendation=daily_rec,
        progress_map={},
        days=7,
    )

    assert len(schedules) == 7
    for s in schedules:
        assert s.total_study_minutes > 0


def test_study_planner_service_workflow():
    service = StudyPlannerService()
    rev_queue = RevisionQueue(queue_id="q1", user_id="u1", items=[], total_due=0)
    nba = Recommendation(
        id="rec1",
        rec_type=RecommendationType.LEARN_NEW,
        title="Study Economics",
        description="Inflation & Monetary Policy",
        priority=RecommendationPriority.HIGH,
        reason=RecommendationReason.NEW_LEARNING,
        confidence_score=0.85,
    )
    daily_rec = DailyStudyRecommendation(
        next_best_action=nba, recommendations=[nba], total_due_revisions=0, streak_days=5
    )

    # Test daily plan
    daily_plan = service.create_daily_plan(
        user_id="u1",
        daily_budget_minutes=60,
        revision_queue=rev_queue,
        daily_recommendation=daily_rec,
        progress_map={},
    )
    assert daily_plan.total_study_minutes > 0

    # Test weekly plan
    weekly_plan = service.create_weekly_plan(
        user_id="u1",
        daily_budget_minutes=120,
        revision_queue=rev_queue,
        daily_recommendation=daily_rec,
        progress_map={},
        target_exam_date="2026-10-01",
    )
    assert weekly_plan.user_id == "u1"
    assert len(weekly_plan.daily_schedules) == 7
    assert weekly_plan.total_allocated_hours > 0.0
    assert weekly_plan.target_exam_date == "2026-10-01"
