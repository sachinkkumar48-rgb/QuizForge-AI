"""
Unit tests for GARUDA AI Agent Framework (BaseAgent, TutorAgent, PlannerAgent, RevisionAgent, QuizAgent, AgentRegistry, AgentFactory).
"""
import pytest
from typing import AsyncGenerator, Optional
from app.garuda.agents import (
    AgentFactory,
    AgentNotFoundException,
    AgentRegistry,
    PlannerAgent,
    QuizAgent,
    RevisionAgent,
    TutorAgent,
)
from app.garuda.conversation import ConversationContext
from app.garuda.providers import BaseAIProvider


class MockAgentProvider(BaseAIProvider):
    @property
    def name(self) -> str:
        return "mock_agent_provider"

    async def generate_response(self, prompt: str, context: Optional[str] = None) -> str:
        return f"MockAgentResponse for: {prompt[:30]}..."

    async def stream_response(self, prompt: str, context: Optional[str] = None) -> AsyncGenerator[str, None]:
        yield "Chunk1 "
        yield "Chunk2"


def test_agent_registry_pre_registered_agents():
    registered = AgentRegistry.list_agents()
    assert "tutor" in registered
    assert "planner" in registered
    assert "revision" in registered
    assert "quiz" in registered


def test_agent_factory_creation():
    provider = MockAgentProvider()

    tutor = AgentFactory.create_agent("tutor", provider=provider)
    assert isinstance(tutor, TutorAgent)
    assert tutor.agent_type == "tutor"
    assert tutor.strategy.strategy_type == "socratic_tutor"

    planner = AgentFactory.create_agent("planner", provider=provider)
    assert isinstance(planner, PlannerAgent)
    assert planner.agent_type == "planner"

    revision = AgentFactory.create_agent("revision", provider=provider)
    assert isinstance(revision, RevisionAgent)
    assert revision.agent_type == "revision"

    quiz = AgentFactory.create_agent("quiz", provider=provider)
    assert isinstance(quiz, QuizAgent)
    assert quiz.agent_type == "quiz"


def test_unregistered_agent_raises_exception():
    with pytest.raises(AgentNotFoundException) as exc_info:
        AgentFactory.create_agent("unknown_agent")
    assert exc_info.value.code == "AGENT_NOT_FOUND"


@pytest.mark.anyio
async def test_agent_execution_flow():
    provider = MockAgentProvider()
    tutor = AgentFactory.create_agent("tutor", provider=provider)

    context = ConversationContext(session_id="s1", user_id="u1")
    context.add_knowledge_chunk("Indian Polity: Article 14 - Right to Equality")

    response = await tutor.execute(context)
    assert "MockAgentResponse for:" in response


@pytest.mark.anyio
async def test_agent_streaming_execution_flow():
    provider = MockAgentProvider()
    quiz_agent = AgentFactory.create_agent("quiz", provider=provider)

    context = ConversationContext(session_id="s2", user_id="u2")
    chunks = []
    async for chunk in quiz_agent.execute_stream(context):
        chunks.append(chunk)

    assert chunks == ["Chunk1 ", "Chunk2"]
