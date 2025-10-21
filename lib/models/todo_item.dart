class TodoItem {
  final String id;
  final String content;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? dueDate;

  TodoItem({
    required this.id,
    required this.content,
    this.isCompleted = false,
    DateTime? createdAt,
    this.dueDate,
  }) : createdAt = createdAt ?? DateTime.now();

  TodoItem copyWith({
    String? id,
    String? content,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? dueDate,
  }) {
    return TodoItem(
      id: id ?? this.id,
      content: content ?? this.content,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
    };
  }

  static TodoItem fromMap(Map<String, dynamic> map) {
    return TodoItem(
      id: map['id'],
      content: map['content'],
      isCompleted: map['isCompleted'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
    );
  }

  // Helper method to check if the todo is overdue
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  // Helper method to check if the todo is close to deadline (within 1 day)
  bool get isCloseToDeadline {
    if (dueDate == null || isCompleted) return false;
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    return !isOverdue && dueDate!.isBefore(tomorrow);
  }
}
