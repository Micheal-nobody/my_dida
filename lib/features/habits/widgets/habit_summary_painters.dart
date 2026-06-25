import 'package:flutter/material.dart';

class WeekBarChartPainter extends CustomPainter {
  final List<double> rates;

  const WeekBarChartPainter({required this.rates});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final stepX = width / 7;

    final bgPaint = Paint()
      ..color = Colors.grey.shade100
      ..style = PaintingStyle.fill;

    final fillPaint = Paint()
      ..color = Colors.green.shade300
      ..style = PaintingStyle.fill;

    final activeFillPaint = Paint()
      ..color = Colors.green.shade500
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final weekdays = ['一', '二', '三', '四', '五', '六', '日'];

    for (int i = 0; i < 7; i++) {
      final double x = i * stepX + (stepX - 22) / 2;
      final double maxBarHeight = height - 30;

      // 绘制背景圆角矩形
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 10, 22, maxBarHeight),
          const Radius.circular(4),
        ),
        bgPaint,
      );

      // 绘制达成率填充高度
      final rate = rates[i];
      if (rate > 0) {
        final barHeight = maxBarHeight * rate;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, 10 + (maxBarHeight - barHeight), 22, barHeight),
            const Radius.circular(4),
          ),
          rate >= 0.8 ? activeFillPaint : fillPaint,
        );
      }

      // 绘制星期文字
      textPainter
        ..text = TextSpan(
          text: weekdays[i],
          style: const TextStyle(color: Colors.grey, fontSize: 11),
        )
        ..layout()
        ..paint(
          canvas,
          Offset(i * stepX + (stepX - textPainter.width) / 2, height - 16),
        );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class HeatmapGridPainter extends CustomPainter {
  final List<int> counts;

  const HeatmapGridPainter({required this.counts});

  @override
  void paint(Canvas canvas, Size size) {
    const double sizeBox = 26;
    const double spacing = 6;

    // 绘制 5 列 x 7 行 (代表 35 天)
    // 每一列是一个星期的 7 天
    for (int col = 0; col < 5; col++) {
      for (int row = 0; row < 7; row++) {
        final index = col * 7 + row;
        if (index >= counts.length) continue;

        final count = counts[index];
        Color color = Colors.grey.shade100;
        if (count > 0) {
          if (count == 1) {
            color = Colors.orange.shade100;
          } else if (count == 2) {
            color = Colors.orange.shade300;
          } else if (count <= 4) {
            color = Colors.orange.shade500;
          } else {
            color = Colors.orange.shade800;
          }
        }

        final paint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;

        final double x = col * (sizeBox + spacing) + 20;
        final double y = row * (sizeBox + spacing) + 10;

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, sizeBox, sizeBox),
            const Radius.circular(4),
          ),
          paint,
        );
      }
    }

    // 绘制横向行首的星期缩写，比如周一、周三、周五
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final weekdayLabels = ['一', '', '三', '', '五', '', '日'];
    for (int r = 0; r < 7; r++) {
      if (weekdayLabels[r].isNotEmpty) {
        textPainter
          ..text = TextSpan(
            text: weekdayLabels[r],
            style: const TextStyle(color: Colors.grey, fontSize: 9),
          )
          ..layout()
          ..paint(
            canvas,
            Offset(
              2,
              r * (sizeBox + spacing) + 10 + (sizeBox - textPainter.height) / 2,
            ),
          );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
