"""
Validation Engine for GARUDA National PYQ Repository (Python).
"""
from dataclasses import dataclass
from enum import Enum
from typing import List, Optional

from app.garuda.pyq.models import Question, SupportedExam


class ValidationErrorCode(str, Enum):
    DUPLICATE_QUESTION = "duplicateQuestion"
    BROKEN_LINK = "brokenLink"
    MISSING_METADATA = "missingMetadata"
    INVALID_YEAR = "invalidYear"
    INVALID_EXAM = "invalidExam"
    INVALID_MAPPING = "invalidMapping"


@dataclass
class ValidationError:
    code: ValidationErrorCode
    message: str
    question_id: str


class PYQValidator:
    @staticmethod
    def validate_question(
        question: Question, existing_questions: Optional[List[Question]] = None
    ) -> List[ValidationError]:
        errors = []
        valid_exams = {e.id.lower() for e in SupportedExam.initial_exams()}

        # 1. Invalid Exam
        if not question.exam_id.strip() or (
            question.exam_id.lower() not in valid_exams and not question.exam_id.startswith("custom_")
        ):
            errors.append(
                ValidationError(
                    code=ValidationErrorCode.INVALID_EXAM,
                    message=f"Invalid or unsupported Exam ID: {question.exam_id}",
                    question_id=question.id,
                )
            )

        # 2. Invalid Year
        if question.year < 1950 or question.year > 2030:
            errors.append(
                ValidationError(
                    code=ValidationErrorCode.INVALID_YEAR,
                    message=f"Invalid examination year: {question.year}",
                    question_id=question.id,
                )
            )

        # 3. Missing Metadata
        if not question.id.strip() or not question.subject.strip() or not question.topic.strip() or not question.original_question.strip():
            errors.append(
                ValidationError(
                    code=ValidationErrorCode.MISSING_METADATA,
                    message="Missing mandatory metadata (ID, subject, topic, or question text)",
                    question_id=question.id,
                )
            )

        # 4. Invalid Mapping
        if not question.options and question.official_answer.correct_option_keys:
            errors.append(
                ValidationError(
                    code=ValidationErrorCode.INVALID_MAPPING,
                    message="Official answer specifies options, but options list is empty",
                    question_id=question.id,
                )
            )

        # 5. Duplicate Question
        if existing_questions:
            for existing in existing_questions:
                if (
                    existing.id != question.id
                    and existing.original_question.strip().lower() == question.original_question.strip().lower()
                    and existing.exam_id == question.exam_id
                    and existing.year == question.year
                ):
                    errors.append(
                        ValidationError(
                            code=ValidationErrorCode.DUPLICATE_QUESTION,
                            message=f"Duplicate question text detected with existing question {existing.id}",
                            question_id=question.id,
                        )
                    )

        return errors

    @staticmethod
    def validate_batch(questions: List[Question]) -> List[ValidationError]:
        all_errors = []
        for i, q in enumerate(questions):
            others = questions[:i] + questions[i + 1 :]
            all_errors.extend(PYQValidator.validate_question(q, existing_questions=others))
        return all_errors
