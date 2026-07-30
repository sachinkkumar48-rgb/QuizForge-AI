"""
Abstract AI Service Interface for Project TITAN.
Defines the architectural contract for AI/LLM providers following Clean Architecture principles.
"""
from abc import ABC, abstractmethod
from typing import Any, Dict, List, Tuple


class AIService(ABC):
    """
    Abstract Base Class for AI Services in Project TITAN.
    Guarantees pluggability for LLM implementations (e.g. Gemini, OpenAI, Mock).
    """

    @abstractmethod
    def generate_quiz(
        self,
        text: str,
        questions: int = 5,
        difficulty: str = "medium",
        language: str = "English",
    ) -> Tuple[List[Dict[str, Any]], int]:
        """
        Abstract contract to generate quiz questions from text context.

        Args:
            text (str): Source text content for quiz generation.
            questions (int): Desired number of questions.
            difficulty (str): Difficulty level (easy, medium, hard).
            language (str): Target language for quiz content.

        Returns:
            Tuple[List[Dict[str, Any]], int]: (List of quiz question dicts, processing time in ms)
        """
        raise NotImplementedError

    @abstractmethod
    def health_check(self) -> Dict[str, Any]:
        """
        Abstract contract to check AI provider reachability and status.

        Returns:
            Dict[str, Any]: Provider health status payload.
        """
        raise NotImplementedError
