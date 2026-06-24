import 'package:isar_community/isar.dart';
import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/features/checklist/models/checklist.dart';
import 'package:my_dida/shared/repositories/base_repository.dart';

class ChecklistRepository extends BaseRepository<Checklist> {
  ChecklistRepository() : _isar = getIt<Isar>();
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
  Future<List<Checklist>> getAllData() async => collection.where().findAll();
}
