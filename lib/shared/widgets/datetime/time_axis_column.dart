import 'package:flutter/material.dart';

class TimeAxisColumn extends StatelessWidget {
  const TimeAxisColumn({
    super.key,
    this.width = 60,
    this.hourHeight = 60,
    this.hourCount = 24,
    this.highlightedHours = const {8, 9},
    this.highlightColor = Colors.orange,
    this.labelColor,
    this.labelStyle,
  });

  final double width;
  final double hourHeight;
  final int hourCount;
  final Set<int> highlightedHours;
  final Color highlightColor;
  final Color? labelColor;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final labels = List<String>.generate(
      hourCount,
      (index) => index.toString().padLeft(2, '0'),
    );

    return SizedBox(
      width: width,
      height: hourHeight * hourCount,
      child: Column(
        children: labels.asMap().entries.map((entry) {
          final hour = entry.key;
          final time = entry.value;
          final isHighlighted = highlightedHours.contains(hour);

          return Container(
            height: hourHeight,
            decoration: BoxDecoration(
              color: isHighlighted ? highlightColor.withValues(alpha: 0.1) : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                time,
                style:
                    labelStyle ??
                    TextStyle(
                      fontSize: 14,
                      color: labelColor ?? Colors.grey[600],
                      fontWeight: isHighlighted
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
