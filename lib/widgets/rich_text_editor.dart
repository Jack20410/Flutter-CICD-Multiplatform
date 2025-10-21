// lib/widgets/rich_text_editor.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'image_overlay_manager.dart';
import 'audio_overlay_manager.dart'; // Add this import
import 'highlighted_text.dart';
import 'todo_overlay_manager.dart';
import 'todo_creation_dialog.dart';

mixin ImageMetadataProvider {
  String saveImageMetadata(String text);
}

mixin AudioMetadataProvider {
  String saveAudioMetadata(String text);
}
mixin TodoMetadataProvider {
  String saveTodoMetadata(String text);
}

class RichTextEditor extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String searchQuery;
  final Function(String) onImageRemove;
  final Function(String) onAudioRemove; // Add this parameter

  const RichTextEditor({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.searchQuery,
    required this.onImageRemove,
    required this.onAudioRemove, // Add this parameter
  });

  @override
  State<RichTextEditor> createState() => _RichTextEditorState();
  // ignore: library_private_types_in_public_api
  static _RichTextEditorState? of(BuildContext context) {
    return context.findAncestorStateOfType<_RichTextEditorState>();
  }
}

class _RichTextEditorState extends State<RichTextEditor>
    with ImageMetadataProvider, AudioMetadataProvider, TodoMetadataProvider {
  final ScrollController _scrollController = ScrollController();
  late TextEditingController _displayController;
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final FocusNode _contentFocusNode = FocusNode();
  String _lastControllerText = '';
  late ImageOverlayManager _imageManager;
  late AudioOverlayManager _audioManager; // Add this
  late TodoOverlayManager _todoManager;
  bool _isUpdatingFromController = false;
  @override
  void initState() {
    super.initState();
    _lastControllerText = widget.controller.text;

    // Initialize display controller with clean text
    final cleanText = widget.controller.text
        .replaceAll(RegExp(r'\[IMAGE:[^\]]+\]\n?'), '')
        .replaceAll(RegExp(r'\[IMAGE_META:[^\]]+\]\n?'), '')
        .replaceAll(RegExp(r'\[AUDIO:[^\]]+\]\n?'), '')
        .replaceAll(RegExp(r'\[AUDIO_META:[^\]]+\]\n?'), '')
        .replaceAll(RegExp(r'\[TODO_META:[^\]]+\]\n?'), '')
        .trim();

    _displayController = TextEditingController(text: cleanText);

    // Initialize title and content controllers
    final lines = cleanText.split('\n');
    _titleController =
        TextEditingController(text: lines.isNotEmpty ? lines[0] : '');
    _contentController = TextEditingController(
        text: lines.length > 1 ? lines.sublist(1).join('\n') : '');

    _imageManager = ImageOverlayManager(
      onImageRemove: widget.onImageRemove,
      onStateChanged: () => setState(() {}),
      onMetadataChanged: _saveMetadataToController,
    );

    _audioManager = AudioOverlayManager(
      onAudioRemove: widget.onAudioRemove,
      onStateChanged: () => setState(() {}),
      onMetadataChanged: _saveMetadataToController,
    );

    _todoManager = TodoOverlayManager(
      onStateChanged: () => setState(() {}),
      onMetadataChanged: _saveMetadataToController,
    );

    // Initialize managers with text
    _imageManager.initializeFromText(widget.controller.text);
    _audioManager.initializeFromText(widget.controller.text);
    _todoManager.initializeFromText(widget.controller.text);

    // Add listener last to avoid triggering during initialization
    widget.controller.addListener(_onControllerChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    _displayController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _contentFocusNode.dispose();
    _scrollController.dispose();
    _imageManager.dispose();
    _audioManager.dispose();
    _todoManager.dispose();
    super.dispose();
  }

  void _saveMetadataToController() {
    final currentText = widget.controller.text;
    String updatedText = _imageManager.saveImageMetadata(currentText);
    updatedText = _audioManager
        .saveAudioMetadata(updatedText); // Make sure this is called
    updatedText = _todoManager.saveTodoMetadata(updatedText);
    if (currentText != updatedText) {
      widget.controller.removeListener(_onControllerChange);
      widget.controller.text = updatedText;
      _lastControllerText = updatedText;
      widget.controller.addListener(_onControllerChange);
    }
  }

  void _onControllerChange() {
    if (widget.controller.text != _lastControllerText) {
      _updateDisplayController();
      _imageManager.initializeFromText(widget.controller.text);
      _audioManager.initializeFromText(widget.controller.text);
      _todoManager.initializeFromText(widget.controller.text);
      _lastControllerText = widget.controller.text;
    }
  }

  void _updateDisplayController() {
    if (_isUpdatingFromController) return;

    final cleanText = widget.controller.text
        .replaceAll(RegExp(r'\[IMAGE:[^\]]+\]\n?'), '')
        .replaceAll(RegExp(r'\[IMAGE_META:[^\]]+\]\n?'), '')
        .replaceAll(RegExp(r'\[AUDIO:[^\]]+\]\n?'), '')
        .replaceAll(RegExp(r'\[AUDIO_META:[^\]]+\]\n?'), '')
        .replaceAll(RegExp(r'\[TODO_META:[^\]]+\]\n?'), '')
        .trim();

    if (_displayController.text != cleanText) {
      _isUpdatingFromController = true;
      _displayController.text = cleanText;

      // Split and update title/content controllers
      final lines = cleanText.split('\n');
      if (lines.isNotEmpty) {
        _titleController.text = lines[0];
        _contentController.text =
            lines.length > 1 ? lines.sublist(1).join('\n') : '';
      }
      _isUpdatingFromController = false;
    }
  }

  void _onDisplayTextChanged(String value) {
    if (_isUpdatingFromController) return;

    final RegExp imageRegex = RegExp(r'\[IMAGE:([^\]]+)\]');
    final RegExp audioRegex = RegExp(r'\[AUDIO:([^\]]+)\]');
    final RegExp todoMetaRegex = RegExp(r'\[TODO_META:[^\]]+\]');

    final existingImages = imageRegex
        .allMatches(widget.controller.text)
        .map((match) => match.group(0)!)
        .toList();

    final existingAudios = audioRegex
        .allMatches(widget.controller.text)
        .map((match) => match.group(0)!)
        .toList();

    final existingTodoMeta = todoMetaRegex
        .allMatches(widget.controller.text)
        .map((match) => match.group(0)!)
        .toList();

    String newText = value;
    for (String imageTag in existingImages) {
      newText += '\n$imageTag';
    }
    for (String audioTag in existingAudios) {
      newText += '\n$audioTag';
    }
    for (String todoMeta in existingTodoMeta) {
      newText += '\n$todoMeta';
    }

    _lastControllerText = newText;
    _isUpdatingFromController = true;
    widget.controller.text = newText;
    _displayController.text = value;
    _isUpdatingFromController = false;

    // Don't update title/content controllers here as they triggered this change
    // Updating them here causes cursor jumping and only allows 1 character to be typed
  }

  void _handleTapOutside() {
    _imageManager.deselectAll();
    _audioManager.deselectAll(); // Add this
    _todoManager.deselectAll();
  }

  @override
  String saveTodoMetadata(String text) {
    return _todoManager.saveTodoMetadata(text);
  }

  @override
  String saveImageMetadata(String text) {
    return _imageManager.saveImageMetadata(text);
  }

  @override
  String saveAudioMetadata(String text) {
    // Add this method
    return _audioManager.saveAudioMetadata(text);
  }

  // Add method to add audio from outside
  void addAudio(String audioPath) {
    _audioManager.addAudio(audioPath);
  }

  Widget _buildStyledTextField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoTextField(
          controller: _titleController,
          focusNode: widget.focusNode,
          placeholder: 'Start typing your note title...',
          maxLines: 1,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: widget.searchQuery.isNotEmpty ? Colors.transparent : null,
          ),
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          padding: const EdgeInsets.only(bottom: 8),
          onChanged: (value) {
            if (!_isUpdatingFromController) {
              _onDisplayTextChanged(value +
                  (_contentController.text.isEmpty
                      ? ''
                      : '\n${_contentController.text}'));
            }
          },
        ),
        CupertinoTextField(
          controller: _contentController,
          focusNode: _contentFocusNode,
          placeholder: 'Add your note content...',
          maxLines: null,
          minLines: 15,
          style: TextStyle(
            fontSize: 16,
            color: widget.searchQuery.isNotEmpty ? Colors.transparent : null,
          ),
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          padding: EdgeInsets.zero,
          onChanged: (value) {
            if (!_isUpdatingFromController) {
              _onDisplayTextChanged(
                  _titleController.text + (value.isEmpty ? '' : '\n$value'));
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
          width: 0.5,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          _imageManager.updateContainerSize(
              Size(constraints.maxWidth, constraints.maxHeight));
          _audioManager.updateContainerSize(
              Size(constraints.maxWidth, constraints.maxHeight));
          _todoManager.updateContainerSize(Size(
              constraints.maxWidth, constraints.maxHeight)); // Add this line

          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              // Only deselect if not tapping on text fields
              _handleTapOutside();
            },
            onDoubleTap: () {
              // Show todo creation dialog
              showCupertinoDialog(
                context: context,
                builder: (context) => TodoCreationDialog(
                  onCreateTodo: (content, dueDate) {
                    // Add todo at center of screen
                    final position = Offset(
                      constraints.maxWidth / 2 - 100,
                      constraints.maxHeight / 2 - 50,
                    );
                    _todoManager.addTodo(content, position, dueDate: dueDate);
                  },
                ),
              );
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Container(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 24, // Reduced padding
                ),
                padding: const EdgeInsets.all(12), // Reduced padding
                child: Stack(
                  children: [
                    // Text input area
                    Column(
                      children: [
                        Stack(
                          children: [
                            // Background text field for editing
                            _buildStyledTextField(),

                            // Overlay highlighted text when searching
                            if (widget.searchQuery.isNotEmpty)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    child: HighlightedText(
                                      text: _displayController.text.isEmpty
                                          ? 'Start typing your note...'
                                          : _displayController.text,
                                      searchQuery: widget.searchQuery,
                                      textStyle: TextStyle(
                                        fontSize: 16,
                                        color: _displayController.text.isEmpty
                                            ? CupertinoColors.placeholderText
                                                .resolveFrom(context)
                                            : CupertinoColors.label
                                                .resolveFrom(context),
                                      ),
                                      highlightStyle: TextStyle(
                                        backgroundColor: CupertinoColors
                                            .systemYellow
                                            .withOpacity(0.3),
                                        color: CupertinoColors.label
                                            .resolveFrom(context),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),

                    // Images positioned within the scrollable content
                    ..._imageManager.buildImageOverlays(
                        context, widget.controller.text),

                    // Audio players positioned within the scrollable content
                    ..._audioManager.buildAudioOverlays(
                        context, widget.controller.text),

                    ..._todoManager.buildTodoOverlays(context),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
