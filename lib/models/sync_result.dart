import '../models/note.dart';

class SyncResult {
  final int uploadedCount;
  final int downloadedCount;
  final int updatedCount;
  final int conflictsResolved;
  final List<Note> notesToUpdate;
  
  SyncResult({
    required this.uploadedCount,
    required this.downloadedCount,
    required this.updatedCount,
    required this.conflictsResolved,
    required this.notesToUpdate,
  });
}