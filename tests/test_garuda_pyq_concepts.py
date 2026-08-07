"""
Unit tests for GARUDA Concept Mapping Engine (Python).
"""
import pytest
from datetime import datetime, timezone

from app.garuda.pyq.concepts import (
    CognitiveLevel,
    Concept,
    ConceptRelationship,
    ConceptValidationService,
    MappingMethod,
    OfflineConceptRepository,
    QuestionConceptMapping,
    QuestionNature,
    ReviewStatus,
)


def test_concept_model_creation():
    now = datetime.now(timezone.utc)
    c = Concept(
        id="C_ART_21",
        name="Right to Life",
        description="Protection of life and personal liberty",
        subject="Polity",
        module="Rights",
        topic="Fundamental Rights",
        created_at=now,
        updated_at=now,
        knowledge_object_ids=["KO_ART_21"],
    )
    assert c.id == "C_ART_21"
    assert c.knowledge_object_ids == ["KO_ART_21"]


@pytest.mark.anyio
async def test_question_concept_mapping_and_auto_rejection():
    repo = OfflineConceptRepository()
    valid_mapping = QuestionConceptMapping(
        question_id="Q100",
        concept_id="C_ART_21",
        confidence_score=0.92,
        mapping_method=MappingMethod.MANUAL,
    )
    assert not valid_mapping.is_auto_rejected

    low_conf_mapping = QuestionConceptMapping(
        question_id="Q100",
        concept_id="C_IRRELEVANT",
        confidence_score=0.30,
        mapping_method=MappingMethod.RULE_BASED,
        review_status=ReviewStatus.REJECTED,
    )
    assert low_conf_mapping.is_auto_rejected

    await repo.save_mapping(valid_mapping)
    await repo.save_mapping(low_conf_mapping)

    mappings = await repo.get_mappings_for_question("Q100")
    assert len(mappings) == 2


def test_detect_circular_relationships():
    rels = [
        ConceptRelationship(id="R1", source_concept_id="C1", target_concept_id="C2"),
        ConceptRelationship(id="R2", source_concept_id="C2", target_concept_id="C3"),
        ConceptRelationship(id="R3", source_concept_id="C3", target_concept_id="C1"),
    ]
    cycles = ConceptValidationService.detect_circular_relationships(rels)
    assert len(cycles) > 0
