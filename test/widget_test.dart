import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab10/crud_page.dart';

void main() {
  testWidgets('CrudPage renders correctly', (WidgetTester tester) async {
    // Build the CrudPage widget inside a MaterialApp
    await tester.pumpWidget(
      MaterialApp(
        home: CrudPage(type: 'task'),
      ),
    );

    // Verify AppBar title
    expect(find.text('Task Management'), findsOneWidget);

    // Verify Add button exists
    expect(find.text('Add Task'), findsOneWidget);

    // Verify TextField exists
    expect(find.byType(TextField), findsOneWidget);
  });
}