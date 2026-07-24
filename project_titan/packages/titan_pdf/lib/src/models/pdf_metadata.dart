import 'package:meta/meta.dart';

/// Immutable metadata extracted from a PDF document.
@immutable
class PdfMetadata {
  final String? author;
  final String? title;
  final String? subject;
  final String? keywords;
  final String? creator;
  final String? producer;
  final DateTime? creationDate;
  final DateTime? modificationDate;

  const PdfMetadata({
    this.author,
    this.title,
    this.subject,
    this.keywords,
    this.creator,
    this.producer,
    this.creationDate,
    this.modificationDate,
  });

  const PdfMetadata.empty()
      : author = null,
        title = null,
        subject = null,
        keywords = null,
        creator = null,
        producer = null,
        creationDate = null,
        modificationDate = null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfMetadata &&
          runtimeType == other.runtimeType &&
          author == other.author &&
          title == other.title &&
          subject == other.subject &&
          keywords == other.keywords &&
          creator == other.creator &&
          producer == other.producer &&
          creationDate == other.creationDate &&
          modificationDate == other.modificationDate;

  @override
  int get hashCode =>
      author.hashCode ^
      title.hashCode ^
      subject.hashCode ^
      keywords.hashCode ^
      creator.hashCode ^
      producer.hashCode ^
      creationDate.hashCode ^
      modificationDate.hashCode;

  @override
  String toString() =>
      'PdfMetadata(title: $title, author: $author, subject: $subject)';
}
