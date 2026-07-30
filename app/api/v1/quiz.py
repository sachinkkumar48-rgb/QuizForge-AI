"""
Quiz API v1 endpoints.
"""
from fastapi import APIRouter, Depends
from app.schemas.quiz import (
    QuizGenerateRequest,
    QuizGenerateResponse,
)
from app.services.gemini_service import GeminiService

router = APIRouter(tags=["quiz"])


@router.post("/generate", response_model=QuizGenerateResponse)
def generate_quiz(
    request: QuizGenerateRequest,
    gemini_service: GeminiService = Depends(),
) -> QuizGenerateResponse:
    """
    Generate a quiz from text using Gemini 2.5 Flash.
    """
    quiz_questions, processing_time_ms = gemini_service.generate_quiz(
        text=request.text,
        questions=request.questions,
        difficulty=request.difficulty,
        language=request.language,
    )
    return QuizGenerateResponse(
        success=True,
        quiz=quiz_questions,
        processing_time_ms=processing_time_ms,
    )
