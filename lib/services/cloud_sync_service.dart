// lib/services/cloud_sync_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note.dart';

class CloudSyncService {
  final String userId;
  final String? userEmail;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  CloudSyncService({required this.userId, this.userEmail});
  
  Future<List<Note>> fetchRemoteNotes() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Note.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch remote notes: $e');
    }
  }
  
  Future<void> uploadNote(Note note) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(note.id.toString())
          .set(note.toMap());
    } catch (e) {
      throw Exception('Failed to upload note: $e');
    }
  }
}