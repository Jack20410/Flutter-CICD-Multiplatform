import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import 'audio_player_widget.dart';

class AudioItem {
  final String audioPath;
  Offset position;
  String? metadata;
  String? customName;

  AudioItem({
    required this.audioPath,
    required this.position,
    this.metadata,
    this.customName,
  });

  Map<String, dynamic> toMap() {
    return {
      'audioPath': audioPath,
      'x': position.dx,
      'y': position.dy,
      'metadata': metadata,
      'customName': customName,
    };
  }

  static AudioItem fromMap(Map<String, dynamic> map) {
    return AudioItem(
      audioPath: map['audioPath'],
      position: Offset(map['x'], map['y']),
      metadata: map['metadata'],
      customName: map['customName'],
    );
  }
}

class AudioOverlayManager {
  final Function(String) onAudioRemove;
  final VoidCallback onStateChanged;
  final VoidCallback onMetadataChanged;

  final List<AudioItem> _audioItems = [];
  String? _selectedAudioPath;
  Size _containerSize = Size.zero;

  AudioOverlayManager({
    required this.onAudioRemove,
    required this.onStateChanged,
    required this.onMetadataChanged,
  });

  void updateContainerSize(Size size) {
    _containerSize = size;
  }

  void addAudio(String audioPath) {
    // Calculate position for new audio (avoid overlapping)
    Offset position = const Offset(20, 100);

    // Check for existing audio items and adjust position
    while (
        _audioItems.any((item) => (item.position - position).distance < 100)) {
      position = Offset(position.dx + 20, position.dy + 120);

      // Wrap around if we go too far
      if (position.dy > _containerSize.height - 200) {
        position = Offset(position.dx + 100, 100);
      }
    }

    final audioItem = AudioItem(
      audioPath: audioPath,
      position: position,
    );

    _audioItems.add(audioItem);
    onStateChanged();
  }

  void removeAudio(String audioPath) {
    _audioItems.removeWhere((item) => item.audioPath == audioPath);
    if (_selectedAudioPath == audioPath) {
      _selectedAudioPath = null;
    }
    onAudioRemove(audioPath);
    onStateChanged();
  }

  void selectAudio(String audioPath) {
    _selectedAudioPath = audioPath;
    onStateChanged();
  }

  void deselectAll() {
    if (_selectedAudioPath != null) {
      _selectedAudioPath = null;
      onStateChanged();
    }
  }

  void renameAudio(String audioPath, String newName) {
    final index = _audioItems.indexWhere((item) => item.audioPath == audioPath);
    if (index != -1) {
      _audioItems[index].customName = newName;
      onStateChanged();
      onMetadataChanged();
    }
  }

  void _loadAudioMetadata(String text) {
    final RegExp metadataRegex = RegExp(r'\[AUDIO_META:([^\]]+)\]');
    final match = metadataRegex.firstMatch(text);

    if (match != null) {
      try {
        final metadataJson = match.group(1);
        final decodedBytes = base64Decode(metadataJson!);
        final metadataString = utf8.decode(decodedBytes);
        final metadata = jsonDecode(metadataString) as Map<String, dynamic>;

        if (metadata.containsKey('positions')) {
          final positions = metadata['positions'] as Map<String, dynamic>;
          for (final entry in positions.entries) {
            final pos = entry.value as Map<String, dynamic>;
            final position =
                Offset(pos['x']?.toDouble() ?? 20, pos['y']?.toDouble() ?? 20);

            // Find existing audio item or create new one
            final existingIndex =
                _audioItems.indexWhere((item) => item.audioPath == entry.key);
            if (existingIndex != -1) {
              _audioItems[existingIndex].position = position;
            } else {
              _audioItems.add(AudioItem(
                audioPath: entry.key,
                position: position,
              ));
            }
          }
        }

        if (metadata.containsKey('customNames')) {
          final names = metadata['customNames'] as Map<String, dynamic>;
          for (final entry in names.entries) {
            final existingIndex =
                _audioItems.indexWhere((item) => item.audioPath == entry.key);
            if (existingIndex != -1) {
              _audioItems[existingIndex].customName = entry.value as String?;
            }
          }
        }
        // ignore: empty_catches
      } catch (e) {}
    }
  }

  String saveAudioMetadata(String text) {
    // Remove existing metadata first
    text = text.replaceAll(RegExp(r'\[AUDIO_META:[^\]]+\]\n?'), '');

    // Don't add metadata if there are no audios
    if (_audioItems.isEmpty) {
      return text;
    }

    final metadata = {
      'positions': {},
      'customNames': {},
    };

    for (final audioItem in _audioItems) {
      metadata['positions']![audioItem.audioPath] = {
        'x': audioItem.position.dx,
        'y': audioItem.position.dy,
      };

      if (audioItem.customName != null && audioItem.customName!.isNotEmpty) {
        metadata['customNames']![audioItem.audioPath] = audioItem.customName;
      }
    }

    final metadataString = jsonEncode(metadata);
    final encodedMetadata = base64Encode(utf8.encode(metadataString));

    // Add metadata at the end, ensuring clean format
    final cleanText = text.trim();
    return cleanText.isEmpty
        ? '[AUDIO_META:$encodedMetadata]'
        : '$cleanText\n[AUDIO_META:$encodedMetadata]';
  }

  List<String> _getAudioPaths(String text) {
    final RegExp audioRegex = RegExp(r'\[AUDIO:([^\]]+)\]');
    return audioRegex
        .allMatches(text)
        .map((match) => match.group(1)!)
        .where((path) => path.isNotEmpty)
        .toList();
  }

  void initializeFromText(String text) {
    final RegExp audioRegex = RegExp(r'\[AUDIO:([^\]]+)\]');
    final matches = audioRegex.allMatches(text);

    // Load saved metadata first
    _loadAudioMetadata(text);

    int index = 0;
    for (final match in matches) {
      final String? audioPath = match.group(1);
      if (audioPath != null && File(audioPath).existsSync()) {
        // Check if we already have this audio item from metadata loading
        bool exists = _audioItems.any((item) => item.audioPath == audioPath);

        if (!exists) {
          final audioItem = AudioItem(
            audioPath: audioPath,
            position: Offset(20, 100 + (index * 120.0)),
          );
          _audioItems.add(audioItem);
        }
        index++;
      }
    }

    onStateChanged();
  }

  List<Widget> buildAudioOverlays(BuildContext context, String text) {
    final audioPaths = _getAudioPaths(text);
    List<Widget> widgets = [];

    for (String audioPath in audioPaths) {
      if (!File(audioPath).existsSync()) continue;

      final audioItem = _audioItems.firstWhere(
        (item) => item.audioPath == audioPath,
        orElse: () =>
            AudioItem(audioPath: audioPath, position: const Offset(20, 100)),
      );

      final isSelected = _selectedAudioPath == audioPath;

      widgets.add(
        Positioned(
          left: audioItem.position.dx,
          top: audioItem.position.dy,
          child: GestureDetector(
            onTap: () {
              selectAudio(audioPath);
            },
            onPanStart: (details) {
              _selectedAudioPath = null;
              onStateChanged();
              HapticFeedback.mediumImpact();
            },
            onPanUpdate: (details) {
              final index = _audioItems
                  .indexWhere((item) => item.audioPath == audioPath);
              if (index != -1) {
                final currentPosition = _audioItems[index].position;
                final newPosition = Offset(
                  currentPosition.dx + details.delta.dx,
                  currentPosition.dy + details.delta.dy,
                );

                // Constrain to container bounds
                final constrainedX =
                    newPosition.dx.clamp(0.0, _containerSize.width - 280 - 24);
                final constrainedY = newPosition.dy.clamp(0.0, double.infinity);

                _audioItems[index].position = Offset(constrainedX, constrainedY);
                onStateChanged();
              }
            },
            onPanEnd: (details) {
              onStateChanged();
              onMetadataChanged();
              HapticFeedback.lightImpact();
            },
            onPanCancel: () {
              onStateChanged();
            },
            child: AudioPlayerWidget(
              audioPath: audioPath,
              position: audioItem.position,
              isSelected: isSelected,
              onTap: () => selectAudio(audioPath),
              onMove: (offset) {},
              onRemove: removeAudio,
              onRename: renameAudio,
              isDragging: false,
              customName: audioItem.customName,
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  void dispose() {
    _audioItems.clear();
  }
}
