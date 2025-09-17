import 'package:isar/isar.dart';
import 'package:my_dida/model/entity/Habit.dart';
import 'package:my_dida/repository/BaseRepository.dart';

import '../config/locator.dart';

class HabitRepository extends BaseRepository<Habit> {
  final Isar _isar;

  HabitRepository() : _isar = locator<Isar>();

  @override
  IsarCollection<Habit> get collection => _isar.habits;

  // 添加习惯
  Future<void> addHabit(Habit habit) async {
    await _isar.writeTxn(() async {
      await _isar.habits.put(habit);
    });
  }

  // 更新习惯的打卡次数
  Future<void> updateCheckInCount(Habit habit, int newCount) async {
    await _isar.writeTxn(() async {
      habit.currentCheckInCount = newCount;
      await _isar.habits.put(habit);
    });
  }

  // 重置今日打卡次数（每天开始时调用）
  Future<void> resetTodayCheckInCount(Habit habit) async {
    await _isar.writeTxn(() async {
      habit.currentCheckInCount = 0;
      await _isar.habits.put(habit);
    });
  }

  // 更新习惯统计信息
  Future<void> updateHabitStats(Habit habit) async {
    await _isar.writeTxn(() async {
      habit.totalCheckInCount += 1;
      // 这里可以添加连续打卡天数的逻辑
      await _isar.habits.put(habit);
    });
  }

  // 跳过今天的习惯（设置为半透明状态）
  Future<void> skipToday(Habit habit) async {
    await _isar.writeTxn(() async {
      // 可以添加一个字段来标记是否跳过今天
      await _isar.habits.put(habit);
    });
  }

  // 获取所有习惯
  Future<List<Habit>> getAllHabits() async {
    return await _isar.habits.where().findAll();
  }

  // 根据ID获取习惯
  Future<Habit?> getHabitById(int id) async {
    return await _isar.habits.get(id);
  }

  // 删除习惯
  Future<bool> deleteHabit(int id) async {
    return await _isar.writeTxn(() async {
      return await _isar.habits.delete(id);
    });
  }
}
