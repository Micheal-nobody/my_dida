import 'package:flutter/material.dart';

class CalendarTimeColumn extends StatelessWidget {
  const CalendarTimeColumn({super.key});

  @override
  Widget build(BuildContext context) {
    List<String> timeLabels = [];
    for (int i = 1; i <= 23; i++) {
      timeLabels.add(i.toString().padLeft(2, '0'));
    }
    timeLabels.add('00');

    return SizedBox(
      width: 60,
      height: 1440, // 固定高度：24小时 * 60px
      child: Column(
        children: timeLabels.map((time) {
          bool isHighlighted = time == '08' || time == '09';

          return Container(
            height: 60,
            decoration: BoxDecoration(
              color: isHighlighted
                  ? Colors.orange.withValues(alpha: 0.1)
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                time,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
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
