"""
GARUDA AI Module Package Initializer.
Re-exports clean domain entities, value objects, exceptions, interfaces, provider framework,
conversation framework, agent framework, Gemini provider, Knowledge Engine, Learning Profile Engine,
Recommendation Engine, Adaptive Revision Engine, Smart Study Planner, Integration Orchestrator,
and Learner-Facing Tutor Workflow components.
"""
from app.garuda.agents import (
    AgentException,
    AgentFactory,
    AgentNotFoundException,
    AgentRegistry,
    BaseAgent,
    PlannerAgent,
    QuizAgent,
    RevisionAgent,
    TutorAgent,
)
from app.garuda.conversation import (
    ConversationContext,
    ConversationException,
    ConversationStrategy,
    InvalidPromptTemplateException,
    PromptBuilder,
    PromptTemplate,
    StrategyNotFoundException,
    TutorPersona,
)
from app.garuda.domain import (
    ChatMessage,
    ConversationSession,
    ConversationSessionNotFoundException,
    GarudaException,
    GarudaSession,
    InvalidMessageException,
    LearningProfile,
    LearningProfileNotFoundException,
    MessageRole,
    ProviderUnavailableException,
    TopicMastery,
)
from app.garuda.gemini_provider import GeminiProvider
from app.garuda.interfaces import (
    IAIServiceProvider,
    IConversationService,
    IConversationSessionRepository,
    IKnowledgeStore,
    ILearningProfileRepository,
    ILearningProfileService,
)
from app.garuda.knowledge import (
    DocumentNotFoundException,
    EmbeddingServiceException,
    IChunkingService,
    IEmbeddingService,
    InMemoryVectorStore,
    IRetriever,
    IVectorStore,
    KnowledgeChunk,
    KnowledgeDocument,
    KnowledgeEngineException,
    SimpleRetriever,
    VectorStoreException,
    cosine_similarity,
)
from app.garuda.orchestrator import (
    GarudaOrchestrator,
    GarudaTutoringResponse,
)
from app.garuda.planner import (
    DailySchedule,
    RevisionFirstTimeAllocationStrategy,
    StudyPlan,
    StudyPlanGenerator,
    StudyPlannerService,
    StudyTask,
    TaskPriority,
    TaskType,
    TimeAllocationStrategy,
    WeeklyPlanner,
)
from app.garuda.profile import (
    LearningProfileService,
    LearningStatistics,
    MasteryCalculator,
    RevisionReadinessCalculator,
    TopicProgress,
    WeakTopicDetector,
)
from app.garuda.providers import (
    AIProviderFactory,
    AIProviderRegistry,
    BaseAIProvider,
)
from app.garuda.recommendation import (
    DailyStudyRecommendation,
    MaintainStreakRule,
    NextBestActionCalculator,
    OverdueRevisionRule,
    PracticeQuizRule,
    Recommendation,
    RecommendationPriority,
    RecommendationReason,
    RecommendationRule,
    RecommendationService,
    RecommendationType,
    ReinforceStrongRule,
    TakeBreakRule,
    WeakTopicRevisionRule,
)
from app.garuda.revision import (
    AdaptiveRevisionEngine,
    RevisionItem,
    RevisionItemType,
    RevisionPriority,
    RevisionQueue,
    RevisionScheduler,
    RevisionSession,
)
from app.garuda.pdf_workflow import (
    PDFKnowledgeSession,
    PDFKnowledgeWorkflow,
    PDFKnowledgeWorkflowResult,
    SimpleChunkingService,
)
from app.garuda.workflow import (
    TutorSession,
    TutorWorkflow,
    TutorWorkflowResult,
)


__all__ = [
    # Domain & Exceptions
    "MessageRole",
    "ChatMessage",
    "ConversationSession",
    "TopicMastery",
    "LearningProfile",
    "GarudaSession",
    "GarudaException",
    "LearningProfileNotFoundException",
    "ConversationSessionNotFoundException",
    "InvalidMessageException",
    "ProviderUnavailableException",
    # Interfaces
    "ILearningProfileRepository",
    "IConversationSessionRepository",
    "IAIServiceProvider",
    "IKnowledgeStore",
    "ILearningProfileService",
    "IConversationService",
    # Provider Framework
    "BaseAIProvider",
    "AIProviderRegistry",
    "AIProviderFactory",
    "GeminiProvider",
    # Conversation & Prompt Framework
    "ConversationContext",
    "PromptTemplate",
    "PromptBuilder",
    "TutorPersona",
    "ConversationStrategy",
    "ConversationException",
    "InvalidPromptTemplateException",
    "StrategyNotFoundException",
    # Agent Framework
    "BaseAgent",
    "TutorAgent",
    "PlannerAgent",
    "RevisionAgent",
    "QuizAgent",
    "AgentRegistry",
    "AgentFactory",
    "AgentException",
    "AgentNotFoundException",
    # Knowledge Engine (RAG)
    "KnowledgeDocument",
    "KnowledgeChunk",
    "IChunkingService",
    "IEmbeddingService",
    "IVectorStore",
    "IRetriever",
    "InMemoryVectorStore",
    "SimpleRetriever",
    "cosine_similarity",
    "KnowledgeEngineException",
    "DocumentNotFoundException",
    "EmbeddingServiceException",
    "VectorStoreException",
    # Learning Profile Engine
    "TopicProgress",
    "LearningStatistics",
    "MasteryCalculator",
    "WeakTopicDetector",
    "RevisionReadinessCalculator",
    "LearningProfileService",
    # Recommendation Engine
    "Recommendation",
    "RecommendationPriority",
    "RecommendationType",
    "RecommendationReason",
    "RecommendationRule",
    "WeakTopicRevisionRule",
    "OverdueRevisionRule",
    "MaintainStreakRule",
    "PracticeQuizRule",
    "TakeBreakRule",
    "ReinforceStrongRule",
    "NextBestActionCalculator",
    "DailyStudyRecommendation",
    "RecommendationService",
    # Adaptive Revision Engine
    "RevisionItem",
    "RevisionPriority",
    "RevisionItemType",
    "RevisionQueue",
    "RevisionScheduler",
    "RevisionSession",
    "AdaptiveRevisionEngine",
    # Smart Study Planner
    "StudyTask",
    "TaskType",
    "TaskPriority",
    "DailySchedule",
    "StudyPlan",
    "TimeAllocationStrategy",
    "RevisionFirstTimeAllocationStrategy",
    "WeeklyPlanner",
    "StudyPlanGenerator",
    "StudyPlannerService",
    # Integration Orchestrator
    "GarudaOrchestrator",
    "GarudaTutoringResponse",
    # Tutor Workflow
    "TutorSession",
    "TutorWorkflow",
    "TutorWorkflowResult",
    # PDF Knowledge Workflow
    "PDFKnowledgeSession",
    "PDFKnowledgeWorkflow",
    "PDFKnowledgeWorkflowResult",
    "SimpleChunkingService",
]

