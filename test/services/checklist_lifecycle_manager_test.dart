import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:my_dida/config/locator.dart';
import 'package:my_dida/core/ui/app_message_service.dart';
import 'package:my_dida/model/entity/checklist.dart';
import 'package:my_dida/model/entity/habit.dart';
import 'package:my_dida/model/entity/operation.dart';
import 'package:my_dida/model/entity/task.dart';
import 'package:my_dida/repository/checklist_repository.dart';
import 'package:my_dida/services/checklist_lifecycle_manager.dart';

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
  });
}
