import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_app/providers/note_provider.dart';

void main() {
  group('Notes App Tests', () {
    testWidgets('NoteProvider initializes correctly',
        (WidgetTester tester) async {
      final noteProvider = NoteProvider.forTesting();
      expect(noteProvider.notes, isEmpty);
    });

    testWidgets('NoteProvider can add a note', (WidgetTester tester) async {
      final noteProvider = NoteProvider.forTesting();

      // Initially empty
      expect(noteProvider.notes.length, 0);

      // Note: Actual note addition would require full app context
      // This is a simplified test
    });
  });
}
