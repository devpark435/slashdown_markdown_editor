import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

// ===== 블록 기반 에디터 타입 정의 =====
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
}

// ===== 블록 데이터 구조 =====
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.serverType,
      'value': value,
      'meta': meta ?? {},
      'index': index ?? 0,
    };
  }

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

  factory EditorBlock.fromMarkdown(
    String id,
    EditorBlockType type,
    String text,
  ) {
    Map<String, dynamic> value;

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
        break;
      case EditorBlockType.bulleted:
      case EditorBlockType.numbered:
        value = {
          'text': [
            {'text': text.replaceAll(RegExp(r'^[-\d+\.]\s*'), '')},
          ],
          'listType':
              type == EditorBlockType.bulleted ? 'unordered' : 'ordered',
        };
        break;
      case EditorBlockType.todo:
        final isChecked = text.contains('[x]');
        value = {
          'text': [
            {'text': text.replaceAll(RegExp(r'^-\s*\[[ x]\]\s*'), '')},
          ],
          'checked': isChecked,
        };
        break;
      case EditorBlockType.blockquote:
        value = {
          'text': [
            {'text': text.replaceAll(RegExp(r'^>\s*'), '')},
          ],
        };
        break;
      case EditorBlockType.code:
        value = {
          'code': text,
          'language': 'javascript', // 기본값
        };
        break;
      case EditorBlockType.callout:
        value = {
          'text': [
            {'text': text.replaceAll(RegExp(r'^>\s*[📝🔥💡⚠️]\s*'), '')},
          ],
          'theme': 'info',
        };
        break;
      case EditorBlockType.image:
        value = {'src': '', 'alt': text, 'width': 600, 'height': 400};
        break;
      default:
        value = {
          'text': [
            {'text': text},
          ],
        };
    }

    return EditorBlock(id: id, type: type, value: value);
  }

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

  String _getTextContent() {
    final textList = value['text'] as List<dynamic>?;
    if (textList == null || textList.isEmpty) return '';
    return textList.map((item) => item['text'] ?? '').join('');
  }
}

class EditorDocument {
  final List<EditorBlock> blocks;
  final Map<String, dynamic>? meta;

  const EditorDocument({required this.blocks, this.meta});

  Map<String, dynamic> toJson() {
    return {
      'blocks': blocks.map((block) => block.toJson()).toList(),
      'meta': meta ?? {},
    };
  }

  factory EditorDocument.fromJson(Map<String, dynamic> json) {
    final blocksJson = json['blocks'] as List<dynamic>;
    final blocks = blocksJson
        .map(
          (blockJson) =>
              EditorBlock.fromJson(blockJson as Map<String, dynamic>),
        )
        .toList();

    return EditorDocument(
      blocks: blocks,
      meta: json['meta'] as Map<String, dynamic>?,
    );
  }

  String toMarkdown() {
    return blocks.map((block) => block.toMarkdown()).join('\n\n');
  }

  factory EditorDocument.fromMarkdown(String markdown) {
    final lines = markdown.split('\n');
    final blocks = <EditorBlock>[];
    String currentBlockText = '';
    EditorBlockType currentType = EditorBlockType.paragraph;
    bool inCodeBlock = false;
    String codeContent = '';

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.isEmpty) {
        if (currentBlockText.isNotEmpty) {
          blocks.add(
            EditorBlock.fromMarkdown(
              'block_${blocks.length}',
              currentType,
              inCodeBlock ? codeContent : currentBlockText,
            ),
          );
          currentBlockText = '';
          codeContent = '';
        }
        continue;
      }

      // 코드 블록 처리
      if (line.startsWith('```')) {
        if (inCodeBlock) {
          blocks.add(
            EditorBlock.fromMarkdown(
              'block_${blocks.length}',
              EditorBlockType.code,
              codeContent,
            ),
          );
          inCodeBlock = false;
          codeContent = '';
        } else {
          inCodeBlock = true;
          currentType = EditorBlockType.code;
        }
        continue;
      }

      if (inCodeBlock) {
        codeContent += line + '\n';
        continue;
      }

      // 블록 타입 감지
      if (line.startsWith('### ')) {
        currentType = EditorBlockType.heading3;
        currentBlockText = line;
      } else if (line.startsWith('## ')) {
        currentType = EditorBlockType.heading2;
        currentBlockText = line;
      } else if (line.startsWith('# ')) {
        currentType = EditorBlockType.heading1;
        currentBlockText = line;
      } else if (line.startsWith('- [x] ') || line.startsWith('- [ ] ')) {
        currentType = EditorBlockType.todo;
        currentBlockText = line;
      } else if (line.startsWith('- ')) {
        currentType = EditorBlockType.bulleted;
        currentBlockText = line;
      } else if (RegExp(r'^\d+\. ').hasMatch(line)) {
        currentType = EditorBlockType.numbered;
        currentBlockText = line;
      } else if (line.startsWith('> 📝') || line.startsWith('> 💡')) {
        currentType = EditorBlockType.callout;
        currentBlockText = line;
      } else if (line.startsWith('> ')) {
        currentType = EditorBlockType.blockquote;
        currentBlockText = line;
      } else if (line == '---') {
        blocks.add(
          EditorBlock.fromMarkdown(
            'block_${blocks.length}',
            EditorBlockType.divider,
            '',
          ),
        );
        continue;
      } else if (line.startsWith('![')) {
        currentType = EditorBlockType.image;
        currentBlockText = line;
      } else {
        currentType = EditorBlockType.paragraph;
        currentBlockText = line;
      }

      blocks.add(
        EditorBlock.fromMarkdown(
          'block_${blocks.length}',
          currentType,
          currentBlockText,
        ),
      );
      currentBlockText = '';
    }

    // 마지막 블록 처리
    if (currentBlockText.isNotEmpty) {
      blocks.add(
        EditorBlock.fromMarkdown(
          'block_${blocks.length}',
          currentType,
          currentBlockText,
        ),
      );
    }

    return EditorDocument(blocks: blocks);
  }
}

// ===== 에디터 설정 =====
class SlashdownEditorConfig {
  final TextStyle textStyle;
  final Color backgroundColor;
  final Color overlayBackgroundColor;
  final Color selectedItemColor;
  final Color borderColor;
  final double borderRadius;
  final EdgeInsets padding;
  final int maxLines;
  final String hintText;
  final bool enableSlashCommand;
  final bool enablePreview;
  final List<EditorBlockType> availableBlocks;

  const SlashdownEditorConfig({
    this.textStyle = const TextStyle(fontSize: 16, fontFamily: 'monospace'),
    this.backgroundColor = Colors.white,
    this.overlayBackgroundColor = Colors.white,
    this.selectedItemColor = const Color(0xFFF3F4F6),
    this.borderColor = const Color(0xFFE5E7EB),
    this.borderRadius = 8.0,
    this.padding = const EdgeInsets.all(16),
    this.maxLines = 20,
    this.hintText = '마크다운으로 작성하세요... "/" 를 입력하면 메뉴가 나타납니다',
    this.enableSlashCommand = true,
    this.enablePreview = true,
    this.availableBlocks = EditorBlockType.values,
  });
}

// ===== 메인 슬래시다운 에디터 위젯 =====
class SlashdownEditor extends StatefulWidget {
  final String initialText;
  final SlashdownEditorConfig config;
  final Function(String text)? onChanged;
  final Function(String text)? onSubmitted;
  final Function(EditorDocument document)? onDocumentChanged;

  const SlashdownEditor({
    super.key,
    this.initialText = '',
    this.config = const SlashdownEditorConfig(),
    this.onChanged,
    this.onSubmitted,
    this.onDocumentChanged,
  });

  @override
  State<SlashdownEditor> createState() => _SlashdownEditorState();
}

class _SlashdownEditorState extends State<SlashdownEditor> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  OverlayEntry? _overlayEntry;
  int _selectedIndex = 0;
  List<EditorBlockType> _filteredBlocks = [];
  int _slashPosition = -1;
  bool _showPreview = false;
  EditorDocument? _currentDocument;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _focusNode = FocusNode();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _hideOverlay();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    widget.onChanged?.call(_controller.text);

    // 문서 구조 변경 알림
    final document = EditorDocument.fromMarkdown(_controller.text);
    _currentDocument = document;
    widget.onDocumentChanged?.call(document);

    if (!widget.config.enableSlashCommand) return;

    final text = _controller.text;
    final cursorPosition = _controller.selection.baseOffset;

    final slashIndex = _findSlashCommand(text, cursorPosition);

    if (slashIndex != -1) {
      final searchTerm =
          text.substring(slashIndex + 1, cursorPosition).toLowerCase();
      _filterBlocks(searchTerm);
      _slashPosition = slashIndex;
      _showOverlay();
    } else {
      _hideOverlay();
    }
  }

  int _findSlashCommand(String text, int cursorPosition) {
    if (cursorPosition <= 0) return -1;

    for (int i = cursorPosition - 1; i >= 0; i--) {
      final char = text[i];
      if (char == '/') {
        if (i == 0 || text[i - 1] == '\n' || text[i - 1] == ' ') {
          return i;
        }
      } else if (char == ' ' || char == '\n') {
        break;
      }
    }
    return -1;
  }

  void _filterBlocks(String searchTerm) {
    _filteredBlocks = widget.config.availableBlocks
        .where((block) => block.label.toLowerCase().contains(searchTerm))
        .toList();
    _selectedIndex = 0;
  }

  void _showOverlay() {
    _hideOverlay();

    if (_filteredBlocks.isEmpty) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => _SlashCommandOverlay(
        filteredBlocks: _filteredBlocks,
        selectedIndex: _selectedIndex,
        onBlockSelected: _insertBlock,
        onIndexChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        config: widget.config,
        textFieldRenderBox: context.findRenderObject() as RenderBox?,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _insertBlock(EditorBlockType blockType) {
    if (_slashPosition == -1) return;

    final text = _controller.text;
    final cursorPosition = _controller.selection.baseOffset;

    final beforeSlash = text.substring(0, _slashPosition);
    final afterCursor = text.substring(cursorPosition);

    String newText;
    int newCursorPosition;

    if (blockType == EditorBlockType.code) {
      newText = beforeSlash + blockType.markdown + afterCursor + '\n```';
      newCursorPosition = beforeSlash.length + 4;
    } else if (blockType == EditorBlockType.image) {
      newText = beforeSlash + blockType.markdown + ')' + afterCursor;
      newCursorPosition = beforeSlash.length + 4;
    } else if (blockType == EditorBlockType.link) {
      newText = beforeSlash + blockType.markdown + ')' + afterCursor;
      newCursorPosition = beforeSlash.length + 1;
    } else {
      newText = beforeSlash + blockType.markdown + afterCursor;
      newCursorPosition = beforeSlash.length + blockType.markdown.length;
    }

    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );

    _hideOverlay();
    HapticFeedback.lightImpact();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (_overlayEntry == null) return;

    if (event is KeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowDown:
          setState(() {
            _selectedIndex = (_selectedIndex + 1) % _filteredBlocks.length;
          });
          _showOverlay();
          break;
        case LogicalKeyboardKey.arrowUp:
          setState(() {
            _selectedIndex = (_selectedIndex - 1 + _filteredBlocks.length) %
                _filteredBlocks.length;
          });
          _showOverlay();
          break;
        case LogicalKeyboardKey.enter:
          if (_filteredBlocks.isNotEmpty) {
            _insertBlock(_filteredBlocks[_selectedIndex]);
          }
          break;
        case LogicalKeyboardKey.escape:
          _hideOverlay();
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 상단 툴바
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.config.backgroundColor,
            border: Border(
              bottom: BorderSide(color: widget.config.borderColor),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(_showPreview ? Icons.edit : Icons.preview),
                onPressed: widget.config.enablePreview
                    ? () {
                        setState(() {
                          _showPreview = !_showPreview;
                        });
                      }
                    : null,
                tooltip: _showPreview ? '편집 모드' : '미리보기',
              ),
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: () => _exportToClipboard('json'),
                tooltip: 'JSON 복사',
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () => _exportToClipboard('markdown'),
                tooltip: '마크다운 복사',
              ),
              const Spacer(),
              if (!_showPreview)
                Text(
                  '${_controller.text.length} 문자',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
        ),

        // 에디터 또는 미리보기 영역
        Expanded(
          child: _showPreview
              ? _MarkdownPreview(
                  text: _controller.text,
                  config: widget.config,
                )
              : KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: _handleKeyEvent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.config.backgroundColor,
                      border: Border.all(color: widget.config.borderColor),
                      borderRadius: BorderRadius.circular(
                        widget.config.borderRadius,
                      ),
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      style: widget.config.textStyle,
                      maxLines: widget.config.maxLines,
                      decoration: InputDecoration(
                        hintText: widget.config.hintText,
                        border: InputBorder.none,
                        contentPadding: widget.config.padding,
                      ),
                      onSubmitted: widget.onSubmitted,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  void _exportToClipboard(String format) {
    String content;
    String message;

    if (format == 'json') {
      final document =
          _currentDocument ?? EditorDocument.fromMarkdown(_controller.text);
      final json = jsonEncode(document.toJson());
      content = _formatJson(json);
      message = 'JSON이 클립보드에 복사되었습니다';
    } else {
      content = _controller.text;
      message = '마크다운이 클립보드에 복사되었습니다';
    }

    Clipboard.setData(ClipboardData(text: content));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatJson(String json) {
    try {
      final decoded = jsonDecode(json);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(decoded);
    } catch (e) {
      return json;
    }
  }
}

// ===== 슬래시 명령어 오버레이 =====
class _SlashCommandOverlay extends StatefulWidget {
  final List<EditorBlockType> filteredBlocks;
  final int selectedIndex;
  final Function(EditorBlockType) onBlockSelected;
  final Function(int) onIndexChanged;
  final SlashdownEditorConfig config;
  final RenderBox? textFieldRenderBox;

  const _SlashCommandOverlay({
    required this.filteredBlocks,
    required this.selectedIndex,
    required this.onBlockSelected,
    required this.onIndexChanged,
    required this.config,
    this.textFieldRenderBox,
  });

  @override
  State<_SlashCommandOverlay> createState() => _SlashCommandOverlayState();
}

class _SlashCommandOverlayState extends State<_SlashCommandOverlay> {
  @override
  Widget build(BuildContext context) {
    Offset position = const Offset(16, 100);
    if (widget.textFieldRenderBox != null) {
      final textFieldPosition = widget.textFieldRenderBox!.localToGlobal(
        Offset.zero,
      );
      position = Offset(textFieldPosition.dx + 16, textFieldPosition.dy + 60);
    }

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(widget.config.borderRadius),
        child: Container(
          width: 280,
          constraints: const BoxConstraints(maxHeight: 300),
          decoration: BoxDecoration(
            color: widget.config.overlayBackgroundColor,
            borderRadius: BorderRadius.circular(widget.config.borderRadius),
            border: Border.all(color: widget.config.borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: widget.config.borderColor),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.flash_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    const Text(
                      '블록 추가',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              // 블록 리스트
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: widget.filteredBlocks.length,
                  itemBuilder: (context, index) {
                    final block = widget.filteredBlocks[index];
                    final isSelected = index == widget.selectedIndex;

                    return InkWell(
                      onTap: () => widget.onBlockSelected(block),
                      onHover: (hovering) {
                        if (hovering) {
                          widget.onIndexChanged(index);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? widget.config.selectedItemColor
                              : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF3B82F6)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                block.icon,
                                size: 16,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    block.label,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? Colors.black
                                          : Colors.grey[800],
                                    ),
                                  ),
                                  if (block.markdown.isNotEmpty)
                                    Text(
                                      block.markdown.trim(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== 마크다운 미리보기 위젯 =====
class _MarkdownPreview extends StatelessWidget {
  final String text;
  final SlashdownEditorConfig config;

  const _MarkdownPreview({required this.text, required this.config});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: config.padding,
      decoration: BoxDecoration(
        color: config.backgroundColor,
        border: Border.all(color: config.borderColor),
        borderRadius: BorderRadius.circular(config.borderRadius),
      ),
      child: SingleChildScrollView(child: _parseMarkdown(text)),
    );
  }

  Widget _parseMarkdown(String text) {
    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      // 헤딩
      if (line.startsWith('### ')) {
        widgets.add(_buildHeading(line.substring(4), 3));
      } else if (line.startsWith('## ')) {
        widgets.add(_buildHeading(line.substring(3), 2));
      } else if (line.startsWith('# ')) {
        widgets.add(_buildHeading(line.substring(2), 1));
      }
      // 인용
      else if (line.startsWith('> 📝') || line.startsWith('> 💡')) {
        widgets.add(_buildCallout(line.substring(4)));
      } else if (line.startsWith('> ')) {
        widgets.add(_buildQuote(line.substring(2)));
      }
      // 리스트
      else if (line.startsWith('- [ ] ')) {
        widgets.add(_buildCheckbox(line.substring(6), false));
      } else if (line.startsWith('- [x] ')) {
        widgets.add(_buildCheckbox(line.substring(6), true));
      } else if (line.startsWith('- ')) {
        widgets.add(_buildBulletPoint(line.substring(2)));
      }
      // 넘버링 리스트
      else if (RegExp(r'^\d+\. ').hasMatch(line)) {
        final match = RegExp(r'^(\d+)\. (.*)').firstMatch(line);
        if (match != null) {
          widgets.add(
            _buildNumberedPoint(match.group(2)!, int.parse(match.group(1)!)),
          );
        }
      }
      // 구분선
      else if (line.trim() == '---') {
        widgets.add(_buildDivider());
      }
      // 코드 블록
      else if (line.startsWith('```')) {
        final codeLines = <String>[];
        i++;
        while (i < lines.length && !lines[i].startsWith('```')) {
          codeLines.add(lines[i]);
          i++;
        }
        widgets.add(_buildCodeBlock(codeLines.join('\n')));
      }
      // 일반 텍스트
      else {
        widgets.add(_buildParagraph(line));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildHeading(String text, int level) {
    double fontSize = 24 - (level - 1) * 4;
    FontWeight weight = level == 1 ? FontWeight.bold : FontWeight.w600;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: weight,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          height: 1.5,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildQuote(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        border: Border(left: BorderSide(color: Color(0xFF3B82F6), width: 4)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontStyle: FontStyle.italic,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildCallout(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        border: Border.all(color: const Color(0xFF0EA5E9)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Text('📝', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberedPoint(String text, int number) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. ',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox(String text, bool checked) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 16),
      child: Row(
        children: [
          Icon(
            checked ? Icons.check_box : Icons.check_box_outline_blank,
            size: 20,
            color: checked ? const Color(0xFF10B981) : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                decoration: checked ? TextDecoration.lineThrough : null,
                color: checked ? Colors.grey : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeBlock(String code) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        code,
        style: const TextStyle(
          fontSize: 14,
          fontFamily: 'monospace',
          color: Colors.white,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      height: 1,
      color: Colors.grey[300],
    );
  }
}

// ===== 패키지 사용 예제 앱 =====
class SlashdownEditorApp extends StatefulWidget {
  const SlashdownEditorApp({super.key});

  @override
  State<SlashdownEditorApp> createState() => _SlashdownEditorAppState();
}

class _SlashdownEditorAppState extends State<SlashdownEditorApp> {
  String _markdownText = '''# Slashdown 에디터 패키지 🚀

**React 에디터와 100% 호환**되는 블록 기반 마크다운 에디터입니다!

## ✨ 핵심 기능

### 📝 슬래시 명령어 시스템
"/" 를 입력하면 블록 메뉴가 나타납니다:

- **헤딩**: # ## ###
- **리스트**: 불릿, 넘버링, 체크박스  
- **인용**: > 텍스트
- **콜아웃**: > 📝 중요한 정보
- **코드**: ``` 코드 블록
- **구분선**: ---

### 🔧 데이터 구조
각 블록은 JSON으로 직렬화됩니다:

```json
{
  "blocks": [
    {
      "id": "block_0", 
      "type": "paragraph",
      "value": {
        "text": [{"text": "내용"}]
      }
    }
  ]
}
```

### 📋 체크리스트 예시:

- [x] 슬래시 명령어 구현
- [x] 블록 시스템 구현  
- [x] JSON 직렬화/역직렬화
- [x] 미리보기 기능
- [ ] 드래그 앤 드롭
- [ ] 실시간 협업

> 📝 **팁**: 이 에디터는 백엔드 API에 바로 연동할 수 있습니다!

## 🚀 사용법

### 기본 사용
```dart
SlashdownEditor(
  onChanged: (text) => print('텍스트: '),
  onDocumentChanged: (document) {
    // JSON 형태로 백엔드에 저장
    final json = document.toJson();
    // API 호출: POST /api/documents
  },
)
```

### 커스터마이징  
```dart
SlashdownEditor(
  config: SlashdownEditorConfig(
    availableBlocks: [
      EditorBlockType.paragraph,
      EditorBlockType.heading1,
      EditorBlockType.code,
    ],
  ),
)
```

---

**시작해보세요!** "/" 를 입력하고 블록을 만들어보세요.''';

  EditorDocument? _currentDocument;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Slashdown Editor Package',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'Slashdown Editor 📝',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: true,
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.info_outline),
              onSelected: (action) {
                if (action == 'usage') {
                  _showUsageDialog();
                } else if (action == 'structure') {
                  _showBlockStructure();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'usage',
                  child: Row(
                    children: [
                      Icon(Icons.help_outline, size: 20),
                      SizedBox(width: 8),
                      Text('사용법'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'structure',
                  child: Row(
                    children: [
                      Icon(Icons.architecture, size: 20),
                      SizedBox(width: 8),
                      Text('블록 구조'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Container(
          margin: const EdgeInsets.all(16),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SlashdownEditor(
                initialText: _markdownText,
                config: const SlashdownEditorConfig(
                  textStyle: TextStyle(
                    fontSize: 16,
                    fontFamily: 'monospace',
                    height: 1.5,
                  ),
                  backgroundColor: Colors.white,
                  overlayBackgroundColor: Colors.white,
                  selectedItemColor: Color(0xFFF3F4F6),
                  borderColor: Color(0xFFE5E7EB),
                  padding: EdgeInsets.all(20),
                  maxLines: 25,
                ),
                onChanged: (text) {
                  setState(() {
                    _markdownText = text;
                  });
                },
                onDocumentChanged: (document) {
                  setState(() {
                    _currentDocument = document;
                  });
                  print('📄 문서 업데이트: ${document.blocks.length} 블록');

                  // 여기서 백엔드 API 호출 가능
                  // await yourApiService.saveDocument(document.toJson());
                },
                onSubmitted: (text) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('문서가 제출되었습니다!')));
                },
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            if (_currentDocument != null) {
              final json = jsonEncode(_currentDocument!.toJson());
              Clipboard.setData(ClipboardData(text: json));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('문서 JSON이 클립보드에 복사되었습니다!')),
              );
            }
          },
          icon: const Icon(Icons.api),
          label: const Text('API 데이터'),
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }

  void _showUsageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📦 Slashdown 패키지'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🎯 핵심 기능', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('📝 "/" 입력으로 블록 메뉴'),
            Text('🔄 React 에디터 100% 호환'),
            Text('📊 JSON 직렬화/역직렬화'),
            Text('👁️ 실시간 미리보기'),
            Text('📋 클립보드 내보내기'),
            SizedBox(height: 16),
            Text(
              '💻 개발자 사용법',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('onDocumentChanged로 블록 구조 받기'),
            Text('document.toJson()으로 API 전송'),
            Text('EditorDocument.fromJson()으로 로드'),
            Text('완전히 커스터마이징 가능한 설정'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showBlockStructure() {
    if (_currentDocument == null) return;

    final json = jsonEncode(_currentDocument!.toJson());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey, width: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.api, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    '백엔드 API 데이터',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_currentDocument!.blocks.length} 블록',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: json));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('API 데이터가 클립보드에 복사되었습니다!'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _formatJson(json),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatJson(String json) {
    try {
      final decoded = jsonDecode(json);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(decoded);
    } catch (e) {
      return json;
    }
  }
}

void main() {
  runApp(const SlashdownEditorApp());
}
