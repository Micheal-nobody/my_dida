import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/core/ui/app_message_service.dart';
import 'package:my_dida/features/checklist/models/checklist.dart';
import 'package:my_dida/features/checklist/repositories/checklist_repository.dart';
import 'package:my_dida/features/checklist/services/checklist_lifecycle_manager.dart';
import 'package:my_dida/features/habits/models/habit.dart';
import 'package:my_dida/features/operation_undo/models/operation.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/tasks/repositories/task_repository.dart';

class FakeAppMessageService extends AppMessageService {
  final List<String> successMessages = [];
  final List<String> errorMessages = [];

  @override
  void showSuccess(String message, {Duration? duration}) {
    successMessages.add(message);
  }

  @override
  void showError(String message, {Duration? duration}) {
    errorMessages.add(message);
  }
}

void main() {
  late Isar isar;
  late Directory tempDir;
  late ChecklistRepository checklistRepository;
  late FakeAppMessageService messageService;
  late ChecklistLifecycleManager lifecycleManager;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await getIt.reset();

    tempDir = await Directory.systemTemp.createTemp('my_dida_checklist_test_');
    isar = await Isar.open(
      [ChecklistSchema, HabitSchema, OperationSchema, TaskSchema],
      directory: tempDir.path,
      name: 'checklist_test_${DateTime.now().microsecondsSinceEpoch}',
    );

    messageService = FakeAppMessageService();
    getIt.registerSingleton<Isar>(isar);
    getIt.registerSingleton<AppMessageService>(messageService);

    checklistRepository = ChecklistRepository();
    getIt.registerSingleton<ChecklistRepository>(checklistRepository);
    getIt.registerSingleton<TaskRepository>(TaskRepository());

    lifecycleManager = ChecklistLifecycleManagerImpl(
      checklistRepository: checklistRepository,
      messageService: messageService,
    );
  });

  tearDown(() async {
    await getIt.reset();
    await isar.close(deleteFromDisk: true);
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('ChecklistLifecycleManager Tests', () {
    test(
      'createChecklist inserts checklist into DB and shows success message',
      () async {
        await lifecycleManager.createChecklist('Test Checklist', 0xFF0000);

        final checklists = await checklistRepository.getAllData();
        expect(checklists.length, 1);
        expect(checklists.first.name, 'Test Checklist');
        expect(checklists.first.colorValue, 0xFF0000);

        expect(messageService.successMessages, contains('清单创建成功！'));
      },
    );

    test('createChecklist throws and shows error when name is empty', () async {
      expect(
        () => lifecycleManager.createChecklist('  ', 0xFF0000),
        throwsA(isA<Exception>()),
      );

      final checklists = await checklistRepository.getAllData();
      expect(checklists.isEmpty, isTrue);

      expect(messageService.errorMessages, isNotEmpty);
    });

    test(
      'updateChecklist updates name and color of existing checklist',
      () async {
        final checklist = Checklist(name: 'Old Name', colorValue: 0x00FF00);
        await checklistRepository.addData(checklist);

        checklist.name = 'New Name';
        checklist.colorValue = 0x0000FF;

        await lifecycleManager.updateChecklist(checklist);

        final checklists = await checklistRepository.getAllData();
        expect(checklists.length, 1);
        expect(checklists.first.name, 'New Name');
        expect(checklists.first.colorValue, 0x0000FF);
        expect(messageService.successMessages, contains('清单更新成功！'));
      },
    );

    test('deleteChecklist deletes checklist by ID', () async {
      final checklist = Checklist(name: 'To Delete', colorValue: 0x00FF00);
      await checklistRepository.addData(checklist);
      final id = checklist.id;

      await lifecycleManager.deleteChecklist(id, name: 'To Delete');

      final checklists = await checklistRepository.getAllData();
      expect(checklists.isEmpty, isTrue);
      expect(messageService.successMessages, contains('Deleted "To Delete"'));
    });

    test(
      'deleteChecklist reassigns its tasks to inbox (ID=1) and deletes checklist',
      () async {
        // Create a checklist to delete
        final checklist = Checklist(name: 'To Delete', colorValue: 0x00FF00);
        await checklistRepository.addData(checklist);
        final deleteId = checklist.id;

        // Ensure Inbox checklist (ID = 1) exists in the database
        final inboxChecklist = Checklist(name: '收集箱')..id = 1;
        await checklistRepository.addData(inboxChecklist);

        // Create tasks associated with the deleted checklist and another checklist
        final taskRepo = getIt<TaskRepository>();
        final task1 = Task(
          name: 'Task 1',
          isAllDay: false,
          checklistId: deleteId,
        );
        final task2 = Task(
          name: 'Task 2',
          isAllDay: false,
          checklistId: deleteId,
        );
        final taskOther = Task(
          name: 'Task Other',
          isAllDay: false,
          checklistId: 999,
        );

        await taskRepo.addData(task1);
        await taskRepo.addData(task2);
        await taskRepo.addData(taskOther);

        // Delete the checklist
        await lifecycleManager.deleteChecklist(deleteId, name: 'To Delete');

        // Verify the checklist is gone
        final checklists = await checklistRepository.getAllData();
        expect(checklists.any((c) => c.id == deleteId), isFalse);

        // Verify task reassignment
        final updatedTask1 = await taskRepo.selectById(task1.id);
        final updatedTask2 = await taskRepo.selectById(task2.id);
        final updatedTaskOther = await taskRepo.selectById(taskOther.id);

        expect(updatedTask1?.checklistId, equals(1));
        expect(updatedTask2?.checklistId, equals(1));
        expect(updatedTaskOther?.checklistId, equals(999));
      },
    );
  });
}
