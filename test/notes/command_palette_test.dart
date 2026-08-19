import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notebook_pro/features/notes/presentation/widgets/command_palette_dialog.dart';

void main() {
  testWidgets('CommandPaletteDialog displays search input and quick commands', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: CommandPaletteDialog(),
          ),
        ),
      ),
    );
    await tester.pump();

    // Verify search text field is present
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('COMMANDS'), findsOneWidget);
    expect(find.text('New Note'), findsOneWidget);
    expect(find.text('Switch Color Theme'), findsOneWidget);
    expect(find.text('Zoom In Editor'), findsOneWidget);

    // Search for a command
    await tester.enterText(find.byType(TextField), 'Zoom');
    await tester.pump();

    expect(find.text('Zoom In Editor'), findsOneWidget);
    expect(find.text('Zoom Out Editor'), findsOneWidget);
    expect(find.text('New Note'), findsNothing);
  });
}
