import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab10/crud_page.dart';

void main() {
  testWidgets('CrudPage renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CrudPage(
          type: 'task',
          disableFirebase: true, // ✅ CRITICAL
        ),
      ),
    );

    // AppBar title
    expect(find.text('Task Management'), findsOneWidget);

    // Add button text
    expect(find.text('Add Task'), findsOneWidget);

    // Task TextField
    expect(find.byType(TextField), findsOneWidget);
  });
}
