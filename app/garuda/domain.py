"""
GARUDA AI Core Domain Entities, Value Objects, and Domain Exceptions.

Pure Python domain model following Clean Architecture.
Does NOT depend on FastAPI, Flutter, SQLAlchemy, or external AI SDKs.
"""
from dataclasses import dataclass, field
from datetime import datetime, timezone
from enum import Enum
from typing import Any, Dict, List, Optional


class MessageRole(str, Enum):
    SYSTEM = "system"
    USER = "user"
    ASSISTANT = "assistant"


class GarudaException(Exception):
    """Base exception for all GARUDA AI domain errors."""

    def __init__(self, message: str, code: str = "GARUDA_ERROR"):
        super().__init__(message)
        self.message = message
        self.code = code


class LearningProfileNotFoundException(GarudaException):
    """Raised when a requested learning profile does not exist."""

    def __init__(self, user_id: str):
        super().__init__(f"Learning profile for user '{user_id}' not found.", code="PROFILE_NOT_FOUND")


class ConversationSessionNotFoundException(GarudaException):
    """Raised when a requested conversation session does not exist."""

    def __init__(self, session_id: str):
        super().__init__(f"Conversation session '{session_id}' not found.", code="SESSION_NOT_FOUND")


class InvalidMessageException(GarudaException):
    """Raised when an invalid message is passed to conversation processing."""

    def __init__(self, reason: str):
        super().__init__(f"Invalid message: {reason}", code="INVALID_MESSAGE")


class ProviderUnavailableException(GarudaException):
    """Raised when an AI provider is unreachable or fails to generate a response."""

    def __init__(self, provider_name: str, detail: str = ""):
        message = f"AI Provider '{provider_name}' is currently unavailable."
        if detail:
            message += f" Detail: {detail}"
        super().__init__(message, code="PROVIDER_UNAVAILABLE")


@dataclass
class ChatMessage:
    """Represents a single message in a GARUDA Socratic conversation session."""
    id: str
    role: MessageRole
    content: str
    timestamp: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
    metadata: Dict[str, Any] = field(default_factory=dict)

    def is_user(self) -> bool:
        return self.role == MessageRole.USER

    def is_assistant(self) -> bool:
        return self.role == MessageRole.ASSISTANT


@dataclass
class ConversationSession:
    """Represents an active multi-turn conversation session between a student and GARUDA AI."""
    session_id: str
    user_id: str
    title: str
    messages: List[ChatMessage] = field(default_factory=list)
    created_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
    updated_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
    metadata: Dict[str, Any] = field(default_factory=dict)

    def add_message(self, message: ChatMessage) -> None:
        """Adds a message to the session and updates timestamp."""
        if not message.content or not message.content.strip():
            raise InvalidMessageException("Message content cannot be empty.")
        self.messages.append(message)
        self.updated_at = datetime.now(timezone.utc)

    def get_message_count(self) -> int:
        return len(self.messages)

    def get_last_message(self) -> Optional[ChatMessage]:
        return self.messages[-1] if self.messages else None


@dataclass
class TopicMastery:
    """Represents user performance and cognitive retention metric for a specific topic."""
    topic_id: str
    topic_name: str
    mastery_score: float = 0.0  # 0.0 to 1.0
    total_attempts: int = 0
    correct_attempts: int = 0
    retention_decay_rate: float = 0.1
    last_revised_at: Optional[datetime] = None

    def update_attempt(self, is_correct: bool) -> None:
        """Updates attempt counters and recalculates topic mastery score."""
        self.total_attempts += 1
        if is_correct:
            self.correct_attempts += 1

        raw_accuracy = self.correct_attempts / self.total_attempts
        # Weighted moving average for mastery score
        self.mastery_score = round(0.7 * raw_accuracy + 0.3 * (1.0 if is_correct else 0.0), 2)
        self.last_revised_at = datetime.now(timezone.utc)

    def is_weak(self) -> bool:
        """Determines if the topic requires targeted revision (< 0.6 mastery)."""
        return self.mastery_score < 0.6


@dataclass
class LearningProfile:
    """Represents a student's comprehensive cognitive learning profile and topic mastery state."""
    user_id: str
    overall_mastery: float = 0.0
    topic_masteries: Dict[str, TopicMastery] = field(default_factory=dict)
    updated_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))

    def update_topic(self, mastery: TopicMastery) -> None:
        """Updates topic mastery and recalculates overall mastery score."""
        self.topic_masteries[mastery.topic_id] = mastery
        if self.topic_masteries:
            total = sum(t.mastery_score for t in self.topic_masteries.values())
            self.overall_mastery = round(total / len(self.topic_masteries), 2)
        self.updated_at = datetime.now(timezone.utc)

    def get_weak_topics(self) -> List[TopicMastery]:
        """Returns list of topics marked as weak (< 0.6 mastery)."""
        return [t for t in self.topic_masteries.values() if t.is_weak()]


    def get_strong_topics(self) -> List[TopicMastery]:
        """Returns list of topics marked as strong (>= 0.8 mastery)."""
        return [t for t in self.topic_masteries.values() if t.mastery_score >= 0.8]


@dataclass
class GarudaSession:
    """Root aggregate domain entity coupling user identity, conversation session, and learning profile."""
    session_id: str
    user_id: str
    conversation: ConversationSession
    profile: LearningProfile
    created_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))

    def is_active(self) -> bool:
        return bool(self.session_id and self.user_id)
