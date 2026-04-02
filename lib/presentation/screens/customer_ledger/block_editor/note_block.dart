import 'dart:convert';
import 'package:uuid/uuid.dart';

/// Block types supported by the note editor.
enum NoteBlockType {
  paragraph,
  heading,
  checklist,
  bullet,
  numbered,
  image,
  divider,
}

/// A single block in a note.
class NoteBlock {
  final String id;
  final NoteBlockType type;
  final String text;
  final bool checked; // only for checklist
  final int number; // only for numbered
  // Image fields
  final String? url;
  final String? storagePath;
  final String? localPath;

  const NoteBlock({
    required this.id,
    required this.type,
    this.text = '',
    this.checked = false,
    this.number = 1,
    this.url,
    this.storagePath,
    this.localPath,
  });

  /// Whether this block has a text field.
  bool get isTextBlock =>
      type != NoteBlockType.image && type != NoteBlockType.divider;

  /// Whether this is a list-style block (can be "exited" on empty Enter).
  bool get isListBlock =>
      type == NoteBlockType.checklist ||
      type == NoteBlockType.bullet ||
      type == NoteBlockType.numbered;

  /// Whether this image is local (not yet uploaded).
  bool get isLocalImage => type == NoteBlockType.image && localPath != null && url == null;

  NoteBlock copyWith({
    String? id,
    NoteBlockType? type,
    String? text,
    bool? checked,
    int? number,
    String? url,
    String? storagePath,
    String? localPath,
  }) {
    return NoteBlock(
      id: id ?? this.id,
      type: type ?? this.type,
      text: text ?? this.text,
      checked: checked ?? this.checked,
      number: number ?? this.number,
      url: url ?? this.url,
      storagePath: storagePath ?? this.storagePath,
      localPath: localPath ?? this.localPath,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'type': type.name,
    };
    if (isTextBlock) map['text'] = text;
    if (type == NoteBlockType.checklist) map['checked'] = checked;
    if (type == NoteBlockType.numbered) map['number'] = number;
    if (type == NoteBlockType.image) {
      if (url != null) map['url'] = url;
      if (storagePath != null) map['path'] = storagePath;
      // localPath is transient, not persisted
    }
    return map;
  }

  factory NoteBlock.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type']?.toString() ?? 'paragraph';
    final type = NoteBlockType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => NoteBlockType.paragraph,
    );
    return NoteBlock(
      id: json['id']?.toString() ?? const Uuid().v4(),
      type: type,
      text: json['text']?.toString() ?? '',
      checked: json['checked'] == true,
      number: (json['number'] as num?)?.toInt() ?? 1,
      url: json['url']?.toString(),
      storagePath: json['path']?.toString(),
    );
  }

  /// Create a new empty paragraph block.
  factory NoteBlock.paragraph([String text = '']) => NoteBlock(
        id: const Uuid().v4(),
        type: NoteBlockType.paragraph,
        text: text,
      );

  /// Create a new checklist block.
  factory NoteBlock.checklist([String text = '', bool checked = false]) =>
      NoteBlock(
        id: const Uuid().v4(),
        type: NoteBlockType.checklist,
        text: text,
        checked: checked,
      );

  /// Create a new bullet block.
  factory NoteBlock.bullet([String text = '']) => NoteBlock(
        id: const Uuid().v4(),
        type: NoteBlockType.bullet,
        text: text,
      );

  /// Create a new numbered block.
  factory NoteBlock.numbered([String text = '', int number = 1]) => NoteBlock(
        id: const Uuid().v4(),
        type: NoteBlockType.numbered,
        text: text,
        number: number,
      );

  /// Create a new heading block.
  factory NoteBlock.heading([String text = '']) => NoteBlock(
        id: const Uuid().v4(),
        type: NoteBlockType.heading,
        text: text,
      );

  /// Create a new image block.
  factory NoteBlock.image({String? localPath, String? url, String? storagePath}) =>
      NoteBlock(
        id: const Uuid().v4(),
        type: NoteBlockType.image,
        localPath: localPath,
        url: url,
        storagePath: storagePath,
      );

  /// Create a divider block.
  factory NoteBlock.divider() => NoteBlock(
        id: const Uuid().v4(),
        type: NoteBlockType.divider,
      );
}

// ─── Serialization helpers ─────────────────────────────────────────────────

/// Serialize blocks to JSON string for the `content` column.
String blocksToJson(List<NoteBlock> blocks) {
  return jsonEncode({
    'v': 1,
    'blocks': blocks.map((b) => b.toJson()).toList(),
  });
}

/// Parse note content — handles both block-JSON and legacy plain text.
List<NoteBlock> parseNoteContent(String? content, List<dynamic>? legacyImages) {
  if (content == null || content.trim().isEmpty) {
    return [NoteBlock.paragraph()];
  }

  // Try block-JSON format
  final trimmed = content.trim();
  if (trimmed.startsWith('{') && trimmed.contains('"v"')) {
    try {
      final map = jsonDecode(trimmed) as Map<String, dynamic>;
      final blocksList = map['blocks'] as List<dynamic>? ?? [];
      final blocks = blocksList
          .map((b) => b is Map<String, dynamic> ? NoteBlock.fromJson(b) : null)
          .whereType<NoteBlock>()
          .toList();
      if (blocks.isEmpty) return [NoteBlock.paragraph()];
      return blocks;
    } catch (_) {
      // Fall through to legacy parsing
    }
  }

  // Legacy plain-text migration
  return _parseLegacyContent(content, legacyImages);
}

List<NoteBlock> _parseLegacyContent(String content, List<dynamic>? legacyImages) {
  final lines = content.split('\n');
  final blocks = <NoteBlock>[];

  for (final line in lines) {
    if (line.startsWith('☐ ')) {
      blocks.add(NoteBlock.checklist(line.substring(2), false));
    } else if (line.startsWith('☑ ')) {
      blocks.add(NoteBlock.checklist(line.substring(2), true));
    } else if (line.startsWith('• ')) {
      blocks.add(NoteBlock.bullet(line.substring(2)));
    } else {
      blocks.add(NoteBlock.paragraph(line));
    }
  }

  // Append legacy images as image blocks
  if (legacyImages != null) {
    for (final img in legacyImages) {
      if (img is Map<String, dynamic>) {
        final url = img['url']?.toString();
        final path = img['path']?.toString();
        if (url != null) {
          blocks.add(NoteBlock.image(url: url, storagePath: path));
        }
      }
    }
  }

  if (blocks.isEmpty) return [NoteBlock.paragraph()];
  return blocks;
}

/// Extract a plain-text preview from note content (for list cards).
/// Handles both block-JSON and legacy plain text.
String plainTextPreview(String? content, {int maxLength = 120}) {
  if (content == null || content.trim().isEmpty) return '';

  final trimmed = content.trim();
  if (trimmed.startsWith('{') && trimmed.contains('"v"')) {
    try {
      final map = jsonDecode(trimmed) as Map<String, dynamic>;
      final blocksList = map['blocks'] as List<dynamic>? ?? [];
      final buffer = StringBuffer();
      for (final b in blocksList) {
        if (b is! Map<String, dynamic>) continue;
        final type = b['type']?.toString();
        final text = b['text']?.toString() ?? '';
        if (text.isEmpty) continue;
        if (type == 'checklist') {
          buffer.write(b['checked'] == true ? '☑ ' : '☐ ');
        } else if (type == 'bullet') {
          buffer.write('• ');
        }
        buffer.writeln(text);
        if (buffer.length >= maxLength) break;
      }
      final result = buffer.toString().trim();
      return result.length > maxLength
          ? '${result.substring(0, maxLength)}…'
          : result;
    } catch (_) {
      // Fall through
    }
  }

  // Legacy plain text — return as-is (already readable)
  return content.length > maxLength
      ? '${content.substring(0, maxLength)}…'
      : content;
}

/// Extract image URLs from note content for list card thumbnails.
/// Handles both block-JSON and legacy images JSONB.
List<String> extractImageUrls(String? content, dynamic legacyImages) {
  final urls = <String>[];

  // Try block content first
  if (content != null && content.trim().startsWith('{') && content.contains('"v"')) {
    try {
      final map = jsonDecode(content.trim()) as Map<String, dynamic>;
      final blocksList = map['blocks'] as List<dynamic>? ?? [];
      for (final b in blocksList) {
        if (b is Map<String, dynamic> && b['type'] == 'image') {
          final url = b['url']?.toString();
          if (url != null && url.isNotEmpty) urls.add(url);
        }
      }
      if (urls.isNotEmpty) return urls;
    } catch (_) {}
  }

  // Fallback to legacy images column
  if (legacyImages == null) return urls;
  try {
    final list = legacyImages is String ? jsonDecode(legacyImages) : legacyImages;
    if (list is List) {
      for (final e in list) {
        if (e is Map) {
          final url = e['url']?.toString();
          if (url != null && url.isNotEmpty) urls.add(url);
        }
      }
    }
  } catch (_) {}
  return urls;
}
