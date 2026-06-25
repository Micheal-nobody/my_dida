import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/core/ui/app_message_service.dart';
import 'package:my_dida/features/tasks/services/attachment_service.dart';
import 'package:path/path.dart' as p;

class MockAppMessageService extends AppMessageService {
  String? lastWarning;

  @override
  void showWarning(String message, {Duration? duration}) {
    lastWarning = message;
  }
}

void main() {
  late Directory tempDir;
  late AttachmentServiceImpl service;
  late MockAppMessageService mockMessageService;

  setUp(() async {
    // 每次测试创建独立的临时目录
    tempDir = await Directory.systemTemp.createTemp('my_dida_attachment_test');
    service = AttachmentServiceImpl(
      documentsDirectoryProvider: () async => tempDir,
    );

    mockMessageService = MockAppMessageService();
    // 注册 mock 的 AppMessageService 以避免测试中的 Toast/Messenger 抛空指针
    if (getIt.isRegistered<AppMessageService>()) {
      await getIt.unregister<AppMessageService>();
    }
    getIt.registerSingleton<AppMessageService>(mockMessageService);
  });

  tearDown(() async {
    // 清理临时文件系统
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
    // 恢复 mock 注册
    await getIt.unregister<AppMessageService>();
  });

  group('AttachmentService Tests', () {
    test('resolvePath should parse attachments:// correctly', () async {
      final ref = 'attachments://100/my_photo.png';
      final resolved = await service.resolvePath(ref);
      expect(
        resolved,
        p.join(tempDir.path, kAttachmentDirName, '100', 'my_photo.png'),
      );
    });

    test('totalSizeOfTask should calculate aggregate size correctly', () async {
      const taskId = 200;
      final taskDir = Directory(
        p.join(tempDir.path, kAttachmentDirName, '$taskId'),
      );
      await taskDir.create(recursive: true);

      // 写两个测试文件
      await File(p.join(taskDir.path, 'f1.txt')).writeAsBytes([1, 2, 3]);
      await File(p.join(taskDir.path, 'f2.txt')).writeAsBytes([4, 5, 6, 7]);

      final total = await service.totalSizeOfTask(taskId);
      expect(total, 7);
    });

    test('deleteAllAttachments should remove whole task directory', () async {
      const taskId = 300;
      final taskDir = Directory(
        p.join(tempDir.path, kAttachmentDirName, '$taskId'),
      );
      await taskDir.create(recursive: true);
      await File(p.join(taskDir.path, 'f1.txt')).writeAsBytes([1, 2, 3]);

      expect(await taskDir.exists(), isTrue);
      await service.deleteAllAttachments(taskId);
      expect(await taskDir.exists(), isFalse);
    });

    test('cleanupOrphans should delete folders of missing taskIds', () async {
      final attachmentsRoot = Directory(
        p.join(tempDir.path, kAttachmentDirName),
      );
      await attachmentsRoot.create(recursive: true);

      // 创建三个任务附件目录：1, 2, 3
      final t1 = Directory(p.join(attachmentsRoot.path, '1'))..createSync();
      final t2 = Directory(p.join(attachmentsRoot.path, '2'))..createSync();
      final t3 = Directory(p.join(attachmentsRoot.path, '3'))..createSync();

      expect(t1.existsSync(), isTrue);
      expect(t2.existsSync(), isTrue);
      expect(t3.existsSync(), isTrue);

      // 假设当前有效的 taskId 只有 1 和 3，2 应该被清理
      await service.cleanupOrphans([1, 3]);

      expect(t1.existsSync(), isTrue);
      expect(t2.existsSync(), isFalse);
      expect(t3.existsSync(), isTrue);
    });

    test('saveBytes should enforce single file size limit (50MB)', () async {
      const taskId = 400;

      // 构造 50MB + 1 字节的数据
      final oversize = kMaxSingleAttachmentBytes + 1;
      final fakeBytes = Uint8List(oversize);

      expect(
        () => service.saveBytes(
          taskId: taskId,
          bytes: fakeBytes,
          extension: '.dat',
        ),
        throwsA(
          isA<AttachmentLimitException>().having(
            (e) => e.kind,
            'kind',
            AttachmentLimitKind.singleFile,
          ),
        ),
      );
    });

    test('saveBytes should enforce total task size limit (500MB)', () async {
      const taskId = 500;
      final taskDir = Directory(
        p.join(tempDir.path, kAttachmentDirName, '$taskId'),
      );
      await taskDir.create(recursive: true);

      // 模拟当前已经占用了 490MB
      final currentSize = 490 * 1024 * 1024;
      await File(p.join(taskDir.path, 'large.bin')).writeAsBytes(
        Uint8List(10), // 我们不需要真的写 490MB 撑爆内存，直接在 totalSizeOfTask 上 mock 或规避。
      );
      // 为了精确测试总量限制又不耗尽内存，我们直接通过分次写入 20MB 文件来累计触发：
      // 例如：分 26 次写入 20MB 文件，最后一次会超 500MB。
      final chunk = 20 * 1024 * 1024;
      final chunkBytes = Uint8List(chunk);

      // 连续写入，直到报错总量超限
      int writtenCount = 0;
      bool threw = false;

      try {
        for (int i = 0; i < 30; i++) {
          await service.saveBytes(
            taskId: taskId,
            bytes: chunkBytes,
            extension: '.bin',
          );
          writtenCount++;
        }
      } on AttachmentLimitException catch (e) {
        threw = true;
        expect(e.kind, AttachmentLimitKind.taskTotal);
      }

      expect(threw, isTrue);
      // 500MB / 20MB = 25 次，在第 26 次写入时一定会触发异常拦截
      expect(writtenCount, lessThanOrEqualTo(25));
    });
  });
}
