import 'package:flutter/material.dart';

/// 通用图标常量，避免在多个地方重复定义相同的图标
class IconConstants {
  /// 习惯图标列表
  static const List<Map<String, dynamic>> habitIcons = [
    {'name': 'star', 'icon': Icons.star, 'label': '星星'},
    {'name': 'brush', 'icon': Icons.brush, 'label': '刷牙'},
    {'name': 'fitness', 'icon': Icons.fitness_center, 'label': '健身'},
    {'name': 'book', 'icon': Icons.book, 'label': '阅读'},
    {'name': 'water', 'icon': Icons.water_drop, 'label': '喝水'},
    {'name': 'sleep', 'icon': Icons.bedtime, 'label': '睡觉'},
    {'name': 'food', 'icon': Icons.restaurant, 'label': '吃饭'},
    {'name': 'meditation', 'icon': Icons.self_improvement, 'label': '冥想'},
    {'name': 'walk', 'icon': Icons.directions_walk, 'label': '散步'},
    {'name': 'music', 'icon': Icons.music_note, 'label': '音乐'},
    {'name': 'work', 'icon': Icons.work, 'label': '工作'},
    {'name': 'study', 'icon': Icons.school, 'label': '学习'},
    {'name': 'exercise', 'icon': Icons.sports_gymnastics, 'label': '运动'},
    {'name': 'coffee', 'icon': Icons.coffee, 'label': '咖啡'},
    {'name': 'heart', 'icon': Icons.favorite, 'label': '爱心'},
  ];

  /// 任务图标列表
  static const List<Map<String, dynamic>> taskIcons = [
    {'name': 'task', 'icon': Icons.task_alt, 'label': '任务'},
    {'name': 'work', 'icon': Icons.work, 'label': '工作'},
    {'name': 'home', 'icon': Icons.home, 'label': '家庭'},
    {'name': 'shopping', 'icon': Icons.shopping_cart, 'label': '购物'},
    {'name': 'health', 'icon': Icons.health_and_safety, 'label': '健康'},
    {'name': 'travel', 'icon': Icons.flight, 'label': '旅行'},
    {'name': 'meeting', 'icon': Icons.meeting_room, 'label': '会议'},
    {'name': 'call', 'icon': Icons.phone, 'label': '电话'},
    {'name': 'email', 'icon': Icons.email, 'label': '邮件'},
    {'name': 'document', 'icon': Icons.description, 'label': '文档'},
  ];

  /// 根据名称获取图标
  static IconData? getIconByName(String name, {bool isHabit = true}) {
    final iconList = isHabit ? habitIcons : taskIcons;
    final iconData = iconList.firstWhere(
      (icon) => icon['name'] == name,
      orElse: () => iconList.first,
    );
    return iconData['icon'] as IconData?;
  }

  /// 根据名称获取图标标签
  static String getIconLabel(String name, {bool isHabit = true}) {
    final iconList = isHabit ? habitIcons : taskIcons;
    final iconData = iconList.firstWhere(
      (icon) => icon['name'] == name,
      orElse: () => iconList.first,
    );
    return iconData['label'] as String;
  }
}
