import 'package:flutter/material.dart';

class CalendarEntryCard extends StatelessWidget {
  const CalendarEntryCard({
    required this.text,
    required this.backgroundColor,
    required this.onPressed,
    this.margin = EdgeInsets.zero,
    this.padding = EdgeInsets.zero,
    this.borderRadius = 4,
    this.textStyle,
    this.alignment,
    this.opacity = 1,
    this.useFittedBox = false,
    this.borderColor,
    super.key,
  });

  final String text;
  final Color backgroundColor;
  final VoidCallback onPressed;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final TextStyle? textStyle;
  final AlignmentGeometry? alignment;
  final double opacity;
  final bool useFittedBox;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final child = Text(
      text,
      style:
          textStyle ??
          const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );

    return GestureDetector(
      onTap: onPressed,
      child: Opacity(
        opacity: opacity,
        child: Container(
          margin: margin,
          padding: padding,
          alignment: alignment,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: borderColor == null
                ? null
                : Border.all(color: borderColor!),
          ),
          child: useFittedBox
              ? FittedBox(fit: BoxFit.scaleDown, child: child)
              : child,
        ),
      ),
    );
  }
}
