import 'dart:async';
import 'package:flutter/material.dart';

import '../config/locator.dart';
import '../model/entity/habit.dart';
import '../model/entity/operation.dart';
import '../repository/habit_repository.dart';
import 'operation_stack_provider.dart';

class HabitProvider with ChangeNotifier {
  HabitProvider()
    : _habitRepository = getIt<HabitRepository>(),
      _operationStack = getIt<OperationStackProvider>() {
    _subscription = _habitRepository.watchAll().listen((habits) {
      _habits = habits;
      notifyListeners();
    });
  }
  List<Habit> _habits = [];
  final HabitRepository _habitRepository;
  final OperationStackProvider _operationStack;
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
    await _habitRepository.addHabit(habit);

    // 记录添加习惯操作
    final operation = Operation.createAddHabitOperation(habit);
    await _operationStack.addOperation(operation);
  }

  // 更新习惯
  Future<void> updateHabit(Habit habit) async {
    // 获取旧状态用于操作记录
    final oldHabit = _habits.firstWhere((h) => h.id == habit.id);

    await _habitRepository.update(habit);

    // 记录更新习惯操作
    final operation = Operation.createUpdateHabitOperation(
      oldHabit,
      habit,
      '更新了习惯"${habit.name}"',
    );
    await _operationStack.addOperation(operation);
  }

  // 删除习惯
  Future<void> deleteHabit(int id) async {
    // 获取要删除的习惯用于操作记录
    final habit = _habits.firstWhere((h) => h.id == id);

    // 记录删除习惯操作
    final operation = Operation.createDeleteHabitOperation(habit);
    await _operationStack.addOperation(operation);

    await _habitRepository.deleteHabit(id);
  }

  // 打卡一次
  Future<void> checkIn(Habit habit) async {
    if (habit.currentCheckInCount < habit.checkInCount) {
      // 记录打卡操作
      final operation = Operation.createCheckInOperation(habit);
      await _operationStack.addOperation(operation);

      // 领域逻辑：修改实体字段后持久化
      habit.currentCheckInCount += 1;
      habit.totalCheckInCount += 1;
      await _habitRepository.updateHabit(habit);
    }
  }

  // 跳过今天
  Future<void> skipToday(Habit habit) async {
    await _habitRepository.updateHabit(habit);
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
    for (final Habit habit in _habits) {
      habit.currentCheckInCount = 0;
      await _habitRepository.updateHabit(habit);
    }
  }

  // 监听习惯变化
  Stream<List<Habit>> watchHabits() => _habitRepository.watchAll();

  // 监听特定习惯变化
  Stream<Habit?> watchHabitById(int id) => _habitRepository.watchById(id);

  // 撤销一次打卡
  Future<void> undoLastCheckIn(Habit habit) async {
    if (habit.currentCheckInCount > 0) {
      habit.currentCheckInCount -= 1;
      habit.totalCheckInCount -= 1;
      await _habitRepository.updateHabit(habit);
    }
  }

  // 撤销所有打卡
  Future<void> undoAllCheckIns(Habit habit) async {
    habit.currentCheckInCount = 0;
    if (habit.totalCheckInCount > 0) {
      habit.totalCheckInCount -= 1;
    }
    await _habitRepository.updateHabit(habit);
  }
}
