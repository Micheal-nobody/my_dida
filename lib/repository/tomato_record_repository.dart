import 'package:isar_community/isar.dart';
import 'package:my_dida/config/locator.dart';
import 'package:my_dida/model/entity/tomato_record.dart';
import 'package:my_dida/repository/base_repository.dart';

class TomatoRecordRepository extends BaseRepository<TomatoRecord> {
  TomatoRecordRepository() : _isar = getIt<Isar>();
  final Isar _isar;

  @override
  IsarCollection<TomatoRecord> get collection => _isar.tomatoRecords;

  // 获取特定时间范围内的番茄专注记录
  Future<List<TomatoRecord>> getRecordsInPeriod(DateTime start, DateTime end) async {
    return collection
        .where()
        .filter()
        .startTimeBetween(start, end)
        .findAll();
  }
}
