/// GARUDA Editorial Studio Foundation Package for Project TITAN.
/// Single workspace gateway for creating, editing, reviewing, versioning,
/// approving, and publishing GARUDA Knowledge Objects.
library;

// Domain Entities & Enums
export 'domain/entities/audit_log_entry.dart';
export 'domain/entities/dashboard_metrics.dart';
export 'domain/entities/editorial_role.dart';
export 'domain/entities/editorial_status.dart';
export 'domain/entities/knowledge_object.dart';
export 'domain/entities/knowledge_object_version.dart';

// Repositories
export 'domain/repositories/editorial_repository.dart';

// Validators
export 'validators/knowledge_object_validator.dart';

// Infrastructure
export 'infrastructure/in_memory_editorial_repository.dart';

// Application Controller
export 'application/editorial_studio_controller.dart';

// Presentation & Modules
export 'presentation/dashboard_screen.dart';
export 'presentation/editorial_studio_shell.dart';
export 'presentation/evidence_inbox_screen.dart';
export 'presentation/knowledge_object_manager_screen.dart';
export 'presentation/link_review_screen.dart';
export 'presentation/publishing_queue_screen.dart';
export 'presentation/search_screen.dart';
export 'presentation/settings_screen.dart';
export 'presentation/version_history_screen.dart';

// Coverage Dashboard
export 'dashboard/coverage/garuda_coverage_dashboard.dart';

// Editorial Production Engine (TITAN-KO-008.0)
export 'editorial/dashboard/editorial_metrics_engine.dart';
export 'editorial/editorial_search_engine.dart';
export 'editorial/history/editorial_audit_trail.dart';
export 'editorial/history/rollback_service.dart';
export 'editorial/history/version_comparison_service.dart';
export 'editorial/notifications/editorial_notification_service.dart';
export 'editorial/publication/publication_service.dart';
export 'editorial/quality/quality_score_engine.dart';
export 'editorial/review/editorial_assignment_service.dart';
export 'editorial/review/editorial_decision_engine.dart';
export 'editorial/review/editorial_review_service.dart';
export 'editorial/review/review_models.dart';
export 'editorial/verification/quality_gates.dart';
export 'editorial/workflow/editorial_queue.dart';
export 'editorial/workflow/editorial_state_machine.dart';
export 'editorial/workflow/editorial_workflow_engine.dart';
