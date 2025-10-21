import 'package:flutter/cupertino.dart';

class HighlightedText extends StatelessWidget {
  final String text;
  final String searchQuery;
  final TextStyle? textStyle;
  final TextStyle? highlightStyle;

  const HighlightedText({
    super.key,
    required this.text,
    required this.searchQuery,
    this.textStyle,
    this.highlightStyle,
  });

  // Helper method to clean text from metadata tags
  String _cleanText(String text) {
    // Remove all image and audio tags and metadata
    return text
        .replaceAll(RegExp(r'\[IMAGE:[^\]]+\]\n?'), '')
        .replaceAll(RegExp(r'\[IMAGE_META:[^\]]+\]\n?'), '')
        .replaceAll(RegExp(r'\[AUDIO:[^\]]+\]\n?'), '') // Add this
        .replaceAll(RegExp(r'\[AUDIO_META:[^\]]+\]\n?'), '')
        .replaceAll(RegExp(r'\[TODO_META:[^\]]+\]\n?'), '')
        .trim(); // Remove extra whitespace
  }

  TextStyle get _titleStyle => const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        height: 1.5,
      );

  TextSpan _buildTitleSpan(String title) {
    return TextSpan(
      text: title,
      style: _titleStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Clean the text before searching
    final String cleanText = _cleanText(text);

    if (cleanText.isEmpty) {
      return Text(cleanText, style: textStyle);
    }

    // Split into title and content
    final lines = cleanText.split('\n');
    final title = lines.isNotEmpty ? lines[0] : '';
    final content = lines.length > 1 ? lines.sublist(1).join('\n') : '';

    if (searchQuery.isEmpty) {
      return RichText(
        text: TextSpan(
          children: [
            _buildTitleSpan(title),
            if (content.isNotEmpty) ...[
              const TextSpan(text: '\n'),
              TextSpan(text: content, style: textStyle),
            ],
          ],
        ),
      );
    }

    // Handle search highlighting with title styling
    final List<TextSpan> titleSpans = [];
    final List<TextSpan> contentSpans = [];

    // Process title
    final String lowerCaseTitle = title.toLowerCase();
    final String lowerCaseQuery = searchQuery.toLowerCase();
    int titleStart = 0;
    int titleIndex = lowerCaseTitle.indexOf(lowerCaseQuery);

    while (titleIndex != -1) {
      if (titleIndex > titleStart) {
        titleSpans.add(TextSpan(
          text: title.substring(titleStart, titleIndex),
          style: _titleStyle,
        ));
      }

      titleSpans.add(TextSpan(
        text: title.substring(titleIndex, titleIndex + searchQuery.length),
        style: highlightStyle?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.5,
            ) ??
            TextStyle(
              backgroundColor: CupertinoColors.systemYellow.withOpacity(0.3),
              color: CupertinoColors.label,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.5,
            ),
      ));

      titleStart = titleIndex + searchQuery.length;
      titleIndex = lowerCaseTitle.indexOf(lowerCaseQuery, titleStart);
    }

    if (titleStart < title.length) {
      titleSpans.add(TextSpan(
        text: title.substring(titleStart),
        style: _titleStyle,
      ));
    }

    // Process content
    if (content.isNotEmpty) {
      final String lowerCaseContent = content.toLowerCase();
      int contentStart = 0;
      int contentIndex = lowerCaseContent.indexOf(lowerCaseQuery);

      while (contentIndex != -1) {
        if (contentIndex > contentStart) {
          contentSpans.add(TextSpan(
            text: content.substring(contentStart, contentIndex),
            style: textStyle,
          ));
        }

        contentSpans.add(TextSpan(
          text: content.substring(
              contentIndex, contentIndex + searchQuery.length),
          style: highlightStyle ??
              TextStyle(
                backgroundColor: CupertinoColors.systemYellow.withOpacity(0.3),
                color: CupertinoColors.label,
                fontWeight: FontWeight.bold,
              ),
        ));

        contentStart = contentIndex + searchQuery.length;
        contentIndex = lowerCaseContent.indexOf(lowerCaseQuery, contentStart);
      }

      if (contentStart < content.length) {
        contentSpans.add(TextSpan(
          text: content.substring(contentStart),
          style: textStyle,
        ));
      }
    }

    return RichText(
      text: TextSpan(
        children: [
          ...titleSpans,
          if (content.isNotEmpty) ...[
            const TextSpan(text: '\n'),
            ...contentSpans,
          ],
        ],
      ),
    );
  }
}
