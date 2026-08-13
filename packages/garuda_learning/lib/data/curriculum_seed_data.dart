/// Seed Data for UPSC Constitutional Law Curriculum (TITAN-KO-017.0 P17).
///
/// Offline-first, evidence-backed curriculum framework seed mapping to existing
/// P11–P16 Knowledge Products.
library;

import 'package:garuda_case_law/garuda_case_law.dart'
    show KnowledgeProductType, ProvisionType;

import '../domain/entities/bloom_taxonomy_level.dart';
import '../domain/entities/curriculum_domain.dart';
import '../domain/entities/curriculum_framework.dart';
import '../domain/entities/curriculum_unit.dart';
import '../domain/entities/curriculum_version.dart';
import '../domain/entities/knowledge_product_mapping.dart';
import '../domain/entities/learning_objective.dart';
import '../domain/entities/prerequisite_relationship.dart';
import '../domain/entities/static_mastery_criteria.dart';

class CurriculumSeedData {
  /// Builds the canonical UPSC Constitutional Law Curriculum Framework.
  static CurriculumFramework buildUpscConstitutionalLawFramework() {
    return CurriculumFramework(
      id: 'titan_upsc_constitutional_law_framework',
      title: 'UPSC Indian Polity & Constitutional Law Curriculum',
      description:
          'Evidence-backed, versioned curriculum framework organizing Indian Constitutional Law knowledge products into structured learning objectives and explicit prerequisite sequences.',
      version: CurriculumVersion(
        version: '1.0.0',
        schemaVersion: '1.0',
        effectiveDate: '2026-08-15',
        provenance: 'UPSC GS Paper II Syllabus & GARUDA Corpus Specification',
        releaseNotes: 'Initial P17 authoritative curriculum release.',
      ),
      provenance: 'UPSC_GS2_CONSTITUTIONAL_LAW_SPEC_2026',
      domains: [
        CurriculumDomain(
          id: 'domain_constitutional_foundations',
          title: 'Constitutional Foundations & Fundamental Rights',
          description:
              'Foundational principles of the Indian Constitution, basic structure doctrine, and fundamental rights guarantees.',
          sequenceIndex: 1,
          provenance: 'UPSC GS2 Domain I',
          units: [
            CurriculumUnit(
              id: 'unit_preamble_and_basic_structure',
              domainId: 'domain_constitutional_foundations',
              title: 'Preamble & Basic Structure Doctrine',
              description:
                  'Pedagogical progression from constitutional preamble identity to the Basic Structure limits on amending power.',
              sequenceIndex: 1,
              provenance: 'UPSC GS2 Unit 1.1',
              objectives: [
                LearningObjective(
                  id: 'lo_preamble_identity',
                  unitId: 'unit_preamble_and_basic_structure',
                  title:
                      'Understand the Preamble as the Key to the Constitution',
                  description:
                      'Analyze the legal status, objectives, and legal interpretative value of the Preamble.',
                  bloomLevel: BloomTaxonomyLevel.understand,
                  sequenceIndex: 1,
                  provenance: 'Syllabus Item 1.1.1',
                  masteryCriteria: StaticMasteryCriteria(
                    minRequiredProducts: 1,
                    description: 'Requires basic preamble statutory coverage.',
                  ),
                  supportedProducts: [
                    KnowledgeProductMapping(
                      productType: KnowledgeProductType.topic,
                      productId: 'amending_power_and_basic_structure',
                      title: 'Amending Power & Basic Structure Doctrine',
                      provenance: 'P14 Topic Corpus',
                      role: 'syllabus_topic',
                    ),
                  ],
                ),
                LearningObjective(
                  id: 'lo_basic_structure_doctrine',
                  unitId: 'unit_preamble_and_basic_structure',
                  title: 'Analyze the Basic Structure Doctrine',
                  description:
                      'Examine the evolution and judicial limits imposed on Parliament amending power under Article 368.',
                  bloomLevel: BloomTaxonomyLevel.analyze,
                  sequenceIndex: 2,
                  provenance: 'Syllabus Item 1.1.2',
                  prerequisites: [
                    PrerequisiteRelationship(
                      prerequisiteObjectiveId: 'lo_preamble_identity',
                      provenance: 'Syllabus Rule 1.1.2.a',
                      rationale:
                          'Preamble identity concepts must be understood before basic structure limits can be analyzed.',
                    ),
                  ],
                  masteryCriteria: StaticMasteryCriteria(
                    minRequiredProducts: 2,
                    mandatoryProductIds: ['KESAVANANDA', 'BASIC_STRUCTURE'],
                    description:
                        'Requires Kesavananda landmark case and Basic Structure doctrine product.',
                  ),
                  supportedProducts: [
                    KnowledgeProductMapping(
                      productType: KnowledgeProductType.caseLaw,
                      productId: 'KESAVANANDA',
                      title: 'Kesavananda Bharati v. State of Kerala (1973)',
                      provenance: 'P11 Case Explanation Corpus',
                      role: 'leading_case',
                    ),
                    KnowledgeProductMapping(
                      productType: KnowledgeProductType.doctrine,
                      productId: 'BASIC_STRUCTURE',
                      title: 'Basic Structure Doctrine',
                      provenance: 'P12 Doctrine Knowledge Corpus',
                      role: 'doctrine_core',
                    ),
                  ],
                ),
              ],
            ),
            CurriculumUnit(
              id: 'unit_personal_liberty_art21',
              domainId: 'domain_constitutional_foundations',
              title: 'Right to Life & Personal Liberty (Article 21)',
              description:
                  'Substantive and procedural guarantees of Article 21, due process of law, and privacy jurisprudence.',
              sequenceIndex: 2,
              provenance: 'UPSC GS2 Unit 1.2',
              objectives: [
                LearningObjective(
                  id: 'lo_article_21_foundations',
                  unitId: 'unit_personal_liberty_art21',
                  title: 'Evaluate the Expansion of Article 21 Rights',
                  description:
                      'Trace the transformation from procedure established by law to due process of law under Article 21.',
                  bloomLevel: BloomTaxonomyLevel.evaluate,
                  sequenceIndex: 1,
                  provenance: 'Syllabus Item 1.2.1',
                  prerequisites: [
                    PrerequisiteRelationship(
                      prerequisiteObjectiveId: 'lo_basic_structure_doctrine',
                      provenance: 'Syllabus Rule 1.2.1.a',
                      rationale:
                          'Judicial review and basic structure limits ground the expanded interpretation of fundamental rights.',
                    ),
                  ],
                  masteryCriteria: StaticMasteryCriteria(
                    minRequiredProducts: 2,
                    mandatoryProductIds: ['MANEKA_GANDHI', '21'],
                    description:
                        'Requires Maneka Gandhi case explanation and Article 21 statutory product.',
                  ),
                  supportedProducts: [
                    KnowledgeProductMapping(
                      productType: KnowledgeProductType.caseLaw,
                      productId: 'MANEKA_GANDHI',
                      title: 'Maneka Gandhi v. Union of India (1978)',
                      provenance: 'P11 Case Explanation Corpus',
                      role: 'leading_case',
                    ),
                    KnowledgeProductMapping(
                      productType: KnowledgeProductType.provision,
                      productId: '21',
                      provisionType: ProvisionType.article,
                      title:
                          'Article 21 — Protection of Life and Personal Liberty',
                      provenance: 'P13 Statute Product Corpus',
                      role: 'statutory_basis',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
