class Note {
  final int? id;
  final String title;
  final String content;
  final DateTime createdAt;
  final bool isPinned;
  final List<String> imagePaths;
  final List<String> audioPaths;
  final List<String> tags; // Add this field
  final DateTime? updatedAt;

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.isPinned = false,
    this.imagePaths = const [],
    this.audioPaths = const [],
    this.tags = const [], // Add this parameter
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'isPinned': isPinned,
      'imagePaths': imagePaths,
      'audioPaths': audioPaths,
      'tags': tags,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map, [String? id]) {
    return Note(
      id: map['id'] ?? (id != null ? int.tryParse(id) : null),
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      createdAt: map['createdAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] is int
              ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
              : DateTime.parse(map['updatedAt']))
          : null,
      isPinned: map['isPinned'] is bool
          ? map['isPinned']
          : (map['isPinned'] ?? 0) == 1,
      imagePaths:
          map['imagePaths'] is List ? List<String>.from(map['imagePaths']) : [],
      audioPaths:
          map['audioPaths'] is List ? List<String>.from(map['audioPaths']) : [],
      tags: map['tags'] is List ? List<String>.from(map['tags']) : [],
    );
  }
}
