import 'package:isar_community/isar.dart';
import 'package:my_dida/shared/models/base_entity.dart';

import 'package:my_dida/core/di/locator.dart';

abstract class BaseRepository<T extends BaseEntity> {
  // 获取对应的 Isar 集合,需要继承类自己实现
  IsarCollection<T> get collection;

  // 获取 Isar 实例
  Isar get _isar => getIt<Isar>();

  // 根据 ID 获取实体
  Future<T?> selectById(Id id) async => collection.get(id);

  // 获取所有实体
  Future<List<T>> selectAll() async => collection.where().findAll();

  // 插入单个实体
  Future<Id> insert(T entity) async =>
      _isar.writeTxn(() async => collection.put(entity));

  // 插入多个实体
  Future<List<Id>> insertAll(List<T> entities) async =>
      _isar.writeTxn(() async => collection.putAll(entities));

  // 更新实体
  Future<void> update(T entity) async {
    await _isar.writeTxn(() async {
      await collection.put(entity);
    });
  }

  // 根据 ID 删除实体
  Future<bool> deleteById(Id id) async =>
      _isar.writeTxn(() async => collection.delete(id));

  // 删除多个实体
  Future<int> deleteByIds(List<Id> ids) async =>
      _isar.writeTxn(() async => collection.deleteAll(ids));

  // 删除所有实体
  Future<void> deleteAll() async {
    await _isar.writeTxn(() async {
      await collection.clear();
    });
  }

  // 获取实体数量
  Future<int> count() async => collection.count();

  // 监听所有实体的变化
  Stream<List<T>> watchAll() => collection.where().watch(fireImmediately: true);

  // 监听指定 ID 的实体变化
  Stream<T?> watchById(Id id) =>
      collection.watchObject(id, fireImmediately: true);

  // 分页查询
  Future<List<T>> getPaginated(int page, int limit) async {
    final offset = page * limit;
    return collection.where().offset(offset).limit(limit).findAll();
  }

  // 检查实体是否存在
  Future<bool> exists(Id id) async => await collection.get(id) != null;
}
