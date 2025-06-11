import 'package:flutter/material.dart';

import '../models/editor_config.dart';
import '../utils/performance_utils.dart';

/// 마크다운 미리보기 위젯
/// 성능 최적화 및 모바일 최적화가 적용된 마크다운 렌더러입니다.
class MarkdownPreview extends StatefulWidget {
  final String text;
  final SlashdownEditorConfig config;

  const MarkdownPreview({
    super.key,
    required this.text,
    required this.config,
  });

  @override
  State<MarkdownPreview> createState() => _MarkdownPreviewState();
}

class _MarkdownPreviewState extends State<MarkdownPreview> {
  Widget? _cachedContent;
  String _cachedText = '';
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = widget.config.isMobile(context);
    final adaptivePadding = widget.config.getAdaptivePadding(context);

    // 성능 최적화: 텍스트가 변경되지 않았으면 캐시된 콘텐츠 사용
    if (widget.text != _cachedText || _cachedContent == null) {
      _cachedText = widget.text;
      _cachedContent = PerformanceUtils.measureTime(
        'markdown_render',
        () => _parseMarkdown(widget.text, isMobile),
      );
    }

    return Container(
      width: double.infinity,
      padding: adaptivePadding,
      decoration: BoxDecoration(
        color: widget.config.backgroundColor,
        border: Border.all(color: widget.config.borderColor),
        borderRadius: BorderRadius.circular(widget.config.borderRadius),
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: isMobile
            ? const BouncingScrollPhysics() // iOS 스타일 스크롤
            : const ClampingScrollPhysics(), // Android 스타일 스크롤
        child: _cachedContent!,
      ),
    );
  }

  Widget _parseMarkdown(String text, bool isMobile) {
    if (text.isEmpty) {
      return _buildEmptyState(isMobile);
    }

    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.isEmpty) {
        widgets.add(SizedBox(height: isMobile ? 12 : 8));
        continue;
      }

      // 헤딩
      if (line.startsWith('### ')) {
        widgets.add(_buildHeading(line.substring(4), 3, isMobile));
      } else if (line.startsWith('## ')) {
        widgets.add(_buildHeading(line.substring(3), 2, isMobile));
      } else if (line.startsWith('# ')) {
        widgets.add(_buildHeading(line.substring(2), 1, isMobile));
      }
      // 콜아웃
      else if (line.startsWith('> 📝') ||
          line.startsWith('> 💡') ||
          line.startsWith('> 🔥') ||
          line.startsWith('> ⚠️')) {
        widgets.add(
            _buildCallout(line.substring(4), _getCalloutTheme(line), isMobile));
      }
      // 인용
      else if (line.startsWith('> ')) {
        widgets.add(_buildQuote(line.substring(2), isMobile));
      }
      // TODO 리스트
      else if (line.startsWith('- [ ] ')) {
        widgets.add(_buildCheckbox(line.substring(6), false, isMobile));
      } else if (line.startsWith('- [x] ')) {
        widgets.add(_buildCheckbox(line.substring(6), true, isMobile));
      }
      // 불릿 리스트
      else if (line.startsWith('- ')) {
        widgets.add(_buildBulletPoint(line.substring(2), isMobile));
      }
      // 넘버링 리스트
      else if (RegExp(r'^\d+\. ').hasMatch(line)) {
        final match = RegExp(r'^(\d+)\. (.*)').firstMatch(line);
        if (match != null) {
          widgets.add(_buildNumberedPoint(
              match.group(2)!, int.parse(match.group(1)!), isMobile));
        }
      }
      // 구분선
      else if (line.trim() == '---') {
        widgets.add(_buildDivider(isMobile));
      }
      // 코드 블록
      else if (line.startsWith('```')) {
        final codeLines = <String>[];
        final language = line.substring(3).trim();
        i++;
        while (i < lines.length && !lines[i].startsWith('```')) {
          codeLines.add(lines[i]);
          i++;
        }
        widgets.add(_buildCodeBlock(codeLines.join('\n'), language, isMobile));
      }
      // 이미지
      else if (line.startsWith('![')) {
        final match = RegExp(r'!\[([^\]]*)\]\(([^)]*)\)').firstMatch(line);
        if (match != null) {
          widgets.add(_buildImage(
              match.group(1) ?? '', match.group(2) ?? '', isMobile));
        }
      }
      // 일반 텍스트
      else {
        widgets.add(_buildParagraph(line, isMobile));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildEmptyState(bool isMobile) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 32 : 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.edit_note,
              size: isMobile ? 48 : 40,
              color: Colors.grey[400],
            ),
            SizedBox(height: isMobile ? 16 : 12),
            Text(
              '텍스트를 입력하면\n미리보기가 여기에 표시됩니다',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile ? 16 : 14,
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCalloutTheme(String line) {
    if (line.contains('🔥')) return 'warning';
    if (line.contains('⚠️')) return 'danger';
    if (line.contains('💡')) return 'tip';
    return 'info';
  }

  Widget _buildHeading(String text, int level, bool isMobile) {
    double fontSize =
        isMobile ? (28 - (level - 1) * 4) : (24 - (level - 1) * 4);
    FontWeight weight = level == 1 ? FontWeight.bold : FontWeight.w600;

    return Padding(
      padding:
          EdgeInsets.only(bottom: isMobile ? 16 : 12, top: level > 1 ? 8 : 0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: weight,
          color: Colors.black87,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text, bool isMobile) {
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 12 : 8),
      child: Text(
        _parseInlineElements(text),
        style: TextStyle(
          fontSize: isMobile ? 17 : 16,
          height: 1.6,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildQuote(String text, bool isMobile) {
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 16 : 12),
      padding: EdgeInsets.all(isMobile ? 20 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border:
            const Border(left: BorderSide(color: Color(0xFF3B82F6), width: 4)),
        borderRadius: BorderRadius.circular(isMobile ? 12 : 8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isMobile ? 17 : 16,
          fontStyle: FontStyle.italic,
          color: Colors.black54,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildCallout(String text, String theme, bool isMobile) {
    Color backgroundColor;
    Color borderColor;
    IconData icon;

    switch (theme) {
      case 'warning':
        backgroundColor = const Color(0xFFFEF3C7);
        borderColor = const Color(0xFFF59E0B);
        icon = Icons.warning_rounded;
        break;
      case 'danger':
        backgroundColor = const Color(0xFFFEE2E2);
        borderColor = const Color(0xFFEF4444);
        icon = Icons.error_rounded;
        break;
      case 'tip':
        backgroundColor = const Color(0xFFECFDF5);
        borderColor = const Color(0xFF10B981);
        icon = Icons.lightbulb_rounded;
        break;
      default:
        backgroundColor = const Color(0xFFF0F9FF);
        borderColor = const Color(0xFF0EA5E9);
        icon = Icons.info_rounded;
    }

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 16 : 12),
      padding: EdgeInsets.all(isMobile ? 20 : 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(isMobile ? 12 : 8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: isMobile ? 22 : 20,
            color: borderColor,
          ),
          SizedBox(width: isMobile ? 16 : 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isMobile ? 17 : 16,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text, bool isMobile) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: isMobile ? 8 : 4, left: isMobile ? 20 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: isMobile ? 8 : 6),
            width: isMobile ? 6 : 5,
            height: isMobile ? 6 : 5,
            decoration: const BoxDecoration(
              color: Colors.black87,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: isMobile ? 16 : 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isMobile ? 17 : 16,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberedPoint(String text, int number, bool isMobile) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: isMobile ? 8 : 4, left: isMobile ? 20 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isMobile ? 24 : 20,
            child: Text(
              '$number.',
              style: TextStyle(
                fontSize: isMobile ? 17 : 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          SizedBox(width: isMobile ? 12 : 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isMobile ? 17 : 16,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox(String text, bool checked, bool isMobile) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: isMobile ? 8 : 4, left: isMobile ? 20 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 2),
            width: isMobile ? 22 : 20,
            height: isMobile ? 22 : 20,
            decoration: BoxDecoration(
              color: checked ? const Color(0xFF10B981) : Colors.transparent,
              border: Border.all(
                color: checked ? const Color(0xFF10B981) : Colors.grey[400]!,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: checked
                ? Icon(
                    Icons.check,
                    size: isMobile ? 16 : 14,
                    color: Colors.white,
                  )
                : null,
          ),
          SizedBox(width: isMobile ? 16 : 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isMobile ? 17 : 16,
                height: 1.5,
                decoration: checked ? TextDecoration.lineThrough : null,
                color: checked ? Colors.grey[600] : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeBlock(String code, String language, bool isMobile) {
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 16 : 12),
      padding: EdgeInsets.all(isMobile ? 20 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(isMobile ? 12 : 8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (language.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                language,
                style: TextStyle(
                  fontSize: isMobile ? 14 : 12,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              code,
              style: TextStyle(
                fontSize: isMobile ? 15 : 14,
                fontFamily: 'monospace',
                color: Colors.white,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String alt, String src, bool isMobile) {
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 16 : 12),
      padding: EdgeInsets.all(isMobile ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(isMobile ? 12 : 8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.image,
            size: isMobile ? 24 : 20,
            color: Colors.grey[600],
          ),
          SizedBox(width: isMobile ? 16 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alt.isNotEmpty ? alt : '이미지',
                  style: TextStyle(
                    fontSize: isMobile ? 17 : 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                if (src.isNotEmpty)
                  Text(
                    src,
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 12,
                      color: Colors.grey[600],
                      fontFamily: 'monospace',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isMobile) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: isMobile ? 24 : 20),
      height: 1,
      color: Colors.grey[300],
    );
  }

  String _parseInlineElements(String text) {
    // 간단한 인라인 요소 파싱 (실제로는 더 복잡한 구현이 필요)
    return text
        .replaceAll(RegExp(r'\*\*(.*?)\*\*'), '\$1') // Bold 제거 (미리보기에서는 단순화)
        .replaceAll(RegExp(r'\*(.*?)\*'), '\$1') // Italic 제거
        .replaceAll(RegExp(r'`(.*?)`'), '\$1'); // Inline code 제거
  }
}
