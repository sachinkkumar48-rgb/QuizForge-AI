"""
Unit tests for GARUDA AI Gemini Provider (GeminiProvider).
"""
import pytest
from unittest.mock import MagicMock, patch
from app.garuda.domain import ProviderUnavailableException
from app.garuda.gemini_provider import GeminiProvider
from app.garuda.providers import AIProviderFactory, AIProviderRegistry


def test_gemini_provider_automatic_registration():
    import app.garuda  # triggers auto registration
    providers = AIProviderRegistry.list_providers()
    assert "gemini" in providers
    assert AIProviderRegistry.get_default_name() == "gemini"

    provider = AIProviderFactory.create("gemini")
    assert isinstance(provider, GeminiProvider)
    assert provider.name == "gemini"
    assert "text_generation" in provider.capabilities
    assert "streaming" in provider.capabilities


@pytest.mark.anyio
async def test_gemini_provider_missing_api_key_raises_exception():
    provider = GeminiProvider(config={"api_key": ""})
    assert await provider.is_healthy() is False

    with pytest.raises(ProviderUnavailableException) as exc_info:
        await provider.generate_response("Test prompt")
    assert exc_info.value.code == "PROVIDER_UNAVAILABLE"
    assert "GEMINI_API_KEY" in str(exc_info.value)


@pytest.mark.anyio
async def test_gemini_provider_generate_response_mocked():
    provider = GeminiProvider(config={"api_key": "fake_test_key_12345"})

    mock_client = MagicMock()
    mock_response = MagicMock()
    mock_response.text = "Mocked Gemini Response Text"
    mock_client.models.generate_content.return_value = mock_response

    with patch.object(provider, "_get_client", return_value=mock_client):
        resp = await provider.generate_response("Explain Article 21", context="UPSC Polity")
        assert resp == "Mocked Gemini Response Text"
        mock_client.models.generate_content.assert_called_once()


@pytest.mark.anyio
async def test_gemini_provider_stream_response_mocked():
    provider = GeminiProvider(config={"api_key": "fake_test_key_12345"})

    mock_client = MagicMock()
    chunk1 = MagicMock()
    chunk1.text = "Chunk A "
    chunk2 = MagicMock()
    chunk2.text = "Chunk B"
    mock_client.models.generate_content_stream.return_value = [chunk1, chunk2]

    with patch.object(provider, "_get_client", return_value=mock_client):
        chunks = []
        async for c in provider.stream_response("Stream test prompt"):
            chunks.append(c)

        assert chunks == ["Chunk A ", "Chunk B"]


def test_gemini_provider_token_counting_fallback():
    provider = GeminiProvider(config={"api_key": "fake_test_key_12345"})
    count = provider.count_tokens("Hello world this is a test")
    assert count == 6
