"""
GARUDA AI Adaptive Revision Engine.

Implements RevisionItem, RevisionPriority, RevisionQueue, RevisionScheduler (SM-2+),
RevisionSession, and AdaptiveRevisionEngine.

Deterministic spaced repetition and revision ordering following Clean Architecture and DDD.
Does NOT depend on FastAPI, Flutter, SQLAlchemy, HTTP, Vector DBs, or AI SDKs.
"""
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from enum import Enum, IntEnum
from typing import Dict, List, Optional

from app.garuda.profile import TopicProgress, RevisionReadinessCalculator, WeakTopicDetector


class RevisionPriority(IntEnum):
    LOW = 1
    MEDIUM = 2
    HIGH = 3
    URGENT = 4


class RevisionItemType(str, Enum):
    FLASHCARD = "flashcard"
    QUESTION = "question"
    TOPIC_SUMMARY = "topic_summary"
    ERROR_BANK = "error_bank"


@dataclass
class RevisionItem:
    """Represents a single spaced repetition revision item."""
    item_id: str
    topic_id: str
    topic_name: str
    item_type: RevisionItemType
    priority: RevisionPriority
    due_date: datetime
    interval_days: int = 1
    ease_factor: float = 2.5  # SM-2 default ease factor
    repetitions: int = 0
    last_reviewed_at: Optional[datetime] = None
    metadata: Dict = field(default_factory=dict)

    def is_due(self, current_time: Optional[datetime] = None) -> bool:
        now = current_time or datetime.now(timezone.utc)
        return now >= self.due_date


@dataclass
class RevisionQueue:
    """Represents a student's prioritized daily revision queue."""
    queue_id: str
    user_id: str
    items: List[RevisionItem]
    total_due: int
    daily_limit: int = 20
    generated_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))


@dataclass
class RevisionSession:
    """Aggregate entity representing an active interactive revision session."""
    session_id: str
    user_id: str
    items_to_review: List[RevisionItem]
    completed_items: List[RevisionItem] = field(default_factory=list)
    started_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
    status: str = "active"  # "active", "completed"

    def is_completed(self) -> bool:
        return len(self.items_to_review) == 0 or self.status == "completed"


class RevisionScheduler:
    """
    Deterministic implementation of SuperMemo SM-2+ spaced repetition algorithm.
    Computes next interval, ease factor, and due date based on quality grade (0 to 5).
    """

    @staticmethod
    def schedule_next(
        item: RevisionItem, quality: int, review_time: Optional[datetime] = None
    ) -> RevisionItem:
        """
        Updates item parameters using SM-2 algorithm:
        - quality: 0 (total blackout) to 5 (perfect recall).
        - Quality < 3 is considered a failure (reset repetitions to 0, interval to 1).
        """
        q = max(0, min(5, quality))
        now = review_time or datetime.now(timezone.utc)

        # 1. Update Ease Factor (EF)
        # EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
        new_ef = item.ease_factor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
        new_ef = round(max(1.3, new_ef), 2)  # Minimum ease factor 1.3

        # 2. Update Repetitions and Interval
        if q < 3:
            new_repetitions = 0
            new_interval = 1
        else:
            new_repetitions = item.repetitions + 1
            if new_repetitions == 1:
                new_interval = 1
            elif new_repetitions == 2:
                new_interval = 6
            else:
                new_interval = max(1, round(item.interval_days * new_ef))

        new_due_date = now + timedelta(days=new_interval)

        return RevisionItem(
            item_id=item.item_id,
            topic_id=item.topic_id,
            topic_name=item.topic_name,
            item_type=item.item_type,
            priority=item.priority,
            due_date=new_due_date,
            interval_days=new_interval,
            ease_factor=new_ef,
            repetitions=new_repetitions,
            last_reviewed_at=now,
            metadata=item.metadata,
        )


class AdaptiveRevisionEngine:
    """
    Core engine orchestrating adaptive revision queues, mastery-aware priority scoring,
    and session management.
    """

    @staticmethod
    def build_revision_queue(
        user_id: str,
        progress_map: Dict[str, TopicProgress],
        daily_limit: int = 20,
        current_time: Optional[datetime] = None,
    ) -> RevisionQueue:
        """
        Constructs a deterministically prioritized revision queue for a user.
        Prioritizes weak topics (< 0.60 mastery) and overdue revisions.
        """
        now = current_time or datetime.now(timezone.utc)
        candidate_items: List[RevisionItem] = []

        for topic_id, progress in progress_map.items():
            readiness = RevisionReadinessCalculator.calculate_readiness(progress, current_time=now)
            is_weak = progress.mastery_score < 0.60
            is_overdue = RevisionReadinessCalculator.is_overdue(progress)

            # Assign priority deterministically
            if is_weak and is_overdue:
                priority = RevisionPriority.URGENT
            elif is_weak or is_overdue:
                priority = RevisionPriority.HIGH
            elif progress.mastery_score < 0.80:
                priority = RevisionPriority.MEDIUM
            else:
                priority = RevisionPriority.LOW

            item = RevisionItem(
                item_id=f"rev_{user_id}_{topic_id}",
                topic_id=topic_id,
                topic_name=progress.topic_name,
                item_type=RevisionItemType.TOPIC_SUMMARY if is_weak else RevisionItemType.QUESTION,
                priority=priority,
                due_date=progress.last_attempted_at or now,
                interval_days=max(1, int(progress.mastery_score * 10)),
                ease_factor=round(1.3 + progress.mastery_score * 1.2, 2),
                repetitions=progress.total_attempts,
                last_reviewed_at=progress.last_attempted_at,
                metadata={"readiness": readiness, "mastery_score": progress.mastery_score},
            )
            candidate_items.append(item)

        # Deterministic Sorting:
        # 1. Priority (URGENT -> LOW)
        # 2. Readiness score (descending)
        # 3. Topic ID (alphabetical fallback for absolute determinism)
        candidate_items.sort(
            key=lambda item: (
                item.priority.value,
                item.metadata.get("readiness", 0.0),
                item.topic_id,
            ),
            reverse=True,
        )

        total_due = len(candidate_items)
        truncated_items = candidate_items[:daily_limit]

        return RevisionQueue(
            queue_id=f"q_{user_id}_{int(now.timestamp())}",
            user_id=user_id,
            items=truncated_items,
            total_due=total_due,
            daily_limit=daily_limit,
            generated_at=now,
        )

    @staticmethod
    def create_revision_session(user_id: str, queue: RevisionQueue) -> RevisionSession:
        """Initializes a new interactive RevisionSession from a RevisionQueue."""
        return RevisionSession(
            session_id=f"sess_rev_{user_id}_{int(datetime.now(timezone.utc).timestamp())}",
            user_id=user_id,
            items_to_review=list(queue.items),
            completed_items=[],
        )

    @staticmethod
    def record_item_review(
        session: RevisionSession, item_id: str, quality: int
    ) -> RevisionSession:
        """Processes an item review during a session, updating scheduler state."""
        target_item = None
        remaining_items = []
        for item in session.items_to_review:
            if item.item_id == item_id and target_item is None:
                target_item = item
            else:
                remaining_items.append(item)

        if target_item is None:
            return session  # Item not found in active review queue

        updated_item = RevisionScheduler.schedule_next(target_item, quality)
        session.completed_items.append(updated_item)
        session.items_to_review = remaining_items

        if len(session.items_to_review) == 0:
            session.status = "completed"

        return session
