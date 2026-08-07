"""
GARUDA AI Smart Study Planner.

Implements StudyTask, StudyPlan, DailySchedule, WeeklyPlanner, StudyPlanGenerator,
TimeAllocationStrategy, and StudyPlannerService.

Deterministic study planning following Clean Architecture, SOLID, Strategy, and Builder patterns.
Does NOT depend on FastAPI, Flutter, SQLAlchemy, HTTP, Vector DBs, or AI SDKs.
"""
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from enum import Enum, IntEnum
from typing import Dict, List, Optional

from app.garuda.profile import LearningStatistics, TopicProgress
from app.garuda.recommendation import DailyStudyRecommendation, RecommendationType
from app.garuda.revision import RevisionItem, RevisionQueue


class TaskPriority(IntEnum):
    LOW = 1
    MEDIUM = 2
    HIGH = 3
    URGENT = 4


class TaskType(str, Enum):
    REVISION = "revision"
    LEARNING = "learning"
    QUIZ = "quiz"
    BREAK = "break"
    BUFFER = "buffer"


@dataclass
class StudyTask:
    """Represents an individual scheduled study task block."""
    task_id: str
    task_type: TaskType
    title: str
    description: str
    duration_minutes: int
    priority: TaskPriority
    topic_id: Optional[str] = None
    is_completed: bool = False
    metadata: Dict = field(default_factory=dict)


@dataclass
class DailySchedule:
    """Represents a balanced 1-day study schedule containing task blocks and time budget breakdowns."""
    date_str: str
    tasks: List[StudyTask] = field(default_factory=list)
    total_study_minutes: int = 0
    revision_minutes: int = 0
    learning_minutes: int = 0
    quiz_minutes: int = 0
    break_minutes: int = 0
    buffer_minutes: int = 0

    def add_task(self, task: StudyTask) -> None:
        """Adds a study task block and updates category time tallies."""
        self.tasks.append(task)
        self.total_study_minutes += task.duration_minutes

        if task.task_type == TaskType.REVISION:
            self.revision_minutes += task.duration_minutes
        elif task.task_type == TaskType.LEARNING:
            self.learning_minutes += task.duration_minutes
        elif task.task_type == TaskType.QUIZ:
            self.quiz_minutes += task.duration_minutes
        elif task.task_type == TaskType.BREAK:
            self.break_minutes += task.duration_minutes
        elif task.task_type == TaskType.BUFFER:
            self.buffer_minutes += task.duration_minutes


@dataclass
class StudyPlan:
    """Aggregate domain entity representing a multi-day (e.g. 7-day) composite study plan."""
    plan_id: str
    user_id: str
    start_date: str
    end_date: str
    daily_schedules: List[DailySchedule] = field(default_factory=list)
    total_allocated_hours: float = 0.0
    target_exam_date: Optional[str] = None
    generated_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))


class TimeAllocationStrategy(ABC):
    """Abstract Strategy interface for budgeting daily study time across task categories."""

    @abstractmethod
    def allocate_time(
        self,
        date_str: str,
        daily_budget_minutes: int,
        revision_queue: RevisionQueue,
        daily_recommendation: DailyStudyRecommendation,
        progress_map: Dict[str, TopicProgress],
    ) -> DailySchedule:
        """Allocates daily study minutes across Revision, Learning, Quiz, Break, and Buffer tasks."""
        pass


class RevisionFirstTimeAllocationStrategy(TimeAllocationStrategy):
    """
    Deterministic strategy prioritizing spaced revision items first (40%),
    followed by weak topic learning (30%), practice quizzes (15%), rest breaks (10%), and buffers (5%).
    """

    def allocate_time(
        self,
        date_str: str,
        daily_budget_minutes: int,
        revision_queue: RevisionQueue,
        daily_recommendation: DailyStudyRecommendation,
        progress_map: Dict[str, TopicProgress],
    ) -> DailySchedule:
        schedule = DailySchedule(date_str=date_str)
        remaining_budget = max(30, daily_budget_minutes)

        # 1. Revision Task Blocks (Max 40% of budget)
        revision_budget = int(daily_budget_minutes * 0.40)
        task_counter = 1

        for rev_item in revision_queue.items:
            task_duration = 15  # 15 minutes per revision block
            if revision_budget < 15 or remaining_budget < 15:
                break

            task = StudyTask(
                task_id=f"task_rev_{date_str}_{task_counter}",
                task_type=TaskType.REVISION,
                title=f"Spaced Revision: {rev_item.topic_name}",
                description=f"Revise memory items for {rev_item.topic_name} (Priority: {rev_item.priority.name}).",
                duration_minutes=task_duration,
                priority=TaskPriority(rev_item.priority.value),
                topic_id=rev_item.topic_id,
            )
            schedule.add_task(task)
            revision_budget -= task_duration
            remaining_budget -= task_duration
            task_counter += 1

        # 2. Weak Topic Learning Blocks (30% of budget)
        learning_budget = min(remaining_budget, int(daily_budget_minutes * 0.30))
        nba = daily_recommendation.next_best_action

        if learning_budget >= 20 and nba:
            task = StudyTask(
                task_id=f"task_learn_{date_str}_{task_counter}",
                task_type=TaskType.LEARNING,
                title=nba.title,
                description=nba.description,
                duration_minutes=25,
                priority=TaskPriority(nba.priority.value),
                topic_id=nba.target_topic_id,
            )
            schedule.add_task(task)
            remaining_budget -= 25
            task_counter += 1

        # 3. Practice Quiz Block (15% of budget)
        quiz_budget = min(remaining_budget, int(daily_budget_minutes * 0.15))
        if quiz_budget >= 15:
            task = StudyTask(
                task_id=f"task_quiz_{date_str}_{task_counter}",
                task_type=TaskType.QUIZ,
                title="Daily Assessment Quiz",
                description="Test knowledge across current subjects to update mastery metrics.",
                duration_minutes=15,
                priority=TaskPriority.MEDIUM,
            )
            schedule.add_task(task)
            remaining_budget -= 15
            task_counter += 1

        # 4. Break Block (10% of budget)
        if schedule.total_study_minutes >= 45:
            task = StudyTask(
                task_id=f"task_break_{date_str}_{task_counter}",
                task_type=TaskType.BREAK,
                title="Rest & Memory Consolidation Break",
                description="Take a short 10-minute break to consolidate learning.",
                duration_minutes=10,
                priority=TaskPriority.LOW,
            )
            schedule.add_task(task)
            task_counter += 1

        # 5. Buffer Block (Remaining budget)
        if remaining_budget >= 10:
            task = StudyTask(
                task_id=f"task_buffer_{date_str}_{task_counter}",
                task_type=TaskType.BUFFER,
                title="Buffer & Notes Review Time",
                description="Flexible buffer for catch-up and note reading.",
                duration_minutes=remaining_budget,
                priority=TaskPriority.LOW,
            )
            schedule.add_task(task)

        return schedule


class WeeklyPlanner:
    """Builds a multi-day (e.g. 7-day) balanced weekly study schedule."""

    def __init__(self, allocation_strategy: Optional[TimeAllocationStrategy] = None):
        self.allocation_strategy = allocation_strategy or RevisionFirstTimeAllocationStrategy()

    def build_weekly_schedule(
        self,
        user_id: str,
        start_date: datetime,
        daily_budget_minutes: int,
        revision_queue: RevisionQueue,
        daily_recommendation: DailyStudyRecommendation,
        progress_map: Dict[str, TopicProgress],
        days: int = 7,
    ) -> List[DailySchedule]:
        schedules: List[DailySchedule] = []
        for d in range(days):
            current_day = start_date + timedelta(days=d)
            date_str = current_day.strftime("%Y-%m-%d")

            daily_sched = self.allocation_strategy.allocate_time(
                date_str=date_str,
                daily_budget_minutes=daily_budget_minutes,
                revision_queue=revision_queue,
                daily_recommendation=daily_recommendation,
                progress_map=progress_map,
            )
            schedules.append(daily_sched)

        return schedules


class StudyPlanGenerator:
    """Generates complete StudyPlan objects combining weekly planning and time budgeting."""

    def __init__(self, weekly_planner: Optional[WeeklyPlanner] = None):
        self.weekly_planner = weekly_planner or WeeklyPlanner()

    def generate_plan(
        self,
        user_id: str,
        daily_budget_minutes: int,
        revision_queue: RevisionQueue,
        daily_recommendation: DailyStudyRecommendation,
        progress_map: Dict[str, TopicProgress],
        start_date: Optional[datetime] = None,
        days: int = 7,
        target_exam_date: Optional[str] = None,
    ) -> StudyPlan:
        start_dt = start_date or datetime.now(timezone.utc)
        end_dt = start_dt + timedelta(days=days - 1)

        daily_schedules = self.weekly_planner.build_weekly_schedule(
            user_id=user_id,
            start_date=start_dt,
            daily_budget_minutes=daily_budget_minutes,
            revision_queue=revision_queue,
            daily_recommendation=daily_recommendation,
            progress_map=progress_map,
            days=days,
        )

        total_mins = sum(s.total_study_minutes for s in daily_schedules)
        total_hours = round(total_mins / 60.0, 1)

        return StudyPlan(
            plan_id=f"plan_{user_id}_{start_dt.strftime('%Y%m%d')}",
            user_id=user_id,
            start_date=start_dt.strftime("%Y-%m-%d"),
            end_date=end_dt.strftime("%Y-%m-%d"),
            daily_schedules=daily_schedules,
            total_allocated_hours=total_hours,
            target_exam_date=target_exam_date,
        )


class StudyPlannerService:
    """
    Core orchestrating service for GARUDA Smart Study Planner.
    Consumes profile statistics, recommendations, and revision queues to construct plans.
    """

    def __init__(self, plan_generator: Optional[StudyPlanGenerator] = None):
        self.plan_generator = plan_generator or StudyPlanGenerator()

    def create_daily_plan(
        self,
        user_id: str,
        daily_budget_minutes: int,
        revision_queue: RevisionQueue,
        daily_recommendation: DailyStudyRecommendation,
        progress_map: Dict[str, TopicProgress],
    ) -> DailySchedule:
        """Generates a balanced 1-day study schedule."""
        plan = self.plan_generator.generate_plan(
            user_id=user_id,
            daily_budget_minutes=daily_budget_minutes,
            revision_queue=revision_queue,
            daily_recommendation=daily_recommendation,
            progress_map=progress_map,
            days=1,
        )
        return plan.daily_schedules[0]

    def create_weekly_plan(
        self,
        user_id: str,
        daily_budget_minutes: int,
        revision_queue: RevisionQueue,
        daily_recommendation: DailyStudyRecommendation,
        progress_map: Dict[str, TopicProgress],
        target_exam_date: Optional[str] = None,
    ) -> StudyPlan:
        """Generates a balanced 7-day study plan."""
        return self.plan_generator.generate_plan(
            user_id=user_id,
            daily_budget_minutes=daily_budget_minutes,
            revision_queue=revision_queue,
            daily_recommendation=daily_recommendation,
            progress_map=progress_map,
            days=7,
            target_exam_date=target_exam_date,
        )
