import 'package:isar_community/isar.dart';
import 'package:my_dida/model/entity/task.dart';
import 'package:my_dida/repository/base_repository.dart';
import 'package:my_dida/utils/TimeUtils.dart';

import '../config/locator.dart';

class TaskRepository extends BaseRepository<Task> {
  TaskRepository() : _isar = getIt<Isar>();
  final Isar _isar;

  @override
  IsarCollection<Task> get collection => _isar.tasks;

  // 添加数据
  Future<void> addData(Task data) async {
    await _isar.writeTxn(() async {
      await collection.put(data);
    });
  }

  // 获取所有数据
  Future<List<Task>> getAllData() async => collection.where().findAll();

  Future<List<Task>> getTodayTasks() async {
    final todayRange = DateTimeUtils.getTodayRange();

    return collection
        .where()
        .filter()
        .startTimeBetween(todayRange.start, todayRange.end) // Between 是闭区间！
        .or()
        .endTimeBetween(todayRange.start, todayRange.end)
        .findAll();
  }

  // Optimized method to get tasks for a specific date range
  Future<List<Task>> getTasksForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final dateRange = DateTimeUtils.getDateRange(startDate, endDate);

    return collection
        .where()
        .filter()
        .startTimeBetween(dateRange.start, dateRange.end)
        .or()
        .endTimeBetween(dateRange.start, dateRange.end)
        .or()
        .startTimeIsNull() // Include tasks without specific times
        .findAll();
  }

  // Get tasks for multiple specific dates (more efficient than individual queries)
  Future<List<Task>> getTasksForDates(List<DateTime> dates) async {
    if (dates.isEmpty) return [];

    final startDate = dates.reduce((a, b) => a.isBefore(b) ? a : b);
    final endDate = dates.reduce((a, b) => a.isAfter(b) ? a : b);

    return getTasksForDateRange(startDate, endDate);
  }

  // Get only incomplete tasks for better performance when completed tasks aren't needed
  Future<List<Task>> getIncompleteTasksForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final dateRange = DateTimeUtils.getDateRange(startDate, endDate);

    return collection
        .where()
        .filter()
        .isDoneEqualTo(false)
        .and()
        .group(
          (q) => q
              .startTimeBetween(dateRange.start, dateRange.end)
              .or()
              .endTimeBetween(dateRange.start, dateRange.end)
              .or()
              .startTimeIsNull(),
        )
        .findAll();
  }

  Future<void> addTask(Task newTask) async {
    await _isar.writeTxn(() async {
      await collection.put(newTask);
    });
  }

  Future<List<Task>> getTasksByChecklistId(int id) async =>
      collection.where().filter().checklistIdEqualTo(id).findAll();

  Future<void> updateTaskIsDone(Task task, bool value) async {
    await _isar.writeTxn(() async {
      task.isDone = value;
      await collection.put(task);
    });
  }

  Future<List<Task>> getTasksForDate(DateTime date) async {
    final dateRange = DateTimeUtils.getDateRange(date, date);

    return collection
        .where()
        .filter()
        .startTimeBetween(dateRange.start, dateRange.end)
        .or()
        .endTimeBetween(dateRange.start, dateRange.end)
        .findAll();
  }
}
