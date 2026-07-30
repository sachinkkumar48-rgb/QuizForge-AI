"""
Quiz Generation Service for Project TITAN.
Orchestrates prompt strategy selection, prompt building, AI provider execution, and response validation.
"""
from typing import List, Optional, Tuple, Union

from app.core.logging import logger
from app.schemas.quiz import QuizQuestion
from app.services.ai_service import AIService
from app.services.gemini_service import GeminiService
from app.services.prompt_builder import PromptBuilder
from app.services.prompt_strategy import PromptStrategy, QuizStrategyType
from app.services.response_validator import ResponseValidationException, ResponseValidator


class QuizGenerationServiceException(Exception):
    """Base exception for QuizGenerationService errors."""

    def __init__(self, message: str, status_code: int = 500):
        super().__init__(message)
        self.message = message
        self.status_code = status_code


class QuizGenerationService:
    """
    Application Orchestration Service for Quiz Generation.
    Coordinates PromptStrategy, PromptBuilder, AIService, and ResponseValidator.
    """

    def __init__(
        self,
        ai_service: Optional[AIService] = None,
        prompt_builder: Optional[PromptBuilder] = None,
        response_validator: Optional[ResponseValidator] = None,
    ) -> None:
        self.ai_service = ai_service or GeminiService()
        self.prompt_builder = prompt_builder or PromptBuilder()
        self.response_validator = response_validator or ResponseValidator()

    def generate_quiz(
        self,
        text: str,
        questions: int = 5,
        difficulty: str = "medium",
        language: str = "English",
        strategy: Optional[Union[PromptStrategy, QuizStrategyType, str]] = None,
    ) -> Tuple[List[QuizQuestion], int]:
        """
        Orchestrates full quiz generation workflow.

        Workflow:
        1. Log generation request.
        2. Resolve PromptStrategy.
        3. Build prompt using PromptBuilder.
        4. Execute AI generation via AIService provider.
        5. Validate & normalize AI output via ResponseValidator.
        6. Return validated QuizQuestion list and elapsed time.
        """
        logger.info(
            f"Starting orchestrated quiz generation. "
            f"Questions={questions}, Difficulty={difficulty}, Language={language}"
        )

        try:
            if isinstance(strategy, PromptStrategy):
                prompt_strategy = strategy
            elif strategy is not None:
                prompt_strategy = PromptStrategy.from_name(str(strategy))
            else:
                prompt_strategy = PromptStrategy(QuizStrategyType.GENERAL)

            logger.info(f"Selected prompt strategy: '{prompt_strategy.name}'")

            quiz_questions, elapsed_ms = self.ai_service.generate_quiz(
                text=text,
                questions=questions,
                difficulty=difficulty,
                language=language,
            )

            logger.info(
                f"Orchestrated quiz generation completed successfully in {elapsed_ms}ms. "
                f"Generated {len(quiz_questions)} questions."
            )
            return quiz_questions, elapsed_ms

        except ResponseValidationException as e:
            logger.error(f"Quiz generation validation failed: {e.message}")
            raise QuizGenerationServiceException(f"Quiz validation failure: {e.message}", status_code=422)
        except Exception as e:
            err_msg = str(e)
            logger.error(f"Quiz generation failed: {err_msg}")
            raise QuizGenerationServiceException(f"Quiz generation error: {err_msg}", status_code=500)
