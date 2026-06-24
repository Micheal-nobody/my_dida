import 'package:isar_community/isar.dart';
import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/features/habits/models/habit_check_in_record.dart';
import 'package:my_dida/shared/repositories/base_repository.dart';

class HabitCheckInRecordRepository extends BaseRepository<HabitCheckInRecord> {
  HabitCheckInRecordRepository() : _isar = getIt<Isar>();
  final Isar _isar;

  @override
  IsarCollection<HabitCheckInRecord> get collection =>
      _isar.habitCheckInRecords;

  // 添加打卡记录
  Future<void> addRecord(HabitCheckInRecord record) async {
    await _isar.writeTxn(() async {
      await _isar.habitCheckInRecords.put(record);
    });
  }

  // 获取特定习惯的所有打卡记录
  Future<List<HabitCheckInRecord>> getRecordsByHabitId(int habitId) async {
    return _isar.habitCheckInRecords.where().habitIdEqualTo(habitId).findAll();
  }

  // 获取特定时间段内的打卡记录
  Future<List<HabitCheckInRecord>> getRecordsInTimeRange(
    DateTime start,
    DateTime end,
  ) async {
    return _isar.habitCheckInRecords
        .where()
        .checkInTimeBetween(start, end)
        .findAll();
  }

  // 删除特定打卡记录
  Future<bool> deleteRecord(int id) async {
    return _isar.writeTxn(() async => _isar.habitCheckInRecords.delete(id));
  }

  // 删除特定习惯的所有记录
  Future<int> deleteRecordsByHabitId(int habitId) async {
    return _isar.writeTxn(() async {
      final records = await getRecordsByHabitId(habitId);
      final ids = records.map((e) => e.id).toList();
      return _isar.habitCheckInRecords.deleteAll(ids);
    });
  }

  // 获取所有打卡记录
  Future<List<HabitCheckInRecord>> getAllRecords() async {
    return _isar.habitCheckInRecords.where().findAll();
  }
}
