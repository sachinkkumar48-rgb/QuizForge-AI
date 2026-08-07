"""
Domain Models for GARUDA National PYQ Repository.
"""
from dataclasses import dataclass, field
from datetime import datetime, timezone
from enum import Enum
from typing import Dict, List, Optional, Any, Set


class EditorialStatus(str, Enum):
    IMPORTED = "imported"
    OCR_PENDING = "ocrPending"
    VERIFICATION_PENDING = "verificationPending"
    VERIFIED = "verified"
    MAPPED = "mapped"
    PUBLISHED = "published"
    ARCHIVED = "archived"


class SourceType(str, Enum):
    OFFICIAL_WEBSITE = "officialWebsite"
    OFFICIAL_PDF = "officialPdf"
    VERIFIED_ARCHIVE = "verifiedArchive"
    EDITORIAL_ENTRY = "editorialEntry"


class QuestionType(str, Enum):
    MCQ = "mcq"
    ASSERTION_REASON = "assertionReason"
    MATCHING = "matching"
    MULTIPLE_CORRECT = "multipleCorrect"
    DESCRIPTIVE = "descriptive"


@dataclass(frozen=True)
class SupportedExam:
    id: str
    code: str
    full_name: str
    conducting_body: str
    category: str = "custom"

    @classmethod
    def initial_exams(cls) -> List["SupportedExam"]:
        return [
            cls("upsc_cse", "UPSC_CSE", "UPSC Civil Services Examination", "Union Public Service Commission", "centralCivilServices"),
            cls("cds", "CDS", "Combined Defence Services Examination", "Union Public Service Commission", "defenseServices"),
            cls("nda", "NDA", "National Defence Academy Examination", "Union Public Service Commission", "defenseServices"),
            cls("capf", "CAPF", "Central Armed Police Forces (AC)", "Union Public Service Commission", "defenseServices"),
            cls("epfo_eo_ao", "EPFO_EO_AO", "EPFO Enforcement Officer / Accounts Officer", "Union Public Service Commission", "centralCivilServices"),
            cls("epfo_apfc", "EPFO_APFC", "EPFO Assistant Provident Fund Commissioner", "Union Public Service Commission", "centralCivilServices"),
            cls("ese_gs", "ESE_GS", "Engineering Services Examination (General Studies)", "Union Public Service Commission", "centralCivilServices"),
            cls("rbi_grade_b", "RBI_GRADE_B", "RBI Grade B Officer Examination", "Reserve Bank of India", "regulatoryAndBanking"),
            cls("nabard_grade_a", "NABARD_GRADE_A", "NABARD Grade A Assistant Manager", "NABARD", "regulatoryAndBanking"),
            cls("sebi_grade_a", "SEBI_GRADE_A", "SEBI Grade A Assistant Manager", "Securities and Exchange Board of India", "regulatoryAndBanking"),
            cls("bpsc", "BPSC", "Bihar Public Service Commission Combined Competitive Exam", "Bihar Public Service Commission", "statePublicService"),
            cls("uppsc", "UPPSC", "Uttar Pradesh Combined State / Upper Subordinate Services", "Uttar Pradesh Public Service Commission", "statePublicService"),
            cls("mppsc", "MPPSC", "Madhya Pradesh State Service Examination", "Madhya Pradesh Public Service Commission", "statePublicService"),
            cls("rpsc", "RPSC", "Rajasthan State and Subordinate Services (RAS/RTS)", "Rajasthan Public Service Commission", "statePublicService"),
            cls("mpsc", "MPSC", "Maharashtra State Services Examination", "Maharashtra Public Service Commission", "statePublicService"),
            cls("jpsc", "JPSC", "Jharkhand Combined Civil Services Examination", "Jharkhand Public Service Commission", "statePublicService"),
            cls("cgpsc", "CGPSC", "Chhattisgarh State Service Examination", "Chhattisgarh Public Service Commission", "statePublicService"),
            cls("ukpsc", "UKPSC", "Uttarakhand Combined State Civil Services", "Uttarakhand Public Service Commission", "statePublicService"),
            cls("opsc", "OPSC", "Odisha Civil Services Examination", "Odisha Public Service Commission", "statePublicService"),
            cls("gpsc", "GPSC", "Gujarat Civil Services Examination", "Gujarat Public Service Commission", "statePublicService"),
            cls("ppsc", "PPSC", "Punjab State Civil Services Combined Competitive Exam", "Punjab Public Service Commission", "statePublicService"),
            cls("kpsc", "KPSC", "Karnataka Gazette Officers Combined Competitive Exam", "Karnataka Public Service Commission", "statePublicService"),
            cls("tnpsc", "TNPSC", "Tamil Nadu Public Service Commission Group I", "Tamil Nadu Public Service Commission", "statePublicService"),
            cls("wbpsc", "WBPSC", "West Bengal Civil Service (Executive) Examination", "West Bengal Public Service Commission", "statePublicService"),
        ]


@dataclass(frozen=True)
class Paper:
    id: str
    exam_id: str
    year: int
    stage: str
    paper_name: str
    shift: Optional[str] = None
    total_questions: int = 100
    duration_minutes: int = 120
    default_language: str = "en"


@dataclass(frozen=True)
class QuestionSource:
    source_type: SourceType
    publisher: str
    retrieved_date: datetime
    checksum: str
    url: Optional[str] = None
    verified_date: Optional[datetime] = None
    reviewer: Optional[str] = None


@dataclass(frozen=True)
class Option:
    key: str
    text: str
    explanation: Optional[str] = None
    is_correct: bool = False


@dataclass(frozen=True)
class Answer:
    correct_option_keys: List[str]
    descriptive_answer: Optional[str] = None
    official_answer_source: str = "Official Answer Key"
    verified_date: Optional[datetime] = None
    is_dropped: bool = False


@dataclass(frozen=True)
class TopicMapping:
    subject: str
    topic: str
    subtopic: Optional[str] = None
    microtopic: Optional[str] = None
    taxonomy_codes: List[str] = field(default_factory=list)


@dataclass(frozen=True)
class EditorialReview:
    reviewer_id: str
    status: str
    comments: str
    timestamp: datetime
    checklist: Dict[str, bool] = field(default_factory=dict)


@dataclass(frozen=True)
class QuestionAnalytics:
    appearance_frequency: int = 1
    concept_recurrence_count: int = 0
    exam_distribution: Dict[str, int] = field(default_factory=dict)
    year_trend: Dict[int, int] = field(default_factory=dict)
    difficulty_distribution: Dict[str, float] = field(default_factory=dict)
    cross_exam_mapped_ids: List[str] = field(default_factory=list)


@dataclass(frozen=True)
class Question:
    id: str
    exam_id: str
    year: int
    stage: str
    paper: str
    subject: str
    topic: str
    original_question: str
    options: List[Option]
    official_answer: Answer
    garuda_explanation: str
    source: QuestionSource
    shift: Optional[str] = None
    subtopic: Optional[str] = None
    question_type: QuestionType = QuestionType.MCQ
    difficulty: str = "Medium"
    language: str = "en"
    marks: float = 2.0
    negative_marks: float = 0.66
    verification_status: str = "Verified"
    editorial_status: EditorialStatus = EditorialStatus.PUBLISHED
    editorial_reviews: List[EditorialReview] = field(default_factory=list)
    analytics: QuestionAnalytics = field(default_factory=QuestionAnalytics)
    knowledge_object_links: List[str] = field(default_factory=list)
    article_links: List[str] = field(default_factory=list)
    act_links: List[str] = field(default_factory=list)
    case_links: List[str] = field(default_factory=list)
    amendment_links: List[str] = field(default_factory=list)
    committee_links: List[str] = field(default_factory=list)
    report_links: List[str] = field(default_factory=list)
    current_affairs_links: List[str] = field(default_factory=list)
    related_question_ids: List[str] = field(default_factory=list)
    tags: List[str] = field(default_factory=list)
