"""
Repository Pattern Implementation for GARUDA National PYQ Repository (Python).
"""
from abc import ABC, abstractmethod
from typing import Dict, List, Optional, Any

from app.garuda.pyq.models import Paper, Question


class IPYQRepository(ABC):
    @abstractmethod
    async def save_question(self, question: Question) -> None:
        pass

    @abstractmethod
    async def save_questions(self, questions: List[Question]) -> None:
        pass

    @abstractmethod
    async def get_question_by_id(self, id_: str) -> Optional[Question]:
        pass

    @abstractmethod
    async def get_questions_by_exam(
        self, exam_id: str, year: Optional[int] = None, subject: Optional[str] = None
    ) -> List[Question]:
        pass

    @abstractmethod
    async def search_questions(self, criteria: Dict[str, Any]) -> List[Question]:
        pass

    @abstractmethod
    async def delete_question(self, id_: str) -> None:
        pass

    @abstractmethod
    async def get_question_count(self) -> int:
        pass

    @abstractmethod
    async def get_all_questions(self) -> List[Question]:
        pass


class OfflinePYQRepository(IPYQRepository):
    def __init__(self) -> None:
        self._questions: Dict[str, Question] = {}
        self._papers: Dict[str, Paper] = {}

    async def save_question(self, question: Question) -> None:
        self._questions[question.id] = question

    async def save_questions(self, questions: List[Question]) -> None:
        for q in questions:
            self._questions[q.id] = q

    async def get_question_by_id(self, id_: str) -> Optional[Question]:
        return self._questions.get(id_)

    async def get_questions_by_exam(
        self, exam_id: str, year: Optional[int] = None, subject: Optional[str] = None
    ) -> List[Question]:
        res = []
        for q in self._questions.values():
            if q.exam_id.lower() != exam_id.lower():
                continue
            if year is not None and q.year != year:
                continue
            if subject is not None and q.subject.lower() != subject.lower():
                continue
            res.append(q)
        return res

    async def search_questions(self, criteria: Dict[str, Any]) -> List[Question]:
        keyword = criteria.get("keyword")
        exam_id = criteria.get("exam_id")
        year = criteria.get("year")
        subject = criteria.get("subject")
        topic = criteria.get("topic")
        article = criteria.get("article")
        case_name = criteria.get("case")
        act_name = criteria.get("act")
        difficulty = criteria.get("difficulty")
        language = criteria.get("language")

        res = []
        for q in self._questions.values():
            if exam_id and q.exam_id.lower() != exam_id.lower():
                continue
            if year and q.year != year:
                continue
            if subject and q.subject.lower() != subject.lower():
                continue
            if topic and q.topic.lower() != topic.lower():
                continue
            if difficulty and q.difficulty.lower() != difficulty.lower():
                continue
            if language and q.language.lower() != language.lower():
                continue
            if article and not any(article.lower() in a.lower() for a in q.article_links):
                continue
            if case_name and not any(case_name.lower() in c.lower() for c in q.case_links):
                continue
            if act_name and not any(act_name.lower() in ac.lower() for ac in q.act_links):
                continue
            if keyword:
                kw = keyword.lower()
                matches = (
                    kw in q.original_question.lower()
                    or kw in q.garuda_explanation.lower()
                    or kw in q.topic.lower()
                    or any(kw in t.lower() for t in q.tags)
                )
                if not matches:
                    continue
            res.append(q)
        return res

    async def delete_question(self, id_: str) -> None:
        self._questions.pop(id_, None)

    async def get_question_count(self) -> int:
        return len(self._questions)

    async def get_all_questions(self) -> List[Question]:
        return list(self._questions.values())
