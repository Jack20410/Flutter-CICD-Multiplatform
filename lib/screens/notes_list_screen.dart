// lib/screens/notes_list_screen.dart (Updated)
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/note_provider.dart';
import '../services/auth_service.dart';
import 'note_edit_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'dart:convert';

class NotesListScreen extends StatelessWidget {
  const NotesListScreen({super.key});

  bool _hasUncompletedTodos(Note note) {
    final todoMetaPattern = RegExp(r'\[TODO_META:([^\]]+)\]');
    final todoMatches = todoMetaPattern.allMatches(note.content);

    for (final match in todoMatches) {
      final base64Data = match.group(1) ?? '';

      try {
        // Decode the Base64 string
        final decodedBytes = base64.decode(base64Data);
        final jsonString = utf8.decode(decodedBytes);

        // Parse the JSON
        final Map<String, dynamic> todoData = json.decode(jsonString);

        // Check if there are any uncompleted todos
        if (todoData.containsKey('todos')) {
          final List<dynamic> todos = todoData['todos'];

          for (final todo in todos) {
            if (todo is Map<String, dynamic> &&
                todo.containsKey('isCompleted') &&
                todo['isCompleted'] == false) {
              return true; // Found at least one uncompleted todo
            }
          }
        }
      } catch (e) {
        // If decoding fails, skip this metadata
        debugPrint('Error decoding todo metadata: $e');
        continue;
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: Text(
          'Notes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 30,
            color: CupertinoColors.label.resolveFrom(context),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Profile/Login button
            Consumer<AuthService>(
              builder: (context, authService, child) {
                if (authService.isAuthenticated) {
                  return CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      Navigator.of(context).push(CupertinoPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ));
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: CupertinoColors.activeBlue,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          authService.userInitials,
                          style: const TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                } else {
                  return CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      Navigator.of(context).push(CupertinoPageRoute(
                        builder: (context) => const LoginScreen(),
                      ));
                    },
                    child: const Icon(CupertinoIcons.person_circle),
                  );
                }
              },
            ),
            const SizedBox(width: 8),
            // Add note button
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.of(context).push(CupertinoPageRoute(
                  builder: (context) => const NoteEditScreen(),
                ));
              },
              child: const Icon(CupertinoIcons.add),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Consumer<NoteProvider>(
          builder: (context, noteProvider, child) {
            return Column(
              children: [
                // Enhanced Search Bar with indicator
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    children: [
                      CupertinoSearchTextField(
                        placeholder: 'Search notes...',
                        onChanged: (value) async =>
                            await noteProvider.searchNotes(value),
                        onSuffixTap: () => noteProvider.clearSearch(),
                      ),
                      // Add search indicator
                      if (noteProvider.searchQuery.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(
                                noteProvider.isUsingSemanticSearch
                                    ? CupertinoIcons.sparkles
                                    : CupertinoIcons.search,
                                size: 12,
                                color: CupertinoColors.systemGrey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                noteProvider.isUsingSemanticSearch
                                    ? 'Smart search'
                                    : 'Basic search',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${noteProvider.notes.length} result${noteProvider.notes.length == 1 ? '' : 's'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Notes List
                Expanded(
                  child: _buildNotesList(context, noteProvider),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotesList(BuildContext context, NoteProvider noteProvider) {
    if (noteProvider.notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              noteProvider.searchQuery.isEmpty
                  ? 'No notes yet. Add one!'
                  : 'No notes found for "${noteProvider.searchQuery}"',
              style: TextStyle(
                fontSize: 16,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
            if (noteProvider.searchQuery.isEmpty) ...[
              const SizedBox(height: 16),
              Consumer<AuthService>(
                builder: (context, authService, child) {
                  if (!authService.isAuthenticated) {
                    return Column(
                      children: [
                        Text(
                          'Swipe right on any note to login and sync your notes',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.secondaryLabel
                                .resolveFrom(context),
                          ),
                        ),
                        const SizedBox(height: 12),
                        CupertinoButton(
                          onPressed: () {
                            Navigator.of(context).push(CupertinoPageRoute(
                              builder: (context) => const LoginScreen(),
                            ));
                          },
                          child: const Text('Sign In'),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ],
        ),
      );
    }

    // If searching, show simple list without grouping
    if (noteProvider.searchQuery.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: noteProvider.notes.length,
        itemBuilder: (context, index) {
          final note = noteProvider.notes[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildNoteCard(context, noteProvider, note),
          );
        },
      );
    }

    // Normal grouped view when not searching
    final groupedNotes = noteProvider.groupedNotes;
    final monthKeys = groupedNotes.keys.toList();

    monthKeys.sort((a, b) {
      if (a == 'PINNED' && b != 'PINNED') return -1;
      if (a != 'PINNED' && b == 'PINNED') return 1;
      if (a == 'PINNED' && b == 'PINNED') return 0;

      DateTime dateA = DateFormat('MMM yyyy').parse(a);
      DateTime dateB = DateFormat('MMM yyyy').parse(b);
      return dateB.compareTo(dateA);
    });

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _calculateTotalItems(noteProvider, monthKeys),
      itemBuilder: (context, index) {
        return _buildItem(context, noteProvider, monthKeys, index);
      },
    );
  }

  int _calculateTotalItems(NoteProvider noteProvider, List<String> monthKeys) {
    int totalItems = 0;
    for (String monthKey in monthKeys) {
      totalItems++;
      if (noteProvider.isSectionExpanded(monthKey)) {
        totalItems += noteProvider.groupedNotes[monthKey]!.length;
      }
    }
    return totalItems;
  }

  Widget _buildItem(BuildContext context, NoteProvider noteProvider,
      List<String> monthKeys, int index) {
    int currentIndex = 0;

    for (String monthKey in monthKeys) {
      if (currentIndex == index) {
        return _buildSectionHeader(context, noteProvider, monthKey);
      }
      currentIndex++;

      if (noteProvider.isSectionExpanded(monthKey)) {
        final notesInSection = noteProvider.groupedNotes[monthKey]!;
        if (index < currentIndex + notesInSection.length) {
          final noteIndex = index - currentIndex;
          final note = notesInSection[noteIndex];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildNoteCard(context, noteProvider, note),
          );
        }
        currentIndex += notesInSection.length;
      }
    }

    return Container();
  }

  Widget _buildSectionHeader(
      BuildContext context, NoteProvider noteProvider, String monthKey) {
    final isExpanded = noteProvider.isSectionExpanded(monthKey);
    final notesCount = noteProvider.groupedNotes[monthKey]!.length;
    final isPinnedSection = monthKey == 'PINNED';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Container(
        decoration: BoxDecoration(
          color: isPinnedSection
              ? CupertinoColors.systemOrange.withOpacity(0.1)
              : CupertinoColors.systemGrey6.resolveFrom(context),
          borderRadius: BorderRadius.circular(8),
        ),
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          onPressed: () => noteProvider.toggleSection(monthKey),
          child: Row(
            children: [
              Icon(
                isExpanded
                    ? CupertinoIcons.chevron_down
                    : CupertinoIcons.chevron_right,
                size: 16,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
              const SizedBox(width: 8),
              if (isPinnedSection) ...[
                const Icon(
                  CupertinoIcons.pin_fill,
                  size: 16,
                  color: CupertinoColors.systemOrange,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                monthKey,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isPinnedSection
                      ? CupertinoColors.systemOrange
                      : CupertinoColors.label.resolveFrom(context),
                ),
              ),
              const Spacer(),
              Text(
                '$notesCount note${notesCount == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to clean content from metadata tags
  String _getCleanContent(String content) {
    return content
        .replaceAll(RegExp(r'\[IMAGE:[^\]]+\]\n?'), '')
        .replaceAll(RegExp(r'\[IMAGE_META:[^\]]+\]\n?'), '')
        .replaceAll(RegExp(r'\[AUDIO:[^\]]+\]\n?'), '')
        .replaceAll(RegExp(r'\[AUDIO_META:[^\]]+\]\n?'), '')
        .replaceAll(RegExp(r'\[TODO_META:[^\]]+\]\n?'), '')
        .trim();
  }

  // Helper method to get first media preview
  Widget? _getMediaPreview(Note note) {
    // Check for images first
    if (note.imagePaths.isNotEmpty) {
      final imagePath = note.imagePaths.first;
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: CupertinoColors.systemGrey5,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.file(
            File(imagePath),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Icon(
              CupertinoIcons.photo,
              size: 20,
              color: CupertinoColors.systemGrey2,
            ),
          ),
        ),
      );
    }

    // Check for audio files
    if (note.audioPaths.isNotEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: CupertinoColors.activeBlue.withOpacity(0.1),
        ),
        child: const Icon(
          CupertinoIcons.music_note,
          size: 20,
          color: CupertinoColors.activeBlue,
        ),
      );
    }

    return null;
  }

  // Helper method to build tags
  Widget _buildTags(List<String> tags) {
    if (tags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: tags
          .take(3)
          .map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: CupertinoColors.activeBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '#$tag',
                  style: const TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.activeBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildNoteCard(
      BuildContext context, NoteProvider noteProvider, Note note) {
    final cleanContent = _getCleanContent(note.content);
    final mediaPreview = _getMediaPreview(note);
    final hasUncompletedTodos = _hasUncompletedTodos(note);

    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return Dismissible(
          key: Key(note.id.toString()),
          background: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: authService.isAuthenticated
                  ? CupertinoColors.systemGreen
                  : CupertinoColors.activeBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  authService.isAuthenticated
                      ? (note.isPinned
                          ? CupertinoIcons.pin_slash
                          : CupertinoIcons.pin)
                      : CupertinoIcons.person_circle,
                  color: CupertinoColors.white,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  authService.isAuthenticated
                      ? (note.isPinned ? 'Unpin' : 'Pin')
                      : 'Login',
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          secondaryBackground: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: CupertinoColors.destructiveRed,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.delete,
                  color: CupertinoColors.white,
                  size: 24,
                ),
                SizedBox(height: 4),
                Text(
                  'Delete',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.endToStart) {
              return await showCupertinoDialog<bool>(
                    context: context,
                    builder: (BuildContext ctx) {
                      return CupertinoAlertDialog(
                        title: const Text('Delete Note'),
                        content: const Text(
                            'Are you sure you want to delete this note? This action cannot be undone.'),
                        actions: [
                          CupertinoDialogAction(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          CupertinoDialogAction(
                            isDestructiveAction: true,
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      );
                    },
                  ) ??
                  false;
            } else if (direction == DismissDirection.startToEnd) {
              if (authService.isAuthenticated) {
                noteProvider.togglePinNote(note);
              } else {
                // Navigate to login screen
                Navigator.of(context).push(CupertinoPageRoute(
                  builder: (context) => const LoginScreen(),
                ));
              }
              return false;
            }
            return false;
          },
          onDismissed: (direction) {
            if (direction == DismissDirection.endToStart) {
              noteProvider.deleteNote(note.id!);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.systemGrey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CupertinoButton(
              padding: const EdgeInsets.all(20),
              onPressed: () {
                Navigator.of(context).push(CupertinoPageRoute(
                  builder: (context) => NoteEditScreen(note: note),
                ));
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Tags Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    note.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: CupertinoColors.label
                                          .resolveFrom(context),
                                    ),
                                  ),
                                ),
                                // Todo indicator - only show if there are uncompleted todos
                                if (hasUncompletedTodos)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: CupertinoColors.destructiveRed
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          CupertinoIcons
                                              .exclamationmark_circle_fill,
                                          size: 12,
                                          color: CupertinoColors.destructiveRed,
                                        ),
                                        SizedBox(width: 2),
                                        Text(
                                          'TODO',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color:
                                                CupertinoColors.destructiveRed,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            if (note.tags.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              _buildTags(note.tags),
                            ],
                          ],
                        ),
                      ),
                      // Media preview on the right
                      if (mediaPreview != null) ...[
                        const SizedBox(width: 12),
                        mediaPreview,
                      ],
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Content preview - keep original color
                  if (cleanContent.isNotEmpty)
                    Text(
                      cleanContent,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Date - keep original color
                  Text(
                    DateFormat.yMMMd().format(note.createdAt),
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
