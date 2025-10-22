import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:notes/main.dart';
import 'package:notes/providers/note_provider.dart';
import 'package:notes/providers/theme_provider.dart';
import 'package:notes/screens/notes_list_screen.dart';

void main() {
  group('Notes App Tests', () {
    testWidgets('App should launch without crashing',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>(
              create: (_) => ThemeProvider(),
            ),
            ChangeNotifierProvider<NoteProvider>(
              create: (_) => NoteProvider.forTesting(),
            ),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(CupertinoApp), findsOneWidget);
    });

    testWidgets('NotesListScreen displays empty state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>(
              create: (_) => ThemeProvider(),
            ),
            ChangeNotifierProvider<NoteProvider>(
              create: (_) => NoteProvider.forTesting(),
            ),
          ],
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
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>(
              create: (_) => ThemeProvider(),
            ),
            ChangeNotifierProvider<NoteProvider>(
              create: (_) => NoteProvider.forTesting(),
            ),
          ],
          child: const CupertinoApp(
            home: NotesListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the add button
      await tester.tap(find.byIcon(CupertinoIcons.create_solid));
      await tester.pumpAndSettle();

      // Should navigate to edit screen
      expect(find.text('New Note'), findsOneWidget);
    });

    testWidgets('Theme toggle button should be present',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>(
              create: (_) => ThemeProvider(),
            ),
            ChangeNotifierProvider<NoteProvider>(
              create: (_) => NoteProvider.forTesting(),
            ),
          ],
          child: const CupertinoApp(
            home: NotesListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should find theme toggle button in navigation bar
      expect(find.byType(CupertinoButton), findsWidgets);
    });
  });
}
