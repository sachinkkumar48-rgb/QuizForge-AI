/// Live Classes Platform package for Project TITAN.
library titan_live;

export 'src/engine/live_session_engine.dart';
export 'src/integration/live_engine_integrator.dart';
export 'src/models/live_models.dart';
export 'src/repository/live_class_repository.dart';
export 'src/repository/live_class_repository_impl.dart';

// Use Cases
export 'src/use_cases/continue_recorded_class_use_case.dart';
export 'src/use_cases/get_upcoming_classes_use_case.dart';
export 'src/use_cases/join_live_class_use_case.dart';
export 'src/use_cases/leave_live_class_use_case.dart';
export 'src/use_cases/mark_attendance_use_case.dart';
export 'src/use_cases/schedule_live_class_use_case.dart';
export 'src/use_cases/send_chat_message_use_case.dart';
export 'src/use_cases/start_recording_use_case.dart';
export 'src/use_cases/stop_recording_use_case.dart';
export 'src/use_cases/submit_poll_use_case.dart';

// Widgets
export 'src/widgets/attendance_card.dart';
export 'src/widgets/chat_panel.dart';
export 'src/widgets/instructor_profile_card.dart';
export 'src/widgets/join_session_button.dart';
export 'src/widgets/live_class_card.dart';
export 'src/widgets/live_player.dart';
export 'src/widgets/live_schedule_card.dart';
export 'src/widgets/participant_grid.dart';
export 'src/widgets/poll_widget.dart';
export 'src/widgets/recording_card.dart';
export 'src/widgets/reminder_card.dart';
export 'src/widgets/session_timeline.dart';
export 'src/widgets/upcoming_classes_card.dart';
export 'src/widgets/whiteboard_panel.dart';
