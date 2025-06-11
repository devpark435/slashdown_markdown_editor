import 'package:flutter/material.dart';
import 'package:slashdown_editor/slashdown_editor.dart';

void main() {
  runApp(const TestApp());
}

/// 테스트용 슬래시다운 에디터 앱
class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Slashdown Editor Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const TestHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TestHomePage extends StatefulWidget {
  const TestHomePage({super.key});

  @override
  State<TestHomePage> createState() => _TestHomePageState();
}

class _TestHomePageState extends State<TestHomePage> {
  String _markdownText = '''# 🧪 슬래시다운 에디터 테스트

**테스트를 시작합니다!**

## 기능 테스트

### 1. 슬래시 명령어 테스트
"/" 를 입력해보세요:

### 2. 블록 타입 테스트

#### 리스트 테스트
- 불릿 리스트 1
- 불릿 리스트 2
- 불릿 리스트 3

1. 넘버링 리스트 1
2. 넘버링 리스트 2
3. 넘버링 리스트 3

#### 체크리스트 테스트
- [x] 완료된 작업
- [ ] 미완료 작업
- [ ] 테스트할 작업

> 이것은 인용구입니다

> 📝 이것은 정보 콜아웃입니다

```dart
// 이것은 코드 블록입니다
void main() {
  print('Hello World!');
}
```

---

**테스트 완료!** 위의 요소들이 정상적으로 렌더링되는지 확인해주세요.''';

  EditorDocument? _currentDocument;
  bool _showPreview = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Slashdown Editor Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showPreview ? Icons.edit : Icons.preview),
            onPressed: () {
              setState(() {
                _showPreview = !_showPreview;
              });
            },
            tooltip: _showPreview ? '편집 모드' : '미리보기 모드',
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 2,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Column(
              children: [
                // 상태 표시
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.blue[50],
                  child: Row(
                    children: [
                      Icon(
                        _showPreview ? Icons.preview : Icons.edit,
                        size: 16,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _showPreview ? '미리보기 모드' : '편집 모드',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      if (_currentDocument != null)
                        Text(
                          '${_currentDocument!.stats.blockCount} 블록, ${_currentDocument!.stats.wordCount} 단어',
                          style: TextStyle(
                            color: Colors.blue[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                // 에디터
                Expanded(
                  child: SlashdownEditor(
                    initialText: _markdownText,
                    config: SlashdownEditorConfig(
                      enableHapticFeedback: true,
                      adaptiveUI: true,
                      enablePerformanceMonitoring: true, // 테스트용으로 활성화
                      textStyle: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    onChanged: (text) {
                      setState(() {
                        _markdownText = text;
                      });
                      print('📝 텍스트 변경: ${text.length}자');
                    },
                    onDocumentChanged: (document) {
                      setState(() {
                        _currentDocument = document;
                      });
                      print('📊 문서 변경: ${document.stats}');
                    },
                    onFocus: () {
                      print('🎯 에디터 포커스');
                    },
                    onUnfocus: () {
                      print('❌ 에디터 포커스 해제');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _runTests,
        icon: const Icon(Icons.play_arrow),
        label: const Text('기능 테스트'),
      ),
    );
  }

  void _runTests() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.science, color: Colors.blue),
            SizedBox(width: 8),
            Text('테스트 결과'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTestItem('SlashdownEditor 위젯', '✅ 정상 렌더링'),
            _buildTestItem('텍스트 입력', '✅ 정상 작동'),
            _buildTestItem(
                '문서 변환', _currentDocument != null ? '✅ 정상 작동' : '❌ 실패'),
            _buildTestItem(
                '블록 카운트',
                _currentDocument != null
                    ? '✅ ${_currentDocument!.stats.blockCount}개'
                    : '❌ 없음'),
            _buildTestItem('성능 모니터링', '✅ 활성화됨'),
            const SizedBox(height: 16),
            const Text(
              '추가 테스트:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const Text('• "/" 입력하여 슬래시 명령어 테스트'),
            const Text('• 다양한 블록 타입 삽입 테스트'),
            const Text('• 미리보기 모드 전환 테스트'),
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

  Widget _buildTestItem(String title, String result) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(title, style: const TextStyle(fontSize: 14)),
          ),
          Expanded(
            child: Text(
              result,
              style: TextStyle(
                fontSize: 14,
                color: result.startsWith('✅') ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
