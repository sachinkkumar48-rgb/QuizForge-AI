"""
Unit tests for GARUDA AI Provider Framework (BaseAIProvider, AIProviderRegistry, AIProviderFactory).
"""
import pytest
from typing import AsyncGenerator, Optional
from app.garuda.domain import ProviderUnavailableException
from app.garuda.providers import (
    AIProviderFactory,
    AIProviderRegistry,
    BaseAIProvider,
)


class MockGeminiProvider(BaseAIProvider):
    @property
    def name(self) -> str:
        return "gemini"

    async def generate_response(self, prompt: str, context: Optional[str] = None) -> str:
        return f"Gemini response to: {prompt}"

    async def stream_response(self, prompt: str, context: Optional[str] = None) -> AsyncGenerator[str, None]:
        yield f"Gemini stream: {prompt}"


class MockClaudeProvider(BaseAIProvider):
    @property
    def name(self) -> str:
        return "claude"

    async def generate_response(self, prompt: str, context: Optional[str] = None) -> str:
        return f"Claude response to: {prompt}"

    async def stream_response(self, prompt: str, context: Optional[str] = None) -> AsyncGenerator[str, None]:
        yield f"Claude stream: {prompt}"


@pytest.fixture(autouse=True)
def clean_registry():
    """Ensures registry is reset before each test."""
    AIProviderRegistry.clear()
    yield
    AIProviderRegistry.clear()


def test_provider_registration_and_lookup():
    AIProviderRegistry.register("gemini", MockGeminiProvider)
    AIProviderRegistry.register("claude", MockClaudeProvider)

    assert "gemini" in AIProviderRegistry.list_providers()
    assert "claude" in AIProviderRegistry.list_providers()
    assert AIProviderRegistry.get_default_name() == "gemini"

    cls = AIProviderRegistry.get_provider_cls("gemini")
    assert cls == MockGeminiProvider


def test_factory_create_default_and_specific():
    AIProviderRegistry.register("gemini", MockGeminiProvider, set_as_default=True)
    AIProviderRegistry.register("claude", MockClaudeProvider)

    default_provider = AIProviderFactory.create()
    assert isinstance(default_provider, MockGeminiProvider)
    assert default_provider.name == "gemini"

    claude_provider = AIProviderFactory.create("claude")
    assert isinstance(claude_provider, MockClaudeProvider)
    assert claude_provider.name == "claude"


def test_factory_fallback_cascade():
    AIProviderRegistry.register("claude", MockClaudeProvider)

    # Gemini is not registered, but fallback to Claude should succeed
    provider = AIProviderFactory.create_with_fallback(
        primary_name="gemini", fallback_names=["claude", "ollama"]
    )
    assert isinstance(provider, MockClaudeProvider)
    assert provider.name == "claude"


def test_unregistered_provider_raises_exception():
    with pytest.raises(ProviderUnavailableException) as exc_info:
        AIProviderFactory.create("unregistered_llm")
    assert exc_info.value.code == "PROVIDER_UNAVAILABLE"
    assert "unregistered_llm" in str(exc_info.value)


@pytest.mark.anyio
async def test_mock_provider_execution():
    AIProviderRegistry.register("gemini", MockGeminiProvider)
    provider = AIProviderFactory.create("gemini")

    resp = await provider.generate_response("Explain Clean Architecture")
    assert "Gemini response to: Explain Clean Architecture" in resp
    assert provider.count_tokens("Explain Clean Architecture") == 3
    assert await provider.is_healthy() is True
