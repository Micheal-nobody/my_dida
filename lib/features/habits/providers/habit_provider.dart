import 'dart:async';

import 'package:flutter/material.dart';
import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/features/habits/models/habit.dart';
import 'package:my_dida/features/habits/models/habit_check_in_record.dart';
import 'package:my_dida/features/habits/repositories/habit_check_in_record_repository.dart';
import 'package:my_dida/features/habits/repositories/habit_repository.dart';
import 'package:my_dida/features/habits/services/habit_lifecycle_manager.dart';
import 'package:my_dida/features/tasks/models/repeat_pattern.dart';

enum HabitStatusFilter { all, incomplete, completed }

enum HabitTimeSlotFilter { all, morning, afternoon, evening }

enum HabitFrequencyFilter { all, daily, weekly }

class HabitProvider with ChangeNotifier {
  HabitProvider({
    HabitRepository? habitRepository,
    HabitCheckInRecordRepository? recordRepository,
    HabitLifecycleManager? habitLifecycleManager,
  }) : _habitRepository = habitRepository ?? getIt<HabitRepository>(),
       _recordRepository =
           recordRepository ?? getIt<HabitCheckInRecordRepository>(),
       _habitLifecycleManager =
           habitLifecycleManager ?? getIt<HabitLifecycleManager>() {
    _subscription = _habitRepository.watchAll().listen((habits) {
      _habits = habits;
      notifyListeners();
    });
  }

  List<Habit> _habits = [];
  final HabitRepository _habitRepository;
  final HabitCheckInRecordRepository _recordRepository;
  final HabitLifecycleManager _habitLifecycleManager;
  StreamSubscription<List<Habit>>? _subscription;

  // 过滤状态
  HabitStatusFilter _statusFilter = HabitStatusFilter.all;
  HabitTimeSlotFilter _timeFilter = HabitTimeSlotFilter.all;
  HabitFrequencyFilter _frequencyFilter = HabitFrequencyFilter.all;

  // Getters
  HabitStatusFilter get statusFilter => _statusFilter;

  HabitTimeSlotFilter get timeFilter => _timeFilter;

  HabitFrequencyFilter get frequencyFilter => _frequencyFilter;

  // 获取所有进行中的习惯（未归档），并按 sortOrder 排序
  List<Habit> get activeHabits {
    final list = _habits.where((h) => !h.isArchived).toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  // 获取所有已归档的习惯，按 sortOrder 排序
  List<Habit> get archivedHabits {
    final list = _habits.where((h) => h.isArchived).toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  // 获取过滤后的未归档习惯列表
  List<Habit> get habits {
    return activeHabits.where((habit) {
      // 1. 打卡状态过滤
      if (_statusFilter == HabitStatusFilter.incomplete) {
        if (isTodayCompleted(habit) || habit.isTodaySkipped) return false;
      } else if (_statusFilter == HabitStatusFilter.completed) {
        if (!isTodayCompleted(habit)) return false;
      }

      // 2. 时段过滤
      final hour = habit.remindTime.hour;
      if (_timeFilter == HabitTimeSlotFilter.morning) {
        if (hour < 5 || hour >= 12) return false;
      } else if (_timeFilter == HabitTimeSlotFilter.afternoon) {
        if (hour < 12 || hour >= 18) return false;
      } else if (_timeFilter == HabitTimeSlotFilter.evening) {
        if (hour >= 5 && hour < 18) return false;
      }

      // 3. 频次过滤
      final isWeekly = habit.rrule.type == RepeatType.weekly;
      if (_frequencyFilter == HabitFrequencyFilter.daily && isWeekly) {
        return false;
      } else if (_frequencyFilter == HabitFrequencyFilter.weekly && !isWeekly) {
        return false;
      }

      return true;
    }).toList();
  }

  // 设置过滤条件
  void setFilters({
    HabitStatusFilter? status,
    HabitTimeSlotFilter? time,
    HabitFrequencyFilter? frequency,
  }) {
    if (status != null) _statusFilter = status;
    if (time != null) _timeFilter = time;
    if (frequency != null) _frequencyFilter = frequency;
    notifyListeners();
  }

  // 重置过滤条件
  void resetFilters() {
    _statusFilter = HabitStatusFilter.all;
    _timeFilter = HabitTimeSlotFilter.all;
    _frequencyFilter = HabitFrequencyFilter.all;
    notifyListeners();
  }

  // 获取打卡记录
  Future<List<HabitCheckInRecord>> getRecordsForHabit(int habitId) =>
      _recordRepository.getRecordsByHabitId(habitId);

  Future<List<HabitCheckInRecord>> getAllRecords() =>
      _recordRepository.getAllRecords();

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
  Future<void> checkIn(Habit habit, {double? value}) async {
    await _habitLifecycleManager.checkIn(habit, value: value);
  }

  // 跳过今天
  Future<void> skipToday(Habit habit) async {
    await _habitLifecycleManager.skipToday(habit);
  }

  // 检查今日是否完成打卡
  bool isTodayCompleted(Habit habit) {
    if (habit.habitType == 'yesNo') {
      return habit.currentCheckInCount >= habit.checkInCount;
    } else {
      return habit.currentValue >= (habit.targetValue ?? 1.0);
    }
  }

  // 获取今日打卡进度
  double getTodayProgress(Habit habit) {
    if (habit.habitType == 'yesNo') {
      if (habit.checkInCount == 0) return 0.0;
      return habit.currentCheckInCount / habit.checkInCount;
    } else {
      final target = habit.targetValue ?? 1.0;
      if (target == 0.0) return 0.0;
      return habit.currentValue / target;
    }
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

  // 归档习惯
  Future<void> archiveHabit(int id) async {
    await _habitLifecycleManager.archiveHabit(id);
  }

  // 取消归档习惯
  Future<void> unarchiveHabit(int id) async {
    await _habitLifecycleManager.unarchiveHabit(id);
  }

  // 拖拽排序习惯
  Future<void> reorderHabits(List<Habit> reorderedHabits) async {
    await _habitLifecycleManager.reorderHabits(reorderedHabits);
  }
}
