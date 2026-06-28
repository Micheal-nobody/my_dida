import 'package:flutter/material.dart';
import 'package:my_dida/core/themes/color_constants.dart';
import 'package:my_dida/core/themes/theme_provider.dart';

class SearchHighlightedText extends StatelessWidget {
  const SearchHighlightedText({
    required this.text,
    required this.highlight,
    super.key,
    this.style,
    this.highlightStyle,
  });
  final String text;
  final String highlight;
  final TextStyle? style;
  final TextStyle? highlightStyle;

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.theme;
    if (highlight.isEmpty ||
        !text.toLowerCase().contains(highlight.toLowerCase())) {
      return Text(text, style: style);
    }

    final List<TextSpan> spans = [];
    final lowercaseText = text.toLowerCase();
    final lowercaseHighlight = highlight.toLowerCase();

    int start = 0;
    int indexOfHighlight;

    while ((indexOfHighlight = lowercaseText.indexOf(
          lowercaseHighlight,
          start,
        )) !=
        -1) {
      if (indexOfHighlight > start) {
        spans.add(TextSpan(text: text.substring(start, indexOfHighlight)));
      }
      spans.add(
        TextSpan(
          text: text.substring(
            indexOfHighlight,
            indexOfHighlight + highlight.length,
          ),
          style:
              highlightStyle ??
              const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
        ),
      );
      start = indexOfHighlight + highlight.length;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return RichText(
      text: TextSpan(
        style:
            style ??
            TextStyle(color: colorTheme.textPrimary, fontSize: 16),
        children: spans,
      ),
    );
  }
}
