/// AI Quiz Generation Pipeline package orchestrating PDF text extraction, prompt construction, LLM completion, JSON validation, and Quiz object parsing in Project TITAN.
library titan_quiz_ai;

// Legacy & shared exports
export 'src/bootstrap/titan_quiz_ai_bootstrap.dart';
export 'src/exceptions/quiz_generation_exception.dart';
export 'src/models/generation_statistics.dart';
export 'src/models/quiz_generation_request.dart';
export 'src/models/quiz_generation_result.dart';
export 'src/parsers/quiz_json_parser.dart';
export 'src/prompts/quiz_prompt_builder.dart';
export 'src/repository/quiz_generation_repository.dart';
export 'src/repository/quiz_generation_repository_impl.dart';
export 'src/services/ai_quiz_generation_service.dart';
export 'src/validators/quiz_json_validator.dart';
export 'src/utils/quiz_ai_utils.dart';

// Phase 8B Smart Assessment Domain & Pipeline exports
export 'src/bridge/assessment_source_bridge.dart';
export 'src/models/assessment_blueprint.dart';
export 'src/models/assessment_cancellation_token.dart';
export 'src/models/assessment_generation_request.dart';
export 'src/models/assessment_generation_result.dart';
export 'src/models/assessment_question_type.dart';
export 'src/models/assessment_source.dart';
export 'src/models/generated_question.dart';
export 'src/parsers/assessment_json_parser.dart';
export 'src/prompts/assessment_prompt_builder.dart';
export 'src/services/assessment_chunk_selector.dart';
export 'src/services/assessment_generator.dart';
export 'src/services/default_assessment_generator.dart';
export 'src/services/fake_assessment_generator.dart';
export 'src/validators/assessment_validator.dart';
export 'src/validators/question_deduplicator.dart';

// Phase 8C Interactive Assessment & Remedial Study Loop exports
export 'src/models/answer_status.dart';
export 'src/models/assessment_performance.dart';
export 'src/models/interactive_question_state.dart';
export 'src/models/remedial_study_recommendation.dart';
export 'src/models/retry_mode.dart';
export 'src/services/assessment_performance_analyzer.dart';
