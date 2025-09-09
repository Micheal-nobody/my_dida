import 'package:isar/isar.dart';
import 'package:my_dida/model/IsarTest.dart';
import 'package:my_dida/repository/BaseRepository.dart';
import '../config/locator.dart';

class IsarTestRepository extends BaseRepository<IsarTest>{
  final Isar _isar;
  IsarTestRepository() : _isar = locator<Isar>();

  @override
  IsarCollection<IsarTest> get collection => _isar.isarTests;

  // 添加数据
  Future<void> addData(IsarTest data) async {
    await _isar.writeTxn(() async {
      await _isar.isarTests.put(data);
    });
  }

  // 获取所有数据
  Future<List<IsarTest>> getAllData() async {
    return await _isar.isarTests.where().findAll();
  }
}