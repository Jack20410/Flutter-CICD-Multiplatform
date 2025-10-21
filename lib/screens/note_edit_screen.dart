// lib/screens/note_edit_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/note.dart';
import '../providers/note_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../widgets/rich_text_editor.dart';

class NoteEditScreen extends StatefulWidget {
  const NoteEditScreen({super.key, this.note});
  final Note? note;

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen>
    with WidgetsBindingObserver {
  final _contentController = TextEditingController();
  final _contentSearchController = TextEditingController();
  final FocusNode _contentFocusNode = FocusNode();
  Timer? _debounceTimer;
  Timer? _periodicSaveTimer;
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;
  bool _showContentSearch = false;
  Note? _currentNote;
  List<String> _imagePaths = [];
  List<String> _audioPaths = [];
  List<String> _tags = [];
  final ImagePicker _picker = ImagePicker();

  // Key to access the RichTextEditor's functionality
  final GlobalKey<State<RichTextEditor>> _editorKey =
      GlobalKey<State<RichTextEditor>>();

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;
    if (widget.note != null) {
      final combinedText = widget.note!.content.isEmpty
          ? widget.note!.title
          : '${widget.note!.title}\n${widget.note!.content}';
      _contentController.text = combinedText;
      _imagePaths = List.from(widget.note!.imagePaths);
      _audioPaths = List.from(widget.note!.audioPaths);
      _tags = List.from(widget.note!.tags);
    }

    _contentController.addListener(_onTextChanged);

    _periodicSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_hasUnsavedChanges) {
        _saveNote();
      }
    });
    WidgetsBinding.instance.addObserver(this);
  }

  int _getMatchCount() {
    if (_contentSearchController.text.isEmpty ||
        _contentController.text.isEmpty) {
      return 0;
    }

    // Clean the text from metadata tags before searching
    final cleanText = _contentController.text
        .replaceAll(RegExp(r'\[IMAGE:[^\]]+\]\n?'), '')
        .replaceAll(RegExp(r'\[IMAGE_META:[^\]]+\]\n?'), '')
        .replaceAll(RegExp(r'\[AUDIO:[^\]]+\]\n?'), '') // Add this
        .replaceAll(RegExp(r'\[AUDIO_META:[^\]]+\]\n?'), '')
        .replaceAll(RegExp(r'\[TODO_META:[^\]]+\]\n?'), '')
        .toLowerCase();

    final query = _contentSearchController.text.toLowerCase();
    int count = 0;
    int index = cleanText.indexOf(query);

    while (index != -1) {
      count++;
      index = cleanText.indexOf(query, index + 1);
    }

    return count;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _periodicSaveTimer?.cancel();
    _contentController.removeListener(_onTextChanged);
    _contentController.dispose();
    _contentSearchController.dispose();
    _contentFocusNode.dispose();

    if (_hasUnsavedChanges) {
      _saveNote();
    }

    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_hasUnsavedChanges) {
        _saveNote();
      }
    }
  }

  void _onTextChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }

    // Extract hashtags from content
    final RegExp hashtagRegex = RegExp(r'\B#(\w+)');
    final matches = hashtagRegex.allMatches(_contentController.text);
    final Set<String> newTags = matches.map((m) => m.group(1)!).toSet();

    // Update tags if changed
    final currentTagsSet = _tags.toSet();
    if (newTags.length != currentTagsSet.length ||
        !newTags.every((tag) => currentTagsSet.contains(tag))) {
      setState(() {
        _tags = newTags.toList();
      });
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      // Shorter delay for metadata
      _saveNote();
    });
  }

  Future<void> _saveNote() async {
    if (_isSaving) return;

    final text = _contentController.text;
    final lines = text.split('\n');
    final title = lines.isNotEmpty ? lines[0].trim() : 'Untitled Note';
    var content = lines.length > 1 ? lines.sublist(1).join('\n').trim() : '';

    // Save BOTH image and audio metadata before processing content
    final editorState = _editorKey.currentState;
    if (editorState != null) {
      if (editorState is ImageMetadataProvider) {
        content =
            (editorState as ImageMetadataProvider).saveImageMetadata(content);
      }
      if (editorState is AudioMetadataProvider) {
        content =
            (editorState as AudioMetadataProvider).saveAudioMetadata(content);
      }
    }

    // Extract image paths from content
    final imagePattern = RegExp(r'\[IMAGE:([^\]]+)\]');
    final imageMatches = imagePattern.allMatches(content);
    _imagePaths = imageMatches.map((match) => match.group(1)!).toList();

    // Extract audio paths from content
    final audioPattern = RegExp(r'\[AUDIO:([^\]]+)\]');
    final audioMatches = audioPattern.allMatches(content);
    _audioPaths = audioMatches.map((match) => match.group(1)!).toList();

    if (title.isEmpty &&
        content.isEmpty &&
        _imagePaths.isEmpty &&
        _audioPaths.isEmpty) {
      setState(() {
        _hasUnsavedChanges = false;
      });
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final finalTitle = title.isEmpty ? 'Untitled Note' : title;

    try {
      final noteProvider = Provider.of<NoteProvider>(context, listen: false);

      if (_currentNote == null) {
        Note newNote = Note(
          title: finalTitle,
          content: content, // This now includes both image and audio metadata
          createdAt: DateTime.now(),
          isPinned: false,
          imagePaths: _imagePaths,
          audioPaths: _audioPaths,
          tags: _tags,
        );
        await noteProvider.addNoteWithMedia(newNote);
        await noteProvider.fetchNotes();
        _currentNote = noteProvider.notes.firstWhere(
          (note) => note.title == finalTitle && note.content == content,
          orElse: () => newNote,
        );
      } else {
        Note updatedNote = Note(
          id: _currentNote!.id,
          title: finalTitle,
          content: content, // This now includes both image and audio metadata
          createdAt: _currentNote!.createdAt,
          isPinned: _currentNote!.isPinned,
          imagePaths: _imagePaths,
          audioPaths: _audioPaths,
          tags: _tags,
        );
        await noteProvider.updateNote(updatedNote);
        _currentNote = updatedNote;
      }

      if (mounted) {
        setState(() {
          _hasUnsavedChanges = false;
          _isSaving = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    List<CupertinoActionSheetAction> actions = [];

    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
      actions.add(
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
            _getImage(ImageSource.camera);
          },
          child: const Text('Take Photo'),
        ),
      );
    }

    actions.add(
      CupertinoActionSheetAction(
        onPressed: () {
          Navigator.pop(context);
          _getImage(ImageSource.gallery);
        },
        child: const Text('Choose from Gallery'),
      ),
    );

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Add Image'),
        actions: actions,
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        final directory = await getApplicationDocumentsDirectory();
        final String fileName =
            'note_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String newPath = '${directory.path}/$fileName';
        await File(image.path).copy(newPath);

        _insertImageAtCursor(newPath);
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to pick image: ${e.toString()}'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _pickAudio() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final directory = await getApplicationDocumentsDirectory();
        final String fileName =
            'note_audio_${DateTime.now().millisecondsSinceEpoch}.${result.files.single.extension ?? 'mp3'}';
        final String newPath = '${directory.path}/$fileName';
        await file.copy(newPath);

        _insertAudioAtCursor(newPath);
      } // Add this closing brace
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to pick audio: ${e.toString()}'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
      // Remove the hashtag from the content
      final text = _contentController.text;
      _contentController.text = text.replaceAll('#$tag', tag);
      _hasUnsavedChanges = true;
    });
  }

  void _insertAudioAtCursor(String audioPath) {
    final text = _contentController.text;
    final selection = _contentController.selection;

    int cursorPosition = selection.baseOffset;
    if (cursorPosition < 0 || cursorPosition > text.length) {
      cursorPosition = text.length;
    }

    final audioTag = '[AUDIO:$audioPath]\n';
    final newText = text.replaceRange(cursorPosition, cursorPosition, audioTag);

    setState(() {
      _contentController.text = newText;
      _contentController.selection = TextSelection.collapsed(
        offset: cursorPosition + audioTag.length,
      );
      _hasUnsavedChanges = true;
    });
  }

  void _insertImageAtCursor(String imagePath) {
    final text = _contentController.text;
    final selection = _contentController.selection;

    int cursorPosition = selection.baseOffset;
    if (cursorPosition < 0 || cursorPosition > text.length) {
      cursorPosition = text.length;
    }

    final imageTag = '[IMAGE:$imagePath]\n';
    final newText = text.replaceRange(cursorPosition, cursorPosition, imageTag);

    setState(() {
      _contentController.text = newText;
      _contentController.selection = TextSelection.collapsed(
        offset: cursorPosition + imageTag.length,
      );
      _hasUnsavedChanges = true;
    });
  }

  void _toggleContentSearch() {
    setState(() {
      _showContentSearch = !_showContentSearch;
      if (!_showContentSearch) {
        _contentSearchController.clear();
      }
    });
  }

  void _goBack() async {
    if (_hasUnsavedChanges) {
      await _saveNote();
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: _buildNavigationBar(),
      backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
      child: SafeArea(
        child: Column(
          children: [
            _buildTagsSection(),
            _buildContentSearchBar(),
            _buildContentSection(), // This will now be expanded
            _buildStatusIndicator(),
          ],
        ),
      ),
    );
  }

  CupertinoNavigationBar _buildNavigationBar() {
    return CupertinoNavigationBar(
      middle: Text(_currentNote == null ? 'New Note' : _currentNote!.title),
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _goBack,
        child: const Icon(CupertinoIcons.back),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSearchButton(),
          _buildMoreButton(), // Three-dot menu
          _buildNewNoteButton(), // New Note button
        ],
      ),
    );
  }

  Widget _buildSearchButton() {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: _toggleContentSearch,
      child: Icon(
        _showContentSearch
            ? CupertinoIcons.search_circle_fill
            : CupertinoIcons.search,
        color: _showContentSearch ? CupertinoColors.activeBlue : null,
      ),
    );
  }

  Widget _buildMoreButton() {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: _showMoreOptions,
      child: const Icon(CupertinoIcons.ellipsis),
    );
  }

  Widget _buildNewNoteButton() {
    return CupertinoButton(
      padding: const EdgeInsets.only(left: 8),
      onPressed: () => Navigator.of(context).push(
        CupertinoPageRoute(builder: (context) => const NoteEditScreen()),
      ),
      child: const Icon(
        CupertinoIcons.create_solid,
        color: CupertinoColors.activeBlue,
      ),
    );
  }

  Widget _buildTagsSection() {
    if (_tags.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: _tags
            .map((tag) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: CupertinoColors.activeBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '#$tag',
                        style: const TextStyle(
                          color: CupertinoColors.activeBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _removeTag(tag),
                        child: const Icon(
                          CupertinoIcons.xmark,
                          size: 12,
                          color: CupertinoColors.activeBlue,
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  void _showMoreOptions() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Add to Note'),
        message: const Text('Choose what you want to add to your note'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickImage();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.camera,
                  color: CupertinoColors.activeBlue,
                ),
                SizedBox(width: 12),
                Text(
                  'Add Image',
                  style: TextStyle(color: CupertinoColors.activeBlue),
                ),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickAudio();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.music_note,
                  color: CupertinoColors.activeBlue,
                ),
                SizedBox(width: 12),
                Text(
                  'Add Audio',
                  style: TextStyle(color: CupertinoColors.activeBlue),
                ),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: CupertinoColors.destructiveRed),
          ),
        ),
      ),
    );
  }

  Widget _buildContentSearchBar() {
    if (!_showContentSearch) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          CupertinoSearchTextField(
            controller: _contentSearchController,
            placeholder: 'Search in note content...',
            onChanged: (value) => setState(() {}),
            onSuffixTap: () {
              _contentSearchController.clear();
              setState(() {});
            },
          ),
          if (_contentSearchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${_getMatchCount()} matches found',
                style: TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    return Expanded(
      // This expands the content section to fill available space
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: RichTextEditor(
          key: _editorKey,
          controller: _contentController,
          focusNode: _contentFocusNode,
          searchQuery: _showContentSearch ? _contentSearchController.text : '',
          onImageRemove: (imagePath) {
            setState(() {
              var text = _contentController.text;
              text = text
                  .replaceAll('[IMAGE:$imagePath]\n', '')
                  .replaceAll('[IMAGE:$imagePath]', '');

              final editorState = _editorKey.currentState;
              if (editorState != null && editorState is ImageMetadataProvider) {
                text = (editorState as ImageMetadataProvider)
                    .saveImageMetadata(text);
              }

              _contentController.text = text;
              _hasUnsavedChanges = true;
            });
          },
          onAudioRemove: (audioPath) {
            setState(() {
              var text = _contentController.text;
              text = text
                  .replaceAll('[AUDIO:$audioPath]\n', '')
                  .replaceAll('[AUDIO:$audioPath]', '');

              final editorState = _editorKey.currentState;
              if (editorState != null && editorState is AudioMetadataProvider) {
                text = (editorState as AudioMetadataProvider)
                    .saveAudioMetadata(text);
              }

              _contentController.text = text;
              _hasUnsavedChanges = true;
            });
          },
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isSaving) ...[
            const CupertinoActivityIndicator(),
            const SizedBox(width: 8),
            Text(
              'Saving...',
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontSize: 14,
              ),
            ),
          ] else if (_hasUnsavedChanges) ...[
            const Icon(CupertinoIcons.circle_fill,
                size: 8, color: CupertinoColors.systemOrange),
            const SizedBox(width: 8),
            const Text('Unsaved changes',
                style: TextStyle(
                    color: CupertinoColors.systemOrange, fontSize: 14)),
          ] else if (_contentController.text.isNotEmpty ||
              _imagePaths.isNotEmpty ||
              _audioPaths.isNotEmpty) ...[
            const Icon(CupertinoIcons.checkmark_circle_fill,
                size: 16, color: CupertinoColors.systemGreen),
            const SizedBox(width: 8),
            const Text('All changes saved',
                style: TextStyle(
                    color: CupertinoColors.systemGreen, fontSize: 14)),
          ],
        ],
      ),
    );
  }
}
