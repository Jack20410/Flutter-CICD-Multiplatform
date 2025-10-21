// lib/widgets/image_overlay_manager.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ImageOverlayManager {
  final Function(String) onImageRemove;
  final VoidCallback onStateChanged;
  final VoidCallback? onMetadataChanged;
  final Map<String, Offset> _imagePositions = {};
  final Map<String, Size> _imageSizes = {};
  Size _containerSize = Size.zero;
  String? _draggedImage;
  String? _selectedImage; // Track which image is selected for resizing
  static const double maxImageWidth = 250.0;
  static const double maxImageHeight = 300.0;
  static const double minImageSize = 50.0;

  ImageOverlayManager({
    required this.onImageRemove,
    required this.onStateChanged,
    this.onMetadataChanged, // Add this parameter
  });

  void dispose() {
    // Clean up any resources if needed
  }

  void updateContainerSize(Size size) {
    _containerSize = size;
  }

  // Add method to deselect all images
  void deselectAll() {
    if (_selectedImage != null) {
      _selectedImage = null;
      onStateChanged();
    }
  }

  void initializeFromText(String text) {
    final RegExp imageRegex = RegExp(r'\[IMAGE:([^\]]+)\]');
    final matches = imageRegex.allMatches(text);

    // Load saved positions and sizes from text metadata (if exists)
    _loadImageMetadata(text);

    int index = 0;
    for (final match in matches) {
      final String? imagePath = match.group(1);
      if (imagePath != null) {
        if (!_imagePositions.containsKey(imagePath)) {
          _imagePositions[imagePath] = Offset(20, 20 + (index * 220.0));
        }
        if (!_imageSizes.containsKey(imagePath)) {
          _calculateImageSize(imagePath);
        }
        index++;
      }
    }
  }

  // Load image metadata from text (positions and sizes)
  void _loadImageMetadata(String text) {
    final RegExp metadataRegex = RegExp(r'\[IMAGE_META:([^\]]+)\]');
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
            _imagePositions[entry.key] =
                Offset(pos['x']?.toDouble() ?? 20, pos['y']?.toDouble() ?? 20);
          }
        }

        if (metadata.containsKey('sizes')) {
          final sizes = metadata['sizes'] as Map<String, dynamic>;
          for (final entry in sizes.entries) {
            final size = entry.value as Map<String, dynamic>;
            _imageSizes[entry.key] = Size(size['width']?.toDouble() ?? 200,
                size['height']?.toDouble() ?? 200);
          }
        }
      } catch (e) {
        // If metadata parsing fails, continue with default positions
      }
    }
  }

  // Save image metadata to text
  String saveImageMetadata(String text) {
    // Remove existing metadata first
    text = text.replaceAll(RegExp(r'\[IMAGE_META:[^\]]+\]\n?'), '');

    // Don't add metadata if there are no images
    if (_imagePositions.isEmpty && _imageSizes.isEmpty) {
      return text;
    }

    final metadata = {
      'positions': {},
      'sizes': {},
    };

    for (final entry in _imagePositions.entries) {
      metadata['positions']![entry.key] = {
        'x': entry.value.dx,
        'y': entry.value.dy,
      };
    }

    for (final entry in _imageSizes.entries) {
      metadata['sizes']![entry.key] = {
        'width': entry.value.width,
        'height': entry.value.height,
      };
    }

    final metadataString = jsonEncode(metadata);
    final encodedMetadata = base64Encode(utf8.encode(metadataString));

    // Add metadata at the end, ensuring clean format
    final cleanText = text.trim();
    return cleanText.isEmpty
        ? '[IMAGE_META:$encodedMetadata]'
        : '$cleanText\n[IMAGE_META:$encodedMetadata]';
  }

  Future<void> _calculateImageSize(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      if (!imageFile.existsSync()) return;

      final Uint8List bytes = await imageFile.readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;

      final double imageWidth = image.width.toDouble();
      final double imageHeight = image.height.toDouble();
      final double aspectRatio = imageWidth / imageHeight;

      Size displaySize;
      if (aspectRatio > 1) {
        if (imageWidth > maxImageWidth) {
          displaySize = Size(maxImageWidth, maxImageWidth / aspectRatio);
        } else {
          displaySize = Size(imageWidth, imageHeight);
        }
      } else {
        if (imageHeight > maxImageHeight) {
          displaySize = Size(maxImageHeight * aspectRatio, maxImageHeight);
        } else {
          displaySize = Size(imageWidth, imageHeight);
        }
      }

      final double minSize = 100.0;
      if (displaySize.width < minSize || displaySize.height < minSize) {
        if (aspectRatio > 1) {
          displaySize = Size(minSize, minSize / aspectRatio);
        } else {
          displaySize = Size(minSize * aspectRatio, minSize);
        }
      }

      _imageSizes[imagePath] = displaySize;
      onStateChanged();
    } catch (e) {
      _imageSizes[imagePath] = const Size(200, 200);
      onStateChanged();
    }
  }

  List<String> _getImagePaths(String text) {
    final RegExp imageRegex = RegExp(r'\[IMAGE:([^\]]+)\]');
    return imageRegex
        .allMatches(text)
        .map((match) => match.group(1)!)
        .where((path) => path.isNotEmpty)
        .toList();
  }

  void _openImageViewer(
      BuildContext context, String selectedImagePath, String text) {
    final imagePaths = _getImagePaths(text);
    final initialIndex = imagePaths.indexOf(selectedImagePath);

    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => ImageViewerScreen(
          imagePaths: imagePaths,
          initialIndex: initialIndex >= 0 ? initialIndex : 0,
          onImageRemove: (imagePath) {
            onImageRemove(imagePath);
            _imagePositions.remove(imagePath);
            _imageSizes.remove(imagePath);
            if (_selectedImage == imagePath) {
              _selectedImage = null;
            }
            onStateChanged();
          },
        ),
      ),
    );
  }

  void _selectImage(String imagePath) {
    if (_selectedImage == imagePath) {
      _selectedImage = null; // Deselect if already selected
    } else {
      _selectedImage = imagePath;
    }
    onStateChanged();
  }

  void _resizeImage(String imagePath, Size newSize,
      {bool maintainAspectRatio = false}) {
    final currentSize = _imageSizes[imagePath] ?? const Size(200, 200);
    Size constrainedSize = newSize;

    if (maintainAspectRatio) {
      final aspectRatio = currentSize.width / currentSize.height;
      if (newSize.width / aspectRatio != newSize.height) {
        final widthRatio = newSize.width / currentSize.width;
        final heightRatio = newSize.height / currentSize.height;

        if (widthRatio.abs() > heightRatio.abs()) {
          constrainedSize = Size(newSize.width, newSize.width / aspectRatio);
        } else {
          constrainedSize = Size(newSize.height * aspectRatio, newSize.height);
        }
      }
    }

    constrainedSize = Size(
      constrainedSize.width.clamp(minImageSize, maxImageWidth),
      constrainedSize.height.clamp(minImageSize, maxImageHeight),
    );

    _imageSizes[imagePath] = constrainedSize;
    onStateChanged();
    onMetadataChanged?.call(); // Trigger metadata save
  }

  List<Widget> buildImageOverlays(BuildContext context, String text) {
    final imagePaths = _getImagePaths(text);
    List<Widget> widgets = [];

    for (String imagePath in imagePaths) {
      final position = _imagePositions[imagePath] ?? const Offset(20, 20);
      final imageSize = _imageSizes[imagePath] ?? const Size(200, 200);
      final isSelected = _selectedImage == imagePath;

      widgets.add(
        Positioned(
          left: position.dx,
          top: position.dy,
          child: GestureDetector(
            onTap: () {
              _selectImage(imagePath);
            },
            onDoubleTap: () => _openImageViewer(context, imagePath, text),
            onPanStart: (details) {
              _draggedImage = imagePath;
              _selectedImage = null;
              onStateChanged();
              HapticFeedback.mediumImpact();
            },
            onPanUpdate: (details) {
              if (_draggedImage == imagePath) {
                final currentPosition = _imagePositions[imagePath] ?? position;
                final newPosition = Offset(
                  currentPosition.dx + details.delta.dx,
                  currentPosition.dy + details.delta.dy,
                );

                // Constrain to container bounds
                final imageWidth = imageSize.width + 16;
                final constrainedX = newPosition.dx.clamp(
                    0.0, _containerSize.width - imageWidth - 24);
                final constrainedY = newPosition.dy.clamp(0.0, double.infinity);

                _imagePositions[imagePath] = Offset(constrainedX, constrainedY);
                onStateChanged();
              }
            },
            onPanEnd: (details) {
              _draggedImage = null;
              onStateChanged();
              onMetadataChanged?.call();
              HapticFeedback.lightImpact();
            },
            onPanCancel: () {
              _draggedImage = null;
              onStateChanged();
            },
            child: _buildImageWidget(context, imagePath, imageSize,
                isSelected: isSelected, isDragging: _draggedImage == imagePath),
          ),
        ),
      );

      if (isSelected) {
        widgets.addAll(
            _buildResizeHandles(context, imagePath, position, imageSize));
      }
    }

    return widgets;
  }

  List<Widget> _buildResizeHandles(
      BuildContext context, String imagePath, Offset position, Size imageSize) {
    final handles = <Widget>[];
    final handleSize = 12.0;
    final imageWidth = imageSize.width + 16;
    final imageHeight = imageSize.height + 16;

    // Corner handles (maintain aspect ratio)
    final corners = [
      {
        'pos':
            Offset(position.dx - handleSize / 2, position.dy - handleSize / 2),
        'cursor': SystemMouseCursors.resizeUpLeft,
        'index': 0
      },
      {
        'pos': Offset(position.dx + imageWidth - handleSize / 2,
            position.dy - handleSize / 2),
        'cursor': SystemMouseCursors.resizeUpRight,
        'index': 1
      },
      {
        'pos': Offset(position.dx - handleSize / 2,
            position.dy + imageHeight - handleSize / 2),
        'cursor': SystemMouseCursors.resizeDownLeft,
        'index': 2
      },
      {
        'pos': Offset(position.dx + imageWidth - handleSize / 2,
            position.dy + imageHeight - handleSize / 2),
        'cursor': SystemMouseCursors.resizeDownRight,
        'index': 3
      },
    ];

    // Edge handles (free resize)
    final edges = [
      {
        'pos': Offset(position.dx + imageWidth / 2 - handleSize / 2,
            position.dy - handleSize / 2),
        'cursor': SystemMouseCursors.resizeUp,
        'type': 'top'
      },
      {
        'pos': Offset(position.dx + imageWidth - handleSize / 2,
            position.dy + imageHeight / 2 - handleSize / 2),
        'cursor': SystemMouseCursors.resizeRight,
        'type': 'right'
      },
      {
        'pos': Offset(position.dx + imageWidth / 2 - handleSize / 2,
            position.dy + imageHeight - handleSize / 2),
        'cursor': SystemMouseCursors.resizeDown,
        'type': 'bottom'
      },
      {
        'pos': Offset(position.dx - handleSize / 2,
            position.dy + imageHeight / 2 - handleSize / 2),
        'cursor': SystemMouseCursors.resizeLeft,
        'type': 'left'
      },
    ];

    // Add corner handles
    for (final corner in corners) {
      final pos = corner['pos'] as Offset;
      final cursor = corner['cursor'] as MouseCursor;
      final index = corner['index'] as int;

      handles.add(
        Positioned(
          left: pos.dx,
          top: pos.dy,
          child: MouseRegion(
            cursor: cursor,
            child: GestureDetector(
              onPanUpdate: (details) {
                final currentSize =
                    _imageSizes[imagePath] ?? const Size(200, 200);
                final deltaMultiplier = 1.0;
                Size newSize;

                switch (index) {
                  case 0: // Top-left
                    newSize = Size(
                      currentSize.width - (details.delta.dx * deltaMultiplier),
                      currentSize.height - (details.delta.dy * deltaMultiplier),
                    );
                    // Also adjust position to keep bottom-right corner fixed
                    final currentPosition =
                        _imagePositions[imagePath] ?? const Offset(20, 20);
                    _imagePositions[imagePath] = Offset(
                      currentPosition.dx + (details.delta.dx * deltaMultiplier),
                      currentPosition.dy + (details.delta.dy * deltaMultiplier),
                    );
                    break;
                  case 1: // Top-right
                    newSize = Size(
                      currentSize.width + (details.delta.dx * deltaMultiplier),
                      currentSize.height - (details.delta.dy * deltaMultiplier),
                    );
                    // Adjust Y position to keep bottom edge fixed
                    final currentPosition =
                        _imagePositions[imagePath] ?? const Offset(20, 20);
                    _imagePositions[imagePath] = Offset(
                      currentPosition.dx,
                      currentPosition.dy + (details.delta.dy * deltaMultiplier),
                    );
                    break;
                  case 2: // Bottom-left
                    newSize = Size(
                      currentSize.width - (details.delta.dx * deltaMultiplier),
                      currentSize.height + (details.delta.dy * deltaMultiplier),
                    );
                    // Adjust X position to keep right edge fixed
                    final currentPosition =
                        _imagePositions[imagePath] ?? const Offset(20, 20);
                    _imagePositions[imagePath] = Offset(
                      currentPosition.dx + (details.delta.dx * deltaMultiplier),
                      currentPosition.dy,
                    );
                    break;
                  case 3: // Bottom-right
                    newSize = Size(
                      currentSize.width + (details.delta.dx * deltaMultiplier),
                      currentSize.height + (details.delta.dy * deltaMultiplier),
                    );
                    // Position stays the same for bottom-right resize
                    break;
                  default:
                    newSize = currentSize;
                }

                _resizeImage(imagePath, newSize, maintainAspectRatio: true);
              },
              child: Container(
                width: handleSize,
                height: handleSize,
                decoration: BoxDecoration(
                  color: CupertinoColors.activeBlue,
                  shape: BoxShape.circle,
                  border: Border.all(color: CupertinoColors.white, width: 1),
                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: CupertinoColors.black.withOpacity(0.3),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Add edge handles
    for (final edge in edges) {
      final pos = edge['pos'] as Offset;
      final cursor = edge['cursor'] as MouseCursor;
      final type = edge['type'] as String;

      handles.add(
        Positioned(
          left: pos.dx,
          top: pos.dy,
          child: MouseRegion(
            cursor: cursor,
            child: GestureDetector(
              onPanUpdate: (details) {
                final currentSize =
                    _imageSizes[imagePath] ?? const Size(200, 200);
                Size newSize;

                switch (type) {
                  case 'top':
                    newSize = Size(currentSize.width,
                        currentSize.height - details.delta.dy);
                    break;
                  case 'right':
                    newSize = Size(currentSize.width + details.delta.dx,
                        currentSize.height);
                    break;
                  case 'bottom':
                    newSize = Size(currentSize.width,
                        currentSize.height + details.delta.dy);
                    break;
                  case 'left':
                    newSize = Size(currentSize.width - details.delta.dx,
                        currentSize.height);
                    break;
                  default:
                    newSize = currentSize;
                }

                _resizeImage(imagePath, newSize, maintainAspectRatio: false);
              },
              child: Container(
                width: handleSize,
                height: handleSize,
                decoration: BoxDecoration(
                  color: CupertinoColors.activeBlue,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: CupertinoColors.white, width: 1),
                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: CupertinoColors.black.withOpacity(0.3),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return handles;
  }

  Widget _buildImageWidget(
      BuildContext context, String imagePath, Size imageSize,
      {bool isDragging = false, bool isSelected = false}) {
    return Container(
      width: imageSize.width + 16,
      height: imageSize.height + 16,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? CupertinoColors.activeBlue.resolveFrom(context)
              : _draggedImage == imagePath
                  ? CupertinoColors.activeBlue.resolveFrom(context)
                  : CupertinoColors.separator.resolveFrom(context),
          width: isSelected ? 2 : (_draggedImage == imagePath ? 2 : 1),
          style: isSelected ? BorderStyle.solid : BorderStyle.solid,
        ),
        boxShadow: isDragging
            ? [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: CupertinoColors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.file(
              File(imagePath),
              width: imageSize.width,
              height: imageSize.height,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: imageSize.width,
                  height: imageSize.height,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey5.resolveFrom(context),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.photo,
                        size: (imageSize.width * 0.2).clamp(20.0, 40.0),
                        color: CupertinoColors.systemGrey,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Image\nunavailable',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: (imageSize.width * 0.06).clamp(10.0, 14.0),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Selection indicator overlay
          if (isSelected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: CupertinoColors.activeBlue.resolveFrom(context),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
              ),
            ),

          if (!isDragging && !isSelected)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _imagePositions.remove(imagePath);
                  _imageSizes.remove(imagePath);
                  if (_selectedImage == imagePath) {
                    _selectedImage = null;
                  }
                  onStateChanged();
                  onImageRemove(imagePath);
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: CupertinoColors.destructiveRed,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: CupertinoColors.black.withOpacity(0.3),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Icon(
                    CupertinoIcons.xmark,
                    color: CupertinoColors.white,
                    size: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Image Viewer Screen remains the same as before...
class ImageViewerScreen extends StatefulWidget {
  final List<String> imagePaths;
  final int initialIndex;
  final Function(String) onImageRemove;

  const ImageViewerScreen({
    super.key,
    required this.imagePaths,
    required this.initialIndex,
    required this.onImageRemove,
  });

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  List<String> _currentImagePaths = [];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _currentImagePaths = List.from(widget.imagePaths);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNext() {
    if (_currentIndex < _currentImagePaths.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _removeCurrentImage() {
    if (_currentImagePaths.isNotEmpty) {
      final imageToRemove = _currentImagePaths[_currentIndex];

      setState(() {
        _currentImagePaths.removeAt(_currentIndex);

        if (_currentImagePaths.isEmpty) {
          Navigator.of(context).pop();
        } else {
          if (_currentIndex >= _currentImagePaths.length) {
            _currentIndex = _currentImagePaths.length - 1;
          }

          _pageController = PageController(initialPage: _currentIndex);
        }
      });

      widget.onImageRemove(imageToRemove);

      if (_currentImagePaths.isEmpty) {
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentImagePaths.isEmpty) {
      return const SizedBox.shrink();
    }

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: _currentImagePaths.length,
            itemBuilder: (context, index) {
              return Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.file(
                    File(_currentImagePaths[index]),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.photo,
                              size: 50,
                              color: CupertinoColors.systemGrey,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Image unavailable',
                              style: TextStyle(
                                color: CupertinoColors.systemGrey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),

          // Navigation buttons
          if (_currentImagePaths.length > 1) ...[
            // Left navigation button
            if (_currentIndex > 0)
              Positioned(
                left: 20,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _goToPrevious,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        // ignore: deprecated_member_use
                        color: CupertinoColors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          // ignore: deprecated_member_use
                          color: CupertinoColors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        CupertinoIcons.chevron_left,
                        color: CupertinoColors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),

            // Right navigation button
            if (_currentIndex < _currentImagePaths.length - 1)
              Positioned(
                right: 20,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _goToNext,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        // ignore: deprecated_member_use
                        color: CupertinoColors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          // ignore: deprecated_member_use
                          color: CupertinoColors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        CupertinoIcons.chevron_right,
                        color: CupertinoColors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
          ],

          // Top bar with controls
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    // ignore: deprecated_member_use
                    CupertinoColors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        // ignore: deprecated_member_use
                        color: CupertinoColors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        CupertinoIcons.xmark,
                        color: CupertinoColors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  if (_currentImagePaths.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        // ignore: deprecated_member_use
                        color: CupertinoColors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_currentIndex + 1} of ${_currentImagePaths.length}',
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      showCupertinoDialog(
                        context: context,
                        builder: (context) => CupertinoAlertDialog(
                          title: const Text('Remove Image'),
                          content: const Text(
                              'Are you sure you want to remove this image from the note?'),
                          actions: [
                            CupertinoDialogAction(
                              child: const Text('Cancel'),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            CupertinoDialogAction(
                              isDestructiveAction: true,
                              child: const Text('Remove'),
                              onPressed: () {
                                Navigator.of(context).pop();
                                _removeCurrentImage();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: CupertinoColors.destructiveRed.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        CupertinoIcons.trash,
                        color: CupertinoColors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double borderRadius;
  final double dashWidth;
  final double dashSpace;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 2,
    this.borderRadius = 8,
    this.dashWidth = 8,
    this.dashSpace = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2,
            size.width - strokeWidth, size.height - strokeWidth),
        Radius.circular(borderRadius),
      ));

    final pathMetrics = path.computeMetrics();
    for (final pathMetric in pathMetrics) {
      double distance = 0;
      while (distance < pathMetric.length) {
        final segment = pathMetric.extractPath(
          distance,
          (distance + dashWidth).clamp(0, pathMetric.length),
        );
        canvas.drawPath(segment, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
