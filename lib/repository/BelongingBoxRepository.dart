import 'package:isar/isar.dart';
import 'package:my_dida/model/entity/BelongingBox.dart';
import 'package:my_dida/repository/BaseRepository.dart';
import '../config/locator.dart';

class BelongingBoxRepository extends BaseRepository<BelongingBox> {
  BelongingBoxRepository() : _isar = locator<Isar>();
  final Isar _isar;

  @override
  IsarCollection<BelongingBox> get collection => _isar.belongingBoxs;

  // 添加数据
  Future<void> addData(BelongingBox data) async {
    await _isar.writeTxn(() async {
      await _isar.belongingBoxs.put(data);
    });
  }

  // 获取所有数据
  Future<List<BelongingBox>> getAllData() async =>
      _isar.belongingBoxs.where().findAll();
}
