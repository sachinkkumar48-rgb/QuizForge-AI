import 'package:test/test.dart';
import 'bootstrap/titan_quiz_session_bootstrap_test.dart' as bootstrap_tests;
import 'models/quiz_session_models_test.dart' as model_tests;
import 'repository/quiz_session_repository_impl_test.dart' as repository_tests;
import 'services/quiz_progress_service_test.dart' as progress_tests;
import 'services/quiz_session_service_test.dart' as service_tests;
import 'services/quiz_timer_service_test.dart' as timer_tests;
import 'validators/quiz_session_validator_test.dart' as validator_tests;

void main() {
  group('Titan Quiz Session Package Main Suite', () {
    model_tests.main();
    validator_tests.main();
    timer_tests.main();
    progress_tests.main();
    service_tests.main();
    repository_tests.main();
    bootstrap_tests.main();
  });
}
