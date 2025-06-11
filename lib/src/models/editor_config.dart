import 'package:flutter/material.dart';
import 'editor_block.dart';

/// 슬래시다운 에디터 설정
/// 모바일 최적화와 접근성을 고려한 설정을 제공합니다.
class SlashdownEditorConfig {
  // === 기본 스타일링 ===
  final TextStyle textStyle;
  final Color backgroundColor;
  final Color overlayBackgroundColor;
  final Color selectedItemColor;
  final Color borderColor;
  final Color focusedBorderColor;
  final double borderRadius;
  final EdgeInsets padding;
  final EdgeInsets overlayPadding;

  // === 모바일 최적화 ===
  final double minTouchTargetSize; // 최소 터치 영역 크기
  final bool enableHapticFeedback; // 햅틱 피드백
  final Duration animationDuration; // 애니메이션 지속시간
  final Curve animationCurve; // 애니메이션 커브
  final bool adaptiveUI; // 화면 크기 적응형 UI
  final double mobileBreakpoint; // 모바일 기준점 (너비)

  // === 성능 최적화 ===
  final bool enablePerformanceMonitoring; // 성능 모니터링
  final Duration debounceDelay; // 디바운스 지연시간
  final int maxCachedBlocks; // 최대 캐시 블록 수
  final bool lazyRendering; // 지연 렌더링

  // === 에디터 기능 ===
  final int maxLines;
  final String hintText;
  final bool enableSlashCommand;
  final bool enablePreview;
  final bool enableAutoComplete;
  final bool enableFormatting;
  final List<EditorBlockType> availableBlocks;

  // === 키보드 및 입력 ===
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool enableSpellCheck;
  final bool enableSuggestions;

  // === 접근성 ===
  final String semanticLabel;
  final String semanticHint;
  final bool enableAccessibility;
  final double minimumFontSize;
  final double maximumFontSize;

  const SlashdownEditorConfig({
    // 기본 스타일링
    this.textStyle = const TextStyle(
      fontSize: 16,
      fontFamily: 'monospace',
      height: 1.5,
      color: Colors.black87,
    ),
    this.backgroundColor = Colors.white,
    this.overlayBackgroundColor = Colors.white,
    this.selectedItemColor = const Color(0xFFF3F4F6),
    this.borderColor = const Color(0xFFE5E7EB),
    this.focusedBorderColor = const Color(0xFF3B82F6),
    this.borderRadius = 8.0,
    this.padding = const EdgeInsets.all(16),
    this.overlayPadding = const EdgeInsets.all(8),

    // 모바일 최적화
    this.minTouchTargetSize = 44.0, // iOS HIG 기준
    this.enableHapticFeedback = true,
    this.animationDuration = const Duration(milliseconds: 200),
    this.animationCurve = Curves.easeInOut,
    this.adaptiveUI = true,
    this.mobileBreakpoint = 768.0,

    // 성능 최적화
    this.enablePerformanceMonitoring = false,
    this.debounceDelay = const Duration(milliseconds: 300),
    this.maxCachedBlocks = 100,
    this.lazyRendering = true,

    // 에디터 기능
    this.maxLines = 20,
    this.hintText = '마크다운으로 작성하세요... "/" 를 입력하면 메뉴가 나타납니다',
    this.enableSlashCommand = true,
    this.enablePreview = true,
    this.enableAutoComplete = true,
    this.enableFormatting = true,
    this.availableBlocks = EditorBlockType.values,

    // 키보드 및 입력
    this.keyboardType = TextInputType.multiline,
    this.textInputAction = TextInputAction.newline,
    this.enableSpellCheck = true,
    this.enableSuggestions = true,

    // 접근성
    this.semanticLabel = '마크다운 에디터',
    this.semanticHint = '텍스트를 입력하거나 슬래시를 입력하여 블록을 추가하세요',
    this.enableAccessibility = true,
    this.minimumFontSize = 12.0,
    this.maximumFontSize = 24.0,
  });

  /// 모바일 환경인지 확인
  bool isMobile(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth < mobileBreakpoint;
  }

  /// 터치 영역 크기 계산
  double getTouchTargetSize(BuildContext context) {
    if (!adaptiveUI) return minTouchTargetSize;

    final screenSize = MediaQuery.of(context).size;
    final scaleFactor = screenSize.width / 375.0; // iPhone 기준 스케일
    return (minTouchTargetSize * scaleFactor)
        .clamp(minTouchTargetSize, minTouchTargetSize * 1.5);
  }

  /// 폰트 크기 계산 (접근성 고려)
  double getAdaptiveFontSize(BuildContext context) {
    if (!adaptiveUI) return textStyle.fontSize ?? 16.0;

    final textScaler = MediaQuery.of(context).textScaler;
    final baseFontSize = textStyle.fontSize ?? 16.0;
    final adaptedSize = textScaler.scale(baseFontSize);

    return adaptedSize.clamp(minimumFontSize, maximumFontSize);
  }

  /// 적응형 패딩 계산
  EdgeInsets getAdaptivePadding(BuildContext context) {
    if (!adaptiveUI) return padding;

    if (isMobile(context)) {
      // 모바일에서는 패딩을 약간 줄임
      return EdgeInsets.all(padding.left * 0.75);
    }
    return padding;
  }

  /// 오버레이 위치 계산 (모바일 최적화)
  Offset getOverlayPosition(BuildContext context, RenderBox? textFieldBox) {
    if (textFieldBox == null) return const Offset(16, 100);

    final textFieldPosition = textFieldBox.localToGlobal(Offset.zero);
    final screenSize = MediaQuery.of(context).size;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    if (isMobile(context)) {
      // 모바일에서는 키보드와 겹치지 않도록 위치 조정
      final availableHeight = screenSize.height - keyboardHeight - 100;
      final preferredY = textFieldPosition.dy + 60;

      return Offset(
        16.0,
        preferredY > availableHeight ? availableHeight - 200 : preferredY,
      );
    }

    return Offset(textFieldPosition.dx + 16, textFieldPosition.dy + 60);
  }

  /// 다크 테마 설정 생성
  SlashdownEditorConfig darkTheme() {
    return copyWith(
      backgroundColor: const Color(0xFF1F2937),
      overlayBackgroundColor: const Color(0xFF374151),
      selectedItemColor: const Color(0xFF4B5563),
      borderColor: const Color(0xFF6B7280),
      focusedBorderColor: const Color(0xFF60A5FA),
      textStyle: textStyle.copyWith(color: Colors.white),
    );
  }

  /// 고대비 테마 설정 생성 (접근성)
  SlashdownEditorConfig highContrastTheme() {
    return copyWith(
      backgroundColor: Colors.white,
      overlayBackgroundColor: Colors.white,
      selectedItemColor: const Color(0xFFFFEB3B),
      borderColor: Colors.black,
      focusedBorderColor: const Color(0xFF2196F3),
      textStyle: textStyle.copyWith(
        color: Colors.black,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// 설정 복사 생성
  SlashdownEditorConfig copyWith({
    TextStyle? textStyle,
    Color? backgroundColor,
    Color? overlayBackgroundColor,
    Color? selectedItemColor,
    Color? borderColor,
    Color? focusedBorderColor,
    double? borderRadius,
    EdgeInsets? padding,
    EdgeInsets? overlayPadding,
    double? minTouchTargetSize,
    bool? enableHapticFeedback,
    Duration? animationDuration,
    Curve? animationCurve,
    bool? adaptiveUI,
    double? mobileBreakpoint,
    bool? enablePerformanceMonitoring,
    Duration? debounceDelay,
    int? maxCachedBlocks,
    bool? lazyRendering,
    int? maxLines,
    String? hintText,
    bool? enableSlashCommand,
    bool? enablePreview,
    bool? enableAutoComplete,
    bool? enableFormatting,
    List<EditorBlockType>? availableBlocks,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool? enableSpellCheck,
    bool? enableSuggestions,
    String? semanticLabel,
    String? semanticHint,
    bool? enableAccessibility,
    double? minimumFontSize,
    double? maximumFontSize,
  }) {
    return SlashdownEditorConfig(
      textStyle: textStyle ?? this.textStyle,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      overlayBackgroundColor:
          overlayBackgroundColor ?? this.overlayBackgroundColor,
      selectedItemColor: selectedItemColor ?? this.selectedItemColor,
      borderColor: borderColor ?? this.borderColor,
      focusedBorderColor: focusedBorderColor ?? this.focusedBorderColor,
      borderRadius: borderRadius ?? this.borderRadius,
      padding: padding ?? this.padding,
      overlayPadding: overlayPadding ?? this.overlayPadding,
      minTouchTargetSize: minTouchTargetSize ?? this.minTouchTargetSize,
      enableHapticFeedback: enableHapticFeedback ?? this.enableHapticFeedback,
      animationDuration: animationDuration ?? this.animationDuration,
      animationCurve: animationCurve ?? this.animationCurve,
      adaptiveUI: adaptiveUI ?? this.adaptiveUI,
      mobileBreakpoint: mobileBreakpoint ?? this.mobileBreakpoint,
      enablePerformanceMonitoring:
          enablePerformanceMonitoring ?? this.enablePerformanceMonitoring,
      debounceDelay: debounceDelay ?? this.debounceDelay,
      maxCachedBlocks: maxCachedBlocks ?? this.maxCachedBlocks,
      lazyRendering: lazyRendering ?? this.lazyRendering,
      maxLines: maxLines ?? this.maxLines,
      hintText: hintText ?? this.hintText,
      enableSlashCommand: enableSlashCommand ?? this.enableSlashCommand,
      enablePreview: enablePreview ?? this.enablePreview,
      enableAutoComplete: enableAutoComplete ?? this.enableAutoComplete,
      enableFormatting: enableFormatting ?? this.enableFormatting,
      availableBlocks: availableBlocks ?? this.availableBlocks,
      keyboardType: keyboardType ?? this.keyboardType,
      textInputAction: textInputAction ?? this.textInputAction,
      enableSpellCheck: enableSpellCheck ?? this.enableSpellCheck,
      enableSuggestions: enableSuggestions ?? this.enableSuggestions,
      semanticLabel: semanticLabel ?? this.semanticLabel,
      semanticHint: semanticHint ?? this.semanticHint,
      enableAccessibility: enableAccessibility ?? this.enableAccessibility,
      minimumFontSize: minimumFontSize ?? this.minimumFontSize,
      maximumFontSize: maximumFontSize ?? this.maximumFontSize,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlashdownEditorConfig &&
          runtimeType == other.runtimeType &&
          textStyle == other.textStyle &&
          backgroundColor == other.backgroundColor &&
          enableSlashCommand == other.enableSlashCommand &&
          enableHapticFeedback == other.enableHapticFeedback;

  @override
  int get hashCode => Object.hash(
        textStyle,
        backgroundColor,
        enableSlashCommand,
        enableHapticFeedback,
        adaptiveUI,
      );

  @override
  String toString() {
    return 'SlashdownEditorConfig{mobile: $adaptiveUI, haptic: $enableHapticFeedback, slash: $enableSlashCommand}';
  }
}
