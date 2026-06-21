import 'dart:convert';
import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/features/operation_undo/services/operation_reverter.dart';
import 'package:my_dida/features/habits/models/habit.dart';
import 'package:my_dida/features/habits/models/habit_check_in_record.dart';
import 'package:my_dida/features/habits/repositories/habit_repository.dart';
import 'package:my_dida/features/habits/repositories/habit_check_in_record_repository.dart';

class HabitOperationReverter implements DomainOperationReverter {
  final HabitRepository _habitRepo = getIt<HabitRepository>();
  final HabitCheckInRecordRepository _recordRepo =
      getIt<HabitCheckInRecordRepository>();

  @override
  Future<bool> revertAdd(int id) async {
    await _habitRepo.deleteById(id);
    return true;
  }

  @override
  Future<bool> revertDelete(int id, String? previousData) async {
    if (previousData == null) return false;
    final decoded = jsonDecode(previousData);

    if (decoded is Map<String, dynamic> && decoded.containsKey('habit')) {
      final habit = Habit.fromJson(decoded['habit'] as Map<String, dynamic>);
      await _habitRepo.insert(habit);

      final List<dynamic> recordsJson = decoded['records'] ?? [];
      for (final rJson in recordsJson) {
        if (rJson is Map<String, dynamic>) {
          final record = HabitCheckInRecord.fromJson(rJson);
          await _recordRepo.addRecord(record);
        }
      }
      return true;
    }
    return false;
  }

  @override
  Future<bool> revertUpdate(
    int id,
    String? previousData,
    String description,
  ) async {
    if (previousData == null) return false;
    final decoded = jsonDecode(previousData);
    final habit = Habit.fromJson(decoded as Map<String, dynamic>);
    await _habitRepo.update(habit);

    final isSkip = description.contains('跳过');
    final isCheckIn = description.contains('打卡');
    if (isSkip || isCheckIn) {
      final records = await _recordRepo.getRecordsByHabitId(habit.id);
      final today = DateTime.now();
      final todayRecords = records.where((r) {
        return r.isSkip == isSkip &&
            r.checkInTime.year == today.year &&
            r.checkInTime.month == today.month &&
            r.checkInTime.day == today.day;
      }).toList();

      if (todayRecords.isNotEmpty) {
        todayRecords.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
        await _recordRepo.deleteRecord(todayRecords.first.id);
      }
    }
    return true;
  }
}
