"""
GARUDA AI Learning Profile Engine.

Implements LearningProfileService, MasteryCalculator, TopicProgress, WeakTopicDetector,
RevisionReadinessCalculator, and LearningStatistics.

Deterministic learning model following Clean Architecture and Domain-Driven Design.
Does NOT depend on FastAPI, Flutter, SQLAlchemy, HTTP, Vector DBs, or AI SDKs.
"""
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from typing import Dict, List, Optional

from app.garuda.domain import LearningProfile, TopicMastery
from app.garuda.interfaces import ILearningProfileService


@dataclass
class TopicProgress:
    """Detailed progress metric for a specific study topic."""
    topic_id: str
    topic_name: str
    mastery_score: float = 0.0  # 0.0 to 1.0
    accuracy_rate: float = 0.0  # 0.0 to 1.0
    avg_confidence: float = 3.0  # 1 (low) to 4 (high)
    total_attempts: int = 0
    correct_attempts: int = 0
    last_attempted_at: Optional[datetime] = None
    attempts_history: List[Dict] = field(default_factory=list)

    def record_attempt(self, is_correct: bool, confidence: int = 3, timestamp: Optional[datetime] = None) -> None:
        ts = timestamp or datetime.now(timezone.utc)
        conf = max(1, min(4, confidence))
        self.total_attempts += 1
        if is_correct:
            self.correct_attempts += 1

        self.accuracy_rate = round(self.correct_attempts / self.total_attempts, 2)
        # Moving average of confidence
        if len(self.attempts_history) == 0:
            self.avg_confidence = float(conf)
        else:
            self.avg_confidence = round(0.7 * self.avg_confidence + 0.3 * conf, 2)

        self.last_attempted_at = ts
        self.attempts_history.append({"is_correct": is_correct, "confidence": conf, "timestamp": ts.isoformat()})


@dataclass
class LearningStatistics:
    """Aggregate cognitive and performance statistics for a student."""
    overall_mastery: float = 0.0
    weak_topics_count: int = 0
    strong_topics_count: int = 0
    study_streak_days: int = 0
    learning_velocity: float = 0.0  # Mastery increase per day
    practice_frequency: float = 0.0  # Attempts per day
    total_questions_answered: int = 0
    accuracy_trend: str = "stable"  # "improving", "declining", "stable"


class MasteryCalculator:
    """Deterministic calculator for computing topic mastery score (0.0 to 1.0)."""

    @staticmethod
    def calculate(progress: TopicProgress) -> float:
        """
        Computes topic mastery using weighted formula:
        - 50% accuracy rate
        - 30% normalized confidence score (1..4 mapped to 0..1)
        - 20% recent attempt weight (last 3 attempts accuracy)
        """
        if progress.total_attempts == 0:
            return 0.0

        accuracy_component = progress.accuracy_rate
        confidence_component = (progress.avg_confidence - 1.0) / 3.0  # normalize 1..4 -> 0..1

        recent_attempts = progress.attempts_history[-3:]
        recent_len = len(recent_attempts)
        if recent_len > 0:
            recent_correct = 0
            for a in recent_attempts:
                if a["is_correct"]:
                    recent_correct += 1
            recent_component = recent_correct / recent_len
        else:
            recent_component = accuracy_component

        mastery = (0.50 * accuracy_component) + (0.30 * confidence_component) + (0.20 * recent_component)
        return round(max(0.0, min(1.0, mastery)), 2)


class WeakTopicDetector:
    """Identifies weak vs strong topics based on mastery scores and accuracy trends."""

    @staticmethod
    def detect_weak(
        progress_map: Dict[str, TopicProgress], threshold: float = 0.60
    ) -> List[TopicProgress]:
        """Returns list of TopicProgress objects where mastery is below threshold (< 0.60)."""
        return [p for p in progress_map.values() if p.mastery_score < threshold]

    @staticmethod
    def detect_strong(
        progress_map: Dict[str, TopicProgress], threshold: float = 0.80
    ) -> List[TopicProgress]:
        """Returns list of TopicProgress objects where mastery is at or above threshold (>= 0.80)."""
        return [p for p in progress_map.values() if p.mastery_score >= threshold]


class RevisionReadinessCalculator:
    """Calculates revision readiness score (0.0 to 1.0) based on decay and time elapsed."""

    @staticmethod
    def calculate_readiness(
        progress: TopicProgress, current_time: Optional[datetime] = None
    ) -> float:
        """
        Calculates revision urgency (0.0 = fresh, 1.0 = urgent revision needed).
        Urgency increases as time elapses and is higher for lower mastery topics.
        """
        if progress.last_attempted_at is None:
            return 1.0  # Unattempted topics are urgently due

        now = current_time or datetime.now(timezone.utc)
        elapsed_hours = (now - progress.last_attempted_at).total_seconds() / 3600.0

        # Memory half-life estimation: higher mastery -> longer retention half-life
        half_life_hours = 24.0 * (1.0 + progress.mastery_score * 3.0)  # 24h to 96h half-life

        # Time decay factor
        time_decay = 1.0 - math_exp_decay(elapsed_hours, half_life_hours)
        mastery_penalty = 1.0 - progress.mastery_score

        readiness = round(max(0.0, min(1.0, (0.6 * time_decay) + (0.4 * mastery_penalty))), 2)
        return readiness

    @staticmethod
    def is_overdue(progress: TopicProgress, readiness_threshold: float = 0.70) -> bool:
        """Determines if a topic is overdue for revision."""
        return RevisionReadinessCalculator.calculate_readiness(progress) >= readiness_threshold


def math_exp_decay(elapsed: float, half_life: float) -> float:
    """Helper for exponential decay calculation."""
    if half_life <= 0:
        return 0.0
    return (0.5) ** (elapsed / half_life)


class LearningProfileService(ILearningProfileService):
    """
    Core implementation of ILearningProfileService.
    Manages learner progress updates, mastery calculations, and revision queues.
    """

    def __init__(self):
        self._progress_store: Dict[str, Dict[str, TopicProgress]] = {}

    def get_or_create_progress(self, user_id: str, topic_id: str, topic_name: str) -> TopicProgress:
        """Retrieves or initializes TopicProgress for a user and topic."""
        if user_id not in self._progress_store:
            self._progress_store[user_id] = {}
        user_store = self._progress_store[user_id]
        if topic_id not in user_store:
            user_store[topic_id] = TopicProgress(topic_id=topic_id, topic_name=topic_name)
        return user_store[topic_id]

    def record_attempt(
        self,
        user_id: str,
        topic_id: str,
        topic_name: str,
        is_correct: bool,
        confidence: int = 3,
        timestamp: Optional[datetime] = None,
    ) -> TopicProgress:
        """Records a user attempt, updates progress metrics, and recalculates topic mastery."""
        progress = self.get_or_create_progress(user_id, topic_id, topic_name)
        progress.record_attempt(is_correct, confidence=confidence, timestamp=timestamp)
        progress.mastery_score = MasteryCalculator.calculate(progress)
        return progress

    def calculate_overall_mastery(self, profile: LearningProfile) -> float:
        """Calculates overall student mastery score from topic metrics."""
        if not profile.topic_masteries:
            return 0.0
        total = sum(t.mastery_score for t in profile.topic_masteries.values())
        return round(total / len(profile.topic_masteries), 2)

    def identify_weak_spots(self, profile: LearningProfile) -> List[TopicMastery]:
        """Identifies topics requiring prioritized spaced revision (< 0.60 mastery)."""
        return [t for t in profile.topic_masteries.values() if t.mastery_score < 0.60]

    def compute_statistics(self, user_id: str, streak_days: int = 0) -> LearningStatistics:
        """Computes comprehensive learning statistics for a user."""
        user_store = self._progress_store.get(user_id, {})
        if not user_store:
            return LearningStatistics(study_streak_days=streak_days)

        total_mastery = 0.0
        weak_count = 0
        strong_count = 0
        total_questions = 0
        all_attempts = []

        for p in user_store.values():
            m = p.mastery_score
            total_mastery += m
            if m < 0.60:
                weak_count += 1
            elif m >= 0.80:
                strong_count += 1
            total_questions += p.total_attempts
            all_attempts.extend(p.attempts_history)

        n_topics = len(user_store)
        overall = round(total_mastery / n_topics, 2)
        all_attempts.sort(key=lambda a: a["timestamp"])

        trend = "stable"
        if len(all_attempts) >= 6:
            recent_half = all_attempts[-3:]
            prev_half = all_attempts[-6:-3]
            recent_acc = sum(1 for a in recent_half if a["is_correct"]) / 3.0
            prev_acc = sum(1 for a in prev_half if a["is_correct"]) / 3.0
            if recent_acc > prev_acc + 0.15:
                trend = "improving"
            elif recent_acc < prev_acc - 0.15:
                trend = "declining"

        return LearningStatistics(
            overall_mastery=overall,
            weak_topics_count=weak_count,
            strong_topics_count=strong_count,
            study_streak_days=streak_days,
            learning_velocity=round(overall * 0.1, 2),
            practice_frequency=round(total_questions / max(1, n_topics), 1),
            total_questions_answered=total_questions,
            accuracy_trend=trend,
        )

    def get_revision_queue(self, user_id: str) -> List[TopicProgress]:
        """Returns topics sorted by revision readiness score descending (most urgently due first)."""
        user_store = self._progress_store.get(user_id, {})
        if not user_store:
            return []

        scored = [
            (RevisionReadinessCalculator.calculate_readiness(p), p)
            for p in user_store.values()
        ]
        scored.sort(key=lambda x: x[0], reverse=True)
        return [p for score, p in scored]
