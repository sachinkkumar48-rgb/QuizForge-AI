"""
GARUDA AI Agent Framework.

Implements BaseAgent, AgentRegistry, AgentFactory, TutorAgent, PlannerAgent, RevisionAgent, and QuizAgent.

Follows Clean Architecture, SOLID, Strategy Pattern, Factory Pattern, and Registry Pattern.
Depends ONLY on GARUDA Domain, Conversation, and Provider framework contracts.
Does NOT depend on FastAPI, Flutter, SQLAlchemy, HTTP, or concrete AI SDKs.
"""
from abc import ABC, abstractmethod
from typing import AsyncGenerator, Dict, List, Optional, Type

from app.garuda.conversation import (
    ConversationContext,
    ConversationStrategy,
    PromptBuilder,
)
from app.garuda.domain import GarudaException, ProviderUnavailableException
from app.garuda.providers import AIProviderFactory, BaseAIProvider


class AgentException(GarudaException):
    """Base exception for all agent framework errors."""

    def __init__(self, message: str, code: str = "AGENT_ERROR"):
        super().__init__(message, code=code)


class AgentNotFoundException(AgentException):
    """Raised when a requested agent type is not registered."""

    def __init__(self, agent_type: str):
        super().__init__(
            f"GARUDA Agent '{agent_type}' is not registered in AgentRegistry.",
            code="AGENT_NOT_FOUND",
        )


class BaseAgent(ABC):
    """
    Abstract base class for all GARUDA AI agents.
    Provides orchestration between Conversation Context/Strategies and AI Providers.
    """

    def __init__(self, provider: Optional[BaseAIProvider] = None):
        self._provider = provider

    @property
    @abstractmethod
    def agent_type(self) -> str:
        """Returns unique agent identifier type."""
        pass

    @property
    @abstractmethod
    def strategy(self) -> ConversationStrategy:
        """Returns the conversation strategy associated with this agent."""
        pass

    def get_provider(self) -> BaseAIProvider:
        """Retrieves assigned AI provider or falls back to factory default."""
        if self._provider is not None:
            return self._provider
        return AIProviderFactory.create()

    def build_prompt(self, context: ConversationContext) -> str:
        """Orchestrates prompt construction using strategy and PromptBuilder."""
        strategy_prompt = self.strategy.build_prompt(context)
        builder = PromptBuilder().with_context(context)
        if context.system_prompt:
            builder.with_variable("system_prompt", context.system_prompt)
        full_prompt = builder.build()
        if strategy_prompt not in full_prompt:
            return f"{full_prompt}\n\nSTRATEGY INSTRUCTION:\n{strategy_prompt}"
        return full_prompt

    async def execute(self, context: ConversationContext) -> str:
        """Orchestrates complete agent execution: constructs prompt and calls provider."""
        prompt = self.build_prompt(context)
        provider = self.get_provider()
        return await provider.generate_response(prompt)

    async def execute_stream(self, context: ConversationContext) -> AsyncGenerator[str, None]:
        """Orchestrates streamed agent execution: constructs prompt and streams provider tokens."""
        prompt = self.build_prompt(context)
        provider = self.get_provider()
        async for chunk in provider.stream_response(prompt):
            yield chunk


class TutorAgentStrategy(ConversationStrategy):
    @property
    def strategy_type(self) -> str:
        return "socratic_tutor"

    def build_prompt(self, context: ConversationContext) -> str:
        return "Socratic Dialogue: Guide the student through questioning without revealing answers directly."


class TutorAgent(BaseAgent):
    """Orchestrates multi-turn Socratic chat tutoring."""

    @property
    def agent_type(self) -> str:
        return "tutor"

    @property
    def strategy(self) -> ConversationStrategy:
        return TutorAgentStrategy()


class PlannerAgentStrategy(ConversationStrategy):
    @property
    def strategy_type(self) -> str:
        return "study_planner"

    def build_prompt(self, context: ConversationContext) -> str:
        return "Study Planner: Construct an adaptive study plan and daily workload schedule based on topics."


class PlannerAgent(BaseAgent):
    """Orchestrates study calendar and workload planning."""

    @property
    def agent_type(self) -> str:
        return "planner"

    @property
    def strategy(self) -> ConversationStrategy:
        return PlannerAgentStrategy()


class RevisionAgentStrategy(ConversationStrategy):
    @property
    def strategy_type(self) -> str:
        return "intelligent_revision"

    def build_prompt(self, context: ConversationContext) -> str:
        return "Intelligent Revision: Analyze weak topics and generate prioritized revision tasks."


class RevisionAgent(BaseAgent):
    """Orchestrates spaced repetition queues and weak area revision."""

    @property
    def agent_type(self) -> str:
        return "revision"

    @property
    def strategy(self) -> ConversationStrategy:
        return RevisionAgentStrategy()


class QuizAgentStrategy(ConversationStrategy):
    @property
    def strategy_type(self) -> str:
        return "quiz_generation"

    def build_prompt(self, context: ConversationContext) -> str:
        return "Quiz Generation: Synthesize multiple-choice questions with options, answers, and explanations."


class QuizAgent(BaseAgent):
    """Orchestrates practice quiz synthesis."""

    @property
    def agent_type(self) -> str:
        return "quiz"

    @property
    def strategy(self) -> ConversationStrategy:
        return QuizAgentStrategy()


class AgentRegistry:
    """Registry mapping agent type identifiers to concrete agent classes."""

    _registry: Dict[str, Type[BaseAgent]] = {}

    @classmethod
    def register(cls, agent_type: str, agent_cls: Type[BaseAgent]) -> None:
        clean_type = agent_type.lower().strip()
        cls._registry[clean_type] = agent_cls

    @classmethod
    def get_agent_cls(cls, agent_type: str) -> Type[BaseAgent]:
        clean_type = agent_type.lower().strip()
        if clean_type not in cls._registry:
            raise AgentNotFoundException(clean_type)
        return cls._registry[clean_type]

    @classmethod
    def list_agents(cls) -> List[str]:
        return list(cls._registry.keys())

    @classmethod
    def clear(cls) -> None:
        cls._registry.clear()


# Pre-register standard GARUDA agents
AgentRegistry.register("tutor", TutorAgent)
AgentRegistry.register("planner", PlannerAgent)
AgentRegistry.register("revision", RevisionAgent)
AgentRegistry.register("quiz", QuizAgent)


class AgentFactory:
    """Factory for instantiating specialized GARUDA agents."""

    @staticmethod
    def create_agent(agent_type: str, provider: Optional[BaseAIProvider] = None) -> BaseAgent:
        agent_cls = AgentRegistry.get_agent_cls(agent_type)
        return agent_cls(provider=provider)
