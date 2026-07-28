/// Personalized AI Mentor 2.0 orchestration package for Project TITAN.
library titan_ai_mentor;

export 'src/engine/context_assembler.dart'
    hide
        IdentitySupplier,
        LearningProfileSupplier,
        KnowledgeGraphSupplier,
        SearchSupplier,
        RevisionSupplier,
        RecommendationSupplier,
        PlannerSupplier;
export 'src/engine/context_builder.dart';
export 'src/engine/conversation_memory.dart';
export 'src/engine/conversation_memory_manager.dart';
export 'src/engine/mentor_engine.dart';
export 'src/engine/prompt_builder.dart';
export 'src/models/mentor_context.dart';
export 'src/models/mentor_message.dart';
export 'src/models/mentor_recommendation.dart';
export 'src/models/mentor_session.dart';
export 'src/providers/gemini_mentor_provider.dart';
export 'src/providers/mentor_provider.dart';
export 'src/providers/mock_mentor_provider.dart';
export 'src/providers/openai_mentor_provider.dart';
export 'src/repository/mentor_repository.dart';
export 'src/repository/mentor_repository_impl.dart';
export 'src/use_cases/ask_mentor_use_case.dart';
export 'src/use_cases/continue_conversation_use_case.dart';
export 'src/use_cases/explain_concept_use_case.dart';
export 'src/use_cases/generate_study_plan_use_case.dart';
export 'src/use_cases/suggest_revision_use_case.dart';
export 'src/widgets/mentor_action_card.dart';
export 'src/widgets/mentor_chat_view.dart';
export 'src/widgets/mentor_input_bar.dart';
export 'src/widgets/mentor_message_bubble.dart';
export 'src/widgets/mentor_session_list.dart';
export 'src/widgets/mentor_suggestion_card.dart';
export 'src/widgets/mentor_typing_indicator.dart';
export 'src/widgets/offline_indicator_banner.dart';
export 'src/widgets/provider_status_badge.dart';
