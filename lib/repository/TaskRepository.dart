import 'package:isar/isar.dart';
import 'package:my_dida/model/entity/Task.dart';
import 'package:my_dida/repository/BaseRepository.dart';
import '../locator/locator.dart';

class TaskRepository extends BaseRepository<Task> {
  final Isar _isar;

  TaskRepository() : _isar = locator<Isar>();

  @override
  IsarCollection<Task> get collection => _isar.tasks;

  // 添加数据
  Future<void> addData(Task data) async {
    await _isar.writeTxn(() async {
      await _isar.tasks.put(data);
    });
  }

  // 获取所有数据
  Future<List<Task>> getAllData() async {
    return await _isar.tasks.where().findAll();
  }

  Future<List<Task>> getTodayTasks() async {
    final now = DateTime.now(); // 包含年月日 时 分 秒
    final startOfDay = DateTime(now.year, now.month, now.day);  // 获取今天00:00:00
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999); // 获取今天23:59:59.999

    return await _isar.tasks.where()
      .filter()
      .startTimeBetween(startOfDay, endOfDay) // Between 是闭区间！
      .or()
      .endTimeBetween(startOfDay, endOfDay)
      .findAll();
  }

  Future<void> addTask(Task newTask) async {
    await _isar.writeTxn(() async {
      await _isar.tasks.put(newTask);
    });
  }

  Future<List<Task>> getTasksByBelongingBoxId(int id) async {
    return await _isar.tasks.where()
      .filter()
      .belongingBoxIdEqualTo(id)
      .findAll();
  }

  // Future<List<Task>> getTodosForDate(DateTime date) {
  //   return _isar.tasks.where()
  //       .filter()
  //       .startTimeBetween(date.midnight, date.endOfDay)
  //       .or()
  //       .endTimeBetween(date.midnight, date.endOfDay)
  //       .findAll();
  // }
}
