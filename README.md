# Slashdown Editor 📝

[![pub package](https://img.shields.io/pub/v/slashdown_editor.svg)](https://pub.dev/packages/slashdown_editor)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**모바일 최적화**와 **성능 최적화**가 적용된 Flutter 마크다운 에디터 패키지입니다. React 에디터와 100% 호환되며 백엔드 API와 완벽하게 연동됩니다.

## ✨ 주요 특징

### 📱 모바일 최적화
- **터치 친화적 인터페이스**: iOS/Android HIG 기준 44pt 이상의 터치 영역
- **적응형 UI**: 화면 크기에 따른 반응형 디자인
- **햅틱 피드백**: 자연스러운 상호작용 경험
- **키보드 최적화**: 모바일 키보드와의 완벽한 호환

### ⚡ 성능 최적화
- **디바운싱 & 쓰로틀링**: 과도한 호출 방지
- **렌더링 캐시**: 불필요한 재렌더링 최소화
- **메모리 최적화**: WeakReference 기반 캐시 시스템
- **지연 로딩**: 필요한 시점에만 렌더링

### 🎯 슬래시 명령어 시스템
- **직관적인 블록 추가**: `/` 입력으로 블록 메뉴 표시
- **키보드 네비게이션**: 화살표 키로 블록 선택
- **검색 기능**: 블록 타입 필터링

### 🔗 백엔드 호환성
- **JSON 직렬화/역직렬화**: 표준 API 형식 지원
- **React 에디터 호환**: 기존 웹 에디터와 완벽 호환
- **실시간 동기화**: 문서 변경사항 실시간 감지

## 📦 설치

```yaml
dependencies:
  slashdown_editor: ^0.1.0
```

## 🚀 빠른 시작

### 기본 사용법

```dart
import 'package:slashdown_editor/slashdown_editor.dart';

SlashdownEditor(
  initialText: '# 환영합니다!\n\n마크다운으로 문서를 작성해보세요.',
  onChanged: (text) {
    print('텍스트 변경: $text');
  },
  onDocumentChanged: (document) {
    // 백엔드에 저장
    final json = document.toJson();
    // API 호출: POST /api/documents
  },
)
```

### 커스터마이징

```dart
SlashdownEditor(
  config: SlashdownEditorConfig(
    // 모바일 최적화
    enableHapticFeedback: true,
    adaptiveUI: true,
    minTouchTargetSize: 44.0,
    
    // 성능 최적화
    enablePerformanceMonitoring: false, // 프로덕션에서는 false
    debounceDelay: Duration(milliseconds: 300),
    lazyRendering: true,
    
    // UI 커스터마이징
    backgroundColor: Colors.white,
    borderColor: Colors.grey[300]!,
    textStyle: TextStyle(fontSize: 16, height: 1.5),
    
    // 기능 설정
    enableSlashCommand: true,
    enablePreview: true,
    availableBlocks: [
      EditorBlockType.paragraph,
      EditorBlockType.heading1,
      EditorBlockType.heading2,
      EditorBlockType.bulleted,
      EditorBlockType.todo,
      EditorBlockType.code,
    ],
  ),
)
```

## 📋 지원되는 블록 타입

| 블록 타입 | 마크다운 | 설명 |
|----------|----------|------|
| Paragraph | `텍스트` | 일반 문단 |
| Heading 1 | `# 제목` | 대제목 |
| Heading 2 | `## 제목` | 중제목 |
| Heading 3 | `### 제목` | 소제목 |
| Bulleted List | `- 항목` | 불릿 리스트 |
| Numbered List | `1. 항목` | 번호 리스트 |
| Todo List | `- [ ] 할일` | 체크박스 리스트 |
| Blockquote | `> 인용문` | 인용구 |
| Code Block | ```` ```dart ` | 코드 블록 |
| Callout | `> 📝 정보` | 강조 박스 |
| Divider | `---` | 구분선 |
| Image | `![](url)` | 이미지 |
| Link | `[텍스트](url)` | 링크 |

## 🎨 테마 지원

### 다크 테마
```dart
SlashdownEditor(
  config: SlashdownEditorConfig().darkTheme(),
)
```

### 고대비 테마 (접근성)
```dart
SlashdownEditor(
  config: SlashdownEditorConfig().highContrastTheme(),
)
```

## 📊 성능 모니터링

개발 모드에서 성능 통계를 확인할 수 있습니다:

```dart
SlashdownEditor(
  config: SlashdownEditorConfig(
    enablePerformanceMonitoring: true, // 개발 모드에서만
  ),
)

// 성능 리포트 출력
PerformanceUtils.printReport();
```

## 🔄 백엔드 연동

### JSON 직렬화
```dart
// 문서를 JSON으로 변환
final json = document.toJson();
await apiService.saveDocument(json);

// JSON에서 문서 복원
final document = EditorDocument.fromJson(jsonData);
```

### API 예시
```dart
class DocumentService {
  Future<void> saveDocument(EditorDocument document) async {
    final response = await http.post(
      Uri.parse('/api/documents'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(document.toJson()),
    );
  }
  
  Future<EditorDocument> loadDocument(String id) async {
    final response = await http.get(Uri.parse('/api/documents/$id'));
    final json = jsonDecode(response.body);
    return EditorDocument.fromJson(json);
  }
}
```

## 🎯 사용 예시

### 블로그 에디터
```dart
class BlogEditor extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SlashdownEditor(
        config: SlashdownEditorConfig(
          hintText: '블로그 포스트를 작성해보세요...',
          availableBlocks: [
            EditorBlockType.heading1,
            EditorBlockType.heading2,
            EditorBlockType.paragraph,
            EditorBlockType.image,
            EditorBlockType.code,
          ],
        ),
        onDocumentChanged: (document) {
          // 자동 저장
          BlogService.autosave(document);
        },
      ),
    );
  }
}
```

### 메모 앱
```dart
class MemoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SlashdownEditor(
      config: SlashdownEditorConfig(
        adaptiveUI: true,
        enableHapticFeedback: true,
        availableBlocks: [
          EditorBlockType.paragraph,
          EditorBlockType.todo,
          EditorBlockType.bulleted,
        ],
      ),
    );
  }
}
```

## 🔧 고급 설정

### 커스텀 블록 타입 필터링
```dart
SlashdownEditor(
  config: SlashdownEditorConfig(
    availableBlocks: widget.userLevel == UserLevel.basic
        ? [EditorBlockType.paragraph, EditorBlockType.heading1]
        : EditorBlockType.values,
  ),
)
```

### 접근성 설정
```dart
SlashdownEditor(
  config: SlashdownEditorConfig(
    enableAccessibility: true,
    semanticLabel: '문서 에디터',
    semanticHint: '마크다운 형식으로 문서를 작성할 수 있습니다',
    minimumFontSize: 14.0,
    maximumFontSize: 24.0,
  ),
)
```

## 📱 플랫폼 지원

- ✅ **iOS**: 완전 지원 (햅틱 피드백 포함)
- ✅ **Android**: 완전 지원
- ✅ **Web**: 기본 지원
- ✅ **Desktop**: 기본 지원 (Windows, macOS, Linux)

## 🤝 기여하기

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 라이센스

이 프로젝트는 MIT 라이센스 하에 배포됩니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 🆘 지원

- 📚 [문서](https://github.com/your-username/slashdown_editor/wiki)
- 🐛 [이슈 리포트](https://github.com/your-username/slashdown_editor/issues)
- 💬 [토론](https://github.com/your-username/slashdown_editor/discussions)

## 🙏 감사인사

- Flutter 팀의 훌륭한 프레임워크
- 오픈소스 커뮤니티의 지원
- 모든 기여자들

---

**Made with ❤️ for Flutter developers**
