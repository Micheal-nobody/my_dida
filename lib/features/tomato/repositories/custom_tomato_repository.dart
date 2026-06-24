import 'package:isar_community/isar.dart';
import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/features/tomato/models/custom_tomato.dart';
import 'package:my_dida/shared/repositories/base_repository.dart';

class CustomTomatoRepository extends BaseRepository<CustomTomato> {
  CustomTomatoRepository() : _isar = getIt<Isar>();
  final Isar _isar;

  @override
  IsarCollection<CustomTomato> get collection => _isar.customTomatos;

  Future<List<CustomTomato>> getAll() async => collection.where().findAll();
}
