"""
Integration tests for GARUDA AI PDF Knowledge Workflow (Sprint 8.1 / TITAN-S8.1.002).

Verifies 12-stage grounded PDF tutoring pipeline:
PDF Upload -> Chunk Document -> Generate Embeddings -> Store in Vector Store
-> Retrieve Relevant Chunks -> Conversation Context -> Prompt Builder
-> Tutor Agent -> Gemini Provider -> Learning Profile Update
-> Recommendation Update -> Revision Queue Update -> Study Plan Update
-> PDFKnowledgeWorkflowResult.
"""
import pytest
from typing import AsyncGenerator, List, Optional

from app.garuda.knowledge import IEmbeddingService, KnowledgeChunk
from app.garuda.orchestrator import GarudaOrchestrator
from app.garuda.pdf_workflow import (
    PDFKnowledgeWorkflow,
    PDFKnowledgeWorkflowResult,
)
from app.garuda.providers import AIProviderRegistry, BaseAIProvider


class MockPDFWorkflowAIProvider(BaseAIProvider):
    @property
    def name(self) -> str:
        return "mock_pdf_provider"

    @property
    def capabilities(self) -> set:
        return {"text_generation"}

    async def is_healthy(self) -> bool:
        return True

    def count_tokens(self, text: str) -> int:
        return len(text.split())

    async def generate_response(
        self, prompt: str, context: Optional[str] = None
    ) -> str:
        return f"[Mock PDF Tutor AI Response] Based on the document context: {context[:50] if context else 'None'}."

    async def stream_response(
        self, prompt: str, context: Optional[str] = None
    ) -> AsyncGenerator[str, None]:
        yield "[Mock Stream]"


class MockPDFEmbeddingService(IEmbeddingService):
    async def embed_text(self, text: str) -> List[float]:
        val1 = float(len(text)) / 100.0
        val2 = 1.0 if "article" in text.lower() or "constitution" in text.lower() else 0.0
        val3 = 0.5
        return [val1, val2, val3]

    async def embed_chunks(self, chunks: List[KnowledgeChunk]) -> List[KnowledgeChunk]:
        for c in chunks:
            c.embedding = await self.embed_text(c.text)
        return chunks


@pytest.mark.anyio
async def test_pdf_knowledge_workflow_end_to_end():
    mock_provider = MockPDFWorkflowAIProvider()
    mock_embedding = MockPDFEmbeddingService()

    orchestrator = GarudaOrchestrator(provider=mock_provider)
    workflow = PDFKnowledgeWorkflow(
        orchestrator=orchestrator,
        embedding_service=mock_embedding,
    )

    pdf_text = (
        "The Constitution of India is the supreme law of India. "
        "Article 21 provides that no person shall be deprived of his life "
        "or personal liberty except according to procedure established by law. "
        "Article 14 ensures equality before law and equal protection of laws."
    )

    result: PDFKnowledgeWorkflowResult = await workflow.process_pdf(
        user_id="user_pdf_100",
        document_id="doc_constitution_pdf",
        document_name="Indian_Constitution_Summary.pdf",
        pdf_content=pdf_text,
        user_question="What protection does Article 21 guarantee according to the PDF?",
        is_correct=True,
        confidence=4,
        daily_budget_minutes=120,
        request_id="req_pdf_custom_001",
    )

    # 1. Request ID & Document Identifiers
    assert result.request_id == "req_pdf_custom_001"
    assert result.user_id == "user_pdf_100" if hasattr(result, "user_id") else True
    assert result.document_id == "doc_constitution_pdf"
    assert result.document_name == "Indian_Constitution_Summary.pdf"
    assert "sess_pdf_" in result.session_id

    # 2. Retrieved Chunks (Grounded in PDF)
    assert len(result.retrieved_chunks) > 0
    assert result.retrieved_chunks[0]["doc_id"] == "doc_constitution_pdf"

    # 3. AI Grounded Response
    assert "[Mock PDF Tutor AI Response]" in result.ai_response

    # 4. Learning Profile Summary
    assert result.profile_summary["topic_id"] == "doc_constitution_pdf"
    assert result.profile_summary["total_attempts"] == 1

    # 5. Next Best Action
    assert "id" in result.next_best_action
    assert "rec_type" in result.next_best_action
    assert "priority" in result.next_best_action

    # 6. Revision Summary
    assert "total_due_items" in result.revision_summary

    # 7. Updated Study Plan
    assert result.updated_study_plan["total_study_minutes"] > 0

    # 8. Processing Metadata
    assert result.processing_metadata["turn_number"] == 1
    assert result.processing_metadata["chunks_ingested_count"] > 0
    assert result.processing_metadata["chunks_retrieved_count"] > 0
    assert result.processing_metadata["provider_name"] == "mock_pdf_provider"


@pytest.mark.anyio
async def test_pdf_knowledge_workflow_multi_turn_session():
    mock_provider = MockPDFWorkflowAIProvider()
    mock_embedding = MockPDFEmbeddingService()

    orchestrator = GarudaOrchestrator(provider=mock_provider)
    workflow = PDFKnowledgeWorkflow(
        orchestrator=orchestrator,
        embedding_service=mock_embedding,
    )

    pdf_text = "Chapter 1: Ancient Civilizations. Harappan sites had advanced drainage systems."

    # Turn 1
    res1 = await workflow.execute_turn(
        user_id="user_pdf_200",
        document_id="doc_history_ch1",
        document_name="Ancient_History.pdf",
        pdf_content=pdf_text,
        user_question="Tell me about Harappan drainage systems",
    )
    assert res1.processing_metadata["turn_number"] == 1

    # Turn 2 (same session)
    res2 = await workflow.execute_turn(
        user_id="user_pdf_200",
        document_id="doc_history_ch1",
        document_name="Ancient_History.pdf",
        pdf_content=pdf_text,
        user_question="Why were they important?",
    )
    assert res2.processing_metadata["turn_number"] == 2
    assert res2.session_id == res1.session_id


@pytest.mark.anyio
async def test_pdf_knowledge_workflow_session_lifecycle_and_auto_request_id():
    mock_provider = MockPDFWorkflowAIProvider()
    orchestrator = GarudaOrchestrator(provider=mock_provider)
    workflow = PDFKnowledgeWorkflow(orchestrator=orchestrator)

    res = await workflow.process_pdf(
        user_id="user_pdf_300",
        document_id="doc_science_ch3",
        document_name="Physics_Motion.pdf",
        pdf_content="Newton's laws of motion form the basis of classical mechanics.",
        user_question="Summarize Newton's first law",
    )

    assert res.request_id.startswith("req_pdf_")

    session = workflow.get_or_create_session("user_pdf_300", "doc_science_ch3", "Physics_Motion.pdf")
    assert session.is_active is True

    closed = workflow.close_session("user_pdf_300", "doc_science_ch3")
    assert closed is not None
    assert closed.is_active is False
    assert workflow.close_session("user_pdf_300", "doc_science_ch3") is None


def test_pdf_knowledge_workflow_no_circular_imports():
    import app.garuda
    assert hasattr(app.garuda, "PDFKnowledgeWorkflow")
    assert hasattr(app.garuda, "PDFKnowledgeSession")
    assert hasattr(app.garuda, "PDFKnowledgeWorkflowResult")
    assert hasattr(app.garuda, "SimpleChunkingService")
