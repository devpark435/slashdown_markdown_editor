import '../models/editor_block.dart';

/// 마크다운 파싱 유틸리티
/// 성능 최적화된 마크다운 파서를 제공합니다.
class MarkdownParser {
  /// 캐시된 정규표현식들
  static final RegExp _headingRegex = RegExp(r'^(#{1,3})\s+(.*)');
  static final RegExp _listRegex = RegExp(r'^(\s*)[-\*\+]\s+(.*)');
  static final RegExp _numberedListRegex = RegExp(r'^(\s*)(\d+)\.\s+(.*)');
  static final RegExp _todoRegex = RegExp(r'^(\s*)[-\*\+]\s+\[([ x])\]\s+(.*)');
  static final RegExp _blockquoteRegex = RegExp(r'^>\s*(.*)');
  static final RegExp _calloutRegex = RegExp(r'^>\s*([📝🔥💡⚠️])\s*(.*)');
  static final RegExp _codeBlockRegex = RegExp(r'^```(\w*)?');
  static final RegExp _imageRegex = RegExp(r'^!\[([^\]]*)\]\(([^)]*)\)');
  static final RegExp _linkRegex = RegExp(r'^\[([^\]]*)\]\(([^)]*)\)');
  static final RegExp _dividerRegex = RegExp(r'^-{3,}$');

  /// 단일 라인에서 블록 타입 감지 (성능 최적화됨)
  static EditorBlockType detectBlockType(String line) {
    final trimmed = line.trim();

    // 빈 라인
    if (trimmed.isEmpty) return EditorBlockType.paragraph;

    // 헤딩 (가장 자주 사용됨)
    final headingMatch = _headingRegex.firstMatch(trimmed);
    if (headingMatch != null) {
      final level = headingMatch.group(1)!.length;
      switch (level) {
        case 1:
          return EditorBlockType.heading1;
        case 2:
          return EditorBlockType.heading2;
        case 3:
          return EditorBlockType.heading3;
        default:
          return EditorBlockType.paragraph;
      }
    }

    // TODO 리스트
    if (_todoRegex.hasMatch(trimmed)) {
      return EditorBlockType.todo;
    }

    // 일반 리스트
    if (_listRegex.hasMatch(trimmed)) {
      return EditorBlockType.bulleted;
    }

    // 번호 리스트
    if (_numberedListRegex.hasMatch(trimmed)) {
      return EditorBlockType.numbered;
    }

    // 콜아웃
    if (_calloutRegex.hasMatch(trimmed)) {
      return EditorBlockType.callout;
    }

    // 인용구
    if (_blockquoteRegex.hasMatch(trimmed)) {
      return EditorBlockType.blockquote;
    }

    // 코드 블록
    if (_codeBlockRegex.hasMatch(trimmed)) {
      return EditorBlockType.code;
    }

    // 이미지
    if (_imageRegex.hasMatch(trimmed)) {
      return EditorBlockType.image;
    }

    // 링크
    if (_linkRegex.hasMatch(trimmed)) {
      return EditorBlockType.link;
    }

    // 구분선
    if (_dividerRegex.hasMatch(trimmed)) {
      return EditorBlockType.divider;
    }

    // 기본값
    return EditorBlockType.paragraph;
  }

  /// 텍스트에서 블록 정보 추출
  static BlockParseResult parseBlock(String text, EditorBlockType type) {
    final trimmed = text.trim();

    switch (type) {
      case EditorBlockType.heading1:
      case EditorBlockType.heading2:
      case EditorBlockType.heading3:
        return _parseHeading(trimmed);

      case EditorBlockType.bulleted:
      case EditorBlockType.numbered:
        return _parseList(trimmed, type);

      case EditorBlockType.todo:
        return _parseTodo(trimmed);

      case EditorBlockType.blockquote:
        return _parseBlockquote(trimmed);

      case EditorBlockType.callout:
        return _parseCallout(trimmed);

      case EditorBlockType.code:
        return _parseCodeBlock(trimmed);

      case EditorBlockType.image:
        return _parseImage(trimmed);

      case EditorBlockType.link:
        return _parseLink(trimmed);

      case EditorBlockType.divider:
        return BlockParseResult(
          text: '',
          metadata: {},
          isValid: true,
        );

      default:
        return BlockParseResult(
          text: trimmed,
          metadata: {},
          isValid: true,
        );
    }
  }

  static BlockParseResult _parseHeading(String text) {
    final match = _headingRegex.firstMatch(text);
    if (match == null) {
      return BlockParseResult(text: text, metadata: {}, isValid: false);
    }

    return BlockParseResult(
      text: match.group(2)!,
      metadata: {'level': match.group(1)!.length},
      isValid: true,
    );
  }

  static BlockParseResult _parseList(String text, EditorBlockType type) {
    final regex =
        type == EditorBlockType.numbered ? _numberedListRegex : _listRegex;
    final match = regex.firstMatch(text);

    if (match == null) {
      return BlockParseResult(text: text, metadata: {}, isValid: false);
    }

    final indent = match.group(1)?.length ?? 0;
    final content =
        type == EditorBlockType.numbered ? match.group(3)! : match.group(2)!;

    return BlockParseResult(
      text: content,
      metadata: {
        'indent': indent,
        'listType': type == EditorBlockType.numbered ? 'ordered' : 'unordered',
      },
      isValid: true,
    );
  }

  static BlockParseResult _parseTodo(String text) {
    final match = _todoRegex.firstMatch(text);
    if (match == null) {
      return BlockParseResult(text: text, metadata: {}, isValid: false);
    }

    return BlockParseResult(
      text: match.group(3)!,
      metadata: {
        'checked': match.group(2) == 'x',
        'indent': match.group(1)?.length ?? 0,
      },
      isValid: true,
    );
  }

  static BlockParseResult _parseBlockquote(String text) {
    final match = _blockquoteRegex.firstMatch(text);
    if (match == null) {
      return BlockParseResult(text: text, metadata: {}, isValid: false);
    }

    return BlockParseResult(
      text: match.group(1)!,
      metadata: {},
      isValid: true,
    );
  }

  static BlockParseResult _parseCallout(String text) {
    final match = _calloutRegex.firstMatch(text);
    if (match == null) {
      return BlockParseResult(text: text, metadata: {}, isValid: false);
    }

    final emoji = match.group(1)!;
    String theme = 'info';

    switch (emoji) {
      case '🔥':
        theme = 'warning';
        break;
      case '⚠️':
        theme = 'danger';
        break;
      case '💡':
        theme = 'tip';
        break;
      case '📝':
      default:
        theme = 'info';
        break;
    }

    return BlockParseResult(
      text: match.group(2)!,
      metadata: {'theme': theme, 'emoji': emoji},
      isValid: true,
    );
  }

  static BlockParseResult _parseCodeBlock(String text) {
    final match = _codeBlockRegex.firstMatch(text);
    if (match == null) {
      return BlockParseResult(text: text, metadata: {}, isValid: false);
    }

    return BlockParseResult(
      text: '', // 코드 내용은 별도로 처리
      metadata: {'language': match.group(1) ?? 'text'},
      isValid: true,
    );
  }

  static BlockParseResult _parseImage(String text) {
    final match = _imageRegex.firstMatch(text);
    if (match == null) {
      return BlockParseResult(text: text, metadata: {}, isValid: false);
    }

    return BlockParseResult(
      text: match.group(1)!, // alt text
      metadata: {
        'src': match.group(2)!,
        'alt': match.group(1)!,
      },
      isValid: true,
    );
  }

  static BlockParseResult _parseLink(String text) {
    final match = _linkRegex.firstMatch(text);
    if (match == null) {
      return BlockParseResult(text: text, metadata: {}, isValid: false);
    }

    return BlockParseResult(
      text: match.group(1)!, // link text
      metadata: {
        'url': match.group(2)!,
        'text': match.group(1)!,
      },
      isValid: true,
    );
  }

  /// 인라인 요소 파싱 (볼드, 이탤릭 등)
  static List<InlineElement> parseInlineElements(String text) {
    final elements = <InlineElement>[];
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final char = text[i];

      if (char == '*' && i + 1 < text.length && text[i + 1] == '*') {
        // Bold
        if (buffer.isNotEmpty) {
          elements.add(InlineElement(
              text: buffer.toString(), type: InlineElementType.text));
          buffer.clear();
        }

        final endIndex = text.indexOf('**', i + 2);
        if (endIndex != -1) {
          elements.add(InlineElement(
            text: text.substring(i + 2, endIndex),
            type: InlineElementType.bold,
          ));
          i = endIndex + 1;
        } else {
          buffer.write(char);
        }
      } else if (char == '*') {
        // Italic
        if (buffer.isNotEmpty) {
          elements.add(InlineElement(
              text: buffer.toString(), type: InlineElementType.text));
          buffer.clear();
        }

        final endIndex = text.indexOf('*', i + 1);
        if (endIndex != -1) {
          elements.add(InlineElement(
            text: text.substring(i + 1, endIndex),
            type: InlineElementType.italic,
          ));
          i = endIndex;
        } else {
          buffer.write(char);
        }
      } else if (char == '`') {
        // Inline code
        if (buffer.isNotEmpty) {
          elements.add(InlineElement(
              text: buffer.toString(), type: InlineElementType.text));
          buffer.clear();
        }

        final endIndex = text.indexOf('`', i + 1);
        if (endIndex != -1) {
          elements.add(InlineElement(
            text: text.substring(i + 1, endIndex),
            type: InlineElementType.code,
          ));
          i = endIndex;
        } else {
          buffer.write(char);
        }
      } else {
        buffer.write(char);
      }
    }

    if (buffer.isNotEmpty) {
      elements.add(
          InlineElement(text: buffer.toString(), type: InlineElementType.text));
    }

    return elements;
  }

  /// 마크다운 이스케이프 처리
  static String escapeMarkdown(String text) {
    return text
        .replaceAll(r'\', r'\\')
        .replaceAll('*', r'\*')
        .replaceAll('_', r'\_')
        .replaceAll('#', r'\#')
        .replaceAll('-', r'\-')
        .replaceAll('`', r'\`')
        .replaceAll('>', r'\>')
        .replaceAll('[', r'\[')
        .replaceAll(']', r'\]')
        .replaceAll('(', r'\(')
        .replaceAll(')', r'\)');
  }

  /// 마크다운 언이스케이프 처리
  static String unescapeMarkdown(String text) {
    return text
        .replaceAll(r'\*', '*')
        .replaceAll(r'\_', '_')
        .replaceAll(r'\#', '#')
        .replaceAll(r'\-', '-')
        .replaceAll(r'\`', '`')
        .replaceAll(r'\>', '>')
        .replaceAll(r'\[', '[')
        .replaceAll(r'\]', ']')
        .replaceAll(r'\(', '(')
        .replaceAll(r'\)', ')')
        .replaceAll(r'\\', r'\');
  }
}

/// 블록 파싱 결과
class BlockParseResult {
  final String text;
  final Map<String, dynamic> metadata;
  final bool isValid;

  const BlockParseResult({
    required this.text,
    required this.metadata,
    required this.isValid,
  });

  @override
  String toString() {
    return 'BlockParseResult{text: "$text", valid: $isValid, meta: $metadata}';
  }
}

/// 인라인 요소 타입
enum InlineElementType {
  text,
  bold,
  italic,
  code,
  link,
}

/// 인라인 요소
class InlineElement {
  final String text;
  final InlineElementType type;
  final Map<String, String>? attributes;

  const InlineElement({
    required this.text,
    required this.type,
    this.attributes,
  });

  @override
  String toString() {
    return 'InlineElement{type: $type, text: "$text"}';
  }
}
