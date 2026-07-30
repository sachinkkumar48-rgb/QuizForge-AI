"""
Prompt Strategy Engine for Project TITAN.
Decouples prompt selection strategies from prompt building and templates.
"""
from enum import Enum


class QuizStrategyType(str, Enum):
    """Supported quiz generation prompt strategies."""
    GENERAL = "general"
    UPSC = "upsc"
    BPSC = "bpsc"
    SSC = "ssc"
    REVISION = "revision"
    TEACHER = "teacher"
    INTERVIEW = "interview"


class PromptStrategy:
    """
    Encapsulates selection of appropriate prompt strategies and templates.
    """

    def __init__(self, strategy_type: QuizStrategyType | str = QuizStrategyType.GENERAL):
        if isinstance(strategy_type, str):
            try:
                self.strategy_type = QuizStrategyType(strategy_type.lower().strip())
            except ValueError:
                self.strategy_type = QuizStrategyType.GENERAL
        else:
            self.strategy_type = strategy_type

    @property
    def name(self) -> str:
        """Returns the string name of the selected strategy."""
        return self.strategy_type.value

    def resolve_template_name(self) -> str:
        """
        Maps strategy to template identifier in PromptTemplates.
        """
        if self.strategy_type == QuizStrategyType.UPSC:
            return "upsc"
        return "general"

    @classmethod
    def from_name(cls, strategy_name: str) -> "PromptStrategy":
        """Factory method to resolve PromptStrategy from string identifier."""
        return cls(strategy_type=strategy_name)
