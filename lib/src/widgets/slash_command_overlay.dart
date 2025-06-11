import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/editor_block.dart';
import '../models/editor_config.dart';

/// 슬래시 명령어 오버레이
/// 모바일 최적화된 블록 선택 인터페이스를 제공합니다.
class SlashCommandOverlay extends StatefulWidget {
  final List<EditorBlockType> filteredBlocks;
  final int selectedIndex;
  final Function(EditorBlockType) onBlockSelected;
  final Function(int) onIndexChanged;
  final SlashdownEditorConfig config;
  final BuildContext context;
  final RenderBox? textFieldRenderBox;

  const SlashCommandOverlay({
    super.key,
    required this.filteredBlocks,
    required this.selectedIndex,
    required this.onBlockSelected,
    required this.onIndexChanged,
    required this.config,
    required this.context,
    this.textFieldRenderBox,
  });

  @override
  State<SlashCommandOverlay> createState() => _SlashCommandOverlayState();
}

class _SlashCommandOverlayState extends State<SlashCommandOverlay>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: widget.config.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: widget.config.animationCurve,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: widget.config.animationCurve,
      ),
    );

    _scrollController = ScrollController();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SlashCommandOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 선택된 항목이 화면에 보이도록 스크롤
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _scrollToSelectedItem();
    }
  }

  void _scrollToSelectedItem() {
    if (!_scrollController.hasClients) return;

    const itemHeight = 60.0; // 각 항목의 높이
    final targetOffset = widget.selectedIndex * itemHeight;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;

    // 현재 보이는 영역 계산
    const overlayHeight = 300.0;
    final viewportStart = currentScroll;
    final viewportEnd = currentScroll + overlayHeight;

    // 선택된 항목이 보이지 않으면 스크롤
    if (targetOffset < viewportStart ||
        targetOffset + itemHeight > viewportEnd) {
      _scrollController.animateTo(
        (targetOffset - overlayHeight / 2 + itemHeight / 2)
            .clamp(0.0, maxScroll),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = widget.config.isMobile(context);
    final position =
        widget.config.getOverlayPosition(context, widget.textFieldRenderBox);
    final overlayWidth = isMobile
        ? MediaQuery.of(context).size.width - 32
        : // 모바일에서는 거의 전체 너비
        320.0; // 데스크톱에서는 고정 너비

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          alignment: Alignment.topLeft,
          child: Material(
            elevation: isMobile ? 16 : 8, // 모바일에서는 더 높은 elevation
            borderRadius: BorderRadius.circular(widget.config.borderRadius),
            clipBehavior: Clip.antiAlias,
            child: Container(
              width: overlayWidth,
              constraints: BoxConstraints(
                maxHeight: isMobile
                    ? MediaQuery.of(context).size.height * 0.4
                    : // 모바일에서는 화면의 40%
                    300,
              ),
              decoration: BoxDecoration(
                color: widget.config.overlayBackgroundColor,
                borderRadius: BorderRadius.circular(widget.config.borderRadius),
                border: Border.all(color: widget.config.borderColor),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 헤더
                  _buildHeader(isMobile),

                  // 블록 리스트
                  Flexible(
                    child: _buildBlockList(isMobile),
                  ),

                  // 모바일에서만 표시되는 하단 힌트
                  if (isMobile) _buildMobileHint(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: widget.config.borderColor),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.flash_on,
            size: isMobile ? 20 : 16,
            color: Colors.grey[600],
          ),
          SizedBox(width: isMobile ? 12 : 8),
          Text(
            '블록 추가',
            style: TextStyle(
              fontSize: isMobile ? 16 : 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const Spacer(),
          if (widget.filteredBlocks.isNotEmpty)
            Text(
              '${widget.filteredBlocks.length}개',
              style: TextStyle(
                fontSize: isMobile ? 14 : 12,
                color: Colors.grey[500],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBlockList(bool isMobile) {
    return ListView.builder(
      controller: _scrollController,
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(vertical: isMobile ? 8 : 4),
      itemCount: widget.filteredBlocks.length,
      itemBuilder: (context, index) {
        final block = widget.filteredBlocks[index];
        final isSelected = index == widget.selectedIndex;

        return _buildBlockItem(block, isSelected, index, isMobile);
      },
    );
  }

  Widget _buildBlockItem(
      EditorBlockType block, bool isSelected, int index, bool isMobile) {
    final touchTargetSize = widget.config.getTouchTargetSize(context);

    return InkWell(
      onTap: () {
        widget.onBlockSelected(block);
        if (widget.config.enableHapticFeedback) {
          HapticFeedback.selectionClick();
        }
      },
      onHover: (hovering) {
        if (hovering) {
          widget.onIndexChanged(index);
        }
      },
      child: Container(
        constraints: BoxConstraints(minHeight: touchTargetSize),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 20 : 16,
          vertical: isMobile ? 16 : 12,
        ),
        decoration: BoxDecoration(
          color:
              isSelected ? widget.config.selectedItemColor : Colors.transparent,
          borderRadius: BorderRadius.circular(isMobile ? 12 : 8),
        ),
        margin: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 4),
        child: Row(
          children: [
            // 아이콘 컨테이너
            Container(
              width: isMobile ? 40 : 32,
              height: isMobile ? 40 : 32,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF3B82F6) : Colors.grey[100],
                borderRadius: BorderRadius.circular(isMobile ? 10 : 6),
              ),
              child: Icon(
                block.icon,
                size: isMobile ? 20 : 16,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),

            SizedBox(width: isMobile ? 16 : 12),

            // 텍스트 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    block.label,
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.black87 : Colors.grey[800],
                    ),
                  ),
                  if (block.markdown.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        block.markdown.trim(),
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 12,
                          color: Colors.grey[500],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 선택 표시기 (모바일에서만)
            if (isMobile && isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF3B82F6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 16,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileHint() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: widget.config.borderColor),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            '탭하여 선택',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
