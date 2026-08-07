"""
Python Domain Bridge for GARUDA Concept Mapping Engine (TITAN-PYQ-002).
"""
from dataclasses import dataclass, field
from datetime import datetime, timezone
from enum import Enum
from typing import Dict, List, Optional, Set

from app.garuda.pyq.models import Question, EditorialStatus


class CognitiveLevel(str, Enum):
    REMEMBER = "remember"
    UNDERSTAND = "understand"
    APPLY = "apply"
    ANALYZE = "analyze"
    EVALUATE = "evaluate"
    CREATE = "create"


class QuestionNature(str, Enum):
    FACTUAL = "factual"
    CONCEPTUAL = "conceptual"
    ANALYTICAL = "analytical"
    STATEMENT_BASED = "statementBased"
    ASSERTION_REASON = "assertionReason"
    MATCH_THE_FOLLOWING = "matchTheFollowing"
    CHRONOLOGY = "chronology"
    CASE_BASED = "caseBased"
    MULTI_STATEMENT = "multiStatement"
    MAP_BASED = "mapBased"
    DATA_BASED = "dataBased"


class MappingMethod(str, Enum):
    MANUAL = "manual"
    RULE_BASED = "ruleBased"
    KNOWLEDGE_GRAPH_ASSISTED = "knowledgeGraphAssisted"
    FUTURE_AI_SUGGESTED = "futureAiSuggested"


class ReviewStatus(str, Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"
    FLAGGED = "flagged"


@dataclass(frozen=True)
class Concept:
    id: str
    name: str
    description: str
    subject: str
    module: str
    topic: str
    created_at: datetime
    updated_at: datetime
    subtopic: Optional[str] = None
    aliases: List[str] = field(default_factory=list)
    keywords: List[str] = field(default_factory=list)
    difficulty: str = "Medium"
    knowledge_object_ids: List[str] = field(default_factory=list)
    related_concept_ids: List[str] = field(default_factory=list)
    related_evidence_ids: List[str] = field(default_factory=list)
    editorial_status: EditorialStatus = EditorialStatus.PUBLISHED
    version: int = 1


@dataclass(frozen=True)
class QuestionConceptMapping:
    question_id: str
    concept_id: str
    confidence_score: float
    mapping_method: MappingMethod
    review_status: ReviewStatus = ReviewStatus.PENDING
    reviewed_by: Optional[str] = None
    reviewed_at: Optional[datetime] = None
    remarks: Optional[str] = None

    @property
    def is_auto_rejected(self) -> bool:
        return self.confidence_score < 0.50


@dataclass(frozen=True)
class ConceptRelationship:
    id: str
    source_concept_id: str
    target_concept_id: str
    relationship_type: str = "prerequisite"
    strength: float = 1.0


class OfflineConceptRepository:
    def __init__(self) -> None:
        self._concepts: Dict[str, Concept] = {}
        self._relationships: Dict[str, ConceptRelationship] = {}
        self._mappings: Dict[str, QuestionConceptMapping] = {}

    async def save_concept(self, concept: Concept) -> None:
        self._concepts[concept.id] = concept

    async def get_concept_by_id(self, id_: str) -> Optional[Concept]:
        return self._concepts.get(id_)

    async def save_mapping(self, mapping: QuestionConceptMapping) -> None:
        key = f"{mapping.question_id}_{mapping.concept_id}"
        self._mappings[key] = mapping

    async def get_mappings_for_question(self, question_id: str) -> List[QuestionConceptMapping]:
        return [m for m in self._mappings.values() if m.question_id == question_id]

    async def save_relationship(self, relationship: ConceptRelationship) -> None:
        self._relationships[relationship.id] = relationship

    async def get_all_relationships(self) -> List[ConceptRelationship]:
        return list(self._relationships.values())


class ConceptValidationService:
    @staticmethod
    def detect_circular_relationships(relationships: List[ConceptRelationship]) -> List[str]:
        adj: Dict[str, List[String]] = {}
        for rel in relationships:
            adj.setdefault(rel.source_concept_id, []).append(rel.target_concept_id)

        visited: Set[str] = set()
        rec_stack: Set[str] = set()
        circular_nodes = []

        def dfs(node: str) -> bool:
            visited.add(node)
            rec_stack.add(node)
            for neighbor in adj.get(node, []):
                if neighbor not in visited:
                    if dfs(neighbor):
                        return True
                elif neighbor in rec_stack:
                    return True
            rec_stack.remove(node)
            return False

        for node in list(adj.keys()):
            if node not in visited:
                if dfs(node):
                    circular_nodes.append(node)
        return circular_nodes
