import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

class TodoCreationDialog extends StatefulWidget {
  final Function(String, DateTime?) onCreateTodo;

  const TodoCreationDialog({
    super.key,
    required this.onCreateTodo,
  });

  @override
  State<TodoCreationDialog> createState() => _TodoCreationDialogState();
}

class _TodoCreationDialogState extends State<TodoCreationDialog> {
  final TextEditingController _controller = TextEditingController();
  DateTime? _selectedDueDate;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _createTodo() {
    final content = _controller.text.trim();
    if (content.isNotEmpty) {
      widget.onCreateTodo(content, _selectedDueDate);
      Navigator.of(context).pop();
    }
  }

  void _showDatePicker() {
    final now = DateTime.now();
    final initialDate = _selectedDueDate ?? now;

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        DateTime tempPickedDate = initialDate;
        return Container(
          height: 250,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator.resolveFrom(context),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    CupertinoButton(
                      onPressed: () {
                        setState(() {
                          _selectedDueDate = tempPickedDate;
                        });
                        Navigator.of(context).pop();
                      },
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.dateAndTime,
                  initialDateTime: initialDate,
                  minimumDate: now,
                  onDateTimeChanged: (DateTime newDate) {
                    tempPickedDate = newDate;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Text(
          'Create To-Do Item',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      content: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(
          minHeight: 120,
          maxHeight: 250,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(
                minHeight: 80,
              ),
              child: CupertinoTextField(
                controller: _controller,
                placeholder: 'Enter your to-do item...',
                placeholderStyle: TextStyle(
                  color: CupertinoColors.placeholderText.resolveFrom(context),
                  fontSize: 16,
                ),
                autofocus: true,
                maxLines: 4,
                minLines: 3,
                style: const TextStyle(fontSize: 16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6.resolveFrom(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: CupertinoColors.separator.resolveFrom(context),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(12),
                onSubmitted: (_) => _createTodo(),
              ),
            ),
            const SizedBox(height: 12),
            // Due Date Button
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              onPressed: _showDatePicker,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.calendar,
                    size: 18,
                    color: CupertinoColors.activeBlue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedDueDate == null
                        ? 'Add Due Date (Optional)'
                        : 'Due: ${DateFormat('MMM d, y HH:mm').format(_selectedDueDate!)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.activeBlue,
                    ),
                  ),
                  if (_selectedDueDate != null) ...[
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDueDate = null;
                        });
                      },
                      child: const Icon(
                        CupertinoIcons.xmark_circle_fill,
                        size: 16,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tip: Double-tap on text to create more to-do items',
              style: TextStyle(
                fontSize: 12,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text(
            'Cancel',
            style: TextStyle(
              fontSize: 17,
              color: CupertinoColors.destructiveRed,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: _createTodo,
          child: const Text(
            'Create',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
