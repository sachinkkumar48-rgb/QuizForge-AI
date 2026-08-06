"""
GARUDA Central Acts Knowledge Repository Python Service and Data Models.
Provides Python support for Central Acts, Sections, Search, Validation, and Analytics.
"""

from typing import List, Dict, Any, Optional
from enum import Enum
from pydantic import BaseModel, Field


class ActStatus(str, Enum):
    IN_FORCE = "inForce"
    REPEALED = "repealed"
    AMENDED = "amended"
    PENDING_COMMENCEMENT = "pendingCommencement"
    PARTIALLY_IN_FORCE = "partiallyInForce"


class ActCategory(str, Enum):
    CRIMINAL = "criminal"
    CIVIL = "civil"
    CONSTITUTIONAL = "constitutional"
    COMMERCIAL = "commercial"
    ENVIRONMENTAL = "environmental"
    GOVERNANCE = "governance"
    TAX = "tax"
    SOCIAL_JUSTICE = "socialJustice"
    TECHNOLOGY = "technology"
    SECURITY = "security"
    REGULATORY = "regulatory"


class ActMetadata(BaseModel):
    official_name: str
    short_title: str
    year: int
    act_number: str
    status: ActStatus = ActStatus.IN_FORCE
    category: ActCategory = ActCategory.CIVIL
    ministry: str
    gazette_reference: str
    official_pdf_url: str
    commencement_date: str
    statement_of_objects_and_reasons: str
    applicability: str
    definitions: Dict[str, str] = Field(default_factory=dict)


class ActSection(BaseModel):
    section_id: str
    act_id: str
    chapter_id: Optional[str] = None
    section_number: str
    title: str
    content: str
    explanations: List[str] = Field(default_factory=list)
    exceptions: List[str] = Field(default_factory=list)
    is_important: bool = False
    keywords: List[str] = Field(default_factory=list)
    related_articles: List[str] = Field(default_factory=list)
    landmark_cases: List[str] = Field(default_factory=list)


class ActKnowledgeObject(BaseModel):
    object_id: str
    act_id: str
    metadata: ActMetadata
    sections: List[ActSection] = Field(default_factory=list)
    important_provisions: List[str] = Field(default_factory=list)
    landmark_cases: List[str] = Field(default_factory=list)
    related_articles: List[str] = Field(default_factory=list)
    search_keywords: List[str] = Field(default_factory=list)


class InMemoryActRepositoryPython:
    def __init__(self, acts: Optional[List[ActKnowledgeObject]] = None):
        self._act_map: Dict[str, ActKnowledgeObject] = {}
        if acts:
            for act in acts:
                self.register_act(act)

    def register_act(self, act: ActKnowledgeObject):
        self._act_map[act.act_id] = act

    def get_all_acts(self) -> List[ActKnowledgeObject]:
        return list(self._act_map.values())

    def get_act_by_id(self, act_id: str) -> Optional[ActKnowledgeObject]:
        return self._act_map.get(act_id)

    def search_acts(self, query: str) -> List[ActKnowledgeObject]:
        q = query.strip().lower()
        if not q:
            return self.get_all_acts()
        results = []
        for act in self._act_map.values():
            if (
                q in act.metadata.short_title.lower()
                or q in act.metadata.official_name.lower()
                or any(q in kw.lower() for kw in act.search_keywords)
                or any(q in sec.title.lower() or q in sec.section_number.lower() for sec in act.sections)
            ):
                results.append(act)
        return results


def validate_acts_python(acts: List[ActKnowledgeObject]) -> Dict[str, Any]:
    issues = []
    seen_ids = set()
    for act in acts:
        if act.act_id in seen_ids:
            issues.append(f"Duplicate Act ID: {act.act_id}")
        seen_ids.add(act.act_id)

        if not act.metadata.official_name:
            issues.append(f"Act {act.act_id} missing official name")
        if not act.metadata.short_title:
            issues.append(f"Act {act.act_id} missing short title")

    return {
        "total_validated": len(acts),
        "is_valid": len(issues) == 0,
        "issues": issues,
    }


def generate_act_analytics_python(acts: List[ActKnowledgeObject]) -> Dict[str, Any]:
    total_sections = sum(len(a.sections) for a in acts)
    total_cases = sum(len(a.landmark_cases) for a in acts)
    total_articles = sum(len(a.related_articles) for a in acts)

    return {
        "acts_covered": len(acts),
        "sections_covered": total_sections,
        "landmark_cases_linked": total_cases,
        "constitutional_articles_linked": total_articles,
        "coverage_pct": min(100.0, (len(acts) / 30.0) * 100.0),
    }
