// lib/models/deletion_record.dart
class DeletionRecord {
  final int noteId;
  final DateTime deletedAt;

  DeletionRecord({
    required this.noteId,
    required this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'noteId': noteId,
      'deletedAt': deletedAt.millisecondsSinceEpoch,
    };
  }

  factory DeletionRecord.fromMap(Map<String, dynamic> map) {
    return DeletionRecord(
      noteId: map['noteId'],
      deletedAt: DateTime.fromMillisecondsSinceEpoch(map['deletedAt']),
    );
  }
}
