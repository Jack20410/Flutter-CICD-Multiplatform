import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:note_app/main.dart';
import 'package:note_app/providers/note_provider.dart';
import 'package:note_app/services/auth_service.dart';
import 'package:note_app/screens/notes_list_screen.dart';

void main() {
  group('Notes App Tests', () {
    testWidgets('App should launch without crashing',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
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
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => NoteProvider.forTesting()),
            ChangeNotifierProvider(create: (_) => AuthService()),
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
            ChangeNotifierProvider(create: (_) => NoteProvider.forTesting()),
            ChangeNotifierProvider(create: (_) => AuthService()),
          ],
          child: const CupertinoApp(
            home: NotesListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the add button
      await tester.tap(find.byIcon(CupertinoIcons.add), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Should navigate to edit screen
      expect(find.text('New Note'), findsOneWidget);
    });
  });
}
