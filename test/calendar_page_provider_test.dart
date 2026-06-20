import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:my_dida/config/locator.dart';
import 'package:my_dida/model/entity/calendar_page_config.dart';
import 'package:my_dida/provider/calendar_page_provider.dart';

void main() {
  late Isar isar;
  late Directory tempDir;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await getIt.reset();

    tempDir = await Directory.systemTemp.createTemp(
      'my_dida_calendar_provider_test_',
    );
    isar = await Isar.open(
      [CalendarPageConfigSchema],
      directory: tempDir.path,
      name: 'calendar_provider_test_${DateTime.now().microsecondsSinceEpoch}',
    );

    getIt.registerSingleton<Isar>(isar);
  });

  tearDown(() async {
    await getIt.reset();
    await isar.close(deleteFromDisk: true);
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('CalendarPageProvider configuration tests', () {
    test('Should initialize with default config', () async {
      final provider = CalendarPageProvider();
      // wait for async _loadConfig to complete in constructor (needs a small delay or pump)
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.config.showCompletedTasks, true);
      expect(provider.config.visibleMode, 'all');
      expect(provider.config.visibleChecklistIds, isEmpty);
      expect(provider.config.viewMode, 'month');
      expect(provider.config.isTimeFolded, false);
    });

    test('Should update config and persist it in Isar', () async {
      final provider = CalendarPageProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      await provider.updateConfig(
        showCompletedTasks: false,
        visibleMode: 'custom',
        visibleChecklistIds: [1, 2, 3],
        viewMode: 'week',
        isTimeFolded: true,
      );

      expect(provider.config.showCompletedTasks, false);
      expect(provider.config.visibleMode, 'custom');
      expect(provider.config.visibleChecklistIds, [1, 2, 3]);
      expect(provider.config.viewMode, 'week');
      expect(provider.config.isTimeFolded, true);

      // Verify it's persisted in the database
      final persisted = await isar.calendarPageConfigs.where().findFirst();
      expect(persisted, isNotNull);
      expect(persisted!.showCompletedTasks, false);
      expect(persisted.visibleMode, 'custom');
      expect(persisted.visibleChecklistIds, [1, 2, 3]);
      expect(persisted.viewMode, 'week');
      expect(persisted.isTimeFolded, true);
    });
  });
}
