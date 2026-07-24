/// Provider-agnostic identity, authentication, session management,
/// and Material 3 profile widgets for Project TITAN.
library titan_identity;

export 'src/auth/auth_provider.dart';
export 'src/auth/email_password_auth_provider.dart';
export 'src/auth/google_auth_provider.dart';
export 'src/auth/guest_auth_provider.dart';
export 'src/auth/token_storage.dart';
export 'src/integration/identity_integration_service.dart';
export 'src/models/user.dart';
export 'src/models/user_session.dart';
export 'src/repository/identity_repository.dart';
export 'src/repository/identity_repository_impl.dart';
export 'src/session/session_manager.dart';
export 'src/use_cases/delete_account_use_case.dart';
export 'src/use_cases/get_current_user_use_case.dart';
export 'src/use_cases/refresh_session_use_case.dart';
export 'src/use_cases/register_user_use_case.dart';
export 'src/use_cases/sign_in_use_case.dart';
export 'src/use_cases/sign_out_use_case.dart';
export 'src/widgets/account_menu.dart';
export 'src/widgets/profile_card.dart';
export 'src/widgets/provider_button.dart';
export 'src/widgets/session_status_chip.dart';
export 'src/widgets/sign_in_button.dart';
export 'src/widgets/user_avatar.dart';
