"""
GARUDA AI Conversation Contracts & Prompt Framework.

Implements ConversationContext, PromptTemplate, PromptBuilder, TutorPersona interface,
ConversationStrategy interface, and Conversation Exceptions.

Follows Clean Architecture, Strategy Pattern, Builder Pattern, and Interface-First Design.
Does NOT depend on FastAPI, Flutter, HTTP, SQLAlchemy, or concrete AI SDKs.
"""
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional

from app.garuda.domain import ChatMessage, GarudaException


class ConversationException(GarudaException):
    """Base exception for all conversation framework errors."""

    def __init__(self, message: str, code: str = "CONVERSATION_ERROR"):
        super().__init__(message, code=code)


class InvalidPromptTemplateException(ConversationException):
    """Raised when a prompt template format fails or lacks required variables."""

    def __init__(self, template_id: str, missing_vars: List[str]):
        super().__init__(
            f"PromptTemplate '{template_id}' is missing required variables: {missing_vars}",
            code="INVALID_PROMPT_TEMPLATE",
        )


class StrategyNotFoundException(ConversationException):
    """Raised when a requested conversation strategy is not found."""

    def __init__(self, strategy_type: str):
        super().__init__(
            f"ConversationStrategy '{strategy_type}' is not registered.",
            code="STRATEGY_NOT_FOUND",
        )


@dataclass
class ConversationContext:
    """Encapsulates active conversation context, history, knowledge, and variables."""
    session_id: str
    user_id: str
    history: List[ChatMessage] = field(default_factory=list)
    knowledge_chunks: List[str] = field(default_factory=list)
    variables: Dict[str, Any] = field(default_factory=dict)
    system_prompt: Optional[str] = None

    def add_knowledge_chunk(self, chunk: str) -> None:
        if chunk and chunk.strip():
            self.knowledge_chunks.append(chunk.strip())

    def get_formatted_knowledge(self) -> str:
        if not self.knowledge_chunks:
            return ""
        return "\n---\n".join(self.knowledge_chunks)


@dataclass
class PromptTemplate:
    """Encapsulates system instruction and formatted prompt template rules."""
    template_id: str
    system_instruction: str
    template_format: str
    required_variables: List[str] = field(default_factory=list)

    def format(self, variables: Dict[str, Any]) -> str:
        """Formats the template string after verifying all required variables exist."""
        missing = [v for v in self.required_variables if v not in variables or variables[v] is None]
        if missing:
            raise InvalidPromptTemplateException(self.template_id, missing)
        try:
            return self.template_format.format(**variables)
        except KeyError as e:
            raise InvalidPromptTemplateException(self.template_id, [str(e)])


class TutorPersona(ABC):
    """Abstract interface for GARUDA AI persona personas."""

    @property
    @abstractmethod
    def name(self) -> str:
        """Returns the persona name."""
        pass

    @property
    @abstractmethod
    def system_instruction(self) -> str:
        """Returns the system instruction defining persona identity and behavioral rules."""
        pass

    @property
    def tone(self) -> str:
        """Returns default tone identifier."""
        return "encouraging"


class ConversationStrategy(ABC):
    """
    Abstract Strategy interface for interchangeable conversation strategies.
    Supports Socratic tutoring, Coaching, Revision, Quiz generation, and Note generation.
    """

    @property
    @abstractmethod
    def strategy_type(self) -> str:
        """
        Returns strategy identifier.
        Supported types: 'socratic', 'coaching', 'revision', 'quiz_generation', 'note_generation'
        """
        pass

    @abstractmethod
    def build_prompt(self, context: ConversationContext) -> str:
        """Constructs the complete formatted LLM prompt for the strategy using the context."""
        pass


class PromptBuilder:
    """
    Builder pattern implementation for constructing formatted LLM prompts.
    Assembles system persona, knowledge context, historical turns, and user variables.
    """

    def __init__(self):
        self._persona: Optional[TutorPersona] = None
        self._template: Optional[PromptTemplate] = None
        self._context: Optional[ConversationContext] = None
        self._variables: Dict[str, Any] = {}

    def with_persona(self, persona: TutorPersona) -> "PromptBuilder":
        self._persona = persona
        return self

    def with_template(self, template: PromptTemplate) -> "PromptBuilder":
        self._template = template
        return self

    def with_context(self, context: ConversationContext) -> "PromptBuilder":
        self._context = context
        return self

    def with_variable(self, key: str, value: Any) -> "PromptBuilder":
        self._variables[key] = value
        return self

    def build(self) -> str:
        """Assembles and returns the full composite prompt string."""
        sections: List[str] = []

        # 1. System Persona Instruction
        if self._persona:
            sections.append(f"SYSTEM INSTRUCTION ({self._persona.name}):\n{self._persona.system_instruction}")

        # 2. Template System Instruction if available
        if self._template and self._template.system_instruction:
            sections.append(f"INSTRUCTION:\n{self._template.system_instruction}")

        # 3. Knowledge Context
        if self._context:
            knowledge = self._context.get_formatted_knowledge()
            if knowledge:
                sections.append(f"RETRIEVED KNOWLEDGE CONTEXT:\n{knowledge}")

        # 4. Formatted Template Content
        if self._template:
            if self._context and self._variables:
                combined_vars = {**self._context.variables, **self._variables}
            elif self._context:
                combined_vars = self._context.variables
            else:
                combined_vars = self._variables
            formatted_body = self._template.format(combined_vars)
            sections.append(f"PROMPT BODY:\n{formatted_body}")

        # 5. Conversation History Turns
        if self._context and self._context.history:
            history_str = "\n".join(f"{msg.role.value.upper()}: {msg.content}" for msg in self._context.history)
            sections.append(f"CONVERSATION HISTORY:\n{history_str}")

        return "\n\n---\n\n".join(sections)
