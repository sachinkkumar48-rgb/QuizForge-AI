import 'package:garuda_connectors/garuda_connectors.dart';
import 'package:test/test.dart';

void main() {
  group('CategoryClassifier Tests', () {
    test('Classify Polity, Economy, Environment, Science, Agriculture', () {
      final polity = CategoryClassifier.classifyCategory(
        'Supreme Court Judgement on Constitution Article 370',
        'Landmark verdict by constitutional bench on parliament powers',
      );
      expect(polity, equals('Polity'));

      final economy = CategoryClassifier.classifyCategory(
        'RBI Repo Rate Unchanged',
        'Reserve Bank of India maintains repo rate to control inflation',
      );
      expect(economy, equals('Economy'));

      final env = CategoryClassifier.classifyCategory(
        'National Green Hydrogen Mission Progress',
        'Renewable energy and COP climate targets achieved',
      );
      expect(env, equals('Environment'));

      final science = CategoryClassifier.classifyCategory(
        'ISRO Launches Satellite',
        'Indian Space Research Organisation launches new earth observation satellite',
      );
      expect(science, equals('Science'));

      final agri = CategoryClassifier.classifyCategory(
        'Kisan Credit Card Scheme',
        'MSP and crop insurance for farmers',
      );
      expect(agri, equals('Agriculture'));
    });

    test('extractTags should return relevant keyword tags', () {
      final tags = CategoryClassifier.extractTags(
        'RBI Repo Rate and SEBI Securities Framework',
        'Inflation and banking sector updates',
      );

      expect(tags, contains('RBI'));
      expect(tags, contains('REPO RATE'));
    });
  });
}
