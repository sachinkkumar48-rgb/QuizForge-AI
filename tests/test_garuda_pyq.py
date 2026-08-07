"""
Unit & Integration Tests for GARUDA National PYQ Repository (Python Module).
"""
import pytest
from datetime import datetime, timezone

from app.garuda.pyq import (
    Answer,
    CSVIngestion,
    DuplicateDetector,
    EditorialStatus,
    JSONIngestion,
    ManualEntryIngestion,
    OfflinePYQRepository,
    Option,
    PYQAnalyticsEngine,
    PYQSearchEngine,
    PYQSearchQuery,
    PYQValidator,
    Question,
    QuestionSource,
    SourceType,
    SupportedExam,
    ValidationErrorCode,
)


def test_supported_exams_contains_all_24():
    exams = SupportedExam.initial_exams()
    assert len(exams) == 24
    ids = {e.id for e in exams}
    assert "upsc_cse" in ids
    assert "cds" in ids
    assert "nda" in ids
    assert "capf" in ids
    assert "bpsc" in ids
    assert "uppsc" in ids
    assert "rbi_grade_b" in ids


def test_supported_exam_custom_extension():
    custom = SupportedExam("tspsc_group1", "TSPSC_GRP1", "Telangana State PSC Group 1", "TSPSC")
    assert custom.id == "tspsc_group1"
    assert custom.category == "custom"


@pytest.mark.anyio
async def test_offline_pyq_repository_crud():
    repo = OfflinePYQRepository()
    source = QuestionSource(
        source_type=SourceType.EDITORIAL_ENTRY,
        publisher="Test Publisher",
        retrieved_date=datetime.now(timezone.utc),
        checksum="chk_py_001",
    )
    q = Question(
        id="PYQ_UPSC_2024_001",
        exam_id="upsc_cse",
        year=2024,
        stage="Prelims",
        paper="GS Paper I",
        subject="Polity",
        topic="Fundamental Rights",
        original_question="Which Article deals with Right to Equality?",
        options=[
            Option(key="A", text="Article 14", is_correct=True),
            Option(key="B", text="Article 19"),
        ],
        official_answer=Answer(correct_option_keys=["A"]),
        garuda_explanation="Article 14 guarantees equality before law.",
        source=source,
    )

    await repo.save_question(q)
    assert await repo.get_question_count() == 1

    fetched = await repo.get_question_by_id("PYQ_UPSC_2024_001")
    assert fetched is not None
    assert fetched.subject == "Polity"

    filtered = await repo.get_questions_by_exam("upsc_cse", year=2024)
    assert len(filtered) == 1
    assert filtered[0].id == "PYQ_UPSC_2024_001"


@pytest.mark.anyio
async def test_pyq_search_engine():
    repo = OfflinePYQRepository()
    source = QuestionSource(
        source_type=SourceType.EDITORIAL_ENTRY,
        publisher="Test Publisher",
        retrieved_date=datetime.now(timezone.utc),
        checksum="chk_search",
    )
    q = Question(
        id="Q_SEARCH_1",
        exam_id="upsc_cse",
        year=2024,
        stage="Prelims",
        paper="GS1",
        subject="Polity",
        topic="Preamble",
        original_question="What is the significance of 42nd Amendment?",
        options=[],
        official_answer=Answer(correct_option_keys=["A"]),
        garuda_explanation="Added Socialist, Secular, Integrity.",
        source=source,
        article_links=["Article 368"],
        tags=["Preamble", "Amendments"],
    )
    await repo.save_question(q)

    engine = PYQSearchEngine(repo)
    results = await engine.search(PYQSearchQuery(keyword="Socialist"))
    assert len(results) == 1
    assert results[0].id == "Q_SEARCH_1"


@pytest.mark.anyio
async def test_pyq_analytics_engine():
    repo = OfflinePYQRepository()
    source = QuestionSource(
        source_type=SourceType.EDITORIAL_ENTRY,
        publisher="Test Publisher",
        retrieved_date=datetime.now(timezone.utc),
        checksum="chk_analytics",
    )
    q1 = Question(
        id="Q1",
        exam_id="upsc_cse",
        year=2024,
        stage="Prelims",
        paper="GS1",
        subject="Polity",
        topic="Rights",
        original_question="Q1 Text",
        options=[],
        official_answer=Answer(correct_option_keys=["A"]),
        garuda_explanation="Exp",
        source=source,
        tags=["Rights"],
    )
    q2 = Question(
        id="Q2",
        exam_id="bpsc",
        year=2023,
        stage="Prelims",
        paper="GS1",
        subject="Polity",
        topic="Rights",
        original_question="Q2 Text",
        options=[],
        official_answer=Answer(correct_option_keys=["B"]),
        garuda_explanation="Exp",
        source=source,
        tags=["Rights"],
    )
    await repo.save_questions([q1, q2])

    analytics = PYQAnalyticsEngine(repo)
    summary = await analytics.generate_analytics()
    assert summary.topic_frequency["Rights"] == 2
    assert "upsc_cse" in summary.cross_exam_mapping["Rights"]
    assert "bpsc" in summary.cross_exam_mapping["Rights"]


def test_pyq_validators():
    invalid_q = Question(
        id="INV1",
        exam_id="invalid_exam_code",
        year=1850,
        stage="Prelims",
        paper="GS1",
        subject="Polity",
        topic="Rights",
        original_question="Test question text",
        options=[],
        official_answer=Answer(correct_option_keys=["A"]),
        garuda_explanation="Exp",
        source=QuestionSource(
            source_type=SourceType.EDITORIAL_ENTRY,
            publisher="Test",
            retrieved_date=datetime.now(timezone.utc),
            checksum="chk",
        ),
    )

    errors = PYQValidator.validate_question(invalid_q)
    codes = {e.code for e in errors}
    assert ValidationErrorCode.INVALID_EXAM in codes
    assert ValidationErrorCode.INVALID_YEAR in codes
