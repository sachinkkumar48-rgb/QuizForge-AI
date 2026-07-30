"""
Reusable Prompt Templates for Project TITAN AI Services.
Provides standardized prompt definitions for quiz generation and tutoring domains.
"""


GENERAL_QUIZ_TEMPLATE = """You are an expert quiz generator. Generate a quiz based ONLY on the following context text.

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


UPSC_QUIZ_TEMPLATE = """You are an elite UPSC Civil Services Examination question setter.
Generate high-caliber, analytical multiple-choice questions based strictly on the following context text.

Requirements:
1. Generate exactly {questions} UPSC-style multiple-choice questions.
2. Difficulty level: '{difficulty}' (focus on conceptual clarity, multi-statement options, or direct factual recall as appropriate).
3. Language: '{language}'.
4. Exactly 4 options per question.
5. 'answer' must be the 0-based integer index (0, 1, 2, or 3) of the correct option.
6. Provide a comprehensive, analytical explanation referencing civil services exam standards.

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


class PromptTemplates:
    """Catalog of available prompt templates for Project TITAN."""

    GENERAL_QUIZ = GENERAL_QUIZ_TEMPLATE
    UPSC_QUIZ = UPSC_QUIZ_TEMPLATE

    @classmethod
    def get_template(cls, template_name: str = "general") -> str:
        """
        Retrieves a template string by name.
        Defaults to GENERAL_QUIZ_TEMPLATE if unknown template requested.
        """
        name = template_name.lower().strip()
        if name in ("upsc", "upsc_quiz"):
            return cls.UPSC_QUIZ
        return cls.GENERAL_QUIZ
