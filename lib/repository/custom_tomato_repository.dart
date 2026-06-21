import 'package:isar_community/isar.dart';
import 'package:my_dida/config/locator.dart';
import 'package:my_dida/model/entity/custom_tomato.dart';
import 'package:my_dida/repository/base_repository.dart';

class CustomTomatoRepository extends BaseRepository<CustomTomato> {
  CustomTomatoRepository() : _isar = getIt<Isar>();
  final Isar _isar;

  @override
  IsarCollection<CustomTomato> get collection => _isar.customTomatos;

  Future<List<CustomTomato>> getAll() async {
    return collection.where().findAll();
  }
}
