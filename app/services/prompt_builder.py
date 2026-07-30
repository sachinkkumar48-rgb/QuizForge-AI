"""
Prompt Builder Service for Project TITAN.
Assembles prompts based on PromptStrategy and PromptTemplates.
"""
from typing import Optional, Union

from app.core.logging import logger
from app.services.prompt_strategy import PromptStrategy, QuizStrategyType
from app.services.prompt_templates import PromptTemplates


class PromptBuilder:
    """
    Builder class for constructing structured LLM prompts.
    Uses PromptStrategy for strategy selection and PromptTemplates for layout assembly.
    """

    def build_quiz_prompt(
        self,
        source_text: str,
        number_of_questions: int = 5,
        difficulty: str = "medium",
        language: str = "English",
        strategy: Optional[Union[PromptStrategy, QuizStrategyType, str]] = None,
        template_name: Optional[str] = None,
    ) -> str:
        """
        Assembles a formatted prompt from input parameters using PromptStrategy.

        Args:
            source_text (str): Source context text.
            number_of_questions (int): Desired question count.
            difficulty (str): Difficulty level (easy, medium, hard).
            language (str): Target language.
            strategy (PromptStrategy | QuizStrategyType | str, optional): Strategy selection.
            template_name (str, optional): Legacy template identifier for backward compatibility.

        Returns:
            str: Completed prompt text.
        """
        if isinstance(strategy, PromptStrategy):
            resolved_strategy = strategy
        elif strategy is not None:
            resolved_strategy = PromptStrategy.from_name(str(strategy))
        elif template_name is not None:
            resolved_strategy = PromptStrategy.from_name(template_name)
        else:
            resolved_strategy = PromptStrategy(QuizStrategyType.GENERAL)

        target_template_name = resolved_strategy.resolve_template_name()
        selected_template = PromptTemplates.get_template(target_template_name)

        prompt = selected_template.format(
            text=source_text,
            questions=number_of_questions,
            difficulty=difficulty,
            language=language,
        )

        logger.info(
            f"Assembled quiz prompt using strategy='{resolved_strategy.name}', "
            f"template='{target_template_name}', questions={number_of_questions}, "
            f"difficulty='{difficulty}', language='{language}'"
        )

        return prompt
