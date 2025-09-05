import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note.dart';

class DBHelper {
  static const String _notesKey = 'notes_list';
  static const String _counterKey = 'note_counter';

  static final DBHelper instance = DBHelper._privateConstructor();
  DBHelper._privateConstructor();

  Future<List<Note>> getAllNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getStringList(_notesKey) ?? [];

    return notesJson.map((noteStr) {
      final noteMap = json.decode(noteStr) as Map<String, dynamic>;
       return Note.fromMap(noteMap, noteMap['id']?.toString() ?? '0');

    }).toList()
      ..sort((a, b) {
        // Sort: pinned first, then by creation date (newest first)
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });
  }

  Future<int> insert(Note note) async {
    final notes = await getAllNotes();
    final prefs = await SharedPreferences.getInstance();

    // Generate new ID
    final counter = prefs.getInt(_counterKey) ?? 0;
    final newId = counter + 1;
    await prefs.setInt(_counterKey, newId);

    final noteWithId = Note(
      id: newId,
      title: note.title,
      content: note.content,
      createdAt: note.createdAt,
      isPinned: note.isPinned,
      imagePaths: note.imagePaths,     // Add this
      audioPaths: note.audioPaths,     // Add this
      tags: note.tags,                 // Add this
      updatedAt: DateTime.now(),       // Add this
    );

    notes.add(noteWithId);
    await _saveNotes(notes);
    return newId;
  }

  Future<int> update(Note note) async {
    final notes = await getAllNotes();
    final index = notes.indexWhere((n) => n.id == note.id);

    if (index != -1) {
      notes[index] = note;
      await _saveNotes(notes);
      return 1;
    }
    return 0;
  }

  Future<int> delete(int id) async {
    final notes = await getAllNotes();
    final initialLength = notes.length;
    notes.removeWhere((note) => note.id == id);

    await _saveNotes(notes);
    return initialLength - notes.length;
  }

  Future<void> _saveNotes(List<Note> notes) async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = notes.map((note) => json.encode(note.toMap())).toList();
    await prefs.setStringList(_notesKey, notesJson);
  }
}
