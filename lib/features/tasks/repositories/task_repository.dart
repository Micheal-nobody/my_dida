import 'dart:convert';

import 'package:isar_community/isar.dart';
import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/core/utils/time_utils.dart';
import 'package:my_dida/features/operation_undo/models/operation.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/shared/repositories/base_repository.dart';

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

  // 获取启用了通知提醒且未完成的任务
  Future<List<Task>> getActiveReminderTasks() async => collection
      .where()
      .filter()
      .isDoneEqualTo(false)
      .and()
      .notificationEnabledEqualTo(true)
      .findAll();

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
      collection.where().checklistIdEqualTo(id).findAll();

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

  Stream<List<Task>> watchByChecklistId(int id) =>
      collection.where().checklistIdEqualTo(id).watch(fireImmediately: true);

  Stream<List<Task>> watchTodayTasks() {
    final todayRange = DateTimeUtils.getTodayRange();
    return collection
        .where()
        .filter()
        .startTimeBetween(todayRange.start, todayRange.end)
        .or()
        .endTimeBetween(todayRange.start, todayRange.end)
        .watch(fireImmediately: true);
  }

  Stream<List<Task>> watchTomorrowTasks() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowRange = DateTimeUtils.getDateRange(tomorrow, tomorrow);
    return collection
        .where()
        .filter()
        .isDoneEqualTo(false)
        .and()
        .group(
          (q) => q
              .startTimeBetween(tomorrowRange.start, tomorrowRange.end)
              .or()
              .endTimeBetween(tomorrowRange.start, tomorrowRange.end),
        )
        .watch(fireImmediately: true);
  }

  Stream<List<Task>> watchNext7DaysTasks() {
    final now = DateTime.now();
    final end = now.add(const Duration(days: 6));
    final range = DateTimeUtils.getDateRange(now, end);
    return collection
        .where()
        .filter()
        .isDoneEqualTo(false)
        .and()
        .group(
          (q) => q
              .startTimeBetween(range.start, range.end)
              .or()
              .endTimeBetween(range.start, range.end),
        )
        .watch(fireImmediately: true);
  }

  Stream<List<Task>> watchAllIncompleteTasks() => collection
      .where()
      .filter()
      .isDoneEqualTo(false)
      .watch(fireImmediately: true);

  Stream<List<Task>> watchAllCompletedTasks() => collection
      .where()
      .filter()
      .isDoneEqualTo(true)
      .watch(fireImmediately: true);

  Stream<List<Task>> watchTrashTasks() => _isar.operations
      .where()
      .filter()
      .typeEqualTo(OperationType.delete)
      .and()
      .targetEqualTo(OperationTarget.task)
      .watch(fireImmediately: true)
      .map(
        (ops) => ops.map((op) {
          if (op.previousData == null) {
            return Task(name: '未知任务', isAllDay: false);
          }
          final task = Task.fromJson(jsonDecode(op.previousData!))..id = op.id;
          return task;
        }).toList(),
      );

  Stream<List<Task>> watchAllTasks() =>
      collection.where().watch(fireImmediately: true);

  Future<int> getTasksCount({
    DateTime? start,
    DateTime? end,
    bool? isDone,
    int? checklistId,
  }) async {
    QueryBuilder<Task, Task, QAfterFilterCondition> query = collection
        .where()
        .filter()
        .idGreaterThan(0);
    if (isDone != null) {
      query = query.isDoneEqualTo(isDone);
    }
    if (checklistId != null) {
      query = query.checklistIdEqualTo(checklistId);
    }
    if (start != null && end != null) {
      query = query.group(
        (q) => q.startTimeBetween(start, end).or().endTimeBetween(start, end),
      );
    }
    return query.count();
  }

  Future<int> getTodayTasksCount() async {
    final todayRange = DateTimeUtils.getTodayRange();
    return getTasksCount(
      start: todayRange.start,
      end: todayRange.end,
      isDone: false,
    );
  }

  Future<int> getTomorrowTasksCount() async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowRange = DateTimeUtils.getDateRange(tomorrow, tomorrow);
    return getTasksCount(
      start: tomorrowRange.start,
      end: tomorrowRange.end,
      isDone: false,
    );
  }

  Future<int> getNext7DaysTasksCount() async {
    final now = DateTime.now();
    final end = now.add(const Duration(days: 6));
    final range = DateTimeUtils.getDateRange(now, end);
    return getTasksCount(start: range.start, end: range.end, isDone: false);
  }

  Future<int> getInboxTasksCount() async =>
      getTasksCount(checklistId: 1, isDone: false);

  Future<int> getAllIncompleteTasksCount() async =>
      getTasksCount(isDone: false);

  Future<int> getAllCompletedTasksCount() async => getTasksCount(isDone: true);

  Future<int> getTrashTasksCount() async => _isar.operations
      .where()
      .filter()
      .typeEqualTo(OperationType.delete)
      .and()
      .targetEqualTo(OperationTarget.task)
      .count();
}
