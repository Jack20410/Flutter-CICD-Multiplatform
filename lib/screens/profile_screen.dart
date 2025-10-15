// lib/screens/profile_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/note_provider.dart';
import '../services/cloud_sync_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
                          color: CupertinoColors.secondaryLabel
                              .resolveFrom(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (!authService.isEmailVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                CupertinoColors.systemOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  CupertinoColors.systemOrange.withOpacity(0.3),
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
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
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

  Future<void> _verifyEmail(
      BuildContext context, AuthService authService) async {
    try {
      await authService.sendEmailVerification();
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Verification Email Sent'),
            content: const Text(
                'Please check your email and click the verification link.'),
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

  Future<void> _editProfile(
      BuildContext context, AuthService authService) async {
    final nameController =
        TextEditingController(text: authService.userName ?? '');

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
                await authService.updateProfile(
                    displayName: nameController.text.trim());
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
    final noteProvider = Provider.of<NoteProvider>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    if (!authService.isAuthenticated) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: const Text('User not authenticated'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    noteProvider.setSyncStatus(SyncStatus.checking);

    try {
      final cloudSync = CloudSyncService(userId: authService.userId!);
      final localNotes = noteProvider.notes;
      final remoteNotes = await cloudSync.fetchRemoteNotes();

      // Get deletion records to filter out deleted notes
      final deletions = await noteProvider.getAllDeletions();
      debugPrint("Remote note IDs: ${remoteNotes.map((n) => n.id).toList()}");
      debugPrint("Deletions found during sync: ${deletions.length}"); // Debug
      debugPrint(
          "Deleted note IDs: ${deletions.map((d) => d.noteId).toList()}");
      final deletedIds = deletions.map((d) => d.noteId).toSet();
      debugPrint("Remote notes before filtering: ${remoteNotes.length}");

      // Filter out deleted notes from remote notes
      final validRemoteNotes =
          remoteNotes.where((note) => !deletedIds.contains(note.id)).toList();
      debugPrint(
          "Remote notes after filtering: ${validRemoteNotes.length}"); // Debug
      // Analyze differences
      final localIds = localNotes.map((n) => n.id).toSet();
      final remoteIds = validRemoteNotes.map((n) => n.id).toSet();

      final onlyLocal = localIds.difference(remoteIds);
      final onlyRemote = remoteIds.difference(localIds);

      // Show warning if there are differences
      if (onlyLocal.isNotEmpty || onlyRemote.isNotEmpty) {
        // ignore: use_build_context_synchronously
        final shouldContinue = await _showSyncWarning(
            context, onlyLocal.length, onlyRemote.length);

        if (!shouldContinue) {
          noteProvider.setSyncStatus(SyncStatus.unsaved);
          return;
        }
      }

      noteProvider.setSyncStatus(SyncStatus.syncing);

      // Perform sync operations
      if (onlyLocal.isNotEmpty) {
        // Upload local notes to cloud
        for (final noteId in onlyLocal) {
          final note = localNotes.firstWhere((n) => n.id == noteId);
          await cloudSync.uploadNote(note);
        }
      }

      if (onlyRemote.isNotEmpty) {
        // Download and add remote notes locally
        for (final noteId in onlyRemote) {
          final note = validRemoteNotes.firstWhere((n) => n.id == noteId);
          await noteProvider.addNoteWithMedia(note);
        }
      }

      noteProvider.setSyncStatus(SyncStatus.upToDate);

      // Show success dialog
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Sync Complete'),
            content: Text('Uploaded: ${onlyLocal.length} notes\n'
                'Downloaded: ${onlyRemote.length} notes'),
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
      noteProvider.setSyncStatus(SyncStatus.unsaved);

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

  Future<bool> _showSyncWarning(
      BuildContext context, int localExtra, int remoteExtra) async {
    return await showCupertinoDialog<bool>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Sync Warning'),
            content: Text('Sync will make the following changes:\n\n'
                '${localExtra > 0 ? '• Upload $localExtra local notes to cloud\n' : ''}'
                '${remoteExtra > 0 ? '• Download $remoteExtra notes from cloud\n' : ''}'
                '\nDo you want to continue?'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continue'),
              ),
            ],
          ),
        ) ??
        false;
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

  // Commented out unused method - can be enabled later if needed
  // ignore: unused_element
  Future<void> _deleteAccount(
      BuildContext context, AuthService authService) async {
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
      final passwordController = TextEditingController();

      // ignore: use_build_context_synchronously
      final password = await showCupertinoDialog<String>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Confirm Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'Please enter your password to confirm account deletion:'),
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: passwordController,
                placeholder: 'Password',
                obscureText: true,
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey4),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, passwordController.text),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );

      if (password != null && password.isNotEmpty) {
        // Show loading dialog
        // ignore: use_build_context_synchronously
        showCupertinoDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const CupertinoAlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoActivityIndicator(),
                SizedBox(height: 16),
                Text('Deleting account...'),
              ],
            ),
          ),
        );

        try {
          debugPrint("Starting re-authentication..."); // Debug

          // Re-authenticate user with timeout
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) {
            throw Exception('No user logged in');
          }

          final credential = EmailAuthProvider.credential(
            email: user.email!,
            password: password,
          );

          // Add timeout to prevent hanging
          await user.reauthenticateWithCredential(credential).timeout(
            const Duration(minutes: 2),
            onTimeout: () {
              throw Exception(
                  'Authentication timeout - please check your internet connection');
            },
          );

          debugPrint("Re-authentication successful"); // Debug

          // Now delete the account with timeout
          await user.delete().timeout(
            const Duration(minutes: 2),
            onTimeout: () {
              throw Exception('Account deletion timeout - please try again');
            },
          );

          debugPrint("Account deletion successful"); // Debug

          // Close loading dialog
          if (context.mounted) {
            Navigator.pop(context);
          }

          // Navigate back to main screen
          if (context.mounted) {
            Navigator.pop(context);
          }
        } catch (e) {
          debugPrint("Error during deletion: $e"); // Debug

          // Close loading dialog
          if (context.mounted) {
            Navigator.pop(context);
          }

          if (context.mounted) {
            String errorMessage = e.toString();
            if (errorMessage.contains('wrong-password')) {
              errorMessage = 'Incorrect password. Please try again.';
            } else if (errorMessage.contains('timeout')) {
              errorMessage =
                  'Operation timed out. Please check your internet connection and try again.';
            } else if (errorMessage.contains('network')) {
              errorMessage =
                  'Network error. Please check your internet connection.';
            }

            showCupertinoDialog(
              context: context,
              builder: (context) => CupertinoAlertDialog(
                title: const Text('Error'),
                content: Text(errorMessage),
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
}
