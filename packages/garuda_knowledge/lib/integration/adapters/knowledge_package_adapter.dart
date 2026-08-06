import '../../domain/entities/knowledge_evidence_reference.dart';
import '../../domain/entities/knowledge_object.dart';
import '../../domain/entities/knowledge_relationship.dart';
import '../registry/knowledge_capability.dart';

/// Abstract Package Adapter interface exposing knowledge assets from individual GARUDA packages.
abstract class KnowledgePackageAdapter {
  /// Unique package name identifier (e.g. 'garuda_constitution')
  String get packageName;

  /// Package semantic version
  String get version;

  /// List of capabilities provided by this package
  List<KnowledgeCapability> get capabilities;

  /// Extract Knowledge Objects exposed by this package
  Future<List<KnowledgeObject>> extractObjects();

  /// Extract Relationships exposed by this package
  Future<List<KnowledgeRelationship>> extractRelationships();

  /// Extract Package-level Metadata
  Future<Map<String, dynamic>> extractMetadata();

  /// Extract Evidence References exposed by this package
  Future<List<KnowledgeEvidenceReference>> extractEvidenceReferences();
}
