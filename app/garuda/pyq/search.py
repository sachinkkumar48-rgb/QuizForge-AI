"""
Search Engine for GARUDA National PYQ Repository (Python).
"""
from dataclasses import dataclass
from typing import Dict, List, Optional, Any

from app.garuda.pyq.models import Question
from app.garuda.pyq.repository import IPYQRepository


@dataclass
class PYQSearchQuery:
    exam_id: Optional[str] = None
    year: Optional[int] = None
    subject: Optional[str] = None
    topic: Optional[str] = None
    article: Optional[str] = None
    case_name: Optional[str] = None
    act_name: Optional[str] = None
    keyword: Optional[str] = None
    difficulty: Optional[str] = None
    language: Optional[str] = None

    def to_criteria_map(self) -> Dict[str, Any]:
        return {
            "exam_id": self.exam_id,
            "year": self.year,
            "subject": self.subject,
            "topic": self.topic,
            "article": self.article,
            "case": self.case_name,
            "act": self.act_name,
            "keyword": self.keyword,
            "difficulty": self.difficulty,
            "language": self.language,
        }


class PYQSearchEngine:
    def __init__(self, repository: IPYQRepository) -> None:
        self.repository = repository

    async def search(self, query: PYQSearchQuery) -> List[Question]:
        return await self.repository.search_questions(query.to_criteria_map())

    async def search_by_legal_reference(
        self, article: Optional[str] = None, case_name: Optional[str] = None, act_name: Optional[str] = None
    ) -> List[Question]:
        query = PYQSearchQuery(article=article, case_name=case_name, act_name=act_name)
        return await self.search(query)
