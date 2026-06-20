import 'dart:async';
import 'package:flutter/material.dart';
import 'package:my_dida/services/habit_lifecycle_manager.dart';

import '../config/locator.dart';
import '../model/entity/habit.dart';
import '../repository/habit_repository.dart';

class HabitProvider with ChangeNotifier {
  HabitProvider({
    HabitRepository? habitRepository,
    HabitLifecycleManager? habitLifecycleManager,
  }) : _habitRepository = habitRepository ?? getIt<HabitRepository>(),
       _habitLifecycleManager =
           habitLifecycleManager ?? getIt<HabitLifecycleManager>() {
    _subscription = _habitRepository.watchAll().listen((habits) {
      _habits = habits;
      notifyListeners();
    });
  }
  List<Habit> _habits = [];
  final HabitRepository _habitRepository;
  final HabitLifecycleManager _habitLifecycleManager;
  StreamSubscription<List<Habit>>? _subscription;

  // Getters
  List<Habit> get habits => _habits;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  // 添加习惯
  Future<void> addHabit(Habit habit) async {
    await _habitLifecycleManager.addHabit(habit);
  }

  // 更新习惯
  Future<void> updateHabit(Habit habit) async {
    await _habitLifecycleManager.updateHabit(habit);
  }

  // 删除习惯
  Future<void> deleteHabit(int id) async {
    await _habitLifecycleManager.deleteHabit(id);
  }

  // 打卡一次
  Future<void> checkIn(Habit habit) async {
    await _habitLifecycleManager.checkIn(habit);
  }

  // 跳过今天
  Future<void> skipToday(Habit habit) async {
    await _habitLifecycleManager.skipToday(habit);
  }

  // 检查今日是否完成打卡
  bool isTodayCompleted(Habit habit) =>
      habit.currentCheckInCount >= habit.checkInCount;

  // 获取今日打卡进度
  double getTodayProgress(Habit habit) {
    if (habit.checkInCount == 0) return 0.0;
    return habit.currentCheckInCount / habit.checkInCount;
  }

  // 重置今日打卡次数（每天开始时调用）
  Future<void> resetTodayCheckInCounts() async {
    await _habitLifecycleManager.resetTodayCheckInCounts();
  }

  // 监听习惯变化
  Stream<List<Habit>> watchHabits() => _habitRepository.watchAll();

  // 监听特定习惯变化
  Stream<Habit?> watchHabitById(int id) => _habitRepository.watchById(id);

  // 撤销一次打卡
  Future<void> undoLastCheckIn(Habit habit) async {
    await _habitLifecycleManager.undoLastCheckIn(habit);
  }

  // 撤销所有打卡
  Future<void> undoAllCheckIns(Habit habit) async {
    await _habitLifecycleManager.undoAllCheckIns(habit);
  }
}
