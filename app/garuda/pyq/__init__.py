"""
GARUDA National PYQ Repository Foundation Package (Python Module).
Provides Clean Architecture models, repository patterns, search, analytics, ingestion, and validators.
"""

from app.garuda.pyq.models import (
    EditorialStatus,
    SupportedExam,
    Paper,
    QuestionSource,
    SourceType,
    Option,
    Answer,
    TopicMapping,
    EditorialReview,
    QuestionAnalytics,
    QuestionType,
    Question,
)
from app.garuda.pyq.repository import IPYQRepository, OfflinePYQRepository
from app.garuda.pyq.ingestion import (
    DuplicateDetector,
    ManualEntryIngestion,
    JSONIngestion,
    CSVIngestion,
    PDFImportPipeline,
    OCRPipeline,
)
from app.garuda.pyq.search import PYQSearchQuery, PYQSearchEngine
from app.garuda.pyq.analytics import AnalyticsSummary, PYQAnalyticsEngine
from app.garuda.pyq.validators import ValidationErrorCode, ValidationError, PYQValidator
from app.garuda.pyq.master_corpus import (
    MasterQuestion,
    UPSCMasterCorpusPython,
    generate_master_analytics,
)

__all__ = [
    "EditorialStatus",
    "SupportedExam",
    "Paper",
    "QuestionSource",
    "SourceType",
    "Option",
    "Answer",
    "TopicMapping",
    "EditorialReview",
    "QuestionAnalytics",
    "QuestionType",
    "Question",
    "IPYQRepository",
    "OfflinePYQRepository",
    "DuplicateDetector",
    "ManualEntryIngestion",
    "JSONIngestion",
    "CSVIngestion",
    "PDFImportPipeline",
    "OCRPipeline",
    "PYQSearchQuery",
    "PYQSearchEngine",
    "AnalyticsSummary",
    "PYQAnalyticsEngine",
    "ValidationErrorCode",
    "ValidationError",
    "PYQValidator",
    "MasterQuestion",
    "UPSCMasterCorpusPython",
    "generate_master_analytics",
]
