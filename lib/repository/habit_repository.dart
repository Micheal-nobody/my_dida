import 'package:isar_community/isar.dart';
import 'package:my_dida/model/entity/Habit.dart';
import 'package:my_dida/repository/base_repository.dart';

import '../config/locator.dart';

class HabitRepository extends BaseRepository<Habit> {
  HabitRepository() : _isar = getIt<Isar>();
  final Isar _isar;

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
  Future<List<Habit>> getAllHabits() async => _isar.habits.where().findAll();

  // Get active habits (not completed today) for better performance
  Future<List<Habit>> getActiveHabits() async {
    // This would need additional logic based on your habit completion tracking
    // For now, return all habits but this can be optimized based on completion status
    return _isar.habits.where().findAll();
  }

  // Get habits with pagination for large datasets
  Future<List<Habit>> getHabitsPaginated(int page, int limit) async {
    final offset = page * limit;
    return _isar.habits.where().offset(offset).limit(limit).findAll();
  }

  // 根据ID获取习惯
  Future<Habit?> getHabitById(int id) async => _isar.habits.get(id);

  // 删除习惯
  Future<bool> deleteHabit(int id) async =>
      _isar.writeTxn(() async => _isar.habits.delete(id));
}
