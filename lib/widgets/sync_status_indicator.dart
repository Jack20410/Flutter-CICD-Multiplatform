// lib/widgets/sync_status_indicator.dart
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/note_provider.dart';

class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteProvider>(
      builder: (context, noteProvider, child) {
        final status = noteProvider.syncStatus;
        
        Color color;
        String text;
        IconData icon;
        
        switch (status) {
          case SyncStatus.upToDate:
            color = CupertinoColors.systemGreen;
            text = 'Up to Cloud';
            icon = CupertinoIcons.cloud_upload;
            break;
          case SyncStatus.unsaved:
            color = CupertinoColors.systemOrange;
            text = 'Unsaved Cloud';
            icon = CupertinoIcons.cloud;
            break;
          case SyncStatus.checking:
            color = CupertinoColors.systemBlue;
            text = 'Checking...';
            icon = CupertinoIcons.refresh;
            break;
          case SyncStatus.syncing:
            color = CupertinoColors.systemBlue;
            text = 'Syncing...';
            icon = CupertinoIcons.cloud_upload;
            break;
        }
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                text,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}