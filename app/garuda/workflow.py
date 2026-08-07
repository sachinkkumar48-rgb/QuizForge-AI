"""
GARUDA AI Learner-Facing Tutor Workflow.

Implements TutorWorkflow, TutorSession, and TutorWorkflowResult.

Orchestrates user learning interactions by invoking the underlying GarudaOrchestrator.
Does NOT bypass existing engines, call AI SDKs directly, or duplicate business logic.
Follows Clean Architecture, SOLID Principles, and the Orchestrator Pattern.
"""
import uuid
import time
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from app.garuda.orchestrator import GarudaOrchestrator, GarudaTutoringResponse


@dataclass
class TutorSession:
    """Represents an active learner-facing tutoring session."""
    session_id: str
    user_id: str
    topic_id: str
    topic_name: str
    started_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
    turns_count: int = 0
    is_active: bool = True

    def increment_turn(self) -> None:
        self.turns_count += 1


@dataclass
class TutorWorkflowResult:
    """Production-ready structured result container for learner tutoring interactions."""
    request_id: str
    session_id: str
    user_id: str
    ai_response: str
    retrieved_chunks: List[Dict[str, Any]]
    profile_summary: Dict[str, Any]
    next_best_action: Dict[str, Any]
    revision_summary: Dict[str, Any]
    updated_study_plan: Dict[str, Any]
    processing_metadata: Dict[str, Any]
    timestamp: datetime = field(default_factory=lambda: datetime.now(timezone.utc))


class TutorWorkflow:
    """
    Learner-facing workflow engine for GARUDA AI tutoring turns.
    Delegates pipeline execution exclusively to GarudaOrchestrator.
    """

    def __init__(self, orchestrator: Optional[GarudaOrchestrator] = None):
        self.orchestrator = orchestrator or GarudaOrchestrator()
        self._active_sessions: Dict[str, TutorSession] = {}

    def get_or_create_session(self, user_id: str, topic_id: str, topic_name: str) -> TutorSession:
        """Retrieves or initializes an active TutorSession."""
        session_key = f"{user_id}_{topic_id}"
        if session_key not in self._active_sessions:
            self._active_sessions[session_key] = TutorSession(
                session_id=f"sess_tutor_{uuid.uuid4().hex[:8]}",
                user_id=user_id,
                topic_id=topic_id,
                topic_name=topic_name,
            )
        return self._active_sessions[session_key]

    def close_session(self, user_id: str, topic_id: str) -> Optional[TutorSession]:
        """Closes an active TutorSession and marks it inactive."""
        session_key = f"{user_id}_{topic_id}"
        session = self._active_sessions.get(session_key)
        if session:
            session.is_active = False
            del self._active_sessions[session_key]
        return session

    async def execute_turn(
        self,
        user_id: str,
        topic_id: str,
        topic_name: str,
        user_question: str,
        is_correct: bool = True,
        confidence: int = 3,
        daily_budget_minutes: int = 120,
        request_id: Optional[str] = None,
    ) -> TutorWorkflowResult:
        """
        Executes a complete learner-facing tutoring turn:
        User Question -> Orchestrator -> Complete Workflow -> TutorWorkflowResult.
        """
        req_id = request_id or f"req_{uuid.uuid4().hex[:10]}"
        start_time = time.perf_counter()

        session = self.get_or_create_session(user_id, topic_id, topic_name)
        session.increment_turn()

        # Delegate workflow execution directly to GarudaOrchestrator
        orch_response: GarudaTutoringResponse = await self.orchestrator.execute_tutoring_turn(
            user_id=user_id,
            topic_id=topic_id,
            topic_name=topic_name,
            user_message=user_question,
            is_correct=is_correct,
            confidence=confidence,
            daily_budget_minutes=daily_budget_minutes,
        )

        elapsed_ms = round((time.perf_counter() - start_time) * 1000, 2)

        # Assemble structured TutorWorkflowResult payload
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
            "provider_name": self.orchestrator.provider.name,
            "chunks_retrieved_count": len(orch_response.retrieved_chunks),
        }

        return TutorWorkflowResult(
            request_id=req_id,
            session_id=session.session_id,
            user_id=user_id,
            ai_response=orch_response.response_text,
            retrieved_chunks=retrieved_chunks_summary,
            profile_summary=profile_summary,
            next_best_action=next_best_action_summary,
            revision_summary=revision_summary,
            updated_study_plan=study_plan_summary,
            processing_metadata=processing_metadata,
        )
