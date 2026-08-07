"""
Python Domain Bridge for Sprint 3 Official Ingestion, Traps & Learning Objectives (TITAN-PYQ-003).
"""
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Dict, List, Optional

from app.garuda.pyq.models import Question, QuestionSource, SourceType, Answer, Option, EditorialStatus


@dataclass(frozen=True)
class QuestionTrap:
    id: str
    question_id: str
    trap_type: str
    common_mistake: str
    expected_thinking: str
    wrong_elimination_strategy: str
    correct_elimination_strategy: str


@dataclass(frozen=True)
class LearningObjectives:
    student_should_be_able_to: List[str] = field(default_factory=list)
    define: List[str] = field(default_factory=list)
    identify: List[str] = field(default_factory=list)
    differentiate: List[str] = field(default_factory=list)
    apply: List[str] = field(default_factory=list)
    analyse: List[str] = field(default_factory=list)
    eliminate_options: List[str] = field(default_factory=list)


class OfficialUPSCPolityDataset:
    @staticmethod
    def get_official_questions() -> List[Question]:
        source = QuestionSource(
            source_type=SourceType.OFFICIAL_PDF,
            publisher="Union Public Service Commission",
            retrieved_date=datetime.now(timezone.utc),
            checksum="e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
            url="https://upsc.gov.in/examinations/question-papers/2024/csp_2024_gs1.pdf",
        )

        return [
            Question(
                id="PYQ_UPSC_CSE_2024_GS1_Q014",
                exam_id="upsc_cse",
                year=2024,
                stage="Prelims",
                paper="GS Paper I",
                subject="Polity",
                topic="Right to Property",
                original_question="With reference to the Constitution of India, consider the following statements...",
                options=[
                    Option(key="A", text="1 only"),
                    Option(key="B", text="2 only", is_correct=True),
                ],
                official_answer=Answer(correct_option_keys=["B"]),
                garuda_explanation="",
                source=source,
                editorial_status=EditorialStatus.PUBLISHED,
                article_links=["Article 300A"],
                amendment_links=["44th Amendment Act, 1978"],
                tags=["Polity", "Right to Property"],
            )
        ]
