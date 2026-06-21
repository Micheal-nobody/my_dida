import 'dart:convert';
import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/core/errors/exceptions.dart';
import 'package:my_dida/features/habits/models/habit.dart';
import 'package:my_dida/features/habits/models/habit_check_in_record.dart';
import 'package:my_dida/features/operation_undo/models/operation.dart';
import 'package:my_dida/features/operation_undo/providers/operation_stack_provider.dart';
import 'package:my_dida/features/habits/repositories/habit_repository.dart';
import 'package:my_dida/features/habits/repositories/habit_check_in_record_repository.dart';

abstract class HabitLifecycleManager {
  Future<void> addHabit(Habit habit);
  Future<void> updateHabit(Habit habit);
  Future<void> deleteHabit(int id);
  Future<void> checkIn(Habit habit);
  Future<void> skipToday(Habit habit);
  Future<void> resetTodayCheckInCounts();
  Future<void> undoLastCheckIn(Habit habit);
  Future<void> undoAllCheckIns(Habit habit);
  Future<void> archiveHabit(int id);
  Future<void> unarchiveHabit(int id);
  Future<void> reorderHabits(List<Habit> reorderedHabits);
}

class HabitLifecycleManagerImpl implements HabitLifecycleManager {
  HabitLifecycleManagerImpl({
    HabitRepository? habitRepository,
    HabitCheckInRecordRepository? recordRepository,
    OperationStackProvider? operationStack,
  }) : _habitRepository = habitRepository ?? getIt<HabitRepository>(),
       _recordRepository =
           recordRepository ?? getIt<HabitCheckInRecordRepository>(),
       _operationStack = operationStack ?? getIt<OperationStackProvider>();

  final HabitRepository _habitRepository;
  final HabitCheckInRecordRepository _recordRepository;
  final OperationStackProvider _operationStack;

  @override
  Future<void> addHabit(Habit habit) async {
    try {
      await _habitRepository.addHabit(habit);

      // 记录添加习惯操作
      final operation = Operation.createAddHabitOperation(habit);
      await _operationStack.addOperation(operation);
    } catch (e) {
      throw HabitException('Failed to add habit: $e');
    }
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    try {
      // 获取旧状态用于操作记录
      final oldHabit = await _habitRepository.getHabitById(habit.id);
      if (oldHabit == null) {
        throw HabitException('Habit not found with id: ${habit.id}');
      }

      await _habitRepository.update(habit);

      // 记录更新习惯操作
      final operation = Operation.createUpdateHabitOperation(
        oldHabit,
        habit,
        '更新了习惯"${habit.name}"',
      );
      await _operationStack.addOperation(operation);
    } catch (e) {
      throw HabitException('Failed to update habit: $e');
    }
  }

  @override
  Future<void> deleteHabit(int id) async {
    try {
      // 获取要删除的习惯用于操作记录
      final habit = await _habitRepository.getHabitById(id);
      if (habit == null) {
        throw HabitException('Habit not found with id: $id');
      }

      // 获取要删除习惯的所有打卡记录
      final records = await _recordRepository.getRecordsByHabitId(id);

      // 记录删除习惯操作，我们将 habit 实体和 records 打包保存
      final operation = Operation(
        type: OperationType.delete,
        target: OperationTarget.habit,
        timestamp: DateTime.now(),
        description: '删除了习惯"${habit.name}"',
        targetId: habit.id,
        previousData: jsonEncode({
          'habit': habit.toJson(),
          'records': records.map((r) => r.toJson()).toList(),
        }),
      );
      await _operationStack.addOperation(operation);

      await _recordRepository.deleteRecordsByHabitId(id);
      await _habitRepository.deleteHabit(id);
    } catch (e) {
      throw HabitException('Failed to delete habit: $e');
    }
  }

  @override
  Future<void> checkIn(Habit habit) async {
    try {
      if (habit.currentCheckInCount < habit.checkInCount) {
        // 记录打卡操作
        final operation = Operation.createCheckInOperation(habit);
        await _operationStack.addOperation(operation);

        // 领域逻辑：修改实体字段后持久化
        habit.currentCheckInCount += 1;
        habit.totalCheckInCount += 1;
        await _habitRepository.updateHabit(habit);

        final record = HabitCheckInRecord(
          habitId: habit.id,
          checkInTime: DateTime.now(),
        );
        await _recordRepository.addRecord(record);
      }
    } catch (e) {
      throw HabitException('Failed to check in habit: $e');
    }
  }

  @override
  Future<void> skipToday(Habit habit) async {
    try {
      final oldHabit = Habit.fromJson(habit.toJson());

      habit.isTodaySkipped = true;
      await _habitRepository.updateHabit(habit);

      final record = HabitCheckInRecord(
        habitId: habit.id,
        checkInTime: DateTime.now(),
        isSkip: true,
      );
      await _recordRepository.addRecord(record);

      // 录制跳过习惯操作
      final operation = Operation(
        type: OperationType.update,
        target: OperationTarget.habit,
        timestamp: DateTime.now(),
        description: '跳过了习惯"${habit.name}"',
        targetId: habit.id,
        previousData: jsonEncode(oldHabit.toJson()),
        newData: jsonEncode(habit.toJson()),
      );
      await _operationStack.addOperation(operation);
    } catch (e) {
      throw HabitException('Failed to skip habit: $e');
    }
  }

  @override
  Future<void> resetTodayCheckInCounts() async {
    try {
      final habits = await _habitRepository.getAllHabits();
      for (final Habit habit in habits) {
        habit.currentCheckInCount = 0;
        habit.isTodaySkipped = false;
        await _habitRepository.updateHabit(habit);
      }
    } catch (e) {
      throw HabitException('Failed to reset today check in counts: $e');
    }
  }

  @override
  Future<void> undoLastCheckIn(Habit habit) async {
    try {
      if (habit.currentCheckInCount > 0) {
        habit.currentCheckInCount -= 1;
        if (habit.totalCheckInCount > 0) {
          habit.totalCheckInCount -= 1;
        }
        await _habitRepository.updateHabit(habit);

        // 删除最后一条打卡记录
        final records = await _recordRepository.getRecordsByHabitId(habit.id);
        final today = DateTime.now();
        final todayRecords = records.where((r) {
          return !r.isSkip &&
              r.checkInTime.year == today.year &&
              r.checkInTime.month == today.month &&
              r.checkInTime.day == today.day;
        }).toList();
        if (todayRecords.isNotEmpty) {
          todayRecords.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
          await _recordRepository.deleteRecord(todayRecords.first.id);
        }
      }
    } catch (e) {
      throw HabitException('Failed to undo last check in: $e');
    }
  }

  @override
  Future<void> undoAllCheckIns(Habit habit) async {
    try {
      final int removedCount = habit.currentCheckInCount;
      habit.currentCheckInCount = 0;
      habit.totalCheckInCount = (habit.totalCheckInCount - removedCount).clamp(
        0,
        999999,
      );
      await _habitRepository.updateHabit(habit);

      // 删除今天所有的非Skip打卡记录
      final records = await _recordRepository.getRecordsByHabitId(habit.id);
      final today = DateTime.now();
      final todayRecords = records.where((r) {
        return !r.isSkip &&
            r.checkInTime.year == today.year &&
            r.checkInTime.month == today.month &&
            r.checkInTime.day == today.day;
      }).toList();
      for (final r in todayRecords) {
        await _recordRepository.deleteRecord(r.id);
      }
    } catch (e) {
      throw HabitException('Failed to undo all check ins: $e');
    }
  }

  @override
  Future<void> archiveHabit(int id) async {
    try {
      final habit = await _habitRepository.getHabitById(id);
      if (habit != null) {
        final oldHabit = Habit.fromJson(habit.toJson());
        habit.isArchived = true;
        await _habitRepository.updateHabit(habit);

        // 录制归档操作
        final operation = Operation(
          type: OperationType.update,
          target: OperationTarget.habit,
          timestamp: DateTime.now(),
          description: '归档了习惯"${habit.name}"',
          targetId: habit.id,
          previousData: jsonEncode(oldHabit.toJson()),
          newData: jsonEncode(habit.toJson()),
        );
        await _operationStack.addOperation(operation);
      }
    } catch (e) {
      throw HabitException('Failed to archive habit: $e');
    }
  }

  @override
  Future<void> unarchiveHabit(int id) async {
    try {
      final habit = await _habitRepository.getHabitById(id);
      if (habit != null) {
        final oldHabit = Habit.fromJson(habit.toJson());
        habit.isArchived = false;
        await _habitRepository.updateHabit(habit);

        // 录制激活操作
        final operation = Operation(
          type: OperationType.update,
          target: OperationTarget.habit,
          timestamp: DateTime.now(),
          description: '激活了习惯"${habit.name}"',
          targetId: habit.id,
          previousData: jsonEncode(oldHabit.toJson()),
          newData: jsonEncode(habit.toJson()),
        );
        await _operationStack.addOperation(operation);
      }
    } catch (e) {
      throw HabitException('Failed to unarchive habit: $e');
    }
  }

  @override
  Future<void> reorderHabits(List<Habit> reorderedHabits) async {
    try {
      for (int i = 0; i < reorderedHabits.length; i++) {
        final habit = reorderedHabits[i];
        habit.sortOrder = i;
        await _habitRepository.updateHabit(habit);
      }
    } catch (e) {
      throw HabitException('Failed to reorder habits: $e');
    }
  }
}
