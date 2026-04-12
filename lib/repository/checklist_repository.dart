import 'package:isar_community/isar.dart';
import 'package:my_dida/model/entity/checklist.dart';
import 'package:my_dida/repository/base_repository.dart';
import '../config/locator.dart';

class ChecklistRepository extends BaseRepository<Checklist> {
  ChecklistRepository() : _isar = locator<Isar>();
  final Isar _isar;

  @override
  IsarCollection<Checklist> get collection => _isar.checklists;

  // 添加数据
  Future<void> addData(Checklist data) async {
    await _isar.writeTxn(() async {
      await collection.put(data);
    });
  }

  // 获取所有数据
  Future<List<Checklist>> getAllData() async =>
      collection.where().findAll();
}

