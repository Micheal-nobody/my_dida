import 'package:flutter/material.dart';
import 'package:my_dida/core/themes/theme_provider.dart';

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
  Widget build(BuildContext context) {
    final colorTheme = context.theme;
    return Column(
      children: List.generate(
        hourCount,
        (index) => Container(
          height: hourHeight,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: lineColor ?? colorTheme.divider.withValues(alpha: 0.2),
                width: lineWidth,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
