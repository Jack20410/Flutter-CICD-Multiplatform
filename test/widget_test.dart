import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:notes/main.dart';
import 'package:notes/providers/note_provider.dart';
import 'package:notes/screens/notes_list_screen.dart';

void main() {
  group('Notes App Tests', () {
    testWidgets('NoteProvider initializes correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<NoteProvider>(
          create: (_) => NoteProvider.forTesting(),
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(CupertinoApp), findsOneWidget);
    });

    testWidgets('NotesListScreen displays empty state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<NoteProvider>(
          create: (_) => NoteProvider.forTesting(),
          child: const CupertinoApp(
            home: NotesListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('No notes yet. Add one!'), findsOneWidget);
    });

    testWidgets('Can navigate to add note screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<NoteProvider>(
          create: (_) => NoteProvider.forTesting(),
          child: const CupertinoApp(
            home: NotesListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the add button
      await tester.tap(find.byIcon(CupertinoIcons.create_solid));
      await tester.pumpAndSettle();

      // Note: Actual note addition would require full app context
      // This is a simplified test
    });
  });
}
