import 'package:isar/isar.dart';
import 'package:my_dida/model/TodoItem.dart';
import 'package:my_dida/model/entity/Task.dart';
import 'package:my_dida/repository/BaseRepository.dart';
import '../locator/locator.dart';

class TaskRepository extends BaseRepository<Task>{
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

  // Future<List<Task>> getTodosForDate(DateTime date) {
  //   return _isar.tasks.where()
  //       .filter()
  //       .startTimeBetween(date.midnight, date.endOfDay)
  //       .or()
  //       .endTimeBetween(date.midnight, date.endOfDay)
  //       .findAll();
  // }
}