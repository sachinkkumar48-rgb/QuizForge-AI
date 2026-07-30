"""
Gemini service integration for Project TITAN.
"""
import json
import os
import time
from typing import List, Tuple
from dotenv import load_dotenv
from google import genai
from google.genai import types
from google.genai.errors import APIError

from app.core.settings import settings
from app.schemas.quiz import QuizQuestion

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


class GeminiService:
    """Service class for interacting with Google Gemini API."""

    def __init__(self, api_key: str | None = None, model: str | None = None) -> None:
        self.api_key = api_key or settings.GEMINI_API_KEY
        self.model = model or settings.GEMINI_MODEL

    def _get_client(self) -> genai.Client:
        if not self.api_key or self.api_key.strip() == "" or self.api_key == "your_gemini_api_key_here":
            raise GeminiAPIKeyMissingException("GEMINI_API_KEY environment variable is missing or unconfigured.")
        return genai.Client(api_key=self.api_key)

    def _clean_json_text(self, text: str) -> str:
        cleaned = text.strip()
        if cleaned.startswith("```json"):
            cleaned = cleaned[7:]
        elif cleaned.startswith("```"):
            cleaned = cleaned[3:]
        if cleaned.endswith("```"):
            cleaned = cleaned[:-3]
        return cleaned.strip()

    def generate_quiz(
        self,
        text: str,
        questions: int = 10,
        difficulty: str = "medium",
        language: str = "en",
    ) -> Tuple[List[QuizQuestion], int]:
        """
        Generates a quiz from input text using configured Gemini model.

        Returns:
            Tuple of (List of QuizQuestions, processing_time_ms)
        """
        start_time = time.time()
        client = self._get_client()

        prompt = f"""
You are an expert quiz generator. Generate a quiz based ONLY on the following context text.

Requirements:
1. Generate exactly {questions} multiple-choice questions.
2. Difficulty level: '{difficulty}'.
3. Language: '{language}'.
4. Exactly 4 options per question.
5. 'answer' must be the 0-based integer index (0, 1, 2, or 3) of the correct option.
6. Provide a clear, informative explanation for the correct answer.

Output MUST be strictly valid JSON matching this exact structure:
{{
  "quiz": [
    {{
      "question": "string",
      "options": ["string", "string", "string", "string"],
      "answer": 0,
      "explanation": "string"
    }}
  ]
}}

Context Text:
{text}
"""

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
        except GeminiServiceException:
            raise
        except APIError as e:
            err_msg = str(e)
            if "API_KEY_INVALID" in err_msg or "API key not valid" in err_msg or getattr(e, "code", None) in (401, 403):
                raise GeminiAPIKeyMissingException(f"Invalid Gemini API Key: {err_msg}")
            raise GeminiUnavailableException(f"Gemini API error: {err_msg}")
        except TimeoutError:
            raise GeminiTimeoutException("Gemini API request timed out.")
        except Exception as e:
            err_msg = str(e)
            if "API_KEY_INVALID" in err_msg or "API key not valid" in err_msg:
                raise GeminiAPIKeyMissingException(f"Invalid Gemini API Key: {err_msg}")
            raise GeminiUnavailableException(f"Failed to communicate with Gemini API: {err_msg}")

        elapsed_ms = int((time.time() - start_time) * 1000)

        if not response or not response.text or not response.text.strip():
            raise GeminiEmptyResponseException("Gemini API returned an empty response.")

        cleaned_json = self._clean_json_text(response.text)

        try:
            data = json.loads(cleaned_json)
        except json.JSONDecodeError as e:
            raise GeminiInvalidJSONException(f"Failed to parse Gemini response as JSON: {e}")

        if not isinstance(data, dict) or "quiz" not in data or not isinstance(data["quiz"], list):
            raise GeminiInvalidJSONException("Gemini JSON response missing required 'quiz' list key.")

        quiz_questions: List[QuizQuestion] = []
        try:
            for item in data["quiz"]:
                quiz_questions.append(QuizQuestion(**item))
        except Exception as e:
            raise GeminiInvalidJSONException(f"Gemini quiz items failed schema validation: {e}")

        return quiz_questions, elapsed_ms
