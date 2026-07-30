"""
Gemini service integration for Project TITAN.
Concrete implementation of abstract AIService.
"""
import time
from typing import Any, Dict, List, Tuple
from dotenv import load_dotenv
from google import genai
from google.genai import types
from google.genai.errors import APIError

from app.core.logging import logger
from app.core.settings import settings
from app.schemas.quiz import QuizQuestion
from app.services.ai_service import AIService
from app.services.prompt_builder import PromptBuilder
from app.services.response_validator import ResponseValidator, ResponseValidationException

load_dotenv()


class GeminiServiceException(Exception):
    """Base exception for Gemini service errors."""

    def __init__(self, message: str, status_code: int = 500):
        super().__init__(message)
        self.message = message
        self.status_code = status_code


class GeminiAPIKeyMissingException(GeminiServiceException):
    """Raised when GEMINI_API_KEY environment variable is missing or invalid."""

    def __init__(self, message: str = "GEMINI_API_KEY environment variable is missing or invalid."):
        super().__init__(message, status_code=500)


class GeminiUnavailableException(GeminiServiceException):
    """Raised when Gemini API is unavailable or returns an error."""

    def __init__(self, message: str = "Gemini API service is currently unavailable."):
        super().__init__(message, status_code=500)


class GeminiTimeoutException(GeminiServiceException):
    """Raised when Gemini API request times out."""

    def __init__(self, message: str = "Gemini API request timed out."):
        super().__init__(message, status_code=500)


class GeminiEmptyResponseException(GeminiServiceException):
    """Raised when Gemini API returns an empty response."""

    def __init__(self, message: str = "Gemini API returned an empty response."):
        super().__init__(message, status_code=500)


class GeminiInvalidJSONException(GeminiServiceException):
    """Raised when Gemini API response is not valid JSON."""

    def __init__(self, message: str = "Gemini API returned an invalid JSON response."):
        super().__init__(message, status_code=500)


class GeminiService(AIService):
    """Service class for interacting with Google Gemini API, implementing AIService."""

    def __init__(
        self,
        api_key: str | None = None,
        model: str | None = None,
    ) -> None:
        self.api_key = api_key or settings.GEMINI_API_KEY
        self.model = model or settings.GEMINI_MODEL
        self.prompt_builder = PromptBuilder()
        self.response_validator = ResponseValidator()

    def _get_client(self) -> genai.Client:
        if not self.api_key or self.api_key.strip() == "" or self.api_key == "your_gemini_api_key_here":
            logger.error("Gemini API key missing or unconfigured.")
            raise GeminiAPIKeyMissingException("GEMINI_API_KEY environment variable is missing or unconfigured.")
        return genai.Client(api_key=self.api_key)

    def health_check(self) -> Dict[str, Any]:
        """
        Verifies that GeminiService is correctly configured without making unnecessary network requests.
        """
        try:
            if not self.api_key or self.api_key.strip() == "" or self.api_key == "your_gemini_api_key_here":
                return {
                    "status": "unhealthy",
                    "provider": "gemini",
                    "model": self.model,
                    "configured": False,
                    "error": "GEMINI_API_KEY environment variable is missing or unconfigured.",
                }
            self._get_client()
            return {
                "status": "healthy",
                "provider": "gemini",
                "model": self.model,
                "configured": True,
            }
        except Exception as e:
            return {
                "status": "unhealthy",
                "provider": "gemini",
                "model": self.model,
                "configured": False,
                "error": str(e),
            }

    def generate_quiz(
        self,
        text: str,
        questions: int = 10,
        difficulty: str = "medium",
        language: str = "en",
    ) -> Tuple[List[QuizQuestion], int]:
        """
        Generates a quiz from input text using configured Gemini model, PromptBuilder, and ResponseValidator.

        Returns:
            Tuple of (List of QuizQuestions, processing_time_ms)
        """
        logger.info(f"Starting quiz generation via Gemini provider. Questions={questions}, Difficulty={difficulty}, Language={language}")
        start_time = time.time()
        client = self._get_client()

        prompt = self.prompt_builder.build_quiz_prompt(
            source_text=text,
            number_of_questions=questions,
            difficulty=difficulty,
            language=language,
        )

        try:
            config = types.GenerateContentConfig(
                response_mime_type="application/json",
                temperature=0.3,
            )
            response = client.models.generate_content(
                model=self.model,
                contents=prompt,
                config=config,
            )
        except GeminiServiceException as e:
            logger.error(f"Gemini service exception: {e.message}")
            raise
        except APIError as e:
            err_msg = str(e)
            logger.error(f"Gemini API returned error: {err_msg}")
            if "API_KEY_INVALID" in err_msg or "API key not valid" in err_msg or getattr(e, "code", None) in (401, 403):
                raise GeminiAPIKeyMissingException(f"Invalid Gemini API Key: {err_msg}")
            raise GeminiUnavailableException(f"Gemini API error: {err_msg}")
        except TimeoutError:
            logger.error("Gemini API request timed out.")
            raise GeminiTimeoutException("Gemini API request timed out.")
        except Exception as e:
            err_msg = str(e)
            logger.error(f"Failed to communicate with Gemini API: {err_msg}")
            if "API_KEY_INVALID" in err_msg or "API key not valid" in err_msg:
                raise GeminiAPIKeyMissingException(f"Invalid Gemini API Key: {err_msg}")
            raise GeminiUnavailableException(f"Failed to communicate with Gemini API: {err_msg}")

        elapsed_ms = int((time.time() - start_time) * 1000)

        if not response or not response.text or not response.text.strip():
            logger.error("Gemini API returned an empty response.")
            raise GeminiEmptyResponseException("Gemini API returned an empty response.")

        try:
            quiz_questions = self.response_validator.validate_and_normalize_quiz_response(
                raw_response_text=response.text,
                default_difficulty=difficulty,
            )
        except ResponseValidationException as e:
            raise GeminiInvalidJSONException(e.message)

        logger.info(f"Quiz generation completed successfully in {elapsed_ms}ms. Questions generated: {len(quiz_questions)}")
        return quiz_questions, elapsed_ms
