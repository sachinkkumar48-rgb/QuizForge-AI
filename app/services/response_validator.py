"""
Response Validation Engine for Project TITAN.
Validates, normalizes, and sanitizes raw AI outputs before they reach business logic.
"""
import json
from typing import Any, Dict, List

from app.core.logging import logger
from app.schemas.quiz import QuizQuestion


class ResponseValidationException(Exception):
    """Base exception for response validation failures."""

    def __init__(self, message: str):
        super().__init__(message)
        self.message = message


class ResponseValidator:
    """
    Validator component responsible for inspecting, cleaning, and normalizing raw LLM responses.
    """

    def clean_json_string(self, raw_text: str) -> str:
        """Strips markdown code fence wrappers from raw LLM string."""
        cleaned = raw_text.strip()
        if cleaned.startswith("```json"):
            cleaned = cleaned[7:]
        elif cleaned.startswith("```"):
            cleaned = cleaned[3:]
        if cleaned.endswith("```"):
            cleaned = cleaned[:-3]
        return cleaned.strip()

    def validate_and_normalize_quiz_response(
        self,
        raw_response_text: str,
        default_difficulty: str = "medium",
    ) -> List[QuizQuestion]:
        """
        Validates JSON format, verifies required fields, applies default fallback values,
        and constructs validated QuizQuestion schema objects.

        Args:
            raw_response_text (str): Raw string output from AI provider model.
            default_difficulty (str): Fallback difficulty if not present.

        Returns:
            List[QuizQuestion]: List of validated QuizQuestion objects.

        Raises:
            ResponseValidationException: If JSON is invalid, missing required keys, or malformed.
        """
        if not raw_response_text or not raw_response_text.strip():
            logger.error("Response validation failed: Raw response is empty or whitespace.")
            raise ResponseValidationException("AI provider returned an empty response string.")

        cleaned_text = self.clean_json_string(raw_response_text)

        try:
            data = json.loads(cleaned_text)
        except json.JSONDecodeError as e:
            logger.error(f"Response validation failed: Invalid JSON format ({e}).")
            raise ResponseValidationException(f"Failed to parse AI response as JSON: {e}")

        if not isinstance(data, dict):
            logger.error("Response validation failed: Parsed JSON root is not an object/dict.")
            raise ResponseValidationException("AI response JSON root must be an object.")

        questions_list = data.get("quiz") or data.get("questions")
        if not isinstance(questions_list, list):
            logger.error("Response validation failed: Missing required 'quiz' or 'questions' list array.")
            raise ResponseValidationException("AI response JSON missing required 'quiz' list key.")

        validated_questions: List[QuizQuestion] = []
        for index, item in enumerate(questions_list):
            if not isinstance(item, dict):
                logger.error(f"Response validation failed: Question item at index {index} is not a dictionary.")
                raise ResponseValidationException(f"Question item at index {index} must be a JSON object.")

            if "question" not in item or not str(item["question"]).strip():
                logger.error(f"Response validation failed: Item index {index} missing 'question' text.")
                raise ResponseValidationException(f"Question item at index {index} missing 'question' field.")

            options = item.get("options")
            if not isinstance(options, list) or len(options) != 4:
                logger.error(f"Response validation failed: Item index {index} options must be a list of 4 choices.")
                raise ResponseValidationException(f"Question item at index {index} must contain exactly 4 options.")

            answer = item.get("answer")
            if not isinstance(answer, int) or not (0 <= answer <= 3):
                logger.error(f"Response validation failed: Item index {index} answer index invalid ({answer}).")
                raise ResponseValidationException(f"Question item at index {index} 'answer' must be integer index (0-3).")

            explanation = item.get("explanation")
            if not explanation or not str(explanation).strip():
                item["explanation"] = f"Correct answer is option {answer + 1}: {options[answer]}"

            try:
                validated_questions.append(QuizQuestion(**item))
            except Exception as e:
                logger.error(f"Response validation failed: Item index {index} schema validation error ({e}).")
                raise ResponseValidationException(f"Question item at index {index} failed schema validation: {e}")

        logger.info(f"Response validation successful. Validated {len(validated_questions)} quiz questions.")
        return validated_questions
