import 'dart:math';

import 'package:flutter/material.dart';
import 'package:my_dida/model/entity/tomato_record.dart';

// ==========================================
// 1. 时段分布图 (24小时柱状图)
// ==========================================
class TomatoHourlyDistributionChart extends StatelessWidget {
  const TomatoHourlyDistributionChart({required this.records, super.key});

  final List<TomatoRecord> records;

  @override
  Widget build(BuildContext context) {
    // 将 24 小时划分为 6 个时段，每个时段 4 小时
    // 0: 00-04, 1: 04-08, 2: 08-12, 3: 12-16, 4: 16-20, 5: 20-24
    final List<int> hourlyMinutes = List.filled(6, 0);
    for (final r in records) {
      if (!r.isCompleted) continue;
      final hour = r.startTime.hour;
      final index = (hour / 4).floor().clamp(0, 5);
      hourlyMinutes[index] += r.durationMinutes;
    }

    final maxVal = hourlyMinutes.reduce(max);
    final maxLimit = maxVal == 0 ? 30 : maxVal;

    final labels = ['00-04', '04-08', '08-12', '12-16', '16-20', '20-24'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '专注时段分布 (分钟)',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(6, (i) {
                final minutes = hourlyMinutes[i];
                final percent = minutes / maxLimit;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (minutes > 0)
                        Text(
                          '$minutes',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Container(
                        height: (percent * 80).clamp(4.0, 80.0),
                        width: 16,
                        decoration: BoxDecoration(
                          color: minutes > 0
                              ? Colors.redAccent.shade200
                              : Colors.grey.shade200,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        labels[i],
                        style: const TextStyle(fontSize: 9, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 2. 任务/清单专注占比环形图
// ==========================================
class TomatoCategoryRatioChart extends StatelessWidget {
  const TomatoCategoryRatioChart({required this.records, super.key});

  final List<TomatoRecord> records;

  @override
  Widget build(BuildContext context) {
    // 统计各清单(分类)的专注时长
    final Map<String, int> categoryMap = {};
    int totalMinutes = 0;

    for (final r in records) {
      if (!r.isCompleted) continue;
      final name = r.categoryName ?? '默认收集箱';
      categoryMap[name] = (categoryMap[name] ?? 0) + r.durationMinutes;
      totalMinutes += r.durationMinutes;
    }

    final list = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 配色方案
    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
    ];

    if (totalMinutes == 0) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Text('暂无分类专注数据', style: TextStyle(color: Colors.grey)),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '分类专注分布',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // 环形图区域
              SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: _DonutChartPainter(
                    data: list.map((e) => e.value.toDouble()).toList(),
                    colors: List.generate(
                      list.length,
                      (i) => colors[i % colors.length],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '总专注',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        Text(
                          '$totalMinutes',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          '分钟',
                          style: TextStyle(fontSize: 9, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // 图例与排行列表
              Expanded(
                child: Column(
                  children: List.generate(list.length, (i) {
                    final item = list[i];
                    final color = colors[i % colors.length];
                    final pct = (item.value / totalMinutes * 100)
                        .toStringAsFixed(1);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.key,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${item.value}分 ($pct%)',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter({required this.data, required this.colors});

  final List<double> data;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final double total = data.reduce((a, b) => a + b);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    const double strokeWidth = 14;

    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );
    double startAngle = -pi / 2; // 从 12 点钟方向开始

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < data.length; i++) {
      final sweepAngle = (data[i] / total) * 2 * pi;
      paint.color = colors[i];

      // 使用小缝隙防止圆弧粘连
      canvas.drawArc(rect, startAngle + 0.02, sweepAngle - 0.04, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ==========================================
// 3. 专注趋势折线图
// ==========================================
class TomatoTrendChart extends StatelessWidget {
  const TomatoTrendChart({
    required this.records,
    required this.daysCount,
    super.key,
  });

  final List<TomatoRecord> records;
  final int daysCount; // 显示最近多少天的数据

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final List<int> dailyMinutes = List.filled(daysCount, 0);
    final List<String> labels = [];

    for (int i = daysCount - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      // 匹配日期数据
      int minutes = 0;
      for (final r in records) {
        if (!r.isCompleted) continue;
        if (r.startTime.year == date.year &&
            r.startTime.month == date.month &&
            r.startTime.day == date.day) {
          minutes += r.durationMinutes;
        }
      }
      dailyMinutes[daysCount - 1 - i] = minutes;

      // 日期 label (如 "06-19" 或周几)
      if (daysCount == 7) {
        final weekdayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
        labels.add(weekdayNames[date.weekday - 1]);
      } else {
        // 月视图只标示关键刻度以防重叠
        if (i % 5 == 0 || i == 0 || i == daysCount - 1) {
          labels.add('${date.month}/${date.day}');
        } else {
          labels.add('');
        }
      }
    }

    final maxVal = dailyMinutes.reduce(max);
    final maxLimit = maxVal == 0 ? 60 : maxVal;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '最近 $daysCount 天专注趋势 (分钟)',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: CustomPaint(
              size: const Size(double.infinity, 100),
              painter: _LineChartPainter(
                data: dailyMinutes.map((e) => e.toDouble()).toList(),
                maxLimit: maxLimit.toDouble(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              daysCount,
              (i) => Expanded(
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 8, color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({required this.data, required this.maxLimit});

  final List<double> data;
  final double maxLimit;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final width = size.width;
    final height = size.height;
    final stepX = width / (data.length - 1);

    final linePaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()..style = PaintingStyle.fill;

    final pointPaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;

    final pointOuterPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    final fillPath = Path();

    // 渐变阴影
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.redAccent.withValues(alpha: 0.3),
        Colors.redAccent.withValues(alpha: 0.0),
      ],
    );
    fillPaint.shader = gradient.createShader(
      Rect.fromLTWH(0, 0, width, height),
    );

    final points = <Offset>[];

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      // y 轴倒置，底部是 0，顶部是最大值，留出上边距 10 像素，下边距 10 像素
      final valPercent = data[i] / maxLimit;
      final y = height - (valPercent * (height - 20) + 10);
      final pt = Offset(x, y);
      points.add(pt);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath
          ..moveTo(x, height)
          ..lineTo(x, y);
      } else {
        // 使用二阶贝塞尔曲线，使折线圆滑一些
        final prevPt = points[i - 1];
        final controlPt = Offset(
          (prevPt.dx + pt.dx) / 2,
          (prevPt.dy + pt.dy) / 2,
        );
        path.quadraticBezierTo(
          prevPt.dx,
          prevPt.dy,
          controlPt.dx,
          controlPt.dy,
        );

        fillPath.quadraticBezierTo(
          prevPt.dx,
          prevPt.dy,
          controlPt.dx,
          controlPt.dy,
        );
      }

      if (i == data.length - 1) {
        path.lineTo(x, y);
        fillPath
          ..lineTo(x, y)
          ..lineTo(x, height)
          ..close();
      }
    }

    // 绘制阴影填充
    canvas
      ..drawPath(fillPath, fillPaint)
      // 绘制折线
      ..drawPath(path, linePaint);

    // 绘制数据点小红圈
    for (final pt in points) {
      canvas
        ..drawCircle(pt, 4.5, pointPaint)
        ..drawCircle(pt, 4.5, pointOuterPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
