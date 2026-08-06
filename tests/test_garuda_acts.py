"""
Unit tests for GARUDA Central Acts Library Python Service & Validation Engine.
"""

import pytest
from app.garuda.acts import (
    ActCategory,
    ActKnowledgeObject,
    ActMetadata,
    ActSection,
    ActStatus,
    InMemoryActRepositoryPython,
    generate_act_analytics_python,
    validate_acts_python,
)


@pytest.fixture
def sample_bns_act() -> ActKnowledgeObject:
    return ActKnowledgeObject(
        object_id="ko_bns",
        act_id="act_bns_2023",
        metadata=ActMetadata(
            official_name="The Bharatiya Nyaya Sanhita, 2023",
            short_title="BNS 2023",
            year=2023,
            act_number="45 of 2023",
            status=ActStatus.IN_FORCE,
            category=ActCategory.CRIMINAL,
            ministry="Ministry of Home Affairs",
            gazette_reference="CG-DL-E-25122023-250883",
            official_pdf_url="https://mha.gov.in/bns2023.pdf",
            commencement_date="2024-07-01",
            statement_of_objects_and_reasons="Penal reform",
            applicability="Entire Territory of India",
        ),
        sections=[
            ActSection(
                section_id="sec_bns_103",
                act_id="act_bns_2023",
                section_number="103",
                title="Punishment for Murder",
                content="Whoever commits murder shall be punished with death or life imprisonment.",
                is_important=True,
                keywords=["Murder", "Punishment"],
                related_articles=["Article 21"],
                landmark_cases=["Bachan Singh v. State of Punjab"],
            )
        ],
        landmark_cases=["Bachan Singh v. State of Punjab"],
        related_articles=["Article 21"],
        search_keywords=["BNS", "Murder", "Penal"],
    )


def test_act_knowledge_object_instantiation(sample_bns_act: ActKnowledgeObject):
    assert sample_bns_act.act_id == "act_bns_2023"
    assert sample_bns_act.metadata.year == 2023
    assert len(sample_bns_act.sections) == 1
    assert sample_bns_act.sections[0].section_number == "103"


def test_in_memory_act_repository(sample_bns_act: ActKnowledgeObject):
    repo = InMemoryActRepositoryPython([sample_bns_act])
    assert len(repo.get_all_acts()) == 1

    act = repo.get_act_by_id("act_bns_2023")
    assert act is not None
    assert act.metadata.short_title == "BNS 2023"

    results = repo.search_acts("Murder")
    assert len(results) == 1
    assert results[0].act_id == "act_bns_2023"


def test_validate_acts_python(sample_bns_act: ActKnowledgeObject):
    report = validate_acts_python([sample_bns_act])
    assert report["is_valid"] is True
    assert report["total_validated"] == 1

    dup_report = validate_acts_python([sample_bns_act, sample_bns_act])
    assert dup_report["is_valid"] is False
    assert len(dup_report["issues"]) == 1


def test_generate_act_analytics_python(sample_bns_act: ActKnowledgeObject):
    analytics = generate_act_analytics_python([sample_bns_act])
    assert analytics["acts_covered"] == 1
    assert analytics["sections_covered"] == 1
    assert analytics["landmark_cases_linked"] == 1
    assert analytics["constitutional_articles_linked"] == 1
    assert analytics["coverage_pct"] > 0.0
