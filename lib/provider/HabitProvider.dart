import 'package:flutter/material.dart';
import '../config/locator.dart';
import '../model/entity/Habit.dart';
import '../repository/HabitRepository.dart';

class HabitProvider with ChangeNotifier {
  List<Habit> _habits = [];
  final HabitRepository _habitRepository;

  HabitProvider() : _habitRepository = locator<HabitRepository>();

  // Getters
  List<Habit> get habits => _habits;

  // 加载所有习惯
  Future<void> loadAllHabits() async {
    _habits = await _habitRepository.getAllHabits();
    notifyListeners();
  }

  // 添加习惯
  Future<void> addHabit(Habit habit) async {
    await _habitRepository.addHabit(habit);
    await loadAllHabits();
  }

  // 更新习惯
  Future<void> updateHabit(Habit habit) async {
    await _habitRepository.update(habit);
    await loadAllHabits();
  }

  // 删除习惯
  Future<void> deleteHabit(int id) async {
    await _habitRepository.deleteHabit(id);
    await loadAllHabits();
  }

  // 打卡一次
  Future<void> checkIn(Habit habit) async {
    if (habit.currentCheckInCount < habit.checkInCount) {
      await _habitRepository.updateCheckInCount(
        habit,
        habit.currentCheckInCount + 1,
      );
      await _habitRepository.updateHabitStats(habit);
      await loadAllHabits();
    }
  }

  // 跳过今天
  Future<void> skipToday(Habit habit) async {
    await _habitRepository.skipToday(habit);
    await loadAllHabits();
  }

  // 检查今日是否完成打卡
  bool isTodayCompleted(Habit habit) {
    return habit.currentCheckInCount >= habit.checkInCount;
  }

  // 获取今日打卡进度
  double getTodayProgress(Habit habit) {
    if (habit.checkInCount == 0) return 0.0;
    return habit.currentCheckInCount / habit.checkInCount;
  }

  // 重置今日打卡次数（每天开始时调用）
  Future<void> resetTodayCheckInCounts() async {
    for (Habit habit in _habits) {
      await _habitRepository.resetTodayCheckInCount(habit);
    }
    await loadAllHabits();
  }

  // 监听习惯变化
  Stream<List<Habit>> watchHabits() {
    return _habitRepository.watchAll();
  }

  // 监听特定习惯变化
  Stream<Habit?> watchHabitById(int id) {
    return _habitRepository.watchById(id);
  }
}
