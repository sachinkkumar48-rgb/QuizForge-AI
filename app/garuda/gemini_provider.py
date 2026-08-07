"""
Google Gemini AI Provider Implementation for GARUDA AI.

Translates GARUDA Provider Framework requests into Google GenAI SDK calls.
Fully complies with BaseAIProvider and automatically registers with AIProviderRegistry.

Does NOT contain prompt engineering, tutoring, or conversation business logic.
"""
from typing import AsyncGenerator, Optional, Set
from dotenv import load_dotenv

try:
    from google import genai
    from google.genai.errors import APIError
    GENAI_AVAILABLE = True
except ImportError:
    GENAI_AVAILABLE = False
    genai = None
    APIError = Exception

from app.core.logging import logger
from app.core.settings import settings
from app.garuda.domain import ProviderUnavailableException
from app.garuda.providers import AIProviderRegistry, BaseAIProvider

load_dotenv()


class GeminiProvider(BaseAIProvider):
    """
    Concrete implementation of BaseAIProvider for Google Gemini API.
    """

    def __init__(self, config: Optional[dict] = None):
        super().__init__(config=config)
        cfg = config or {}
        if "api_key" in cfg:
            self.api_key = cfg["api_key"]
        else:
            self.api_key = settings.GEMINI_API_KEY
        self.model = cfg.get("model") or settings.GEMINI_MODEL or "gemini-2.5-flash"


    @property
    def name(self) -> str:
        return "gemini"

    @property
    def capabilities(self) -> Set[str]:
        return {"text_generation", "streaming", "embedding"}

    def _get_client(self):
        """Initializes and returns the Google GenAI Client."""
        if not GENAI_AVAILABLE:
            raise ProviderUnavailableException("gemini", "google-genai SDK is not installed.")

        if not self.api_key or not self.api_key.strip() or self.api_key == "your_gemini_api_key_here":
            raise ProviderUnavailableException("gemini", "GEMINI_API_KEY environment variable is missing or invalid.")

        try:
            return genai.Client(api_key=self.api_key)
        except Exception as e:
            raise ProviderUnavailableException("gemini", f"Failed to initialize Gemini client: {e}")

    async def is_healthy(self) -> bool:
        """Checks if Gemini API key is configured."""
        try:
            return bool(
                self.api_key
                and self.api_key.strip()
                and self.api_key != "your_gemini_api_key_here"
                and GENAI_AVAILABLE
            )
        except Exception:
            return False

    def count_tokens(self, text: str) -> int:
        """Estimates or calculates token count for a text prompt."""
        if not text:
            return 0
        try:
            client = self._get_client()
            result = client.models.count_tokens(model=self.model, contents=text)
            if hasattr(result, "total_tokens"):
                return result.total_tokens
        except Exception:
            pass
        return super().count_tokens(text)

    async def generate_response(self, prompt: str, context: Optional[str] = None) -> str:
        """Translates Provider Framework generate request into Gemini SDK call."""
        client = self._get_client()
        full_prompt = f"Context:\n{context}\n\nPrompt:\n{prompt}" if context else prompt

        try:
            response = client.models.generate_content(
                model=self.model,
                contents=full_prompt,
            )
            if not response or not response.text:
                raise ProviderUnavailableException("gemini", "Gemini API returned an empty response.")
            return response.text
        except ProviderUnavailableException:
            raise
        except APIError as e:
            err_msg = str(e)
            logger.error(f"Gemini API error: {err_msg}")
            raise ProviderUnavailableException("gemini", f"Gemini API Error: {err_msg}")
        except TimeoutError:
            raise ProviderUnavailableException("gemini", "Gemini API request timed out.")
        except Exception as e:
            err_msg = str(e)
            logger.error(f"Failed to communicate with Gemini API: {err_msg}")
            raise ProviderUnavailableException("gemini", f"Communication error: {err_msg}")

    async def stream_response(self, prompt: str, context: Optional[str] = None) -> AsyncGenerator[str, None]:
        """Translates Provider Framework stream request into Gemini SDK stream call."""
        client = self._get_client()
        full_prompt = f"Context:\n{context}\n\nPrompt:\n{prompt}" if context else prompt

        try:
            response_stream = client.models.generate_content_stream(
                model=self.model,
                contents=full_prompt,
            )
            for chunk in response_stream:
                if chunk and chunk.text:
                    yield chunk.text
        except APIError as e:
            err_msg = str(e)
            logger.error(f"Gemini API streaming error: {err_msg}")
            raise ProviderUnavailableException("gemini", f"Gemini API Streaming Error: {err_msg}")
        except TimeoutError:
            raise ProviderUnavailableException("gemini", "Gemini API streaming request timed out.")
        except Exception as e:
            err_msg = str(e)
            logger.error(f"Failed to stream from Gemini API: {err_msg}")
            raise ProviderUnavailableException("gemini", f"Streaming communication error: {err_msg}")


# Automatic Provider Registration
AIProviderRegistry.register("gemini", GeminiProvider, set_as_default=True)
