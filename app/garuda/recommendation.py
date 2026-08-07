"""
GARUDA AI Recommendation Engine.

Implements RecommendationService, Recommendation, RecommendationPriority, RecommendationReason,
RecommendationRule hierarchy, NextBestActionCalculator, and DailyStudyRecommendation.

Deterministic Rule Engine following Clean Architecture, SOLID, Strategy, and Rule Engine patterns.
Does NOT depend on FastAPI, Flutter, SQLAlchemy, HTTP, Vector DBs, or AI SDKs.
"""
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from datetime import datetime, timezone
from enum import Enum, IntEnum
from typing import Dict, List, Optional

from app.garuda.profile import (
    LearningStatistics,
    RevisionReadinessCalculator,
    TopicProgress,
    WeakTopicDetector,
)


class RecommendationPriority(IntEnum):
    LOW = 1
    MEDIUM = 2
    HIGH = 3
    CRITICAL = 4


class RecommendationType(str, Enum):
    REVISE_WEAK = "revise_weak"
    PRACTICE_QUIZ = "practice_quiz"
    LEARN_NEW = "learn_new"
    REVIEW_INCORRECT = "review_incorrect"
    MAINTAIN_STREAK = "maintain_streak"
    COMPLETE_DAILY_GOAL = "complete_daily_goal"
    READ_DOCUMENT = "read_document"
    REINFORCE_STRONG = "reinforce_strong"
    TAKE_BREAK = "take_break"


class RecommendationReason(str, Enum):
    WEAK_TOPIC_REVISION = "weak_topic_revision"
    OVERDUE_REVISION = "overdue_revision"
    STREAK_MAINTENANCE = "streak_maintenance"
    QUIZ_PRACTICE = "quiz_practice"
    NEW_LEARNING = "new_learning"
    REINFORCE_STRONG = "reinforce_strong"
    TAKE_BREAK = "take_break"
    DAILY_GOAL = "daily_goal"


@dataclass
class Recommendation:
    """Represents a single deterministic action recommendation for a student."""
    id: str
    rec_type: RecommendationType
    title: str
    description: str
    priority: RecommendationPriority
    reason: RecommendationReason
    confidence_score: float  # 0.0 to 1.0
    target_topic_id: Optional[str] = None
    metadata: Dict = field(default_factory=dict)


@dataclass
class DailyStudyRecommendation:
    """Composite daily study plan containing Next Best Action (NBA) and prioritized recommendations."""
    next_best_action: Recommendation
    recommendations: List[Recommendation]
    total_due_revisions: int
    streak_days: int
    generated_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))


class RecommendationRule(ABC):
    """Abstract Base Class for composable, independently testable recommendation rules."""

    @property
    @abstractmethod
    def rule_name(self) -> str:
        pass

    @abstractmethod
    def evaluate(
        self, user_id: str, stats: LearningStatistics, progress_map: Dict[str, TopicProgress]
    ) -> Optional[Recommendation]:
        """Evaluates rule criteria against learning state and returns a Recommendation if applicable."""
        pass


class WeakTopicRevisionRule(RecommendationRule):
    """Rule triggering critical/high priority recommendation when weak topics exist."""

    @property
    def rule_name(self) -> str:
        return "WeakTopicRevisionRule"

    def evaluate(
        self, user_id: str, stats: LearningStatistics, progress_map: Dict[str, TopicProgress]
    ) -> Optional[Recommendation]:
        weak_topics = WeakTopicDetector.detect_weak(progress_map)
        if not weak_topics:
            return None

        # Sort weak topics by lowest mastery score first
        weak_topics.sort(key=lambda t: t.mastery_score)
        target = weak_topics[0]

        priority = RecommendationPriority.CRITICAL if target.mastery_score < 0.40 else RecommendationPriority.HIGH
        return Recommendation(
            id=f"rec_weak_{target.topic_id}",
            rec_type=RecommendationType.REVISE_WEAK,
            title=f"Revise Weak Topic: {target.topic_name}",
            description=f"Your mastery in {target.topic_name} is currently {int(target.mastery_score * 100)}%. Focused revision will improve accuracy.",
            priority=priority,
            reason=RecommendationReason.WEAK_TOPIC_REVISION,
            confidence_score=round(1.0 - target.mastery_score, 2),
            target_topic_id=target.topic_id,
        )


class OverdueRevisionRule(RecommendationRule):
    """Rule triggering high priority recommendation when topics are overdue for revision."""

    @property
    def rule_name(self) -> str:
        return "OverdueRevisionRule"

    def evaluate(
        self, user_id: str, stats: LearningStatistics, progress_map: Dict[str, TopicProgress]
    ) -> Optional[Recommendation]:
        overdue = [
            p for p in progress_map.values()
            if RevisionReadinessCalculator.is_overdue(p)
        ]
        if not overdue:
            return None

        overdue.sort(key=lambda p: RevisionReadinessCalculator.calculate_readiness(p), reverse=True)
        target = overdue[0]
        readiness = RevisionReadinessCalculator.calculate_readiness(target)

        return Recommendation(
            id=f"rec_overdue_{target.topic_id}",
            rec_type=RecommendationType.REVIEW_INCORRECT,
            title=f"Spaced Revision Due: {target.topic_name}",
            description=f"It has been several days since you last practiced {target.topic_name}. Review now to prevent memory decay.",
            priority=RecommendationPriority.HIGH,
            reason=RecommendationReason.OVERDUE_REVISION,
            confidence_score=readiness,
            target_topic_id=target.topic_id,
        )


class MaintainStreakRule(RecommendationRule):
    """Rule encouraging student to maintain their active study streak."""

    @property
    def rule_name(self) -> str:
        return "MaintainStreakRule"

    def evaluate(
        self, user_id: str, stats: LearningStatistics, progress_map: Dict[str, TopicProgress]
    ) -> Optional[Recommendation]:
        if stats.study_streak_days == 0:
            return None

        return Recommendation(
            id="rec_streak_maintain",
            rec_type=RecommendationType.MAINTAIN_STREAK,
            title=f"Keep Your {stats.study_streak_days}-Day Streak Alive!",
            description="Complete a short 5-question practice quiz today to preserve your active study streak.",
            priority=RecommendationPriority.MEDIUM,
            reason=RecommendationReason.STREAK_MAINTENANCE,
            confidence_score=0.85,
        )


class PracticeQuizRule(RecommendationRule):
    """Rule recommending a practice quiz when user has unassessed or moderate mastery topics."""

    @property
    def rule_name(self) -> str:
        return "PracticeQuizRule"

    def evaluate(
        self, user_id: str, stats: LearningStatistics, progress_map: Dict[str, TopicProgress]
    ) -> Optional[Recommendation]:
        if not progress_map:
            return Recommendation(
                id="rec_quiz_first",
                rec_type=RecommendationType.PRACTICE_QUIZ,
                title="Take Initial Assessment Quiz",
                description="Complete a diagnostic quiz to generate your cognitive learning profile.",
                priority=RecommendationPriority.HIGH,
                reason=RecommendationReason.QUIZ_PRACTICE,
                confidence_score=0.90,
            )

        moderate_topics = [p for p in progress_map.values() if 0.60 <= p.mastery_score < 0.80]
        if moderate_topics:
            target = moderate_topics[0]
            return Recommendation(
                id=f"rec_quiz_{target.topic_id}",
                rec_type=RecommendationType.PRACTICE_QUIZ,
                title=f"Attempt Practice Quiz on {target.topic_name}",
                description=f"Test your knowledge in {target.topic_name} to elevate your mastery score to strong level.",
                priority=RecommendationPriority.MEDIUM,
                reason=RecommendationReason.QUIZ_PRACTICE,
                confidence_score=0.75,
                target_topic_id=target.topic_id,
            )
        return None


class TakeBreakRule(RecommendationRule):
    """Rule suggesting a rest break if questions answered today exceeds burnout limits."""

    @property
    def rule_name(self) -> str:
        return "TakeBreakRule"

    def evaluate(
        self, user_id: str, stats: LearningStatistics, progress_map: Dict[str, TopicProgress]
    ) -> Optional[Recommendation]:
        if stats.total_questions_answered >= 50:
            return Recommendation(
                id="rec_take_break",
                rec_type=RecommendationType.TAKE_BREAK,
                title="Take a Well-Deserved Break",
                description=f"You have answered {stats.total_questions_answered} questions! Take a 15-minute break to consolidate memory.",
                priority=RecommendationPriority.MEDIUM,
                reason=RecommendationReason.TAKE_BREAK,
                confidence_score=0.95,
            )
        return None


class ReinforceStrongRule(RecommendationRule):
    """Rule suggesting reinforcement of strong topics when no weak topics remain."""

    @property
    def rule_name(self) -> str:
        return "ReinforceStrongRule"

    def evaluate(
        self, user_id: str, stats: LearningStatistics, progress_map: Dict[str, TopicProgress]
    ) -> Optional[Recommendation]:
        strong_topics = WeakTopicDetector.detect_strong(progress_map)
        weak_topics = WeakTopicDetector.detect_weak(progress_map)

        if strong_topics and not weak_topics:
            target = strong_topics[0]
            return Recommendation(
                id=f"rec_strong_{target.topic_id}",
                rec_type=RecommendationType.REINFORCE_STRONG,
                title=f"Mastery Maintenance: {target.topic_name}",
                description=f"You are mastering {target.topic_name}! Complete an advanced challenge to solidify long-term retention.",
                priority=RecommendationPriority.LOW,
                reason=RecommendationReason.REINFORCE_STRONG,
                confidence_score=0.70,
                target_topic_id=target.topic_id,
            )
        return None


class NextBestActionCalculator:
    """Evaluates composable rules and computes the single top-priority Next Best Action (NBA)."""

    def __init__(self, rules: Optional[List[RecommendationRule]] = None):
        self.rules = rules or [
            WeakTopicRevisionRule(),
            OverdueRevisionRule(),
            MaintainStreakRule(),
            PracticeQuizRule(),
            TakeBreakRule(),
            ReinforceStrongRule(),
        ]

    def compute_recommendations(
        self, user_id: str, stats: LearningStatistics, progress_map: Dict[str, TopicProgress]
    ) -> List[Recommendation]:
        """Evaluates all rules, filters out None results, and sorts by priority and confidence score."""
        recs: List[Recommendation] = []
        for rule in self.rules:
            res = rule.evaluate(user_id, stats, progress_map)
            if res is not None:
                recs.append(res)

        # Sort descending by priority (IntEnum) then by confidence score
        recs.sort(key=lambda r: (r.priority.value, r.confidence_score), reverse=True)
        return recs

    def calculate_nba(
        self, user_id: str, stats: LearningStatistics, progress_map: Dict[str, TopicProgress]
    ) -> Recommendation:
        """Returns the single highest priority Next Best Action recommendation."""
        recs = self.compute_recommendations(user_id, stats, progress_map)
        if recs:
            return recs[0]

        # Default fallback Next Best Action
        return Recommendation(
            id="rec_nba_default",
            rec_type=RecommendationType.LEARN_NEW,
            title="Explore New Study Materials",
            description="Select a topic to start your personalized learning journey today.",
            priority=RecommendationPriority.LOW,
            reason=RecommendationReason.NEW_LEARNING,
            confidence_score=0.50,
        )


class RecommendationService:
    """
    Core orchestrating service for generating deterministic recommendations.
    Consumes student profile statistics and progress maps without altering them.
    """

    def __init__(self, nba_calculator: Optional[NextBestActionCalculator] = None):
        self.nba_calculator = nba_calculator or NextBestActionCalculator()

    def generate_daily_recommendation(
        self, user_id: str, stats: LearningStatistics, progress_map: Dict[str, TopicProgress]
    ) -> DailyStudyRecommendation:
        """Generates comprehensive DailyStudyRecommendation payload for a user."""
        all_recs = self.nba_calculator.compute_recommendations(user_id, stats, progress_map)
        nba = self.nba_calculator.calculate_nba(user_id, stats, progress_map)

        overdue_count = sum(
            1 for p in progress_map.values() if RevisionReadinessCalculator.is_overdue(p)
        )

        return DailyStudyRecommendation(
            next_best_action=nba,
            recommendations=all_recs,
            total_due_revisions=overdue_count,
            streak_days=stats.study_streak_days,
        )
