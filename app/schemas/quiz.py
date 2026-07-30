"""
Quiz data schemas and request/response validation models.
"""
from typing import List, Literal
from pydantic import BaseModel, Field, field_validator


class QuizBase(BaseModel):
    title: str
    description: str | None = None


class QuizCreate(QuizBase):
    pass


class QuizResponse(QuizBase):
    id: str


class QuizGenerateRequest(BaseModel):
    text: str = Field(..., min_length=1, description="Source text for quiz generation. Cannot be empty.")
    questions: int = Field(default=10, ge=1, le=50, description="Number of questions to generate (1-50).")
    difficulty: Literal["easy", "medium", "hard"] = Field(description="Difficulty level.")
    language: str = Field(default="en", description="Target language for quiz.")

    @field_validator("text")
    @classmethod
    def text_must_not_be_empty(cls, v: str) -> str:
        if not v or not v.strip():
            raise ValueError("text cannot be empty or whitespace only.")
        return v


class QuizQuestion(BaseModel):
    question: str
    options: List[str]
    answer: int
    explanation: str


class QuizGenerateResponse(BaseModel):
    success: bool
    quiz: List[QuizQuestion]
    processing_time_ms: int
