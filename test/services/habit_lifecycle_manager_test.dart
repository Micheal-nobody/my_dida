import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:my_dida/config/locator.dart';
import 'package:my_dida/model/entity/checklist.dart';
import 'package:my_dida/model/entity/habit.dart';
import 'package:my_dida/model/entity/habit_check_in_record.dart';
import 'package:my_dida/model/entity/operation.dart';
import 'package:my_dida/model/entity/task.dart';
import 'package:my_dida/provider/operation_stack_provider.dart';
import 'package:my_dida/repository/habit_repository.dart';
import 'package:my_dida/repository/habit_check_in_record_repository.dart';
import 'package:my_dida/services/habit_lifecycle_manager.dart';

void main() {
  late Isar isar;
  late Directory tempDir;
  late HabitRepository habitRepository;
  late OperationStackProvider operationStack;
  late HabitLifecycleManager lifecycleManager;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await getIt.reset();

    tempDir = await Directory.systemTemp.createTemp('my_dida_habit_test_');
    isar = await Isar.open(
      [
        ChecklistSchema,
        HabitSchema,
        OperationSchema,
        TaskSchema,
        HabitCheckInRecordSchema
      ],
      directory: tempDir.path,
      name: 'habit_test_${DateTime.now().microsecondsSinceEpoch}',
    );

    getIt.registerSingleton<Isar>(isar);

    habitRepository = HabitRepository();
    getIt.registerSingleton<HabitRepository>(habitRepository);

    final recordRepository = HabitCheckInRecordRepository();
    getIt.registerSingleton<HabitCheckInRecordRepository>(recordRepository);

    operationStack = OperationStackProvider();
    getIt.registerSingleton<OperationStackProvider>(operationStack);
    await operationStack.initialize();

    lifecycleManager = HabitLifecycleManagerImpl(
      habitRepository: habitRepository,
      operationStack: operationStack,
    );
  });

  tearDown(() async {
    await getIt.reset();
    await isar.close(deleteFromDisk: true);
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('HabitLifecycleManager Tests', () {
    test('addHabit inserts habit into DB and records add operation', () async {
      final habit = Habit(
        name: 'Exercise',
        icon: 'gym',
        remindTime: DateTime.now(),
        checkInCount: 1,
        currentCheckInCount: 0,
        startDate: DateTime.now(),
        totalCheckInCount: 0,
        longestContinuousCheckInDays: 0,
      );

      await lifecycleManager.addHabit(habit);

      final habits = await habitRepository.getAllHabits();
      expect(habits.length, 1);
      expect(habits.first.name, 'Exercise');

      expect(operationStack.operations.length, 1);
      expect(operationStack.operations.first.type, OperationType.add);
      expect(operationStack.operations.first.target, OperationTarget.habit);
    });

    test(
      'updateHabit updates habit details and records update operation',
      () async {
        final habit = Habit(
          name: 'Old Habit',
          icon: 'book',
          remindTime: DateTime.now(),
          checkInCount: 2,
          currentCheckInCount: 0,
          startDate: DateTime.now(),
          totalCheckInCount: 0,
          longestContinuousCheckInDays: 0,
        );
        await habitRepository.addHabit(habit);

        // Mutate the habit and update
        habit.name = 'Updated Habit';
        await lifecycleManager.updateHabit(habit);

        final reloaded = await habitRepository.getHabitById(habit.id);
        expect(reloaded?.name, 'Updated Habit');

        expect(
          operationStack.operations.length,
          1,
        ); // Only update operation is added
        expect(operationStack.operations.first.type, OperationType.update);
        expect(operationStack.operations.first.description, contains('更新了习惯'));
      },
    );

    test('deleteHabit deletes habit and records delete operation', () async {
      final habit = Habit(
        name: 'To Delete',
        icon: 'run',
        remindTime: DateTime.now(),
        checkInCount: 1,
        currentCheckInCount: 0,
        startDate: DateTime.now(),
        totalCheckInCount: 0,
        longestContinuousCheckInDays: 0,
      );
      await habitRepository.addHabit(habit);

      await lifecycleManager.deleteHabit(habit.id);

      final habits = await habitRepository.getAllHabits();
      expect(habits.isEmpty, isTrue);

      expect(operationStack.operations.length, 1);
      expect(operationStack.operations.first.type, OperationType.delete);
    });

    test('checkIn increments counts and records checkIn operation', () async {
      final habit = Habit(
        name: 'Meditation',
        icon: 'mind',
        remindTime: DateTime.now(),
        checkInCount: 3,
        currentCheckInCount: 0,
        totalCheckInCount: 10,
        startDate: DateTime.now(),
        longestContinuousCheckInDays: 0,
      );
      await habitRepository.addHabit(habit);

      await lifecycleManager.checkIn(habit);

      final reloaded = await habitRepository.getHabitById(habit.id);
      expect(reloaded?.currentCheckInCount, 1);
      expect(reloaded?.totalCheckInCount, 11);

      expect(operationStack.operations.length, 1);
      expect(operationStack.operations.first.type, OperationType.update);
      expect(
        operationStack.operations.first.description,
        contains('完成了习惯"Meditation"的打卡'),
      );
    });

    test('skipToday updates habit in repository', () async {
      final habit = Habit(
        name: 'Drink Water',
        icon: 'water',
        remindTime: DateTime.now(),
        checkInCount: 5,
        currentCheckInCount: 0,
        startDate: DateTime.now(),
        totalCheckInCount: 0,
        longestContinuousCheckInDays: 0,
      );
      await habitRepository.addHabit(habit);

      habit.name = 'Skipped';
      await lifecycleManager.skipToday(habit);

      final reloaded = await habitRepository.getHabitById(habit.id);
      expect(reloaded?.name, 'Skipped');
    });

    test(
      'resetTodayCheckInCounts resets current check in counts of all habits',
      () async {
        final habit1 = Habit(
          name: 'Habit 1',
          icon: 'gym',
          remindTime: DateTime.now(),
          checkInCount: 2,
          currentCheckInCount: 2,
          startDate: DateTime.now(),
          totalCheckInCount: 0,
          longestContinuousCheckInDays: 0,
        );
        final habit2 = Habit(
          name: 'Habit 2',
          icon: 'book',
          remindTime: DateTime.now(),
          checkInCount: 3,
          currentCheckInCount: 1,
          startDate: DateTime.now(),
          totalCheckInCount: 0,
          longestContinuousCheckInDays: 0,
        );

        await habitRepository.addHabit(habit1);
        await habitRepository.addHabit(habit2);

        await lifecycleManager.resetTodayCheckInCounts();

        final reloaded1 = await habitRepository.getHabitById(habit1.id);
        final reloaded2 = await habitRepository.getHabitById(habit2.id);

        expect(reloaded1?.currentCheckInCount, 0);
        expect(reloaded2?.currentCheckInCount, 0);
      },
    );

    test('undoLastCheckIn decrements check in counts', () async {
      final habit = Habit(
        name: 'Habit',
        icon: 'run',
        remindTime: DateTime.now(),
        checkInCount: 5,
        currentCheckInCount: 2,
        totalCheckInCount: 15,
        startDate: DateTime.now(),
        longestContinuousCheckInDays: 0,
      );
      await habitRepository.addHabit(habit);

      await lifecycleManager.undoLastCheckIn(habit);

      final reloaded = await habitRepository.getHabitById(habit.id);
      expect(reloaded?.currentCheckInCount, 1);
      expect(reloaded?.totalCheckInCount, 14);
    });

    test('undoAllCheckIns resets check in counts', () async {
      final habit = Habit(
        name: 'Habit',
        icon: 'mind',
        remindTime: DateTime.now(),
        checkInCount: 5,
        currentCheckInCount: 3,
        totalCheckInCount: 20,
        startDate: DateTime.now(),
        longestContinuousCheckInDays: 0,
      );
      await habitRepository.addHabit(habit);

      await lifecycleManager.undoAllCheckIns(habit);

      final reloaded = await habitRepository.getHabitById(habit.id);
      expect(reloaded?.currentCheckInCount, 0);
      expect(reloaded?.totalCheckInCount, 17);
    });

    test('skipToday sets isTodaySkipped and creates skip record', () async {
      final habit = Habit(
        name: 'Drink Water',
        icon: 'water',
        remindTime: DateTime.now(),
        checkInCount: 5,
        currentCheckInCount: 0,
        startDate: DateTime.now(),
        totalCheckInCount: 0,
        longestContinuousCheckInDays: 0,
      );
      await habitRepository.addHabit(habit);

      await lifecycleManager.skipToday(habit);

      final reloaded = await habitRepository.getHabitById(habit.id);
      expect(reloaded?.isTodaySkipped, isTrue);

      final recordRepository = getIt<HabitCheckInRecordRepository>();
      final records = await recordRepository.getRecordsByHabitId(habit.id);
      expect(records.length, 1);
      expect(records.first.isSkip, isTrue);
    });

    test('archive and unarchive habits', () async {
      final habit = Habit(
        name: 'Habit',
        icon: 'mind',
        remindTime: DateTime.now(),
        checkInCount: 5,
        currentCheckInCount: 0,
        startDate: DateTime.now(),
        totalCheckInCount: 0,
        longestContinuousCheckInDays: 0,
      );
      await habitRepository.addHabit(habit);

      await lifecycleManager.archiveHabit(habit.id);
      var reloaded = await habitRepository.getHabitById(habit.id);
      expect(reloaded?.isArchived, isTrue);

      await lifecycleManager.unarchiveHabit(habit.id);
      reloaded = await habitRepository.getHabitById(habit.id);
      expect(reloaded?.isArchived, isFalse);
    });

    test('reorder habits assigns sortOrder', () async {
      final habit1 = Habit(
        name: 'H1',
        icon: 'mind',
        remindTime: DateTime.now(),
        checkInCount: 1,
        currentCheckInCount: 0,
        startDate: DateTime.now(),
        totalCheckInCount: 0,
        longestContinuousCheckInDays: 0,
      );
      final habit2 = Habit(
        name: 'H2',
        icon: 'mind',
        remindTime: DateTime.now(),
        checkInCount: 1,
        currentCheckInCount: 0,
        startDate: DateTime.now(),
        totalCheckInCount: 0,
        longestContinuousCheckInDays: 0,
      );
      await habitRepository.addHabit(habit1);
      await habitRepository.addHabit(habit2);

      await lifecycleManager.reorderHabits([habit2, habit1]);

      final reloaded1 = await habitRepository.getHabitById(habit1.id);
      final reloaded2 = await habitRepository.getHabitById(habit2.id);
      expect(reloaded2?.sortOrder, 0);
      expect(reloaded1?.sortOrder, 1);
    });
  });
}
