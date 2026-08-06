import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_knowledge/garuda_knowledge.dart';

void main() {
  group('Ingestion Mapping', () {
    test('DefaultKnowledgeMapper converts ExtractionResult into KnowledgeObject', () {
      final doc = KnowledgeDocument.create(
        documentId: 'MAP-001',
        source: const KnowledgeSource(
          sourceId: 'SUPREME_COURT_INDIA',
          title: 'Supreme Court of India',
        ),
        type: KnowledgeDocumentType.supremeCourtJudgment,
        title: 'Kesavananda Bharati v. State of Kerala',
        content: 'Landmark decision on the Basic Structure Doctrine of the Constitution of India.',
        publicationDate: DateTime(1973, 4, 24),
        officialUrl: 'https://supremecourtofindia.nic.in/judgments/kb.pdf',
      );

      final extractor = DefaultKnowledgeExtractor();
      final parseRes = TextKnowledgeParser().parse(doc);
      final extractionRes = extractor.extract(document: doc, parseResult: parseRes);

      final mapper = DefaultKnowledgeMapper();
      final mapRes = mapper.map(document: doc, extraction: extractionRes);

      expect(mapRes.knowledgeObject, isNotNull);
      expect(mapRes.knowledgeObject.id.value, equals('OBJ-MAP-001'));
      expect(mapRes.knowledgeObject.type, equals(KnowledgeObjectType.caseLaw));
      expect(mapRes.knowledgeObject.title, equals('Kesavananda Bharati v. State of Kerala'));
      expect(mapRes.knowledgeObject.citations.length, equals(1));
      expect(mapRes.knowledgeObject.evidenceReferences.length, equals(1));
    });
  });
}
