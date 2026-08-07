"""
GARUDA AI Abstract Repository and Service Interfaces.

Interface-first contracts following SOLID principles and Clean Architecture.
Does NOT depend on FastAPI, Flutter, SQLAlchemy, HTTP, or external AI SDKs.
"""
from abc import ABC, abstractmethod
from typing import AsyncGenerator, Dict, List, Optional

from app.garuda.domain import (
    ChatMessage,
    ConversationSession,
    LearningProfile,
    TopicMastery,
)


class ILearningProfileRepository(ABC):
    """Abstract contract for learning profile persistence."""

    @abstractmethod
    async def get_profile(self, user_id: str) -> Optional[LearningProfile]:
        """Retrieves user learning profile by ID."""
        pass

    @abstractmethod
    async def save_profile(self, profile: LearningProfile) -> LearningProfile:
        """Persists or updates user learning profile."""
        pass

    @abstractmethod
    async def update_topic_mastery(self, user_id: str, topic_mastery: TopicMastery) -> LearningProfile:
        """Updates a specific topic mastery record within a user profile."""
        pass


class IConversationSessionRepository(ABC):
    """Abstract contract for conversation session persistence."""

    @abstractmethod
    async def get_session(self, session_id: str) -> Optional[ConversationSession]:
        """Retrieves a conversation session by ID."""
        pass

    @abstractmethod
    async def save_session(self, session: ConversationSession) -> ConversationSession:
        """Persists or updates a conversation session."""
        pass

    @abstractmethod
    async def list_user_sessions(self, user_id: str, limit: int = 20) -> List[ConversationSession]:
        """Lists recent conversation sessions for a specific user."""
        pass

    @abstractmethod
    async def delete_session(self, session_id: str) -> bool:
        """Deletes a conversation session."""
        pass


class IAIServiceProvider(ABC):
    """Abstract contract for AI model providers (Gemini, Claude, Local LLMs)."""

    @abstractmethod
    async def generate_response(self, prompt: str, context: Optional[str] = None) -> str:
        """Generates a complete text response for a given prompt and context."""
        pass

    @abstractmethod
    async def stream_response(self, prompt: str, context: Optional[str] = None) -> AsyncGenerator[str, None]:
        """Streams text token chunks for a given prompt and context."""
        pass

    @abstractmethod
    def get_provider_name(self) -> str:
        """Returns provider identifier name."""
        pass


class IKnowledgeStore(ABC):
    """Abstract contract for Knowledge Base and RAG Vector Retrieval."""

    @abstractmethod
    async def index_document(self, doc_id: str, content: str, metadata: Optional[Dict] = None) -> bool:
        """Indexes a document or text chunk into the vector store."""
        pass

    @abstractmethod
    async def query_similar_chunks(self, query: str, top_k: int = 3) -> List[Dict]:
        """Retrieves top-K relevant content chunks matching the query string."""
        pass


class ILearningProfileService(ABC):
    """Abstract contract for cognitive mastery calculations and weak spot identification."""

    @abstractmethod
    def calculate_overall_mastery(self, profile: LearningProfile) -> float:
        """Calculates overall student mastery score from topic metrics."""
        pass

    @abstractmethod
    def identify_weak_spots(self, profile: LearningProfile) -> List[TopicMastery]:
        """Identifies topics requiring prioritized spaced revision."""
        pass


class IConversationService(ABC):
    """Abstract contract for Socratic conversation orchestration."""

    @abstractmethod
    async def process_user_message(
        self, session: ConversationSession, user_message_text: str
    ) -> ChatMessage:
        """Processes user input message and returns GARUDA assistant response."""
        pass

    @abstractmethod
    async def stream_socratic_reply(
        self, session: ConversationSession, user_message_text: str
    ) -> AsyncGenerator[str, None]:
        """Streams GARUDA assistant token reply in Socratic dialogue style."""
        pass
