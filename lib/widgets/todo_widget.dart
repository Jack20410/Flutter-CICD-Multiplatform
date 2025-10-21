import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo_item.dart';

class TodoWidget extends StatefulWidget {
  final TodoItem todoItem;
  final Function(String) onToggle;
  final Function(String) onRemove;
  final Function(String, String) onEdit;
  final Offset position;
  final bool isSelected;
  final Function() onTap;
  final Function(Offset) onMove;

  const TodoWidget({
    super.key,
    required this.todoItem,
    required this.onToggle,
    required this.onRemove,
    required this.onEdit,
    required this.position,
    required this.isSelected,
    required this.onTap,
    required this.onMove,
  });

  @override
  State<TodoWidget> createState() => _TodoWidgetState();
}

class _TodoWidgetState extends State<TodoWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isEditing = false;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.todoItem.content);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _handleToggle() {
    if (widget.todoItem.isCompleted) {
      widget.onToggle(widget.todoItem.id);
    } else {
      // Animate completion
      _animationController.forward().then((_) {
        widget.onToggle(widget.todoItem.id);
        // Remove after animation completes
        Future.delayed(const Duration(milliseconds: 500), () {
          widget.onRemove(widget.todoItem.id);
        });
      });
    }
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  void _finishEditing() {
    if (_textController.text.trim().isNotEmpty) {
      widget.onEdit(widget.todoItem.id, _textController.text.trim());
    }
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: GestureDetector(
        onTap: widget.onTap,
        onPanStart: (details) {
          widget.onTap(); // Select when starting to drag
        },
        onPanUpdate: (details) {
          widget.onMove(widget.position + details.delta);
        },
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value == 0 ? 1.0 : _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value == 0
                    ? 1.0
                    : _opacityAnimation.value,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 200,
                    maxWidth: 300,
                  ),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        CupertinoColors.systemBackground.resolveFrom(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: widget.isSelected
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.separator.resolveFrom(context),
                      width: widget.isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.systemGrey.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Checkbox
                      GestureDetector(
                        onTap: _handleToggle,
                        child: Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.only(top: 2, right: 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: widget.todoItem.isCompleted
                                  ? CupertinoColors.systemGreen
                                  : CupertinoColors.systemGrey
                                      .resolveFrom(context),
                              width: 2,
                            ),
                            color: widget.todoItem.isCompleted
                                ? CupertinoColors.systemGreen
                                : Colors.transparent,
                          ),
                          child: widget.todoItem.isCompleted
                              ? const Icon(
                                  CupertinoIcons.checkmark,
                                  size: 12,
                                  color: CupertinoColors.white,
                                )
                              : null,
                        ),
                      ),

                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _isEditing
                                ? CupertinoTextField(
                                    controller: _textController,
                                    autofocus: true,
                                    decoration: const BoxDecoration(),
                                    style: const TextStyle(fontSize: 14),
                                    onSubmitted: (_) => _finishEditing(),
                                    onEditingComplete: _finishEditing,
                                  )
                                : GestureDetector(
                                    onDoubleTap: _startEditing,
                                    child: Text(
                                      widget.todoItem.content,
                                      style: TextStyle(
                                        fontSize: 14,
                                        decoration: widget.todoItem.isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: widget.todoItem.isCompleted
                                            ? CupertinoColors.systemGrey
                                                .resolveFrom(context)
                                            : CupertinoColors.label
                                                .resolveFrom(context),
                                      ),
                                    ),
                                  ),
                            // Due Date Display
                            if (widget.todoItem.dueDate != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    CupertinoIcons.clock,
                                    size: 12,
                                    color: widget.todoItem.isOverdue
                                        ? CupertinoColors.destructiveRed
                                        : widget.todoItem.isCloseToDeadline
                                            ? CupertinoColors.systemOrange
                                            : CupertinoColors.systemGrey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('MMM d, HH:mm')
                                        .format(widget.todoItem.dueDate!),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: widget.todoItem.isOverdue
                                          ? CupertinoColors.destructiveRed
                                          : widget.todoItem.isCloseToDeadline
                                              ? CupertinoColors.systemOrange
                                              : CupertinoColors.systemGrey,
                                      fontWeight: widget.todoItem.isOverdue ||
                                              widget.todoItem.isCloseToDeadline
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  if (widget.todoItem.isOverdue)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 4),
                                      child: Text(
                                        'OVERDUE',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: CupertinoColors.destructiveRed,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Remove button (only show when selected)
                      if (widget.isSelected)
                        GestureDetector(
                          onTap: () => widget.onRemove(widget.todoItem.id),
                          child: Container(
                            width: 20,
                            height: 20,
                            margin: const EdgeInsets.only(left: 4),
                            decoration: const BoxDecoration(
                              color: CupertinoColors.destructiveRed,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.xmark,
                              size: 10,
                              color: CupertinoColors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
