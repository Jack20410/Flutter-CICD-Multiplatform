import 'package:flutter/cupertino.dart';
import 'dart:convert';
import '../models/todo_item.dart';
import 'todo_widget.dart';

class TodoOverlayManager {
  final VoidCallback onStateChanged;
  final VoidCallback onMetadataChanged;

  List<TodoItem> _todoItems = [];
  Map<String, Offset> _todoPositions = {};
  String? _selectedTodoId;
  Size _containerSize = Size.zero;

  TodoOverlayManager({
    required this.onStateChanged,
    required this.onMetadataChanged,
  });

  void updateContainerSize(Size size) {
    _containerSize = size;
  }

  void addTodo(String content, Offset position, {DateTime? dueDate}) {
    final todoId = 'todo_${DateTime.now().millisecondsSinceEpoch}';
    final todoItem = TodoItem(
      id: todoId,
      content: content,
      dueDate: dueDate,
    );

    _todoItems.add(todoItem);
    _todoPositions[todoId] = position;
    onStateChanged();
    onMetadataChanged();
  }

  void toggleTodo(String todoId) {
    final index = _todoItems.indexWhere((item) => item.id == todoId);
    if (index != -1) {
      _todoItems[index] = _todoItems[index].copyWith(
        isCompleted: !_todoItems[index].isCompleted,
      );
      onStateChanged();
      onMetadataChanged();
    }
  }

  void editTodo(String todoId, String newContent) {
    final index = _todoItems.indexWhere((item) => item.id == todoId);
    if (index != -1) {
      _todoItems[index] = _todoItems[index].copyWith(content: newContent);
      onStateChanged();
      onMetadataChanged();
    }
  }

  void removeTodo(String todoId) {
    _todoItems.removeWhere((item) => item.id == todoId);
    _todoPositions.remove(todoId);
    if (_selectedTodoId == todoId) {
      _selectedTodoId = null;
    }
    onStateChanged();
    onMetadataChanged();
  }

  void selectTodo(String todoId) {
    _selectedTodoId = todoId;
    onStateChanged();
  }

  void deselectAll() {
    if (_selectedTodoId != null) {
      _selectedTodoId = null;
      onStateChanged();
    }
  }

  void moveTodo(String todoId, Offset newPosition) {
    final constrainedPosition = Offset(
      newPosition.dx.clamp(0, _containerSize.width - 250),
      newPosition.dy.clamp(0, _containerSize.height - 100),
    );

    _todoPositions[todoId] = constrainedPosition;
    onStateChanged();
    onMetadataChanged();
  }

  void _loadTodoMetadata(String text) {
    final RegExp metadataRegex = RegExp(r'\[TODO_META:([^\]]+)\]');
    final match = metadataRegex.firstMatch(text);

    if (match != null) {
      try {
        final metadataJson = match.group(1);
        final decodedBytes = base64Decode(metadataJson!);
        final metadataString = utf8.decode(decodedBytes);
        final metadata = jsonDecode(metadataString) as Map<String, dynamic>;

        if (metadata.containsKey('todos')) {
          final todos = metadata['todos'] as List<dynamic>;
          _todoItems =
              todos.map((todoMap) => TodoItem.fromMap(todoMap)).toList();
        }

        if (metadata.containsKey('positions')) {
          final positions = metadata['positions'] as Map<String, dynamic>;
          _todoPositions = {};
          for (final entry in positions.entries) {
            final pos = entry.value as Map<String, dynamic>;
            _todoPositions[entry.key] = Offset(
              pos['x']?.toDouble() ?? 20,
              pos['y']?.toDouble() ?? 20,
            );
          }
        }
        // ignore: empty_catches
      } catch (e) {}
    }
  }

  String saveTodoMetadata(String text) {
    // Remove existing metadata first
    text = text.replaceAll(RegExp(r'\[TODO_META:[^\]]+\]\n?'), '');

    // Don't add metadata if there are no todos
    if (_todoItems.isEmpty) {
      return text;
    }

    final Map<String, dynamic> metadata = {
      'todos': _todoItems.map((item) => item.toMap()).toList(),
      'positions': <String, dynamic>{},
    };

    final positions = metadata['positions'] as Map<String, dynamic>;
    for (final entry in _todoPositions.entries) {
      positions[entry.key] = {
        'x': entry.value.dx,
        'y': entry.value.dy,
      };
    }

    final metadataString = jsonEncode(metadata);
    final encodedMetadata = base64Encode(utf8.encode(metadataString));

    final cleanText = text.trim();
    // Always append metadata with a newline separator
    return cleanText.isEmpty
        ? '[TODO_META:$encodedMetadata]'
        : '$cleanText\n[TODO_META:$encodedMetadata]';
  }

  void initializeFromText(String text) {
    _todoItems.clear();
    _todoPositions.clear();
    _loadTodoMetadata(text);
    onStateChanged();
  }

  List<Widget> buildTodoOverlays(BuildContext context) {
    return _todoItems.map((todoItem) {
      final position = _todoPositions[todoItem.id] ?? const Offset(20, 20);
      final isSelected = _selectedTodoId == todoItem.id;

      return TodoWidget(
        todoItem: todoItem,
        position: position,
        isSelected: isSelected,
        onTap: () => selectTodo(todoItem.id),
        onToggle: toggleTodo,
        onRemove: removeTodo,
        onEdit: editTodo,
        onMove: (newPosition) => moveTodo(todoItem.id, newPosition),
      );
    }).toList();
  }

  void dispose() {
    _todoItems.clear();
    _todoPositions.clear();
  }
}
