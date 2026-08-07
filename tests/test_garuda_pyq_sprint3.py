"""
Unit & Integration tests for TITAN-PYQ-003 Official UPSC Ingestion & Traps (Python).
"""
import pytest

from app.garuda.pyq.ingestion_sprint import (
    LearningObjectives,
    OfficialUPSCPolityDataset,
    QuestionTrap,
)


def test_official_upsc_polity_dataset_ingestion():
    questions = OfficialUPSCPolityDataset.get_official_questions()
    assert len(questions) >= 1
    q = questions[0]
    assert q.id == "PYQ_UPSC_CSE_2024_GS1_Q014"
    assert q.source.checksum.startswith("e3b0c442")
    assert "Article 300A" in q.article_links


def test_question_trap_and_learning_objectives():
    trap = QuestionTrap(
        id="TRAP_1",
        question_id="Q1",
        trap_type="Extreme Words",
        common_mistake="Ignoring 'only'",
        expected_thinking="Identify absolute qualifier",
        wrong_elimination_strategy="Accepting absolute claim",
        correct_elimination_strategy="Eliminating unverified absolute statement",
    )
    assert trap.trap_type == "Extreme Words"

    lo = LearningObjectives(
        student_should_be_able_to=["Define Article 300A"],
        define=["Legal Right"],
    )
    assert len(lo.define) == 1
