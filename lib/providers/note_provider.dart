// lib/providers/note_provider.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';
import '../helpers/db_helper.dart';
import '../services/semantic_search_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/auth_service.dart';
import '../models/deletion_record.dart';
enum SyncStatus { upToDate, unsaved, checking, syncing }
class NoteProvider with ChangeNotifier {
  List<Note> _notes = [];
  List<Note> _filteredNotes = []; // Add this for search results
  final dynamic _dbHelper;
  final Map<String, bool> _expandedSections = {};
  String _searchQuery = '';

  // Fix: Use _filteredNotes when searching, _notes when not
  List<Note> get notes => _searchQuery.isEmpty ? _notes : _filteredNotes;

  // Fix: Add _allNotes getter that semantic search needs
  List<Note> get _allNotes => _notes;

  String get searchQuery => _searchQuery;
  Map<String, bool> get expandedSections => _expandedSections;

  final SemanticSearchService _semanticSearch = SemanticSearchService();
  final bool _useSemanticSearch = true;
  bool _indexBuilt = false;

  bool get isUsingSemanticSearch => _useSemanticSearch && _indexBuilt;
  SyncStatus _syncStatus = SyncStatus.unsaved;
  DateTime? _lastSyncTime;

  SyncStatus get syncStatus => _syncStatus;
  DateTime? get lastSyncTime => _lastSyncTime;

  void setSyncStatus(SyncStatus status) {
    _syncStatus = status;
    notifyListeners();
  }
  Future<void> _buildSearchIndex() async {
    if (_allNotes.isEmpty) return;

    try {
      await _semanticSearch.indexNotes(_allNotes);
      _indexBuilt = true;
    } catch (e) {
      _indexBuilt = false;
    }
  }
  Future<void> checkSyncStatus(AuthService authService) async {
  setSyncStatus(SyncStatus.checking);
  
  try {
    if (!authService.isAuthenticated) {
      setSyncStatus(SyncStatus.unsaved);
      return;
    }
    
    final cloudSync = CloudSyncService(userId: authService.userId!);
    final remoteNotes = await cloudSync.fetchRemoteNotes();
    
    // Compare local and remote notes
    final localNotesIds = _notes.map((n) => n.id).toSet();
    final remoteNotesIds = remoteNotes.map((n) => n.id).toSet();
    
    if (localNotesIds.length == remoteNotesIds.length && 
        localNotesIds.difference(remoteNotesIds).isEmpty) {
      setSyncStatus(SyncStatus.upToDate);
      _lastSyncTime = DateTime.now();
    } else {
      setSyncStatus(SyncStatus.unsaved);
    }
  } catch (e) {
    setSyncStatus(SyncStatus.unsaved);
  }
}
  // Regular constructor
  NoteProvider() : _dbHelper = DBHelper.instance {
    fetchNotes();
  }

  // Test constructor
  NoteProvider.forTesting() : _dbHelper = _MockDBHelper() {
    _notes = [];
  }

  Future<void> fetchNotes() async {
    if (_dbHelper != null) {
      _notes = await _dbHelper.getAllNotes();
      notifyListeners();

      // Build search index after loading notes
      if (_notes.isNotEmpty && !_indexBuilt) {
        _buildSearchIndex();
      }
    }
  }

  // Fix: Replace the basic search with semantic search
  Future<void> searchNotes(String query) async {
    _searchQuery = query;

    if (query.isEmpty) {
      _filteredNotes = [];
      notifyListeners();
      return;
    }

    // Try semantic search first
    if (_useSemanticSearch) {
      try {
        if (!_indexBuilt) {
          await _buildSearchIndex();
        }

        if (_indexBuilt) {
          final results = await _semanticSearch.search(query, _allNotes);
          if (results.isNotEmpty) {
            _filteredNotes = results.map((r) => r.note).toList();
            notifyListeners();
            return;
          }
        }
        // ignore: empty_catches
      } catch (e) {}
    }

    // Fallback to basic search
    _performBasicSearch(query);
    notifyListeners();
  }

  void _performBasicSearch(String query) {
    final lowerQuery = query.toLowerCase();
    _filteredNotes = _notes.where((note) {
      final titleMatch = note.title.toLowerCase().contains(lowerQuery);
      final contentMatch = note.content.toLowerCase().contains(lowerQuery);
      final dateMatch = DateFormat.yMMMd()
          .format(note.createdAt)
          .toLowerCase()
          .contains(lowerQuery);
      final tagsMatch = note.tags.any((tag) =>
          tag.toLowerCase().contains(lowerQuery) ||
          '#${tag.toLowerCase()}'.contains(lowerQuery));
      return titleMatch || contentMatch || dateMatch || tagsMatch;
    }).toList();
  }

  void clearSearch() {
    _searchQuery = '';
    _filteredNotes = [];
    notifyListeners();
  }
  // In NoteProvider class
  Future<List<DeletionRecord>> getAllDeletions() async {
    if (_dbHelper != null) {
      return await _dbHelper.getAllDeletions();
    }
    return [];
  }
  Future<void> addNote(String title, String content) async {
    Note newNote = Note(
      title: title,
      content: content,
      createdAt: DateTime.now(),
      isPinned: false,
    );

    if (_dbHelper != null) {
      await _dbHelper.insert(newNote);
      await fetchNotes();
    } else {
      _notes.add(newNote);
      notifyListeners();
    }

    // Fix: Rebuild search index after adding note
    _indexBuilt = false;
    setSyncStatus(SyncStatus.unsaved);
  }

  Future<void> updateNote(Note note) async {
    if (_dbHelper != null) {
      await _dbHelper.update(note);
      await fetchNotes();
    } else {
      int index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = note;
        notifyListeners();
      }
      setSyncStatus(SyncStatus.unsaved);
    }

    // Fix: Rebuild search index after updating note
    _indexBuilt = false;
  }

  // In lib/providers/note_provider.dart
  Future<void> deleteNote(int id) async {
    if (_dbHelper != null) {
      await _dbHelper.delete(id); // This now records deletion automatically
      await fetchNotes();
    } else {
      _notes.removeWhere((note) => note.id == id);
      notifyListeners();
    }

    _indexBuilt = false;
    setSyncStatus(SyncStatus.unsaved);
  }

  Future<void> addNoteWithMedia(Note note) async {
    if (_dbHelper != null) {
      await _dbHelper.insert(note);
      await fetchNotes();
    } else {
      _notes.add(note);
      notifyListeners();
    }

    // Fix: Rebuild search index after adding note with media
    _indexBuilt = false;
  }
  
  Future<void> togglePinNote(Note note) async {
    Note updatedNote = Note(
      id: note.id,
      title: note.title,
      content: note.content,
      createdAt: note.createdAt,
      isPinned: !note.isPinned,
      imagePaths: note.imagePaths,
      audioPaths: note.audioPaths,
      tags: note.tags,
    );
    await updateNote(updatedNote);
  }

  Map<String, List<Note>> get groupedNotes {
    Map<String, List<Note>> grouped = {};
    List<Note> pinnedNotes = [];
    List<Note> unpinnedNotes = [];

    // Use the correct notes list (filtered when searching, all when not)
    final notesToGroup = _searchQuery.isEmpty ? _notes : _filteredNotes;

    for (Note note in notesToGroup) {
      if (note.isPinned) {
        pinnedNotes.add(note);
      } else {
        unpinnedNotes.add(note);
      }
    }

    if (pinnedNotes.isNotEmpty) {
      grouped['PINNED'] = pinnedNotes;
      if (!_expandedSections.containsKey('PINNED')) {
        _expandedSections['PINNED'] = true;
      }
      pinnedNotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    for (Note note in unpinnedNotes) {
      String monthKey =
          DateFormat('MMM yyyy').format(note.createdAt).toUpperCase();
      if (!grouped.containsKey(monthKey)) {
        grouped[monthKey] = [];
        if (!_expandedSections.containsKey(monthKey)) {
          _expandedSections[monthKey] = true;
        }
      }
      grouped[monthKey]!.add(note);
    }

    grouped.forEach((key, notes) {
      if (key != 'PINNED') {
        notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    });

    return grouped;
  }

  void toggleSection(String monthKey) {
    _expandedSections[monthKey] = !(_expandedSections[monthKey] ?? true);
    notifyListeners();
  }
  
  bool isSectionExpanded(String monthKey) {
    return _expandedSections[monthKey] ?? true;
  }
}

class _MockDBHelper {
  Future<List<Note>> getAllNotes() async => [];
  Future<int> insert(Note note) async => 1;
  Future<int> update(Note note) async => 1;
  Future<int> delete(int id) async => 1;
}
