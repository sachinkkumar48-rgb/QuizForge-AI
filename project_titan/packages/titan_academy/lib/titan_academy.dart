/// TITAN Academy – Course Management System package for Project TITAN.
///
/// Implements Clean Architecture for course browsing, enrollment, progress tracking,
/// and Material 3 dashboard components with cross-engine TITAN integrations.
library titan_academy;

export 'src/integration/academy_engine_integrator.dart';
export 'src/models/academy_models.dart';
export 'src/repository/academy_repository.dart';
export 'src/repository/academy_repository_impl.dart';
export 'src/use_cases/browse_courses_use_case.dart';
export 'src/use_cases/continue_learning_use_case.dart';
export 'src/use_cases/enroll_course_use_case.dart';
export 'src/use_cases/get_course_use_case.dart';
export 'src/use_cases/update_progress_use_case.dart';
export 'src/widgets/academy_dashboard.dart';
export 'src/widgets/chapter_list.dart';
export 'src/widgets/continue_learning_card.dart';
export 'src/widgets/course_card.dart';
export 'src/widgets/course_details_page.dart';
export 'src/widgets/lesson_card.dart';
