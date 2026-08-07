"""
Analytics Engine for GARUDA National PYQ Repository (Python).
"""
from dataclasses import dataclass
from typing import Dict, List, Optional, Set

from app.garuda.pyq.models import Question
from app.garuda.pyq.repository import IPYQRepository


@dataclass
class AnalyticsSummary:
    topic_frequency: Dict[str, int]
    concept_recurrence: Dict[str, int]
    exam_distribution: Dict[str, int]
    year_trend: Dict[int, int]
    difficulty_distribution: Dict[str, int]
    cross_exam_mapping: Dict[str, List[str]]


class PYQAnalyticsEngine:
    def __init__(self, repository: IPYQRepository) -> None:
        self.repository = repository

    async def generate_analytics(self, exam_id: Optional[str] = None) -> AnalyticsSummary:
        if exam_id:
            questions = await self.repository.get_questions_by_exam(exam_id)
        else:
            questions = await self.repository.get_all_questions()

        topic_freq: Dict[str, int] = {}
        concept_rec: Dict[str, int] = {}
        exam_dist: Dict[str, int] = {}
        year_tr: Dict[int, int] = {}
        diff_dist: Dict[str, int] = {}
        cross_map: Dict[str, Set[str]] = {}

        for q in questions:
            topic_freq[q.topic] = topic_freq.get(q.topic, 0) + 1
            exam_dist[q.exam_id] = exam_dist.get(q.exam_id, 0) + 1
            year_tr[q.year] = year_tr.get(q.year, 0) + 1
            diff_dist[q.difficulty] = diff_dist.get(q.difficulty, 0) + 1

            for tag in q.tags:
                concept_rec[tag] = concept_rec.get(tag, 0) + 1

            if q.topic not in cross_map:
                cross_map[q.topic] = set()
            cross_map[q.topic].add(q.exam_id)

        return AnalyticsSummary(
            topic_frequency=topic_freq,
            concept_recurrence=concept_rec,
            exam_distribution=exam_dist,
            year_trend=year_tr,
            difficulty_distribution=diff_dist,
            cross_exam_mapping={k: list(v) for k, v in cross_map.items()},
        )
