// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:slashdown_editor/slashdown_editor.dart';

void main() {
  testWidgets('SlashdownEditor smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SlashdownEditor(
          initialText: 'Test content',
          config: SlashdownEditorConfig(
            enableSpellCheck: false,
          ),
        ),
      ),
    ));

    // Verify that the editor is rendered
    expect(find.byType(SlashdownEditor), findsOneWidget);

    // Verify that the initial text is displayed
    expect(find.text('Test content'), findsOneWidget);
  });
}
