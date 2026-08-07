"""
Ingestion Utilities for GARUDA National PYQ Repository (Python).
"""
import json
from datetime import datetime, timezone
from typing import Dict, List, Any

from app.garuda.pyq.models import (
    Answer,
    EditorialStatus,
    Option,
    Question,
    QuestionSource,
    SourceType,
)


class DuplicateDetector:
    @staticmethod
    def find_duplicates(existing: List[Question], incoming: List[Question]) -> List[Question]:
        duplicates = []
        existing_ids = {q.id for q in existing}
        existing_checksums = {q.source.checksum for q in existing if q.source.checksum}
        existing_texts = {q.original_question.strip().lower() for q in existing}

        for inc in incoming:
            norm_text = inc.original_question.strip().lower()
            if (
                inc.id in existing_ids
                or (inc.source.checksum and inc.source.checksum in existing_checksums)
                or norm_text in existing_texts
            ):
                duplicates.append(inc)
        return duplicates


class ManualEntryIngestion:
    @staticmethod
    def create_question(
        id_: str,
        exam_id: str,
        year: int,
        stage: str,
        paper: str,
        subject: str,
        topic: str,
        original_question: str,
        raw_options: List[Dict[str, Any]],
        correct_keys: List[str],
        garuda_explanation: str,
        reviewer_name: str,
        subtopic: str = "",
        difficulty: str = "Medium",
        language: str = "en",
        marks: float = 2.0,
        negative_marks: float = 0.66,
        article_links: List[str] = None,
        case_links: List[str] = None,
        act_links: List[str] = None,
        tags: List[str] = None,
    ) -> Question:
        options = [
            Option(
                key=opt["key"],
                text=opt["text"],
                explanation=opt.get("explanation"),
                is_correct=(opt["key"] in correct_keys),
            )
            for opt in raw_options
        ]

        source = QuestionSource(
            source_type=SourceType.EDITORIAL_ENTRY,
            publisher="GARUDA Manual Entry",
            retrieved_date=datetime.now(timezone.utc),
            verified_date=datetime.now(timezone.utc),
            reviewer=reviewer_name,
            checksum=f"manual_{id_}",
        )

        return Question(
            id=id_,
            exam_id=exam_id,
            year=year,
            stage=stage,
            paper=paper,
            subject=subject,
            topic=topic,
            subtopic=subtopic or None,
            original_question=original_question,
            options=options,
            official_answer=Answer(correct_option_keys=correct_keys),
            garuda_explanation=garuda_explanation,
            difficulty=difficulty,
            language=language,
            marks=marks,
            negative_marks=negative_marks,
            source=source,
            verification_status="Verified",
            editorial_status=EditorialStatus.VERIFIED,
            article_links=article_links or [],
            case_links=case_links or [],
            act_links=act_links or [],
            tags=tags or [],
        )


class JSONIngestion:
    @staticmethod
    def parse_questions_json(json_str: str) -> List[Question]:
        data = json.loads(json_str)
        res = []
        for item in data:
            source_data = item["source"]
            source = QuestionSource(
                source_type=SourceType(source_data["sourceType"]),
                publisher=source_data.get("publisher", "Archive"),
                retrieved_date=datetime.fromisoformat(source_data["retrievedDate"]),
                checksum=source_data.get("checksum", ""),
            )
            options = [
                Option(
                    key=o["key"],
                    text=o["text"],
                    explanation=o.get("explanation"),
                    is_correct=o.get("isCorrect", False),
                )
                for o in item.get("options", [])
            ]
            ans = Answer(
                correct_option_keys=item["officialAnswer"]["correctOptionKeys"],
                descriptive_answer=item["officialAnswer"].get("descriptiveAnswer"),
            )
            q = Question(
                id=item["id"],
                exam_id=item["examId"],
                year=item["year"],
                stage=item["stage"],
                paper=item["paper"],
                subject=item["subject"],
                topic=item["topic"],
                original_question=item["originalQuestion"],
                options=options,
                official_answer=ans,
                garuda_explanation=item.get("garudaExplanation", ""),
                source=source,
                difficulty=item.get("difficulty", "Medium"),
                language=item.get("language", "en"),
                article_links=item.get("articleLinks", []),
                tags=item.get("tags", []),
            )
            res.append(q)
        return res


class CSVIngestion:
    @staticmethod
    def parse_csv_rows(rows: List[List[str]]) -> List[Question]:
        if not rows:
            return []

        questions = []
        start_idx = 1 if rows[0][0].lower() == "id" else 0
        for i in range(start_idx, len(rows)):
            row = rows[i]
            if len(row) < 13:
                continue
            id_ = row[0].strip()
            exam_id = row[1].strip()
            year = int(row[2].strip()) if row[2].strip().isdigit() else 2024
            stage = row[3].strip()
            paper = row[4].strip()
            subject = row[5].strip()
            topic = row[6].strip()
            q_text = row[7].strip()
            opt_a, opt_b, opt_c, opt_d = row[8].strip(), row[9].strip(), row[10].strip(), row[11].strip()
            correct_key = row[12].strip().upper()
            exp = row[13].strip() if len(row) > 13 else ""

            options = [
                Option(key="A", text=opt_a, is_correct=(correct_key == "A")),
                Option(key="B", text=opt_b, is_correct=(correct_key == "B")),
                Option(key="C", text=opt_c, is_correct=(correct_key == "C")),
                Option(key="D", text=opt_d, is_correct=(correct_key == "D")),
            ]

            source = QuestionSource(
                source_type=SourceType.VERIFIED_ARCHIVE,
                publisher="CSV Pipeline",
                retrieved_date=datetime.now(timezone.utc),
                checksum=f"csv_{id_}",
            )

            questions.append(
                Question(
                    id=id_,
                    exam_id=exam_id,
                    year=year,
                    stage=stage,
                    paper=paper,
                    subject=subject,
                    topic=topic,
                    original_question=q_text,
                    options=options,
                    official_answer=Answer(correct_option_keys=[correct_key]),
                    garuda_explanation=exp,
                    source=source,
                )
            )
        return questions


class PDFImportPipeline:
    async def parse_pdf_content(self, pdf_file_path: str, exam_id: str, year: int, stage: str, paper: str) -> List[Question]:
        return []


class OCRPipeline:
    @staticmethod
    def process_ocr_result(question_draft: Question, ocr_text: str) -> Question:
        return Question(
            id=question_draft.id,
            exam_id=question_draft.exam_id,
            year=question_draft.year,
            stage=question_draft.stage,
            paper=question_draft.paper,
            subject=question_draft.subject,
            topic=question_draft.topic,
            original_question=ocr_text.strip(),
            options=question_draft.options,
            official_answer=question_draft.official_answer,
            garuda_explanation=question_draft.garuda_explanation,
            source=question_draft.source,
            editorial_status=EditorialStatus.VERIFICATION_PENDING,
            verification_status="Pending Verification",
        )
