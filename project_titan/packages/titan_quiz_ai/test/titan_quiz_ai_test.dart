import 'package:test/test.dart';
import 'bootstrap/titan_quiz_ai_bootstrap_test.dart' as bootstrap_tests;
import 'parsers/quiz_json_parser_test.dart' as parser_tests;
import 'prompts/quiz_prompt_builder_test.dart' as prompt_tests;
import 'repository/quiz_generation_repository_impl_test.dart'
    as repository_tests;
import 'services/ai_quiz_generation_service_test.dart' as service_tests;
import 'validators/quiz_json_validator_test.dart' as validator_tests;
import 'utils/quiz_ai_utils_test.dart' as utils_tests;

void main() {
  group('Titan Quiz AI Package Main Suite', () {
    prompt_tests.main();
    validator_tests.main();
    parser_tests.main();
    service_tests.main();
    repository_tests.main();
    bootstrap_tests.main();
    utils_tests.main();
  });
}
