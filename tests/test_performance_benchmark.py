"""
Repeatable Backend Performance Audit & Benchmark Test Suite (TITAN-S9.0.001).

Profiles the existing GARUDA AI backend engines and measures:
- Per-stage latency execution times
- Statistical latency summaries (Average, Median, P95, P99, Standard Deviation)
- CPU call counts and hotspot functions via cProfile
- Memory allocation sizes and peak memory usage via tracemalloc
"""
import asyncio
import time
import pytest
from typing import AsyncGenerator, Dict, List, Optional, Any

from app.core.performance_profiler import (
    BenchmarkStatistics,
    CPUProfiler,
    MemoryProfiler,
    StageTimer,
)
from app.garuda.agents import AgentFactory, TutorAgent
from app.garuda.conversation import ConversationContext, PromptBuilder
from app.garuda.domain import ChatMessage, MessageRole
from app.garuda.knowledge import (
    InMemoryVectorStore,
    KnowledgeChunk,
    KnowledgeDocument,
    SimpleRetriever,
)
from app.garuda.orchestrator import GarudaOrchestrator
from app.garuda.pdf_workflow import PDFKnowledgeWorkflow, SimpleChunkingService
from app.garuda.planner import StudyPlannerService
from app.garuda.profile import (
    LearningProfileService,
    LearningStatistics,
    TopicProgress,
    WeakTopicDetector,
)
from app.garuda.providers import BaseAIProvider
from app.garuda.recommendation import RecommendationService
from app.garuda.revision import AdaptiveRevisionEngine


class MockAIProvider(BaseAIProvider):
    """Mock AI Provider for repeatable deterministic performance benchmarking."""

    def __init__(self, response_text: str = "Mock AI Socratic response.", config: Optional[Dict] = None):
        super().__init__(config=config)
        self._response_text = response_text

    @property
    def name(self) -> str:
        return "mock_ai"

    async def generate_response(self, prompt: str, context: Optional[str] = None) -> str:
        return f"{self._response_text} for prompt: {prompt[:30]}"

    async def stream_response(self, prompt: str, context: Optional[str] = None) -> AsyncGenerator[str, None]:
        yield self._response_text


@pytest.mark.anyio
async def test_tutor_workflow_performance_profile():
    """Profiles Tutor Workflow across all 10 stages and computes latency stats."""
    mock_provider = MockAIProvider(response_text="Socratic guidance answer.")
    orchestrator = GarudaOrchestrator(provider=mock_provider)

    samples_ms: List[float] = []

    for _ in range(30):
        timer = StageTimer()

        timer.start_stage("1. Session Initialization")
        user_id = "user_perf_1"
        topic_id = "top_polity_21"
        topic_name = "Article 21 Rights"
        user_msg = "Explain key rights guaranteed under Article 21"

        timer.start_stage("2. Conversation Context")
        context = ConversationContext(
            session_id=f"sess_{user_id}",
            user_id=user_id,
            system_prompt=f"Topic: {topic_name}",
        )
        context.history.append(ChatMessage(id="msg_1", role=MessageRole.USER, content=user_msg))

        timer.start_stage("3. Prompt Construction")
        prompt = orchestrator.prompt_builder.with_context(context).build()
        assert len(prompt) > 0

        timer.start_stage("4. Knowledge Retrieval")
        retrieved_chunks = []
        if orchestrator.retriever:
            retrieved_chunks = await orchestrator.retriever.retrieve_relevant_chunks(user_msg, top_k=2)

        timer.start_stage("5. Agent Execution")
        tutor_agent = TutorAgent(provider=mock_provider)

        timer.start_stage("6. Provider Invocation")
        response_text = await tutor_agent.execute(context)
        assert len(response_text) > 0

        timer.start_stage("7. Learning Profile Update")
        progress = orchestrator.profile_service.record_attempt(
            user_id=user_id,
            topic_id=topic_id,
            topic_name=topic_name,
            is_correct=True,
            confidence=4,
        )
        stats = orchestrator.profile_service.compute_statistics(user_id)

        timer.start_stage("8. Recommendation Generation")
        progress_map = orchestrator.profile_service._progress_store.get(user_id, {})
        recommendation = orchestrator.recommendation_service.generate_daily_recommendation(
            user_id=user_id,
            stats=stats,
            progress_map=progress_map,
        )

        timer.start_stage("9. Revision Queue Update")
        rev_queue = AdaptiveRevisionEngine.build_revision_queue(
            user_id=user_id,
            progress_map=progress_map,
            daily_limit=20,
        )

        timer.start_stage("10. Study Plan Generation")
        daily_plan = orchestrator.planner_service.create_daily_plan(
            user_id=user_id,
            daily_budget_minutes=120,
            revision_queue=rev_queue,
            daily_recommendation=recommendation,
            progress_map=progress_map,
        )
        timer.end_stage()

        summary = timer.get_summary()
        samples_ms.append(summary["total_ms"])

    metrics = BenchmarkStatistics.calculate(samples_ms)
    assert metrics.count == 30
    assert metrics.mean_ms >= 0.0
    assert metrics.median_ms >= 0.0
    assert metrics.p95_ms >= 0.0
    assert metrics.p99_ms >= 0.0


@pytest.mark.anyio
async def test_pdf_workflow_performance_profile():
    """Profiles PDF Knowledge Workflow stages and measures execution latencies."""
    mock_provider = MockAIProvider(response_text="PDF response text.")
    orchestrator = GarudaOrchestrator(provider=mock_provider)
    pdf_wf = PDFKnowledgeWorkflow(orchestrator=orchestrator)

    samples_ms: List[float] = []

    pdf_text = "Indian Constitution Article 14 guarantees Equality Before Law. Article 21 protects Personal Liberty." * 10

    for i in range(20):
        t0 = time.perf_counter()

        res = await pdf_wf.process_pdf(
            user_id="user_pdf_perf",
            document_id=f"doc_{i}",
            document_name="Constitution_Summary.pdf",
            pdf_content=pdf_text,
            user_question="What is Article 14?",
            is_correct=True,
            confidence=4,
        )

        t1 = time.perf_counter()
        samples_ms.append((t1 - t0) * 1000)
        assert res.session_id.startswith("sess_pdf_")

    metrics = BenchmarkStatistics.calculate(samples_ms)
    assert metrics.count == 20
    assert metrics.mean_ms > 0.0


def test_knowledge_engine_vector_search_profile():
    """Profiles Knowledge Engine vector search and cosine similarity latency."""
    vector_store = InMemoryVectorStore()
    chunk_service = SimpleChunkingService()

    doc = KnowledgeDocument(
        doc_id="doc_polity",
        title="Polity Notes",
        content="Fundamental rights fundamental duties directive principles preamble amendments" * 50,
        doc_type="text",
    )
    chunks = chunk_service.chunk_document(doc, chunk_size=100, overlap=10)

    # Attach dummy embeddings for vector similarity search
    for c in chunks:
        c.embedding = [0.1, 0.2, 0.3, 0.4]

    asyncio.run(vector_store.add_chunks(chunks))

    samples_ms: List[float] = []

    for _ in range(50):
        t0 = time.perf_counter()
        results = asyncio.run(vector_store.query_similar([0.1, 0.2, 0.3, 0.4], top_k=5))
        t1 = time.perf_counter()
        samples_ms.append((t1 - t0) * 1000)
        assert len(results) > 0

    metrics = BenchmarkStatistics.calculate(samples_ms)
    assert metrics.count == 50
    assert metrics.mean_ms >= 0.0


def test_learning_profile_mastery_calculation_profile():
    """Profiles Learning Profile Engine mastery score computation and stats generation."""
    profile_service = LearningProfileService()
    user_id = "user_mastery_test"

    for i in range(100):
        profile_service.record_attempt(
            user_id=user_id,
            topic_id=f"topic_{i % 10}",
            topic_name=f"Topic Name {i % 10}",
            is_correct=(i % 3 != 0),
            confidence=(i % 4) + 1,
        )

    samples_ms: List[float] = []

    def run_calc():
        stats = profile_service.compute_statistics(user_id)
        weak = WeakTopicDetector.detect_weak(profile_service._progress_store[user_id])
        return stats.total_questions_answered > 0 and len(weak) >= 0

    for _ in range(50):
        t0 = time.perf_counter()
        run_calc()
        t1 = time.perf_counter()
        samples_ms.append((t1 - t0) * 1000)

    metrics = BenchmarkStatistics.calculate(samples_ms)
    assert metrics.count == 50
    assert metrics.mean_ms >= 0.0


def test_recommendation_engine_rule_evaluation_profile():
    """Profiles Recommendation Engine rule evaluation and sorting latencies."""
    rec_service = RecommendationService()
    profile_service = LearningProfileService()
    user_id = "user_rec_test"

    for i in range(20):
        profile_service.record_attempt(
            user_id=user_id,
            topic_id=f"t_{i}",
            topic_name=f"Topic {i}",
            is_correct=(i % 2 == 0),
            confidence=3,
        )

    stats = profile_service.compute_statistics(user_id)
    progress_map = profile_service._progress_store[user_id]

    samples_ms: List[float] = []

    for _ in range(50):
        t0 = time.perf_counter()
        rec = rec_service.generate_daily_recommendation(
            user_id=user_id,
            stats=stats,
            progress_map=progress_map,
        )
        t1 = time.perf_counter()
        samples_ms.append((t1 - t0) * 1000)
        assert len(rec.recommendations) >= 0

    metrics = BenchmarkStatistics.calculate(samples_ms)
    assert metrics.count == 50
    assert metrics.mean_ms >= 0.0


def test_revision_engine_sm2_scheduling_profile():
    """Profiles Adaptive Revision Engine SM-2 queue construction and priority ordering."""
    progress_map: Dict[str, TopicProgress] = {}
    for i in range(50):
        progress_map[f"t_{i}"] = TopicProgress(
            topic_id=f"t_{i}",
            topic_name=f"Topic {i}",
            total_attempts=10,
            correct_attempts=6,
            avg_confidence=2.5,
            mastery_score=0.45,
        )

    samples_ms: List[float] = []

    for _ in range(50):
        t0 = time.perf_counter()
        queue = AdaptiveRevisionEngine.build_revision_queue(
            user_id="user_rev_test",
            progress_map=progress_map,
            daily_limit=25,
        )
        t1 = time.perf_counter()
        samples_ms.append((t1 - t0) * 1000)
        assert len(queue.items) > 0

    metrics = BenchmarkStatistics.calculate(samples_ms)
    assert metrics.count == 50
    assert metrics.mean_ms >= 0.0


def test_study_planner_schedule_generation_profile():
    """Profiles Study Planner Service daily and weekly schedule construction."""
    planner = StudyPlannerService()
    progress_map: Dict[str, TopicProgress] = {
        f"t_{i}": TopicProgress(
            topic_id=f"t_{i}",
            topic_name=f"Topic {i}",
            mastery_score=0.5,
        )
        for i in range(15)
    }

    stats = LearningStatistics()
    rev_queue = AdaptiveRevisionEngine.build_revision_queue("u1", progress_map)
    rec_service = RecommendationService()
    rec = rec_service.generate_daily_recommendation("u1", stats=stats, progress_map=progress_map)

    samples_ms: List[float] = []

    for _ in range(50):
        t0 = time.perf_counter()
        daily_plan = planner.create_daily_plan(
            user_id="u1",
            daily_budget_minutes=120,
            revision_queue=rev_queue,
            daily_recommendation=rec,
            progress_map=progress_map,
        )
        t1 = time.perf_counter()
        samples_ms.append((t1 - t0) * 1000)
        assert daily_plan.total_study_minutes > 0

    metrics = BenchmarkStatistics.calculate(samples_ms)
    assert metrics.count == 50
    assert metrics.mean_ms >= 0.0


def test_memory_allocation_profile():
    """Traces memory allocation hotspots across backend operations."""
    def target_operation():
        orchestrator = GarudaOrchestrator(provider=MockAIProvider())
        asyncio.run(orchestrator.execute_tutoring_turn(
            user_id="mem_user",
            topic_id="t_mem",
            topic_name="Memory Test Topic",
            user_message="Explain memory allocation profiling",
        ))

    mem_report = MemoryProfiler.measure(target_operation)
    assert mem_report["allocated_bytes"] >= 0
    assert mem_report["peak_bytes"] > 0
    assert len(mem_report["top_allocations"]) > 0


def test_cpu_hotspot_profile():
    """Profiles CPU execution hot paths and call counts across GARUDA Orchestrator."""
    def target_operation():
        orchestrator = GarudaOrchestrator(provider=MockAIProvider())
        asyncio.run(orchestrator.execute_tutoring_turn(
            user_id="cpu_user",
            topic_id="t_cpu",
            topic_name="CPU Profile Topic",
            user_message="Explain CPU profiling hotspot analysis",
        ))

    cpu_report = CPUProfiler.profile_function(target_operation, top_n=10)
    assert "ncalls" in cpu_report["stats_text"] or "function calls" in cpu_report["stats_text"]
