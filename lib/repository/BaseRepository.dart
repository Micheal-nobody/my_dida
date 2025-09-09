import 'package:isar/isar.dart';
import '../config/locator.dart';

abstract class BaseRepository<T> {
  // 获取对应的 Isar 集合
  IsarCollection<T> get collection;

  // 获取 Isar 实例
  Isar get _isar => locator<Isar>();

  // 插入单个实体
  Future<Id> insert(T entity) async {
    return await _isar.writeTxn(() async {
      return await collection.put(entity);
    });
  }

  // 插入多个实体
  Future<List<Id>> insertAll(List<T> entities) async {
    return await _isar.writeTxn(() async {
      return await collection.putAll(entities);
    });
  }

  // 根据 ID 获取实体
  Future<T?> getById(Id id) async {
    return await collection.get(id);
  }

  // 获取所有实体
  Future<List<T>> getAll() async {
    return await collection.where().findAll();
  }

  // 更新实体
  Future<void> update(T entity) async {
    await _isar.writeTxn(() async {
      await collection.put(entity);
    });
  }

  // 根据 ID 删除实体
  Future<bool> deleteById(Id id) async {
    return await _isar.writeTxn(() async {
      return await collection.delete(id);
    });
  }

  // 删除多个实体
  Future<int> deleteAll(List<Id> ids) async {
    return await _isar.writeTxn(() async {
      return await collection.deleteAll(ids);
    });
  }

  // 删除所有实体
  Future<void> deleteAllEntities() async {
    await _isar.writeTxn(() async {
      await collection.clear();
    });
  }

  // 获取实体数量
  Future<int> count() async {
    return await collection.count();
  }

  // 监听所有实体的变化
  Stream<List<T>> watchAll() {
    return collection.where().watch(fireImmediately: true);
  }

  // 监听指定 ID 的实体变化
  Stream<T?> watchById(Id id) {
    return collection.watchObject(id, fireImmediately: true);
  }

  // 分页查询
  Future<List<T>> getPaginated(int page, int limit) async {
    final offset = page * limit;
    return await collection.where()
        .offset(offset)
        .limit(limit)
        .findAll();
  }

  // 检查实体是否存在
  Future<bool> exists(Id id) async {
    return await collection.get(id) != null;
  }
}