import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/core/logger/logger.dart';
import 'package:my_dida/core/ui/app_message_service.dart';
import 'package:my_dida/core/utils/markdown_utils.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 附件目录名（位于 App 私有目录下）。
const String kAttachmentDirName = 'task_attachments';

/// 单个附件文件大小上限：50MB。
const int kMaxSingleAttachmentBytes = 50 * 1024 * 1024;

/// 单个任务附件总量上限：500MB。
const int kMaxTaskAttachmentBytes = 500 * 1024 * 1024;

/// 任务附件管理服务。
///
/// 负责：
/// - 选源（相册/相机/文件）并拷贝到 App 私有目录
/// - 限额校验（单文件 50MB、单任务 500MB）
/// - 附件虚拟路径（`attachments://<taskId>/<fileName>`）↔ 沙盒绝对路径互转
/// - 按 taskId 统计占用、清理全部附件
/// - 启动孤儿扫描：删除 Isar 中不存在的 taskId 对应目录
///
/// 附件存储在 `${appDocDir}/task_attachments/<taskId>/<uuid>.<ext>` 下。
abstract class AttachmentService {
  /// 解析 `attachments://<taskId>/<fileName>` 为沙盒绝对路径。
  ///
  /// 入参若非 attachments 协议（如普通 http(s) 链接），原样返回。
  ///
  /// 由于解析依赖 path_provider（异步），提供异步方法 [resolvePathAsync]。
  Future<String> resolvePath(String ref);

  /// 从相册选图并拷贝到沙盒，返回 Markdown 图片引用。
  /// 失败或用户取消时返回 null（已 toast 提示）。
  Future<String?> pickImageFromGallery(int taskId);

  /// 调用相机拍照并拷贝到沙盒，返回 Markdown 图片引用。
  Future<String?> pickImageFromCamera(int taskId);

  /// 选择任意文件并拷贝到沙盒，返回 Markdown 文件引用。
  Future<String?> pickFile(int taskId);

  /// 计算某任务当前附件总占用字节（扫描目录求和）。
  Future<int> totalSizeOfTask(int taskId);

  /// 永久删除某任务的全部附件（删除整个 task 目录）。
  Future<void> deleteAllAttachments(int taskId);

  /// 启动孤儿扫描：删除 [validTaskIds] 之外的所有 task 附件目录。
  ///
  /// 传入当前 DB 中全部 taskId，未传入的 taskId 目录视为孤儿删除。
  Future<void> cleanupOrphans(Iterable<int> validTaskIds);

  /// 判断某个附件引用指向的文件是否真实存在于磁盘。
  Future<bool> exists(String ref);
}

class AttachmentServiceImpl implements AttachmentService {
  AttachmentServiceImpl({
    Future<Directory> Function()? documentsDirectoryProvider,
    ImagePicker? imagePicker,
  }) : _documentsDirectoryProvider =
            documentsDirectoryProvider ?? getApplicationDocumentsDirectory,
       _imagePicker = imagePicker ?? ImagePicker();

  final Future<Directory> Function() _documentsDirectoryProvider;
  final ImagePicker _imagePicker;

  /// 抽象出"拷贝一段字节流到沙盒"的逻辑，便于测试与复用。
  ///
  /// 返回写入后的 [fileName]（含扩展名）。失败抛异常。
  @visibleForTesting
  Future<String> saveBytes({
    required int taskId,
    required Uint8List bytes,
    required String extension,
    String? preferredName,
  }) async {
    // 单文件限额
    if (bytes.length > kMaxSingleAttachmentBytes) {
      throw const AttachmentLimitException(
        AttachmentLimitKind.singleFile,
        '单个文件不能超过 50MB',
      );
    }

    // 任务总量限额
    final currentTotal = await totalSizeOfTask(taskId);
    if (currentTotal + bytes.length > kMaxTaskAttachmentBytes) {
      throw const AttachmentLimitException(
        AttachmentLimitKind.taskTotal,
        '该任务附件已达上限（500MB）',
      );
    }

    final taskDir = await _taskDir(taskId);
    final base = preferredName != null && preferredName.isNotEmpty
        ? _sanitizeName(preferredName)
        : _generateId();
    final fileName = '$base$extension';
    final filePath = p.join(taskDir.path, fileName);
    await File(filePath).writeAsBytes(bytes);
    return fileName;
  }

  @override
  Future<String> resolvePath(String ref) async {
    if (!ref.startsWith(MarkdownUtils.attachmentScheme)) {
      return ref; // 非 attachments 协议，原样返回（如 http 链接）
    }
    final relative = ref.substring(MarkdownUtils.attachmentScheme.length);
    final root = await _rootDir();
    return p.normalize(p.join(root.path, kAttachmentDirName, relative));
  }

  @override
  Future<String?> pickImageFromGallery(int taskId) async {
    try {
      final xFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (xFile == null) return null; // 用户取消
      return await _persistPickedFile(taskId, xFile, isImage: true);
    } on AttachmentLimitException {
      rethrow;
    } catch (e) {
      logger.w('从相册选图失败: $e');
      _toast('请在系统设置中开启相册权限');
      return null;
    }
  }

  @override
  Future<String?> pickImageFromCamera(int taskId) async {
    try {
      final xFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
      );
      if (xFile == null) return null;
      return await _persistPickedFile(taskId, xFile, isImage: true);
    } on AttachmentLimitException {
      rethrow;
    } catch (e) {
      logger.w('相机拍照失败: $e');
      _toast('请在系统设置中开启相机权限');
      return null;
    }
  }

  @override
  Future<String?> pickFile(int taskId) async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result == null || result.files.isEmpty) return null;
      final platformFile = result.files.first;
      final bytes = platformFile.bytes;
      final path = platformFile.path;

      // 移动端可能只给 bytes，桌面端给 path
      Uint8List data;
      if (bytes != null) {
        data = bytes;
      } else if (path != null) {
        data = await File(path).readAsBytes();
      } else {
        return null;
      }

      final extension = _extensionOf(platformFile.name);
      final fileName = await saveBytes(
        taskId: taskId,
        bytes: data,
        extension: extension,
        preferredName: platformFile.name,
      );
      return MarkdownUtils.buildFileRef(taskId, fileName);
    } on AttachmentLimitException {
      rethrow;
    } catch (e) {
      logger.w('选择文件失败: $e');
      _toast('选择文件失败');
      return null;
    }
  }

  @override
  Future<int> totalSizeOfTask(int taskId) async {
    try {
      final dir = await _taskDir(taskId);
      if (!await dir.exists()) return 0;
      var total = 0;
      await for (final entity in dir.list(recursive: false, followLinks: false)) {
        if (entity is File) {
          total += await entity.length();
        }
      }
      return total;
    } catch (e) {
      logger.w('统计任务附件大小失败: $e');
      return 0;
    }
  }

  @override
  Future<void> deleteAllAttachments(int taskId) async {
    try {
      final dir = await _taskDir(taskId);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      logger.w('删除任务附件失败: $e');
    }
  }

  @override
  Future<void> cleanupOrphans(Iterable<int> validTaskIds) async {
    try {
      final root = await _rootDir();
      final baseDir = Directory(p.join(root.path, kAttachmentDirName));
      if (!await baseDir.exists()) return;

      final valid = validTaskIds.toSet();
      await for (final entity
          in baseDir.list(recursive: false, followLinks: false)) {
        if (entity is! Directory) continue;
        final name = p.basename(entity.path);
        final id = int.tryParse(name);
        if (id == null || !valid.contains(id)) {
          await entity.delete(recursive: true);
          logger.i('清理孤儿附件目录: $name');
        }
      }
    } catch (e) {
      logger.w('孤儿附件扫描失败: $e');
    }
  }

  @override
  Future<bool> exists(String ref) async {
    final path = await resolvePath(ref);
    return File(path).exists();
  }

  // ------------------------------------------------------------------
  // 私有辅助
  // ------------------------------------------------------------------

  Future<Directory> _rootDir() => _documentsDirectoryProvider();

  Future<Directory> _taskDir(int taskId) async {
    final root = await _rootDir();
    final dir = Directory(p.join(root.path, kAttachmentDirName, '$taskId'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String?> _persistPickedFile(
    int taskId,
    XFile xFile, {
    required bool isImage,
  }) async {
    final bytes = await xFile.readAsBytes();
    final extension = _extensionOf(xFile.name);
    final fileName = await saveBytes(
      taskId: taskId,
      bytes: bytes,
      extension: extension,
      preferredName: xFile.name,
    );
    if (isImage) {
      return MarkdownUtils.buildImageRef(taskId, fileName);
    }
    return MarkdownUtils.buildFileRef(taskId, fileName);
  }

  String _extensionOf(String fileName) {
    final dot = p.extension(fileName);
    return dot.isEmpty ? '' : dot;
  }

  String _sanitizeName(String name) {
    // 保留文件名主体（去扩展名），只留字母数字下划线连字符，避免路径注入。
    final withoutExt = p.basenameWithoutExtension(name);
    final cleaned = withoutExt.replaceAll(RegExp(r'[^\w\u4e00-\u9fa5\-]'), '_');
    return cleaned.isEmpty ? _generateId() : cleaned;
  }

  String _generateId() {
    final r = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final rand = List.generate(
      6,
      (_) => r.nextInt(36).toRadixString(36),
    ).join();
    return '${timestamp}_$rand';
  }

  void _toast(String message) {
    getIt<AppMessageService>().showWarning(message);
  }
}

/// 附件限额异常类型。
enum AttachmentLimitKind { singleFile, taskTotal }

class AttachmentLimitException implements Exception {
  const AttachmentLimitException(this.kind, this.message);

  final AttachmentLimitKind kind;
  final String message;

  @override
  String toString() => 'AttachmentLimitException(${kind.name}): $message';
}
