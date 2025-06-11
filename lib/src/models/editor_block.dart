import 'package:flutter/material.dart';

/// 에디터 블록 타입 정의
/// 각 블록은 고유한 특성과 렌더링 방식을 가집니다.
enum EditorBlockType {
  paragraph('Paragraph', 'paragraph', Icons.text_fields, ''),
  heading1('Heading 1', 'heading-one', Icons.title, '# '),
  heading2('Heading 2', 'heading-two', Icons.title, '## '),
  heading3('Heading 3', 'heading-three', Icons.title, '### '),
  bulleted('Bulleted List', 'bulleted-list', Icons.list, '- '),
  numbered('Numbered List', 'numbered-list', Icons.format_list_numbered, '1. '),
  todo('Todo List', 'todo-list', Icons.check_box, '- [ ] '),
  blockquote('Blockquote', 'blockquote', Icons.format_quote, '> '),
  code('Code Block', 'code', Icons.code, '```\n'),
  callout('Callout', 'callout', Icons.info, '> 📝 '),
  divider('Divider', 'divider', Icons.horizontal_rule, '---\n'),
  image('Image', 'image', Icons.image, '![]('),
  video('Video', 'video', Icons.videocam, '<video>'),
  link('Link', 'link', Icons.link, '[]('),
  embed('Embed', 'embed', Icons.code_off, '<iframe>');

  const EditorBlockType(this.label, this.serverType, this.icon, this.markdown);

  final String label;
  final String serverType; // 백엔드와 호환되는 타입명
  final IconData icon;
  final String markdown;

  /// 모바일에서 터치하기 좋은 최소 높이 반환
  double get minTouchHeight => 44.0;

  /// 블록이 비어있을 때 표시할 플레이스홀더 텍스트
  String get placeholder {
    switch (this) {
      case EditorBlockType.paragraph:
        return '내용을 입력하세요...';
      case EditorBlockType.heading1:
        return '제목 1';
      case EditorBlockType.heading2:
        return '제목 2';
      case EditorBlockType.heading3:
        return '제목 3';
      case EditorBlockType.bulleted:
        return '목록 항목';
      case EditorBlockType.numbered:
        return '번호 목록 항목';
      case EditorBlockType.todo:
        return '할 일 항목';
      case EditorBlockType.blockquote:
        return '인용문';
      case EditorBlockType.code:
        return '코드를 입력하세요...';
      case EditorBlockType.callout:
        return '중요한 정보';
      case EditorBlockType.image:
        return '이미지 설명';
      case EditorBlockType.link:
        return '링크 텍스트';
      default:
        return '내용을 입력하세요...';
    }
  }
}

/// 에디터 블록 데이터 구조
/// JSON 직렬화/역직렬화를 지원하며 React 에디터와 100% 호환됩니다.
class EditorBlock {
  final String id;
  final EditorBlockType type;
  final Map<String, dynamic> value;
  final Map<String, dynamic>? meta;
  final int? index;

  const EditorBlock({
    required this.id,
    required this.type,
    required this.value,
    this.meta,
    this.index,
  });

  /// JSON으로 직렬화 (백엔드 API 호환)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.serverType,
      'value': value,
      'meta': meta ?? {},
      'index': index ?? 0,
    };
  }

  /// JSON에서 블록 생성 (백엔드에서 로드)
  factory EditorBlock.fromJson(Map<String, dynamic> json) {
    final typeString = json['type'] as String;
    final blockType = EditorBlockType.values.firstWhere(
      (type) => type.serverType == typeString,
      orElse: () => EditorBlockType.paragraph,
    );

    return EditorBlock(
      id: json['id'] as String,
      type: blockType,
      value: json['value'] as Map<String, dynamic>,
      meta: json['meta'] as Map<String, dynamic>?,
      index: json['index'] as int?,
    );
  }

  /// 마크다운에서 블록 생성 (성능 최적화됨)
  factory EditorBlock.fromMarkdown(
    String id,
    EditorBlockType type,
    String text,
  ) {
    late Map<String, dynamic> value;

    switch (type) {
      case EditorBlockType.heading1:
      case EditorBlockType.heading2:
      case EditorBlockType.heading3:
        value = {
          'text': [
            {'text': text.replaceAll(RegExp(r'^#+\s*'), '')},
          ],
          'level': type == EditorBlockType.heading1
              ? 1
              : type == EditorBlockType.heading2
                  ? 2
                  : 3,
        };
      case EditorBlockType.bulleted:
      case EditorBlockType.numbered:
        value = {
          'text': [
            {'text': text.replaceAll(RegExp(r'^[-\d+\.]\s*'), '')},
          ],
          'listType':
              type == EditorBlockType.bulleted ? 'unordered' : 'ordered',
        };
      case EditorBlockType.todo:
        final isChecked = text.contains('[x]');
        value = {
          'text': [
            {'text': text.replaceAll(RegExp(r'^-\s*\[[ x]\]\s*'), '')},
          ],
          'checked': isChecked,
        };
      case EditorBlockType.blockquote:
        value = {
          'text': [
            {'text': text.replaceAll(RegExp(r'^>\s*'), '')},
          ],
        };
      case EditorBlockType.code:
        value = {
          'code': text,
          'language': 'javascript', // 기본값
        };
      case EditorBlockType.callout:
        value = {
          'text': [
            {'text': text.replaceAll(RegExp(r'^>\s*[📝🔥💡⚠️]\s*'), '')},
          ],
          'theme': 'info',
        };
      case EditorBlockType.image:
        value = {'src': '', 'alt': text, 'width': 600, 'height': 400};
      default:
        value = {
          'text': [
            {'text': text},
          ],
        };
    }

    return EditorBlock(id: id, type: type, value: value);
  }

  /// 마크다운으로 변환 (성능 최적화)
  String toMarkdown() {
    switch (type) {
      case EditorBlockType.heading1:
        return '# ${_getTextContent()}';
      case EditorBlockType.heading2:
        return '## ${_getTextContent()}';
      case EditorBlockType.heading3:
        return '### ${_getTextContent()}';
      case EditorBlockType.bulleted:
        return '- ${_getTextContent()}';
      case EditorBlockType.numbered:
        return '1. ${_getTextContent()}';
      case EditorBlockType.todo:
        final checked = value['checked'] == true ? 'x' : ' ';
        return '- [$checked] ${_getTextContent()}';
      case EditorBlockType.blockquote:
        return '> ${_getTextContent()}';
      case EditorBlockType.code:
        return '```${value['language'] ?? ''}\n${value['code'] ?? ''}\n```';
      case EditorBlockType.callout:
        return '> 📝 ${_getTextContent()}';
      case EditorBlockType.divider:
        return '---';
      case EditorBlockType.image:
        return '![${value['alt'] ?? ''}](${value['src'] ?? ''})';
      default:
        return _getTextContent();
    }
  }

  /// 텍스트 콘텐츠 추출 (캐시됨)
  String _getTextContent() {
    final textList = value['text'] as List<dynamic>?;
    if (textList == null || textList.isEmpty) return '';
    return textList.map((item) => item['text'] ?? '').join('');
  }

  /// 블록이 비어있는지 확인
  bool get isEmpty {
    switch (type) {
      case EditorBlockType.code:
        return (value['code'] as String?)?.isEmpty ?? true;
      case EditorBlockType.divider:
        return false; // 구분선은 항상 내용이 있음
      case EditorBlockType.image:
        return (value['src'] as String?)?.isEmpty ?? true;
      default:
        return _getTextContent().isEmpty;
    }
  }

  /// 블록 복사 생성 (불변성 보장)
  EditorBlock copyWith({
    String? id,
    EditorBlockType? type,
    Map<String, dynamic>? value,
    Map<String, dynamic>? meta,
    int? index,
  }) {
    return EditorBlock(
      id: id ?? this.id,
      type: type ?? this.type,
      value: value ?? Map<String, dynamic>.from(this.value),
      meta: meta ??
          (this.meta != null ? Map<String, dynamic>.from(this.meta!) : null),
      index: index ?? this.index,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditorBlock &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type;

  @override
  int get hashCode => id.hashCode ^ type.hashCode;

  @override
  String toString() {
    return 'EditorBlock{id: $id, type: $type, isEmpty: $isEmpty}';
  }
}
