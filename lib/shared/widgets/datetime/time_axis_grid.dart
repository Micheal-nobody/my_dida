import 'package:flutter/material.dart';

class TimeAxisGrid extends StatelessWidget {
  const TimeAxisGrid({
    super.key,
    this.hourCount = 24,
    this.hourHeight = 60,
    this.lineColor,
    this.lineWidth = 0.5,
  });

  final int hourCount;
  final double hourHeight;
  final Color? lineColor;
  final double lineWidth;

  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(
      hourCount,
      (index) => Container(
        height: hourHeight,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: lineColor ?? Colors.grey.withValues(alpha: 0.2),
              width: lineWidth,
            ),
          ),
        ),
      ),
    ),
  );
}
