"""
Unit tests for GARUDA AI Conversation Contracts & Prompt Framework.
"""
import pytest
from app.garuda.conversation import (
    ConversationContext,
    ConversationStrategy,
    InvalidPromptTemplateException,
    PromptBuilder,
    PromptTemplate,
    StrategyNotFoundException,
    TutorPersona,
)
from app.garuda.domain import ChatMessage, MessageRole


class MockSocraticPersona(TutorPersona):
    @property
    def name(self) -> str:
        return "Socratic Tutor"

    @property
    def system_instruction(self) -> str:
        return "Guide the student by asking probing questions rather than giving direct answers."


class MockSocraticStrategy(ConversationStrategy):
    @property
    def strategy_type(self) -> str:
        return "socratic"

    def build_prompt(self, context: ConversationContext) -> str:
        return f"Socratic Prompt for user '{context.user_id}': {context.get_formatted_knowledge()}"


class MockQuizGenerationStrategy(ConversationStrategy):
    @property
    def strategy_type(self) -> str:
        return "quiz_generation"

    def build_prompt(self, context: ConversationContext) -> str:
        topic = context.variables.get("topic", "General")
        return f"Generate Quiz for Topic: {topic}"


def test_conversation_context_helpers():
    ctx = ConversationContext(session_id="s1", user_id="u1")
    assert ctx.get_formatted_knowledge() == ""

    ctx.add_knowledge_chunk("Snippet A: Preamble")
    ctx.add_knowledge_chunk("Snippet B: Fundamental Rights")
    assert "Snippet A: Preamble" in ctx.get_formatted_knowledge()
    assert "Snippet B: Fundamental Rights" in ctx.get_formatted_knowledge()


def test_prompt_template_formatting_and_missing_vars():
    tmpl = PromptTemplate(
        template_id="t1",
        system_instruction="Analyze topic",
        template_format="Explain concept '{concept}' for student level '{level}'.",
        required_variables=["concept", "level"],
    )

    formatted = tmpl.format({"concept": "Federalism", "level": "Advanced"})
    assert formatted == "Explain concept 'Federalism' for student level 'Advanced'."

    with pytest.raises(InvalidPromptTemplateException) as exc_info:
        tmpl.format({"concept": "Federalism"})
    assert exc_info.value.code == "INVALID_PROMPT_TEMPLATE"
    assert "level" in str(exc_info.value)


def test_prompt_builder_construction():
    persona = MockSocraticPersona()
    tmpl = PromptTemplate(
        template_id="t2",
        system_instruction="Focus on UPSC Polity",
        template_format="Topic: {topic}",
        required_variables=["topic"],
    )

    msg1 = ChatMessage(id="m1", role=MessageRole.USER, content="Explain Article 14.")
    msg2 = ChatMessage(id="m2", role=MessageRole.ASSISTANT, content="What does equality before law mean to you?")

    ctx = ConversationContext(
        session_id="s100",
        user_id="u50",
        history=[msg1, msg2],
        variables={"topic": "Article 14 - Right to Equality"},
    )
    ctx.add_knowledge_chunk("Article 14 guarantees equality before law.")

    builder = PromptBuilder()
    full_prompt = (
        builder.with_persona(persona)
        .with_template(tmpl)
        .with_context(ctx)
        .build()
    )

    assert "SYSTEM INSTRUCTION (Socratic Tutor):" in full_prompt
    assert "Guide the student by asking probing questions" in full_prompt
    assert "INSTRUCTION:\nFocus on UPSC Polity" in full_prompt
    assert "RETRIEVED KNOWLEDGE CONTEXT:\nArticle 14 guarantees equality before law." in full_prompt
    assert "PROMPT BODY:\nTopic: Article 14 - Right to Equality" in full_prompt
    assert "USER: Explain Article 14." in full_prompt
    assert "ASSISTANT: What does equality before law mean to you?" in full_prompt


def test_interchangeable_strategies():
    ctx = ConversationContext(session_id="s1", user_id="u1", variables={"topic": "Polity"})
    ctx.add_knowledge_chunk("Context chunk")

    socratic = MockSocraticStrategy()
    quiz_gen = MockQuizGenerationStrategy()

    assert socratic.strategy_type == "socratic"
    assert "Socratic Prompt for user 'u1'" in socratic.build_prompt(ctx)

    assert quiz_gen.strategy_type == "quiz_generation"
    assert quiz_gen.build_prompt(ctx) == "Generate Quiz for Topic: Polity"
