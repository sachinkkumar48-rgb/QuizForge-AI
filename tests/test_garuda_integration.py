"""
End-to-End Integration Tests for GARUDA AI Master Architecture (Sprint 8.0).

Verifies 7 integrated workflow stages:
Tutor Agent -> Prompt Builder -> Knowledge Engine -> Gemini Provider -> Recommendation Engine
-> Revision Engine -> Study Planner.
"""
import pytest
from typing import AsyncGenerator, List, Optional
from unittest.mock import AsyncMock, MagicMock

from app.garuda.domain import MessageRole
from app.garuda.knowledge import IEmbeddingService, IRetriever, KnowledgeChunk
from app.garuda.orchestrator import GarudaOrchestrator, GarudaTutoringResponse
from app.garuda.providers import BaseAIProvider


class MockAIProvider(BaseAIProvider):
    """Mock AI Provider for zero-network integration testing."""

    @property
    def name(self) -> str:
        return "mock_gemini"

    @property
    def capabilities(self) -> set:
        return {"text_generation", "streaming"}

    async def is_healthy(self) -> bool:
        return True

    def count_tokens(self, text: str) -> int:
        return len(text.split())

    async def generate_response(
        self, prompt: str, system_instruction: Optional[str] = None, context: Optional[str] = None
    ) -> str:
        return f"[Mock Tutor Response] Understood topic. Relevant context: {context or 'None'}."

    async def stream_response(
        self, prompt: str, system_instruction: Optional[str] = None, context: Optional[str] = None
    ) -> AsyncGenerator[str, None]:
        yield "[Mock Stream Chunk]"


class MockRetriever(IRetriever):
    """Mock Knowledge Engine Retriever."""

    async def retrieve_relevant_chunks(self, query: str, top_k: int = 3) -> List[KnowledgeChunk]:
        return [
            KnowledgeChunk(
                chunk_id="chunk_101",
                doc_id="doc_polity",
                text="Article 21 guarantees protection of life and personal liberty.",
                chunk_index=0,
                embedding=[0.1, 0.2, 0.3],
            )
        ]


@pytest.mark.anyio
async def test_garuda_end_to_end_orchestration_flow():
    mock_provider = MockAIProvider()
    mock_retriever = MockRetriever()

    orchestrator = GarudaOrchestrator(
        provider=mock_provider,
        retriever=mock_retriever,
    )

    # Execute complete tutoring turn
    response: GarudaTutoringResponse = await orchestrator.execute_tutoring_turn(
        user_id="user_test_800",
        topic_id="t_polity_21",
        topic_name="Article 21 Rights",
        user_message="Can you explain Article 21 with Socratic questions?",
        is_correct=False,  # Weak attempt to trigger revision & recommendations
        confidence=2,
        daily_budget_minutes=120,
    )

    # 1. Verify AI Response & Agent Execution
    assert "[Mock Tutor Response]" in response.response_text
    assert len(response.retrieved_chunks) == 1
    assert response.retrieved_chunks[0].chunk_id == "chunk_101"

    # 2. Verify Learning Profile Update
    assert response.updated_progress.topic_id == "t_polity_21"
    assert response.updated_progress.total_attempts == 1
    assert response.updated_progress.correct_attempts == 0
    assert response.user_statistics.total_questions_answered == 1

    # 3. Verify Recommendation Engine
    assert response.daily_recommendation.next_best_action is not None
    assert len(response.daily_recommendation.recommendations) > 0

    # 4. Verify Adaptive Revision Engine Queue
    assert response.revision_queue.total_due == 1
    assert len(response.revision_queue.items) == 1
    assert response.revision_queue.items[0].topic_id == "t_polity_21"

    # 5. Verify Smart Study Planner Daily Schedule
    assert response.daily_study_plan.total_study_minutes > 0
    assert response.daily_study_plan.revision_minutes == 15
    assert len(response.daily_study_plan.tasks) >= 3


def test_garuda_no_circular_imports():
    import app.garuda
    assert hasattr(app.garuda, "GarudaOrchestrator")
    assert hasattr(app.garuda, "BaseAIProvider")
    assert hasattr(app.garuda, "BaseAgent")
    assert hasattr(app.garuda, "KnowledgeDocument")
    assert hasattr(app.garuda, "LearningProfileService")
    assert hasattr(app.garuda, "RecommendationService")
    assert hasattr(app.garuda, "AdaptiveRevisionEngine")
    assert hasattr(app.garuda, "StudyPlannerService")
