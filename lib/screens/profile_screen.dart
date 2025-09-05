// lib/screens/profile_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/note_provider.dart';
import '../models/note.dart';
import '../models/sync_result.dart';
import '../services/cloud_sync_service.dart';
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.back),
        ),
        middle: const Text('Profile'),
      ),
      child: SafeArea(
        child: Consumer<AuthService>(
          builder: (context, authService, child) {
            if (!authService.isAuthenticated) {
              return const Center(
                child: Text('Not logged in'),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Profile Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: CupertinoColors.activeBlue,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Center(
                          child: Text(
                            authService.userInitials,
                            style: const TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (authService.userName != null) ...[
                        Text(
                          authService.userName!,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        authService.userEmail ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          color: CupertinoColors.secondaryLabel.resolveFrom(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (!authService.isEmailVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: CupertinoColors.systemOrange.withOpacity(0.3),
                            ),
                          ),
                          child: const Text(
                            'Email not verified',
                            style: TextStyle(
                              color: CupertinoColors.systemOrange,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Account Section
                _buildSection(
                  context,
                  'Account',
                  [
                    if (!authService.isEmailVerified)
                      _buildListItem(
                        context,
                        icon: CupertinoIcons.mail,
                        title: 'Verify Email',
                        subtitle: 'Verify your email address',
                        onTap: () => _verifyEmail(context, authService),
                        trailing: const Icon(CupertinoIcons.chevron_right),
                      ),
                    _buildListItem(
                      context,
                      icon: CupertinoIcons.person,
                      title: 'Edit Profile',
                      subtitle: 'Update your name and information',
                      onTap: () => _editProfile(context, authService),
                      trailing: const Icon(CupertinoIcons.chevron_right),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Data Section
                _buildSection(
                  context,
                  'Data & Sync',
                  [
                    _buildListItem(
                      context,
                      icon: CupertinoIcons.cloud_download,
                      title: 'Sync Notes',
                      subtitle: 'Sync your notes across devices',
                      onTap: () => _syncNotes(context),
                      trailing: const Icon(CupertinoIcons.chevron_right),
                    ),
                    _buildListItem(
                      context,
                      icon: CupertinoIcons.square_arrow_up,
                      title: 'Export Data',
                      subtitle: 'Export your notes as backup',
                      onTap: () => _exportData(context),
                      trailing: const Icon(CupertinoIcons.chevron_right),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Sign Out Button
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color: CupertinoColors.destructiveRed,
                    onPressed: () => _signOut(context, authService),
                    child: const Text('Sign Out'),
                  ),
                ),

                const SizedBox(height: 16),

                // Delete Account Button
                CupertinoButton(
                  onPressed: () => _deleteAccount(context, authService),
                  child: const Text(
                    'Delete Account',
                    style: TextStyle(
                      color: CupertinoColors.destructiveRed,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
        ),
        Container(
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
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildListItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return CupertinoButton(
      padding: const EdgeInsets.all(16),
      onPressed: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            size: 24,
            color: CupertinoColors.activeBlue,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Future<void> _verifyEmail(BuildContext context, AuthService authService) async {
    try {
      await authService.sendEmailVerification();
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Verification Email Sent'),
            content: const Text('Please check your email and click the verification link.'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to send verification email: ${e.toString()}'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _editProfile(BuildContext context, AuthService authService) async {
    final nameController = TextEditingController(text: authService.userName ?? '');
    
    await showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Edit Profile'),
        content: CupertinoTextField(
          controller: nameController,
          placeholder: 'Display Name',
          decoration: BoxDecoration(
            border: Border.all(color: CupertinoColors.systemGrey4),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              try {
                await authService.updateProfile(displayName: nameController.text.trim());
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
              } catch (e) {
                // Handle error
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _syncNotes(BuildContext context) async {
    // Show loading dialog
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CupertinoAlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoActivityIndicator(),
            SizedBox(height: 16),
            Text('Syncing notes...'),
          ],
        ),
      ),
    );

    try {
      // Get the note provider
      final noteProvider = Provider.of<NoteProvider>(context, listen: false);
      
      // Get auth service for user identification
      final authService = Provider.of<AuthService>(context, listen: false);
      
      if (!authService.isAuthenticated) {
        throw Exception('User not authenticated');
      }

      // Initialize cloud sync service if not already done
      final cloudSyncService = CloudSyncService(
    userId: authService.userId ?? '', // Use empty string as fallback
    userEmail: authService.userEmail,
  );

      // Get local notes
      final localNotes = noteProvider.notes;
      
      // Fetch remote notes
      final remoteNotes = await cloudSyncService.fetchRemoteNotes();
      
      // Perform sync logic
      final syncResult = await _performNoteSync(
        localNotes: localNotes,
        remoteNotes: remoteNotes,
        cloudSyncService: cloudSyncService,
      );

      // Update local database with synced notes
      await _updateLocalNotes(noteProvider, syncResult);
      
      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Show success dialog
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Sync Complete'),
            content: Text(
              'Successfully synced ${syncResult.updatedCount} notes.\n'
              'Uploaded: ${syncResult.uploadedCount}\n'
              'Downloaded: ${syncResult.downloadedCount}\n'
              'Conflicts resolved: ${syncResult.conflictsResolved}',
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }

    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }
      
      // Show error dialog
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Sync Failed'),
            content: Text('Failed to sync notes: ${e.toString()}'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<SyncResult> _performNoteSync({
    required List<Note> localNotes,
    required List<Note> remoteNotes,
    required CloudSyncService cloudSyncService,
  }) async {
    int uploadedCount = 0;
    int downloadedCount = 0;
    int updatedCount = 0;
    int conflictsResolved = 0;

    // Create maps for easier lookup
    final localNotesMap = {for (var note in localNotes) note.id: note};
    final remoteNotesMap = {for (var note in remoteNotes) note.id: note};

    final List<Note> notesToUpload = [];
    final List<Note> notesToDownload = [];
    final List<Note> notesToUpdate = [];

    // Find notes that need to be uploaded (local only)
    for (var localNote in localNotes) {
      if (!remoteNotesMap.containsKey(localNote.id)) {
        notesToUpload.add(localNote);
      } else {
        // Compare timestamps for conflicts
        final remoteNote = remoteNotesMap[localNote.id]!;
        if (localNote.updatedAt != null && remoteNote.updatedAt != null) {
          if (localNote.updatedAt!.isAfter(remoteNote.updatedAt!)) {
            notesToUpload.add(localNote);
            conflictsResolved++;
          } else if (remoteNote.updatedAt!.isAfter(localNote.updatedAt!)) {
            notesToDownload.add(remoteNote);
            conflictsResolved++;
          }
        }
      }
    }

    // Find notes that need to be downloaded (remote only)
    for (var remoteNote in remoteNotes) {
      if (!localNotesMap.containsKey(remoteNote.id)) {
        notesToDownload.add(remoteNote);
      }
    }

    // Upload local notes
    for (var note in notesToUpload) {
      await cloudSyncService.uploadNote(note);
      uploadedCount++;
    }

    // Download remote notes
    for (var note in notesToDownload) {
      notesToUpdate.add(note);
      downloadedCount++;
    }

    updatedCount = notesToUpload.length + notesToDownload.length;

    return SyncResult(
      uploadedCount: uploadedCount,
      downloadedCount: downloadedCount,
      updatedCount: updatedCount,
      conflictsResolved: conflictsResolved,
      notesToUpdate: notesToUpdate,
    );
  }

  Future<void> _updateLocalNotes(NoteProvider noteProvider, SyncResult syncResult) async {
    // Add/update notes from sync result
    for (var note in syncResult.notesToUpdate) {
      if (noteProvider.notes.any((n) => n.id == note.id)) {
        await noteProvider.updateNote(note);
      } else {
        await noteProvider.addNoteWithMedia(note);
      }
    }
  }

  Future<void> _exportData(BuildContext context) async {

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Export Data'),
        content: const Text('Data export will be implemented soon.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context, AuthService authService) async {
    final shouldSignOut = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      try {
        await authService.signOut();
        if (context.mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Error'),
              content: Text('Failed to sign out: ${e.toString()}'),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteAccount(BuildContext context, AuthService authService) async {
    final shouldDelete = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and will permanently delete all your data.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await authService.deleteAccount();
        if (context.mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Error'),
              content: Text('Failed to delete account: ${e.toString()}'),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    }
  }
}