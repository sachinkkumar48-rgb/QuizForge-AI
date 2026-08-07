"""
GARUDA AI Master Integration Orchestrator.

Integrates all 11 GARUDA modules into a coherent, production-ready workflow:
Domain -> Provider Framework -> Gemini Provider -> Conversation Framework -> Agent Framework
-> Knowledge Engine -> Learning Profile Engine -> Recommendation Engine -> Adaptive Revision Engine
-> Smart Study Planner.

Adheres strictly to Clean Architecture, SOLID Principles, and Dependency Inversion.
"""
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Dict, List, Optional, Any

from app.garuda.agents import AgentFactory, BaseAgent, TutorAgent, PlannerAgent
from app.garuda.conversation import (
    ConversationContext,
    PromptBuilder,
    PromptTemplate,
    TutorPersona,
)
from app.garuda.domain import ChatMessage, MessageRole
from app.garuda.knowledge import (
    IEmbeddingService,
    IRetriever,
    IVectorStore,
    InMemoryVectorStore,
    KnowledgeChunk,
    SimpleRetriever,
)
from app.garuda.planner import DailySchedule, StudyPlan, StudyPlannerService
from app.garuda.profile import LearningProfileService, LearningStatistics, TopicProgress
from app.garuda.providers import AIProviderFactory, BaseAIProvider
from app.garuda.recommendation import DailyStudyRecommendation, RecommendationService
from app.garuda.revision import AdaptiveRevisionEngine, RevisionQueue, RevisionSession


@dataclass
class GarudaTutoringResponse:
    """Encapsulates the complete end-to-end result of a GARUDA AI tutoring interaction turn."""
    response_text: str
    retrieved_chunks: List[KnowledgeChunk]
    updated_progress: TopicProgress
    user_statistics: LearningStatistics
    daily_recommendation: DailyStudyRecommendation
    revision_queue: RevisionQueue
    daily_study_plan: DailySchedule
    timestamp: datetime = field(default_factory=lambda: datetime.now(timezone.utc))


class GarudaOrchestrator:
    """
    Master Integration Orchestrator for GARUDA AI.
    Connects domain entities, provider frameworks, prompt builders, RAG knowledge retrieval,
    cognitive profiling, recommendation rules, SM-2 revision queues, and study planning agents.
    """

    def __init__(
        self,
        provider: Optional[BaseAIProvider] = None,
        retriever: Optional[IRetriever] = None,
        profile_service: Optional[LearningProfileService] = None,
        recommendation_service: Optional[RecommendationService] = None,
        planner_service: Optional[StudyPlannerService] = None,
    ):
        self.provider = provider or AIProviderFactory.create("gemini")
        self.retriever = retriever
        self.profile_service = profile_service or LearningProfileService()
        self.recommendation_service = recommendation_service or RecommendationService()
        self.planner_service = planner_service or StudyPlannerService()
        self.prompt_builder = PromptBuilder()

    async def execute_tutoring_turn(
        self,
        user_id: str,
        topic_id: str,
        topic_name: str,
        user_message: str,
        is_correct: bool = True,
        confidence: int = 3,
        daily_budget_minutes: int = 120,
    ) -> GarudaTutoringResponse:
        """
        Executes a complete integrated 7-stage GARUDA workflow:
        1. Knowledge Engine (RAG) -> Conversation Context
        2. Prompt Framework & Persona -> AI Provider
        3. Agent Execution (TutorAgent) -> Response Generation
        4. Learning Profile Engine -> Progress & Statistics Update
        5. Recommendation Engine -> Rule Engine Next Best Action
        6. Adaptive Revision Engine -> Spaced Repetition Queue
        7. Smart Study Planner -> Daily Schedule & Study Plan
        """
        # Step 1: Knowledge Engine Retrieval
        retrieved_chunks: List[KnowledgeChunk] = []
        context_text = ""
        if self.retriever:
            retrieved_chunks = await self.retriever.retrieve_relevant_chunks(user_message, top_k=2)
            context_text = "\n".join([f"[{c.chunk_id}]: {c.text}" for c in retrieved_chunks])

        # Step 2 & 3: Agent Execution via TutorAgent & Provider Framework
        tutor_agent: TutorAgent = AgentFactory.create_agent("tutor", provider=self.provider)  # type: ignore

        context = ConversationContext(
            session_id=f"sess_tutor_{user_id}",
            user_id=user_id,
            system_prompt=f"Persona: SOCRATIC_TUTOR. Topic: {topic_name}",
        )
        if context_text:
            context.add_knowledge_chunk(context_text)
        context.history.append(ChatMessage(id=f"msg_{user_id}_1", role=MessageRole.USER, content=user_message))

        # Agent execution dispatches prompt construction to PromptBuilder and invokes provider
        ai_response_text = await tutor_agent.execute(context)

        # Step 4: Learning Profile Engine Update
        updated_progress = self.profile_service.record_attempt(
            user_id=user_id,
            topic_id=topic_id,
            topic_name=topic_name,
            is_correct=is_correct,
            confidence=confidence,
        )
        user_stats = self.profile_service.compute_statistics(user_id)
        user_progress_map = self.profile_service._progress_store.get(user_id, {})

        # Step 5: Recommendation Engine (Rule Engine NBA)
        daily_rec = self.recommendation_service.generate_daily_recommendation(
            user_id=user_id,
            stats=user_stats,
            progress_map=user_progress_map,
        )

        # Step 6: Adaptive Revision Engine (SM-2 Spaced Repetition Queue)
        rev_queue = AdaptiveRevisionEngine.build_revision_queue(
            user_id=user_id,
            progress_map=user_progress_map,
            daily_limit=20,
        )

        # Step 7: Smart Study Planner (Daily Schedule & Study Plan)
        daily_plan = self.planner_service.create_daily_plan(
            user_id=user_id,
            daily_budget_minutes=daily_budget_minutes,
            revision_queue=rev_queue,
            daily_recommendation=daily_rec,
            progress_map=user_progress_map,
        )

        return GarudaTutoringResponse(
            response_text=ai_response_text,
            retrieved_chunks=retrieved_chunks,
            updated_progress=updated_progress,
            user_statistics=user_stats,
            daily_recommendation=daily_rec,
            revision_queue=rev_queue,
            daily_study_plan=daily_plan,
        )
