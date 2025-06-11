import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

import '../models/editor_block.dart';
import '../models/editor_document.dart';
import '../models/editor_config.dart';
import '../utils/performance_utils.dart';
import 'slash_command_overlay.dart';
import 'markdown_preview.dart';

/// 슬래시다운 에디터 - 메인 위젯
/// 모바일 최적화 및 성능 최적화가 적용된 마크다운 에디터입니다.
class SlashdownEditor extends StatefulWidget {
  final String initialText;
  final SlashdownEditorConfig config;
  final Function(String text)? onChanged;
  final Function(String text)? onSubmitted;
  final Function(EditorDocument document)? onDocumentChanged;
  final VoidCallback? onFocus;
  final VoidCallback? onUnfocus;

  const SlashdownEditor({
    super.key,
    this.initialText = '',
    this.config = const SlashdownEditorConfig(),
    this.onChanged,
    this.onSubmitted,
    this.onDocumentChanged,
    this.onFocus,
    this.onUnfocus,
  });

  @override
  State<SlashdownEditor> createState() => _SlashdownEditorState();
}

class _SlashdownEditorState extends State<SlashdownEditor>
    with TickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // 오버레이 관련
  OverlayEntry? _overlayEntry;
  int _selectedIndex = 0;
  List<EditorBlockType> _filteredBlocks = [];
  int _slashPosition = -1;

  // 상태 관리
  bool _showPreview = false;
  bool _isFocused = false;
  EditorDocument? _currentDocument;
  String _lastText = '';

  @override
  void initState() {
    super.initState();

    // 성능 모니터링 활성화
    if (widget.config.enablePerformanceMonitoring) {
      PerformanceUtils.setEnabled(true);
    }

    _controller = TextEditingController(text: widget.initialText);
    _focusNode = FocusNode();
    _animationController = AnimationController(
      duration: widget.config.animationDuration,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _animationController, curve: widget.config.animationCurve),
    );

    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);

    _lastText = widget.initialText;
    _animationController.forward();
  }

  @override
  void dispose() {
    _hideOverlay();
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();

    if (widget.config.enablePerformanceMonitoring) {
      PerformanceUtils.printReport();
    }

    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    if (_isFocused) {
      widget.onFocus?.call();
      if (widget.config.enableHapticFeedback) {
        HapticFeedback.lightImpact();
      }
    } else {
      widget.onUnfocus?.call();
      _hideOverlay();
    }
  }

  void _onTextChanged() {
    final text = _controller.text;

    // 문서 구조 변경 알림 (성능 최적화 적용)
    if (text != _lastText) {
      final document = EditorDocument.fromMarkdown(text);
      _currentDocument = document;
      widget.onDocumentChanged?.call(document);
      _lastText = text;
    }

    // 슬래시 명령어 처리
    if (widget.config.enableSlashCommand && _isFocused) {
      _handleSlashCommand(text);
    }
  }

  void _handleSlashCommand(String text) {
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
      builder: (context) => SlashCommandOverlay(
        filteredBlocks: _filteredBlocks,
        selectedIndex: _selectedIndex,
        onBlockSelected: _insertBlock,
        onIndexChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        config: widget.config,
        context: context,
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

    PerformanceUtils.measureTime('block_insertion', () {
      final text = _controller.text;
      final cursorPosition = _controller.selection.baseOffset;

      final beforeSlash = text.substring(0, _slashPosition);
      final afterCursor = text.substring(cursorPosition);

      String newText;
      int newCursorPosition;

      switch (blockType) {
        case EditorBlockType.code:
          newText = '$beforeSlash${blockType.markdown}$afterCursor\n```';
          newCursorPosition = beforeSlash.length + 4;
          break;
        case EditorBlockType.image:
        case EditorBlockType.link:
          newText = '$beforeSlash${blockType.markdown})$afterCursor';
          newCursorPosition =
              beforeSlash.length + (blockType == EditorBlockType.link ? 1 : 4);
          break;
        default:
          newText = '$beforeSlash${blockType.markdown}$afterCursor';
          newCursorPosition = beforeSlash.length + blockType.markdown.length;
      }

      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newCursorPosition),
      );

      _hideOverlay();

      if (widget.config.enableHapticFeedback) {
        HapticFeedback.lightImpact();
      }
    });
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

  void _togglePreview() {
    setState(() {
      _showPreview = !_showPreview;
    });

    if (widget.config.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
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
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  @override
  Widget build(BuildContext context) {
    final isMobile = widget.config.isMobile(context);
    final adaptivePadding = widget.config.getAdaptivePadding(context);
    final adaptiveFontSize = widget.config.getAdaptiveFontSize(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // 상단 툴바 (모바일 최적화)
          _buildToolbar(context, isMobile),

          // 에디터 또는 미리보기 영역
          Expanded(
            child: _showPreview
                ? MarkdownPreview(
                    text: _controller.text,
                    config: widget.config,
                  )
                : _buildEditor(context, adaptivePadding, adaptiveFontSize),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, bool isMobile) {
    final toolbarHeight = isMobile ? 56.0 : 48.0;
    final iconSize = isMobile ? 24.0 : 20.0;

    return Container(
      height: toolbarHeight,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: widget.config.backgroundColor,
        border: Border(
          bottom: BorderSide(color: widget.config.borderColor),
        ),
      ),
      child: Row(
        children: [
          // 미리보기 토글
          if (widget.config.enablePreview)
            _buildToolbarButton(
              icon: _showPreview ? Icons.edit : Icons.preview,
              tooltip: _showPreview ? '편집 모드' : '미리보기',
              onPressed: _togglePreview,
              iconSize: iconSize,
            ),

          const SizedBox(width: 8),

          // 내보내기 버튼들
          _buildToolbarButton(
            icon: Icons.download,
            tooltip: 'JSON 복사',
            onPressed: () => _exportToClipboard('json'),
            iconSize: iconSize,
          ),

          const SizedBox(width: 8),

          _buildToolbarButton(
            icon: Icons.copy,
            tooltip: '마크다운 복사',
            onPressed: () => _exportToClipboard('markdown'),
            iconSize: iconSize,
          ),

          const Spacer(),

          // 문서 정보 (모바일에서는 간략하게)
          if (!_showPreview)
            Text(
              isMobile
                  ? '${_controller.text.length}'
                  : '${_controller.text.length} 문자',
              style: TextStyle(
                fontSize: isMobile ? 12 : 12,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required double iconSize,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: iconSize, color: Colors.grey[700]),
        ),
      ),
    );
  }

  Widget _buildEditor(
      BuildContext context, EdgeInsets padding, double fontSize) {
    final isMobile = widget.config.isMobile(context);

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _handleKeyEvent,
      child: Container(
        decoration: BoxDecoration(
          color: widget.config.backgroundColor,
          border: Border.all(
            color: _isFocused
                ? widget.config.focusedBorderColor
                : widget.config.borderColor,
          ),
          borderRadius: BorderRadius.circular(widget.config.borderRadius),
        ),
        child: Semantics(
          label: widget.config.semanticLabel,
          hint: widget.config.semanticHint,
          textField: true,
          multiline: true,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            style: widget.config.textStyle.copyWith(fontSize: fontSize),
            maxLines: widget.config.maxLines,
            keyboardType: widget.config.keyboardType,
            textInputAction: widget.config.textInputAction,
            enableSuggestions: widget.config.enableSuggestions,
            spellCheckConfiguration: widget.config.enableSpellCheck
                ? const SpellCheckConfiguration()
                : const SpellCheckConfiguration.disabled(),
            decoration: InputDecoration(
              hintText: widget.config.hintText,
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: fontSize * 0.9,
              ),
              border: InputBorder.none,
              contentPadding: padding,
            ),
            onSubmitted: widget.onSubmitted,
            // 모바일 최적화: 자동 스크롤
            scrollPadding:
                isMobile ? const EdgeInsets.all(20.0) : EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}
