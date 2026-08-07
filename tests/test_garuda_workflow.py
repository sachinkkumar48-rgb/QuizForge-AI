"""
Integration tests for GARUDA AI Learner-Facing Tutor Workflow (Sprint 8.1).
"""
import pytest
from typing import AsyncGenerator, List, Optional
from app.garuda.knowledge import IRetriever, KnowledgeChunk
from app.garuda.orchestrator import GarudaOrchestrator
from app.garuda.providers import BaseAIProvider
from app.garuda.workflow import TutorWorkflow, TutorWorkflowResult


class MockWorkflowAIProvider(BaseAIProvider):
    @property
    def name(self) -> str:
        return "mock_workflow_provider"

    @property
    def capabilities(self) -> set:
        return {"text_generation"}

    async def is_healthy(self) -> bool:
        return True

    def count_tokens(self, text: str) -> int:
        return len(text.split())

    async def generate_response(
        self, prompt: str, system_instruction: Optional[str] = None, context: Optional[str] = None
    ) -> str:
        return "[Mock Tutor AI Response] What is your understanding of fundamental rights?"

    async def stream_response(
        self, prompt: str, system_instruction: Optional[str] = None, context: Optional[str] = None
    ) -> AsyncGenerator[str, None]:
        yield "[Mock Stream]"


class MockWorkflowRetriever(IRetriever):
    async def retrieve_relevant_chunks(self, query: str, top_k: int = 3) -> List[KnowledgeChunk]:
        return [
            KnowledgeChunk(
                chunk_id="chk_workflow_1",
                doc_id="doc_polity",
                text="Article 14 guarantees equality before the law.",
                chunk_index=0,
                embedding=[0.1, 0.2],
            )
        ]


@pytest.mark.anyio
async def test_tutor_workflow_end_to_end():
    mock_provider = MockWorkflowAIProvider()
    mock_retriever = MockWorkflowRetriever()

    orchestrator = GarudaOrchestrator(
        provider=mock_provider,
        retriever=mock_retriever,
    )
    workflow = TutorWorkflow(orchestrator=orchestrator)

    # Execute workflow turn
    result: TutorWorkflowResult = await workflow.execute_turn(
        user_id="user_wf_100",
        topic_id="t_polity_14",
        topic_name="Article 14 Equality",
        user_question="How does Article 14 apply to administrative discretion?",
        is_correct=False,
        confidence=2,
        daily_budget_minutes=120,
        request_id="req_custom_123",
    )

    # 1. Request ID & Sessions
    assert result.request_id == "req_custom_123"
    assert result.user_id == "user_wf_100"
    assert "sess_tutor_" in result.session_id

    # 2. AI Response
    assert "[Mock Tutor AI Response]" in result.ai_response

    # 3. Retrieved Chunks
    assert len(result.retrieved_chunks) == 1
    assert result.retrieved_chunks[0]["chunk_id"] == "chk_workflow_1"

    # 4. Profile Summary
    assert result.profile_summary["topic_id"] == "t_polity_14"
    assert result.profile_summary["total_attempts"] == 1

    # 5. Next Best Action
    assert "id" in result.next_best_action
    assert "rec_type" in result.next_best_action
    assert "priority" in result.next_best_action

    # 6. Revision Summary
    assert result.revision_summary["total_due_items"] == 1

    # 7. Updated Study Plan
    assert result.updated_study_plan["total_study_minutes"] > 0

    # 8. Processing Metadata
    assert result.processing_metadata["turn_number"] == 1
    assert result.processing_metadata["provider_name"] == "mock_workflow_provider"
    assert result.processing_metadata["processing_time_ms"] > 0


@pytest.mark.anyio
async def test_tutor_workflow_multi_turn_session_tracking():
    mock_provider = MockWorkflowAIProvider()
    orchestrator = GarudaOrchestrator(provider=mock_provider)
    workflow = TutorWorkflow(orchestrator=orchestrator)

    # Turn 1
    res1 = await workflow.execute_turn(
        user_id="user_wf_200",
        topic_id="t_history_01",
        topic_name="Ancient History",
        user_question="Tell me about Harappan Civilization",
    )
    assert res1.processing_metadata["turn_number"] == 1

    # Turn 2 (same user & topic)
    res2 = await workflow.execute_turn(
        user_id="user_wf_200",
        topic_id="t_history_01",
        topic_name="Ancient History",
        user_question="What were their main trade routes?",
    )
    assert res2.processing_metadata["turn_number"] == 2
    assert res2.session_id == res1.session_id


@pytest.mark.anyio
async def test_tutor_workflow_auto_request_id_and_session_lifecycle():
    mock_provider = MockWorkflowAIProvider()
    orchestrator = GarudaOrchestrator(provider=mock_provider)
    workflow = TutorWorkflow(orchestrator=orchestrator)

    # Turn without passing explicit request_id
    res = await workflow.execute_turn(
        user_id="user_wf_300",
        topic_id="t_econ_01",
        topic_name="Macroeconomics",
        user_question="Explain GDP vs GNP",
    )
    assert res.request_id.startswith("req_")

    # Verify session retrieval & closure
    session = workflow.get_or_create_session("user_wf_300", "t_econ_01", "Macroeconomics")
    assert session.is_active is True

    closed = workflow.close_session("user_wf_300", "t_econ_01")
    assert closed is not None
    assert closed.is_active is False
    assert workflow.close_session("user_wf_300", "t_econ_01") is None


def test_tutor_workflow_default_orchestrator_initialization():
    from app.garuda.gemini_provider import GeminiProvider
    from app.garuda.providers import AIProviderRegistry
    AIProviderRegistry.register("gemini", GeminiProvider, set_as_default=True)

    workflow = TutorWorkflow()
    assert workflow.orchestrator is not None
    assert workflow.orchestrator.provider.name == "gemini"




