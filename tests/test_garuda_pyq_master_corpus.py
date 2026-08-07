"""
Unit & Integration Tests for GARUDA Master PYQ Corpus (1995–2025) Python Module.
"""

import pytest
from app.garuda.pyq import (
    MasterQuestion,
    UPSCMasterCorpusPython,
    generate_master_analytics,
)


def test_upsc_master_corpus_python_coverage():
    questions = UPSCMasterCorpusPython.get_questions_1995_2025()
    assert len(questions) == 31

    years = {q.year for q in questions}
    assert len(years) == 31
    assert min(years) == 1995
    assert max(years) == 2025


def test_upsc_master_question_fields():
    questions = UPSCMasterCorpusPython.get_questions_1995_2025()
    for q in questions:
        assert q.id.startswith("PYQ_UPSC_CSE_")
        assert q.exam_id == "upsc_cse"
        assert q.stage == "Prelims"
        assert q.paper == "GS Paper I"
        assert q.official_answer in ["A", "B", "C", "D"]
        assert len(q.article_links) > 0
        assert len(q.act_links) > 0


def test_generate_master_analytics_python():
    questions = UPSCMasterCorpusPython.get_questions_1995_2025()
    analytics = generate_master_analytics(questions)

    assert analytics["total_questions"] == 31
    assert analytics["years_covered"] == 31
    assert analytics["min_year"] == 1995
    assert analytics["max_year"] == 2025
    assert len(analytics["subject_distribution"]) > 0
    assert len(analytics["article_frequency"]) > 0
