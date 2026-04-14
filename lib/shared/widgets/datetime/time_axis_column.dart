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
    this.previewTime,
  });

  final double width;
  final double hourHeight;
  final int hourCount;
  final Set<int> highlightedHours;
  final Color highlightColor;
  final Color? labelColor;
  final TextStyle? labelStyle;
  final DateTime? previewTime;

  String _formatPreviewTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final labels = List<String>.generate(
      hourCount,
      (index) => index.toString().padLeft(2, '0'),
    );
    final totalHeight = hourHeight * hourCount;
    final previewMinuteOfDay = previewTime == null
        ? null
        : previewTime!.hour * 60 + previewTime!.minute;
    final previewTop = previewMinuteOfDay == null
        ? null
        : (previewMinuteOfDay / 60) * hourHeight;
    final previewLineTop = previewTop == null
        ? null
        : (previewTop - 1).clamp(0.0, totalHeight - 2).toDouble();
    const previewBadgeHeight = 22.0;
    final previewBadgeTop = previewTop == null
        ? null
        : (previewTop - (previewBadgeHeight / 2))
              .clamp(0.0, totalHeight - previewBadgeHeight)
              .toDouble();

    return SizedBox(
      width: width,
      height: totalHeight,
      child: Stack(
        children: [
          Column(
            children: labels.asMap().entries.map((entry) {
              final hour = entry.key;
              final time = entry.value;
              final isHighlighted = highlightedHours.contains(hour);

              return Container(
                height: hourHeight,
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? highlightColor.withValues(alpha: 0.1)
                      : null,
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
          if (previewLineTop != null && previewBadgeTop != null) ...[
            Positioned(
              left: width - 12,
              right: 0,
              top: previewLineTop,
              child: Container(height: 2, color: highlightColor),
            ),
            Positioned(
              left: 4,
              right: 6,
              top: previewBadgeTop,
              child: IgnorePointer(
                child: Container(
                  height: previewBadgeHeight,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: highlightColor,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: highlightColor.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    _formatPreviewTime(previewTime!),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
