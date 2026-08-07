"""
GARUDA AI Learner-Facing PDF Knowledge Workflow (Sprint 8.1 / TITAN-S8.1.002).

Implements PDFKnowledgeWorkflow, PDFKnowledgeSession, and PDFKnowledgeWorkflowResult.

Orchestrates user PDF document grounding and learning interactions by performing RAG ingestion
(chunking, embedding, vector storage) and delegating execution exclusively through GarudaOrchestrator.

Follows Clean Architecture, SOLID Principles, and the Orchestrator Pattern.
Does NOT call Gemini SDK directly, access vector DBs directly, or duplicate core business logic.
"""
import time
import uuid
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from app.garuda.knowledge import (
    IChunkingService,
    IEmbeddingService,
    InMemoryVectorStore,
    IVectorStore,
    KnowledgeChunk,
    KnowledgeDocument,
    SimpleRetriever,
)
from app.garuda.orchestrator import GarudaOrchestrator, GarudaTutoringResponse


class SimpleChunkingService(IChunkingService):
    """Reference implementation of IChunkingService for splitting documents into text chunks."""

    def chunk_document(
        self, doc: KnowledgeDocument, chunk_size: int = 500, overlap: int = 50
    ) -> List[KnowledgeChunk]:
        """Splits a KnowledgeDocument into a sequence of KnowledgeChunks."""
        if not doc.content:
            return []

        chunks: List[KnowledgeChunk] = []
        text = doc.content
        start = 0
        idx = 0
        step = max(1, chunk_size - overlap)

        while start < len(text):
            end = min(len(text), start + chunk_size)
            chunk_text = text[start:end]
            chunks.append(
                KnowledgeChunk(
                    chunk_id=f"{doc.doc_id}_chk_{idx}",
                    doc_id=doc.doc_id,
                    text=chunk_text,
                    chunk_index=idx,
                    metadata={"title": doc.title, "doc_type": doc.doc_type, **doc.metadata},
                )
            )
            idx += 1
            if end == len(text):
                break
            start += step

        return chunks


@dataclass
class PDFKnowledgeSession:
    """Represents an active PDF document knowledge tutoring session."""
    session_id: str
    user_id: str
    document_id: str
    document_name: str
    started_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
    chunks_count: int = 0
    turns_count: int = 0
    is_active: bool = True

    def increment_turn(self) -> None:
        self.turns_count += 1


@dataclass
class PDFKnowledgeWorkflowResult:
    """Production-ready structured result container for PDF knowledge interactions."""
    request_id: str
    session_id: str
    document_id: str
    document_name: str
    retrieved_chunks: List[Dict[str, Any]]
    ai_response: str
    profile_summary: Dict[str, Any]
    next_best_action: Dict[str, Any]
    revision_summary: Dict[str, Any]
    updated_study_plan: Dict[str, Any]
    processing_metadata: Dict[str, Any]
    timestamp: datetime = field(default_factory=lambda: datetime.now(timezone.utc))


class PDFKnowledgeWorkflow:
    """
    Learner-facing PDF Knowledge Workflow engine for GARUDA AI.
    Orchestrates PDF text chunking, embedding generation, vector storage, RAG retrieval,
    and delegates pipeline execution exclusively to GarudaOrchestrator.
    """

    def __init__(
        self,
        orchestrator: Optional[GarudaOrchestrator] = None,
        chunking_service: Optional[IChunkingService] = None,
        embedding_service: Optional[IEmbeddingService] = None,
        vector_store: Optional[IVectorStore] = None,
    ):
        self.orchestrator = orchestrator or GarudaOrchestrator()
        self.chunking_service = chunking_service or SimpleChunkingService()
        self.embedding_service = embedding_service
        self.vector_store = vector_store or InMemoryVectorStore()
        self._active_sessions: Dict[str, PDFKnowledgeSession] = {}

    def get_or_create_session(
        self, user_id: str, document_id: str, document_name: str
    ) -> PDFKnowledgeSession:
        """Retrieves or initializes an active PDFKnowledgeSession."""
        session_key = f"{user_id}_{document_id}"
        if session_key not in self._active_sessions:
            self._active_sessions[session_key] = PDFKnowledgeSession(
                session_id=f"sess_pdf_{uuid.uuid4().hex[:8]}",
                user_id=user_id,
                document_id=document_id,
                document_name=document_name,
            )
        return self._active_sessions[session_key]

    def close_session(self, user_id: str, document_id: str) -> Optional[PDFKnowledgeSession]:
        """Closes an active PDFKnowledgeSession and marks it inactive."""
        session_key = f"{user_id}_{document_id}"
        session = self._active_sessions.get(session_key)
        if session:
            session.is_active = False
            del self._active_sessions[session_key]
        return session

    async def process_pdf(
        self,
        user_id: str,
        document_id: str,
        document_name: str,
        pdf_content: str,
        user_question: str,
        is_correct: bool = True,
        confidence: int = 3,
        daily_budget_minutes: int = 120,
        request_id: Optional[str] = None,
    ) -> PDFKnowledgeWorkflowResult:
        """
        Executes a complete PDF Grounded Knowledge Tutoring Workflow:
        PDF Upload -> Chunk Document -> Generate Embeddings -> Store in Vector Store
        -> Retrieve Relevant Chunks -> Conversation Context -> Prompt Builder
        -> Tutor Agent -> Gemini Provider -> Learning Profile Update
        -> Recommendation Update -> Revision Queue Update -> Study Plan Update
        -> PDFKnowledgeWorkflowResult.
        """
        req_id = request_id or f"req_pdf_{uuid.uuid4().hex[:10]}"
        start_time = time.perf_counter()

        session = self.get_or_create_session(user_id, document_id, document_name)
        session.increment_turn()

        # Step 1 & 2: PDF Document creation & Chunking
        doc = KnowledgeDocument(
            doc_id=document_id,
            title=document_name,
            content=pdf_content,
            doc_type="pdf",
        )
        chunks = self.chunking_service.chunk_document(doc)
        session.chunks_count = len(chunks)

        # Step 3: Embeddings generation & Vector Store persistence
        if self.embedding_service and chunks:
            embedded_chunks = await self.embedding_service.embed_chunks(chunks)
            await self.vector_store.add_chunks(embedded_chunks)

            # Bind SimpleRetriever with embedding service and vector store to orchestrator
            retriever = SimpleRetriever(
                embedding_service=self.embedding_service,
                vector_store=self.vector_store,
            )
            self.orchestrator.retriever = retriever

        # Step 4-10: Delegate tutoring turn directly to GarudaOrchestrator
        orch_response: GarudaTutoringResponse = await self.orchestrator.execute_tutoring_turn(
            user_id=user_id,
            topic_id=document_id,
            topic_name=document_name,
            user_message=user_question,
            is_correct=is_correct,
            confidence=confidence,
            daily_budget_minutes=daily_budget_minutes,
        )

        elapsed_ms = round((time.perf_counter() - start_time) * 1000, 2)

        # Step 11: Assemble structured PDFKnowledgeWorkflowResult payload
        retrieved_chunks_summary = [
            {"chunk_id": c.chunk_id, "doc_id": c.doc_id, "snippet": c.text[:100]}
            for c in orch_response.retrieved_chunks
        ]

        profile_summary = {
            "topic_id": orch_response.updated_progress.topic_id,
            "topic_name": orch_response.updated_progress.topic_name,
            "mastery_score": orch_response.updated_progress.mastery_score,
            "accuracy_rate": orch_response.updated_progress.accuracy_rate,
            "total_attempts": orch_response.updated_progress.total_attempts,
            "overall_mastery": orch_response.user_statistics.overall_mastery,
            "study_streak_days": orch_response.user_statistics.study_streak_days,
        }

        nba = orch_response.daily_recommendation.next_best_action
        next_best_action_summary = {
            "id": nba.id,
            "rec_type": nba.rec_type.value,
            "title": nba.title,
            "description": nba.description,
            "priority": nba.priority.name,
            "reason": nba.reason.value,
            "confidence_score": nba.confidence_score,
        }

        revision_summary = {
            "total_due_items": orch_response.revision_queue.total_due,
            "queue_size": len(orch_response.revision_queue.items),
            "urgent_items_count": sum(
                1 for i in orch_response.revision_queue.items if i.priority.name == "URGENT"
            ),
        }

        study_plan_summary = {
            "date_str": orch_response.daily_study_plan.date_str,
            "total_study_minutes": orch_response.daily_study_plan.total_study_minutes,
            "revision_minutes": orch_response.daily_study_plan.revision_minutes,
            "learning_minutes": orch_response.daily_study_plan.learning_minutes,
            "quiz_minutes": orch_response.daily_study_plan.quiz_minutes,
            "task_count": len(orch_response.daily_study_plan.tasks),
        }

        processing_metadata = {
            "processing_time_ms": elapsed_ms,
            "turn_number": session.turns_count,
            "chunks_ingested_count": len(chunks),
            "provider_name": self.orchestrator.provider.name,
            "chunks_retrieved_count": len(orch_response.retrieved_chunks),
        }

        return PDFKnowledgeWorkflowResult(
            request_id=req_id,
            session_id=session.session_id,
            document_id=document_id,
            document_name=document_name,
            retrieved_chunks=retrieved_chunks_summary,
            ai_response=orch_response.response_text,
            profile_summary=profile_summary,
            next_best_action=next_best_action_summary,
            revision_summary=revision_summary,
            updated_study_plan=study_plan_summary,
            processing_metadata=processing_metadata,
        )

    async def execute_turn(
        self,
        user_id: str,
        document_id: str,
        document_name: str,
        pdf_content: str,
        user_question: str,
        is_correct: bool = True,
        confidence: int = 3,
        daily_budget_minutes: int = 120,
        request_id: Optional[str] = None,
    ) -> PDFKnowledgeWorkflowResult:
        """Alias for process_pdf to support standardized turn execution."""
        return await self.process_pdf(
            user_id=user_id,
            document_id=document_id,
            document_name=document_name,
            pdf_content=pdf_content,
            user_question=user_question,
            is_correct=is_correct,
            confidence=confidence,
            daily_budget_minutes=daily_budget_minutes,
            request_id=request_id,
        )
