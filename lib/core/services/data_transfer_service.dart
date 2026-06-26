import 'dart:convert';
import 'dart:io';
import 'package:isar_community/isar.dart';
import 'package:my_dida/core/constants/app_constants.dart';
import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/core/logger/logger.dart';
import 'package:my_dida/features/checklist/models/checklist.dart';
import 'package:my_dida/features/habits/models/habit.dart';
import 'package:my_dida/features/habits/models/habit_check_in_record.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/tomato/models/custom_tomato.dart';
import 'package:my_dida/features/tomato/models/tomato_record.dart';
import 'package:path_provider/path_provider.dart';

class DataTransferService {
  final Isar _isar = getIt<Isar>();

  /// 获取默认的导出路径
  Future<String> getDefaultExportPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}${Platform.pathSeparator}dida_backup.json';
  }

  /// 导出数据
  /// [filePath] 导出的文件目标绝对路径
  Future<void> exportData(String filePath) async {
    try {
      // 1. 获取所有需要导出的实体数据
      final checklists = await _isar.checklists.where().findAll();
      final tasks = await _isar.tasks.where().findAll();
      final habits = await _isar.habits.where().findAll();
      final habitCheckInRecords = await _isar.habitCheckInRecords
          .where()
          .findAll();
      final tomatoRecords = await _isar.tomatoRecords.where().findAll();
      final customTomatoes = await _isar.customTomatos.where().findAll();

      // 2. 组装成 JSON Map
      final backupData = {
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'checklists': checklists.map((e) => e.toJson()).toList(),
        'tasks': tasks.map((e) => e.toJson()).toList(),
        'habits': habits.map((e) => e.toJson()).toList(),
        'habitCheckInRecords': habitCheckInRecords
            .map((e) => e.toJson())
            .toList(),
        'tomatoRecords': tomatoRecords.map((e) => e.toJson()).toList(),
        'customTomatoes': customTomatoes.map((e) => e.toJson()).toList(),
      };

      // 3. 写入文件
      final file = File(filePath);
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      await file.writeAsString(jsonString, flush: true);
      logger.i('数据成功导出至: $filePath');
    } catch (e, stack) {
      logger.e('数据导出失败', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// 导入数据
  /// [filePath] 导入文件的绝对路径
  Future<void> importData(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw FileNotFoundException('备份文件不存在: $filePath');
      }

      final jsonString = await file.readAsString();
      final Map<String, dynamic> backupData =
          json.decode(jsonString) as Map<String, dynamic>;

      // 校验版本或基本格式
      if (!backupData.containsKey('version')) {
        throw FormatException('无效的备份文件格式');
      }

      // 1. 解析各实体列表
      final checklistsJson = backupData['checklists'] as List? ?? [];
      final tasksJson = backupData['tasks'] as List? ?? [];
      final habitsJson = backupData['habits'] as List? ?? [];
      final habitCheckInRecordsJson =
          backupData['habitCheckInRecords'] as List? ?? [];
      final tomatoRecordsJson = backupData['tomatoRecords'] as List? ?? [];
      final customTomatoesJson = backupData['customTomatoes'] as List? ?? [];

      final checklists = checklistsJson
          .map((e) => Checklist.fromJson(e as Map<String, dynamic>))
          .toList();
      final tasks = tasksJson
          .map((e) => Task.fromJson(e as Map<String, dynamic>))
          .toList();
      final habits = habitsJson
          .map((e) => Habit.fromJson(e as Map<String, dynamic>))
          .toList();
      final habitCheckInRecords = habitCheckInRecordsJson
          .map((e) => HabitCheckInRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      final tomatoRecords = tomatoRecordsJson
          .map((e) => TomatoRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      final customTomatoes = customTomatoesJson
          .map((e) => CustomTomato.fromJson(e as Map<String, dynamic>))
          .toList();

      // 2. 执行数据库写入事务：清空相关表并按原 ID 重新写入
      await _isar.writeTxn(() async {
        // 清空表
        await _isar.tasks.clear();
        await _isar.checklists.clear();
        await _isar.habits.clear();
        await _isar.habitCheckInRecords.clear();
        await _isar.tomatoRecords.clear();
        await _isar.customTomatos.clear();

        // 重新写入
        await _isar.checklists.putAll(checklists);
        await _isar.tasks.putAll(tasks);
        await _isar.habits.putAll(habits);
        await _isar.habitCheckInRecords.putAll(habitCheckInRecords);
        await _isar.tomatoRecords.putAll(tomatoRecords);
        await _isar.customTomatos.putAll(customTomatoes);

        // 保证必须包含默认清单（收集箱）
        final defaultBox = await _isar.checklists.get(
          AppConstants.defaultCheckList.id,
        );
        if (defaultBox == null) {
          final box = Checklist(name: '收集箱')
            ..id = AppConstants.defaultCheckList.id;
          await _isar.checklists.put(box);
        }
      });

      logger.i('数据成功从 $filePath 导入。');
    } catch (e, stack) {
      logger.e('数据导入失败', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// 删除数据（清空所有实体类数据）
  Future<void> clearData() async {
    try {
      await _isar.writeTxn(() async {
        await _isar.tasks.clear();
        await _isar.checklists.clear();
        await _isar.habits.clear();
        await _isar.habitCheckInRecords.clear();
        await _isar.tomatoRecords.clear();
        await _isar.customTomatos.clear();

        // 重新生成默认清单（收集箱）
        final box = Checklist(name: '收集箱')
          ..id = AppConstants.defaultCheckList.id;
        await _isar.checklists.put(box);
      });
    } catch (e, stack) {
      logger.e('删除数据失败', error: e, stackTrace: stack);
      rethrow;
    }
  }
}

class FileNotFoundException implements Exception {
  final String message;
  FileNotFoundException(this.message);

  @override
  String toString() => 'FileNotFoundException: $message';
}
