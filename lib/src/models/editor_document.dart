import 'editor_block.dart';
import '../utils/performance_utils.dart';

/// 에디터 문서 구조
/// 블록들의 집합으로 구성되며 백엔드 API와 100% 호환됩니다.
class EditorDocument {
  final List<EditorBlock> blocks;
  final Map<String, dynamic>? meta;

  // 성능 최적화를 위한 캐시
  String? _cachedMarkdown;
  Map<String, dynamic>? _cachedJson;
  int _cacheVersion = 0;

  EditorDocument({required this.blocks, this.meta}) {
    _invalidateCache();
  }

  /// 캐시 무효화 (블록이 변경될 때 호출)
  void _invalidateCache() {
    _cachedMarkdown = null;
    _cachedJson = null;
    _cacheVersion++;
  }

  /// JSON으로 직렬화 (성능 최적화 - 캐시됨)
  Map<String, dynamic> toJson() {
    return _cachedJson ??= {
      'blocks': blocks.map((block) => block.toJson()).toList(),
      'meta': meta ?? {},
      'version': _cacheVersion,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  /// JSON에서 문서 생성
  factory EditorDocument.fromJson(Map<String, dynamic> json) {
    final blocksJson = json['blocks'] as List<dynamic>;
    final blocks = blocksJson
        .map((blockJson) =>
            EditorBlock.fromJson(blockJson as Map<String, dynamic>))
        .toList();

    return EditorDocument(
      blocks: blocks,
      meta: json['meta'] as Map<String, dynamic>?,
    );
  }

  /// 마크다운으로 변환 (성능 최적화 - 캐시됨)
  String toMarkdown() {
    if (_cachedMarkdown != null) return _cachedMarkdown!;

    return _cachedMarkdown = PerformanceUtils.measureTime(
          'document_to_markdown',
          () => blocks.map((block) => block.toMarkdown()).join('\n\n'),
        ) ??
        '';
  }

  /// 마크다운에서 문서 생성 (성능 최적화됨)
  factory EditorDocument.fromMarkdown(String markdown) {
    return PerformanceUtils.measureTime('document_from_markdown', () {
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
          codeContent += '$line\n';
          continue;
        }

        // 블록 타입 감지 (성능 최적화됨)
        final blockType = _detectBlockType(line);
        currentType = blockType;
        currentBlockText = line;

        if (blockType == EditorBlockType.divider) {
          blocks.add(
            EditorBlock.fromMarkdown(
              'block_${blocks.length}',
              EditorBlockType.divider,
              '',
            ),
          );
          continue;
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
    });
  }

  /// 블록 타입 감지 (성능 최적화됨)
  static EditorBlockType _detectBlockType(String line) {
    // 가장 자주 사용되는 것부터 먼저 체크 (성능 최적화)
    if (line.startsWith('# ')) return EditorBlockType.heading1;
    if (line.startsWith('## ')) return EditorBlockType.heading2;
    if (line.startsWith('### ')) return EditorBlockType.heading3;
    if (line.startsWith('- ')) {
      if (line.startsWith('- [x] ') || line.startsWith('- [ ] ')) {
        return EditorBlockType.todo;
      }
      return EditorBlockType.bulleted;
    }
    if (line.startsWith('> ')) {
      if (line.startsWith('> 📝') || line.startsWith('> 💡')) {
        return EditorBlockType.callout;
      }
      return EditorBlockType.blockquote;
    }
    if (RegExp(r'^\d+\. ').hasMatch(line)) return EditorBlockType.numbered;
    if (line == '---') return EditorBlockType.divider;
    if (line.startsWith('![')) return EditorBlockType.image;

    return EditorBlockType.paragraph;
  }

  /// 블록 추가
  EditorDocument addBlock(EditorBlock block) {
    final newBlocks = List<EditorBlock>.from(blocks)..add(block);
    return EditorDocument(blocks: newBlocks, meta: meta);
  }

  /// 블록 제거
  EditorDocument removeBlock(String blockId) {
    final newBlocks = blocks.where((block) => block.id != blockId).toList();
    return EditorDocument(blocks: newBlocks, meta: meta);
  }

  /// 블록 업데이트
  EditorDocument updateBlock(String blockId, EditorBlock newBlock) {
    final newBlocks = blocks.map((block) {
      return block.id == blockId ? newBlock : block;
    }).toList();
    return EditorDocument(blocks: newBlocks, meta: meta);
  }

  /// 블록 순서 변경
  EditorDocument reorderBlocks(int oldIndex, int newIndex) {
    final newBlocks = List<EditorBlock>.from(blocks);
    final block = newBlocks.removeAt(oldIndex);
    newBlocks.insert(newIndex, block);
    return EditorDocument(blocks: newBlocks, meta: meta);
  }

  /// 빈 블록들 제거
  EditorDocument removeEmptyBlocks() {
    final newBlocks = blocks.where((block) => !block.isEmpty).toList();
    return EditorDocument(blocks: newBlocks, meta: meta);
  }

  /// 문서 통계
  DocumentStats get stats {
    int characterCount = 0;
    int wordCount = 0;
    final blockTypeCounts = <EditorBlockType, int>{};

    for (final block in blocks) {
      // 블록 타입 카운트
      blockTypeCounts[block.type] = (blockTypeCounts[block.type] ?? 0) + 1;

      // 텍스트 통계 (코드 블록 제외)
      if (block.type != EditorBlockType.code &&
          block.type != EditorBlockType.divider) {
        final text = block.toMarkdown();
        characterCount += text.length;
        wordCount +=
            text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
      }
    }

    return DocumentStats(
      blockCount: blocks.length,
      characterCount: characterCount,
      wordCount: wordCount,
      blockTypeCounts: blockTypeCounts,
    );
  }

  /// 문서가 비어있는지 확인
  bool get isEmpty => blocks.isEmpty || blocks.every((block) => block.isEmpty);

  /// 문서 복사 생성 (불변성 보장)
  EditorDocument copyWith({
    List<EditorBlock>? blocks,
    Map<String, dynamic>? meta,
  }) {
    return EditorDocument(
      blocks: blocks ?? List<EditorBlock>.from(this.blocks),
      meta: meta ??
          (this.meta != null ? Map<String, dynamic>.from(this.meta!) : null),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditorDocument &&
          runtimeType == other.runtimeType &&
          blocks.length == other.blocks.length &&
          _listsEqual(blocks, other.blocks);

  bool _listsEqual(List<EditorBlock> a, List<EditorBlock> b) {
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => blocks.fold(0, (hash, block) => hash ^ block.hashCode);

  @override
  String toString() {
    return 'EditorDocument{blocks: ${blocks.length}, isEmpty: $isEmpty}';
  }
}

/// 문서 통계 정보
class DocumentStats {
  final int blockCount;
  final int characterCount;
  final int wordCount;
  final Map<EditorBlockType, int> blockTypeCounts;

  const DocumentStats({
    required this.blockCount,
    required this.characterCount,
    required this.wordCount,
    required this.blockTypeCounts,
  });

  /// 읽기 시간 추정 (분)
  double get estimatedReadingTime {
    const double wordsPerMinute = 200.0;
    return wordCount / wordsPerMinute;
  }

  @override
  String toString() {
    return 'DocumentStats{blocks: $blockCount, chars: $characterCount, words: $wordCount, readTime: ${estimatedReadingTime.toStringAsFixed(1)}min}';
  }
}
