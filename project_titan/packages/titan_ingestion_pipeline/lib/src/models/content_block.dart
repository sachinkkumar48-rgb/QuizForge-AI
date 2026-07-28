import 'package:meta/meta.dart';

/// Base abstract class for content blocks extracted during parsing.
@immutable
abstract class ContentBlock {
  final String id;

  const ContentBlock({required this.id});

  Map<String, dynamic> toJson();
}

/// Heading Block (H1-H6)
class HeadingBlock extends ContentBlock {
  final int level;
  final String text;

  const HeadingBlock({
    required super.id,
    required this.level,
    required this.text,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'heading',
        'id': id,
        'level': level,
        'text': text,
      };

  factory HeadingBlock.fromJson(Map<String, dynamic> json) => HeadingBlock(
        id: json['id'] as String,
        level: json['level'] as int,
        text: json['text'] as String,
      );
}

/// Paragraph Block
class ParagraphBlock extends ContentBlock {
  final String text;

  const ParagraphBlock({
    required super.id,
    required this.text,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'paragraph',
        'id': id,
        'text': text,
      };

  factory ParagraphBlock.fromJson(Map<String, dynamic> json) => ParagraphBlock(
        id: json['id'] as String,
        text: json['text'] as String,
      );
}

/// Bullet List Block
class BulletListBlock extends ContentBlock {
  final List<String> items;

  BulletListBlock({
    required super.id,
    required List<String> items,
  }) : items = List.unmodifiable(items);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'bullet_list',
        'id': id,
        'items': items,
      };

  factory BulletListBlock.fromJson(Map<String, dynamic> json) =>
      BulletListBlock(
        id: json['id'] as String,
        items: List<String>.from(json['items'] as List),
      );
}

/// Table Block
class TableBlock extends ContentBlock {
  final List<String> headers;
  final List<List<String>> rows;

  TableBlock({
    required super.id,
    required List<String> headers,
    required List<List<String>> rows,
  })  : headers = List.unmodifiable(headers),
        rows = List.unmodifiable(rows.map((r) => List<String>.unmodifiable(r)));

  @override
  Map<String, dynamic> toJson() => {
        'type': 'table',
        'id': id,
        'headers': headers,
        'rows': rows,
      };

  factory TableBlock.fromJson(Map<String, dynamic> json) => TableBlock(
        id: json['id'] as String,
        headers: List<String>.from(json['headers'] as List),
        rows: (json['rows'] as List)
            .map((r) => List<String>.from(r as List))
            .toList(),
      );
}

/// Image Reference Block
class ImageReferenceBlock extends ContentBlock {
  final String url;
  final String caption;
  final String altText;

  const ImageReferenceBlock({
    required super.id,
    required this.url,
    this.caption = '',
    this.altText = '',
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'image_reference',
        'id': id,
        'url': url,
        'caption': caption,
        'altText': altText,
      };

  factory ImageReferenceBlock.fromJson(Map<String, dynamic> json) =>
      ImageReferenceBlock(
        id: json['id'] as String,
        url: json['url'] as String,
        caption: json['caption'] as String? ?? '',
        altText: json['altText'] as String? ?? '',
      );
}

/// Formula Block (LaTeX / MathML)
class FormulaBlock extends ContentBlock {
  final String latex;
  final bool isInline;

  const FormulaBlock({
    required super.id,
    required this.latex,
    this.isInline = false,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'formula',
        'id': id,
        'latex': latex,
        'isInline': isInline,
      };

  factory FormulaBlock.fromJson(Map<String, dynamic> json) => FormulaBlock(
        id: json['id'] as String,
        latex: json['latex'] as String,
        isInline: json['isInline'] as bool? ?? false,
      );
}

/// Diagram Reference Block
class DiagramReferenceBlock extends ContentBlock {
  final String diagramId;
  final String description;
  final String diagramType;

  const DiagramReferenceBlock({
    required super.id,
    required this.diagramId,
    required this.description,
    this.diagramType = 'flowchart',
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'diagram_reference',
        'id': id,
        'diagramId': diagramId,
        'description': description,
        'diagramType': diagramType,
      };

  factory DiagramReferenceBlock.fromJson(Map<String, dynamic> json) =>
      DiagramReferenceBlock(
        id: json['id'] as String,
        diagramId: json['diagramId'] as String,
        description: json['description'] as String,
        diagramType: json['diagramType'] as String? ?? 'flowchart',
      );
}

/// Example Block
class ExampleBlock extends ContentBlock {
  final String title;
  final String content;

  const ExampleBlock({
    required super.id,
    required this.title,
    required this.content,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'example',
        'id': id,
        'title': title,
        'content': content,
      };

  factory ExampleBlock.fromJson(Map<String, dynamic> json) => ExampleBlock(
        id: json['id'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
      );
}

/// Quote Block
class QuoteBlock extends ContentBlock {
  final String quote;
  final String author;

  const QuoteBlock({
    required super.id,
    required this.quote,
    this.author = '',
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'quote',
        'id': id,
        'quote': quote,
        'author': author,
      };

  factory QuoteBlock.fromJson(Map<String, dynamic> json) => QuoteBlock(
        id: json['id'] as String,
        quote: json['quote'] as String,
        author: json['author'] as String? ?? '',
      );
}

/// Code Block
class CodeBlock extends ContentBlock {
  final String code;
  final String language;

  const CodeBlock({
    required super.id,
    required this.code,
    this.language = 'plain',
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'code_block',
        'id': id,
        'code': code,
        'language': language,
      };

  factory CodeBlock.fromJson(Map<String, dynamic> json) => CodeBlock(
        id: json['id'] as String,
        code: json['code'] as String,
        language: json['language'] as String? ?? 'plain',
      );
}

/// Activity Block
class ActivityBlock extends ContentBlock {
  final String title;
  final String instructions;
  final String activityType;

  const ActivityBlock({
    required super.id,
    required this.title,
    required this.instructions,
    this.activityType = 'exercise',
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'activity',
        'id': id,
        'title': title,
        'instructions': instructions,
        'activityType': activityType,
      };

  factory ActivityBlock.fromJson(Map<String, dynamic> json) => ActivityBlock(
        id: json['id'] as String,
        title: json['title'] as String,
        instructions: json['instructions'] as String,
        activityType: json['activityType'] as String? ?? 'exercise',
      );
}

/// Helper function to parse any ContentBlock from JSON.
ContentBlock parseContentBlockFromJson(Map<String, dynamic> json) {
  final type = json['type'] as String?;
  switch (type) {
    case 'heading':
      return HeadingBlock.fromJson(json);
    case 'paragraph':
      return ParagraphBlock.fromJson(json);
    case 'bullet_list':
      return BulletListBlock.fromJson(json);
    case 'table':
      return TableBlock.fromJson(json);
    case 'image_reference':
      return ImageReferenceBlock.fromJson(json);
    case 'formula':
      return FormulaBlock.fromJson(json);
    case 'diagram_reference':
      return DiagramReferenceBlock.fromJson(json);
    case 'example':
      return ExampleBlock.fromJson(json);
    case 'quote':
      return QuoteBlock.fromJson(json);
    case 'code_block':
      return CodeBlock.fromJson(json);
    case 'activity':
      return ActivityBlock.fromJson(json);
    default:
      return ParagraphBlock(
        id: json['id'] as String? ?? 'unk',
        text: json['text'] as String? ?? '',
      );
  }
}
