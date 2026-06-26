import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/features/checklist/models/checklist.dart';
import 'package:my_dida/features/habits/models/habit.dart';
import 'package:my_dida/features/habits/models/habit_check_in_record.dart';
import 'package:my_dida/features/habits/repositories/habit_check_in_record_repository.dart';
import 'package:my_dida/features/habits/repositories/habit_repository.dart';
import 'package:my_dida/features/habits/services/habit_lifecycle_manager.dart';
import 'package:my_dida/features/habits/services/habit_operation_reverter.dart';
import 'package:my_dida/features/operation_undo/models/operation.dart';
import 'package:my_dida/features/operation_undo/providers/operation_stack_provider.dart';
import 'package:my_dida/features/operation_undo/services/operation_reverter.dart';
import 'package:my_dida/features/tasks/models/task.dart';

void main() {
  late Isar isar;
  late Directory tempDir;
  late HabitRepository habitRepository;
  late HabitCheckInRecordRepository recordRepository;
  late OperationStackProvider operationStack;
  late HabitLifecycleManager lifecycleManager;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await getIt.reset();

    tempDir = await Directory.systemTemp.createTemp('my_dida_undo_habit_test_');
    isar = await Isar.open(
      [
        ChecklistSchema,
        HabitSchema,
        OperationSchema,
        TaskSchema,
        HabitCheckInRecordSchema,
      ],
      directory: tempDir.path,
      name: 'undo_habit_test_${DateTime.now().microsecondsSinceEpoch}',
    );

    getIt.registerSingleton<Isar>(isar);

    habitRepository = HabitRepository();
    getIt.registerSingleton<HabitRepository>(habitRepository);

    recordRepository = HabitCheckInRecordRepository();
    getIt.registerSingleton<HabitCheckInRecordRepository>(recordRepository);

    // 注册多态还原注册器
    final registry = EntityRegistry()
      ..register(OperationTarget.habit, HabitOperationReverter());
    getIt.registerSingleton<EntityRegistry>(registry);

    // 注册 OperationReverter
    getIt.registerSingleton<OperationReverter>(GenericOperationReverter());

    operationStack = OperationStackProvider();
    getIt.registerSingleton<OperationStackProvider>(operationStack);
    await operationStack.initialize();

    lifecycleManager = HabitLifecycleManagerImpl(
      habitRepository: habitRepository,
      recordRepository: recordRepository,
      operationStack: operationStack,
    );
    getIt.registerSingleton<HabitLifecycleManager>(lifecycleManager);
  });

  tearDown(() async {
    await getIt.reset();
    await isar.close(deleteFromDisk: true);
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Habit Undo Consistency Tests', () {
    test(
      'Check-in and skip operations can be recorded and fully undone with records removed',
      () async {
        // 1. 创建习惯
        final habit = Habit(
          name: 'Drink Water',
          icon: 'water',
          remindTime: DateTime.now(),
          checkInCount: 3,
          currentCheckInCount: 0,
          startDate: DateTime.now(),
          totalCheckInCount: 0,
          longestContinuousCheckInDays: 0,
        );
        await lifecycleManager.addHabit(habit);

        final savedHabit = (await habitRepository.getAllHabits()).first;
        expect(savedHabit.currentCheckInCount, 0);

        // 2. 打卡并验证记录
        await lifecycleManager.checkIn(savedHabit);
        final checkedHabit = await habitRepository.getHabitById(savedHabit.id);
        expect(checkedHabit!.currentCheckInCount, 1);
        expect(checkedHabit.totalCheckInCount, 1);

        final recordsAfterCheckIn = await recordRepository.getRecordsByHabitId(
          savedHabit.id,
        );
        expect(recordsAfterCheckIn.length, 1);
        expect(recordsAfterCheckIn.first.isSkip, false);

        // 3. 撤销打卡
        await operationStack.undo();
        final reloadedHabit = await habitRepository.getHabitById(savedHabit.id);
        expect(reloadedHabit!.currentCheckInCount, 0);
        expect(reloadedHabit.totalCheckInCount, 0);

        // 验证撤销后，打卡记录也被删除了
        final recordsAfterUndo = await recordRepository.getRecordsByHabitId(
          savedHabit.id,
        );
        expect(recordsAfterUndo, isEmpty);

        // 4. 跳过打卡
        await lifecycleManager.skipToday(reloadedHabit);
        final skippedHabit = await habitRepository.getHabitById(savedHabit.id);
        expect(skippedHabit!.isTodaySkipped, true);

        final recordsAfterSkip = await recordRepository.getRecordsByHabitId(
          savedHabit.id,
        );
        expect(recordsAfterSkip.length, 1);
        expect(recordsAfterSkip.first.isSkip, true);

        // 5. 撤销跳过打卡
        await operationStack.undo();
        final unskippedHabit = await habitRepository.getHabitById(
          savedHabit.id,
        );
        expect(unskippedHabit!.isTodaySkipped, false);

        // 验证撤销后，skip 记录也被删除
        final recordsAfterUndoSkip = await recordRepository.getRecordsByHabitId(
          savedHabit.id,
        );
        expect(recordsAfterUndoSkip, isEmpty);
      },
    );

    test(
      'Archive and unarchive operations can be recorded and undone',
      () async {
        final habit = Habit(
          name: 'Read Book',
          icon: 'book',
          remindTime: DateTime.now(),
          checkInCount: 1,
          currentCheckInCount: 0,
          startDate: DateTime.now(),
          totalCheckInCount: 0,
          longestContinuousCheckInDays: 0,
        );
        await lifecycleManager.addHabit(habit);
        final savedHabit = (await habitRepository.getAllHabits()).first;

        // 1. 归档习惯并撤销
        await lifecycleManager.archiveHabit(savedHabit.id);
        final archivedHabit = await habitRepository.getHabitById(savedHabit.id);
        expect(archivedHabit!.isArchived, true);

        await operationStack.undo();
        final reloadedHabit = await habitRepository.getHabitById(savedHabit.id);
        expect(reloadedHabit!.isArchived, false);

        // 2. 激活归档习惯并撤销（先归档，再激活，再撤销）
        await lifecycleManager.archiveHabit(savedHabit.id);
        expect(operationStack.operations.first.description, contains('归档'));

        await lifecycleManager.unarchiveHabit(savedHabit.id);
        final unarchivedHabit = await habitRepository.getHabitById(
          savedHabit.id,
        );
        expect(unarchivedHabit!.isArchived, false);
        expect(operationStack.operations.first.description, contains('激活'));

        await operationStack.undo();
        final finalHabit = await habitRepository.getHabitById(savedHabit.id);
        expect(finalHabit!.isArchived, true);
      },
    );

    test(
      'Delete habit operation and all check-in records can be fully undone',
      () async {
        // 1. 创建习惯
        final habit = Habit(
          name: 'Gym',
          icon: 'gym',
          remindTime: DateTime.now(),
          checkInCount: 3,
          currentCheckInCount: 0,
          startDate: DateTime.now(),
          totalCheckInCount: 0,
          longestContinuousCheckInDays: 0,
        );
        await lifecycleManager.addHabit(habit);
        final savedHabit = (await habitRepository.getAllHabits()).first;

        // 2. 打卡 2 次，产生 2 条记录
        await lifecycleManager.checkIn(savedHabit);
        await lifecycleManager.checkIn(savedHabit);

        final reloadedHabit = await habitRepository.getHabitById(savedHabit.id);
        final records = await recordRepository.getRecordsByHabitId(
          savedHabit.id,
        );
        expect(records.length, 2);

        // 3. 删除习惯
        // 清空操作栈里的打卡操作，专注于删除和撤销删除
        await operationStack.clearOperations();

        await lifecycleManager.deleteHabit(savedHabit.id);

        // 验证数据库中习惯和打卡流水都已经被彻底删除
        final deletedHabit = await habitRepository.getHabitById(savedHabit.id);
        expect(deletedHabit, isNull);

        final deletedRecords = await recordRepository.getRecordsByHabitId(
          savedHabit.id,
        );
        expect(deletedRecords, isEmpty);

        // 验证 Operation 栈里记录了复杂的 json 打包数据
        expect(operationStack.operations.length, 1);
        final op = operationStack.operations.first;
        expect(op.type, OperationType.delete);

        final decoded = jsonDecode(op.previousData!);
        expect(decoded.containsKey('habit'), true);
        expect(decoded.containsKey('records'), true);
        expect((decoded['records'] as List).length, 2);

        // 4. 撤销删除
        await operationStack.undo();

        // 验证撤销后，习惯被插回，并且 2 条打卡流水也恢复插回！
        final restoredHabit = await habitRepository.getHabitById(savedHabit.id);
        expect(restoredHabit, isNotNull);
        expect(restoredHabit!.name, 'Gym');
        expect(restoredHabit.currentCheckInCount, 2);

        final restoredRecords = await recordRepository.getRecordsByHabitId(
          savedHabit.id,
        );
        expect(restoredRecords.length, 2);
      },
    );
  });
}
