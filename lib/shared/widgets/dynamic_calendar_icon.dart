import 'package:flutter/material.dart';

/// 动态显示当前日期（天数）的日历图标
class DynamicCalendarIcon extends StatelessWidget {
  const DynamicCalendarIcon({super.key, this.date});
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    // 获取当前 IconTheme 的颜色，以适配 BottomNavigationBar 的 active/inactive 颜色
    final themeColor =
        IconTheme.of(context).color ?? Theme.of(context).primaryColor;
    final currentDate = date ?? DateTime.now();
    final dayStr = currentDate.day.toString();

    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 日历外框
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              border: Border.all(color: themeColor, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          // 日历顶部红/彩色横条（这里用当前主题色填充，使其更具一致性）
          Positioned(
            top: 2,
            left: 2,
            right: 2,
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: themeColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(2),
                  topRight: Radius.circular(2),
                ),
              ),
            ),
          ),
          // 日历中部的日期数字
          Positioned(
            bottom: 2,
            child: Text(
              dayStr,
              style: TextStyle(
                color: themeColor,
                fontSize: dayStr.length > 1 ? 12 : 15,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
