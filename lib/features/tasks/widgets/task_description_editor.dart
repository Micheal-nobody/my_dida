import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown_editor_plus/markdown_editor_plus.dart';
import 'package:markdown_editor_plus/src/toolbar.dart' as mep;
import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/core/ui/app_message_service.dart';
import 'package:my_dida/core/utils/markdown_utils.dart';
import 'package:my_dida/features/tasks/services/attachment_service.dart';

class TaskDescriptionEditor extends StatefulWidget {
  const TaskDescriptionEditor({
    required this.taskId,
    required this.value,
    required this.onSubmit,
    super.key,
    this.onChanged,
    this.hintText = '添加备注...',
  });

  final int taskId;
  final String value;
  final Future<void> Function(String value) onSubmit;
  final void Function(String value)? onChanged;
  final String hintText;

  @override
  State<TaskDescriptionEditor> createState() => _TaskDescriptionEditorState();
}

class _TaskDescriptionEditorState extends State<TaskDescriptionEditor> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  late mep.Toolbar _mepToolbar;
  bool _isEditing = false;
  late final AttachmentService _attachmentService;

  @override
  void initState() {
    super.initState();
    _attachmentService = getIt<AttachmentService>();
    _controller = TextEditingController(text: widget.value);

    _mepToolbar = mep.Toolbar(
      controller: _controller,
      bringEditorToFocus: () {
        if (!_focusNode.hasFocus) {
          _focusNode.requestFocus();
        }
      },
    );

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        _commit();
      }
    });
  }

  @override
  void didUpdateWidget(covariant TaskDescriptionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 只有在非编辑状态下，外部值变化才同步到 controller
    if (!_isEditing && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _commit() async {
    final value = _controller.text.trim();
    await widget.onSubmit(value);
    if (mounted) {
      setState(() {
        _isEditing = false;
      });
    }
  }

  // 插入图片的底部分享/选择菜单
  void _showImagePickerSourceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('从相册选择'),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final ref = await _attachmentService.pickImageFromGallery(
                    widget.taskId,
                  );
                  if (ref != null) {
                    _insertAttachmentRef(ref);
                  }
                } on AttachmentLimitException catch (e) {
                  getIt<AppMessageService>().showWarning(e.message);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('拍照'),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final ref = await _attachmentService.pickImageFromCamera(
                    widget.taskId,
                  );
                  if (ref != null) {
                    _insertAttachmentRef(ref);
                  }
                } on AttachmentLimitException catch (e) {
                  getIt<AppMessageService>().showWarning(e.message);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // 插入文件选择
  Future<void> _pickFile(BuildContext context) async {
    try {
      final ref = await _attachmentService.pickFile(widget.taskId);
      if (ref != null) {
        _insertAttachmentRef(ref);
      }
    } on AttachmentLimitException catch (e) {
      getIt<AppMessageService>().showWarning(e.message);
    }
  }

  void _insertAttachmentRef(String ref) {
    // 强制把焦点拉回输入框，并在光标处插入 Markdown
    _focusNode.requestFocus();
    // 延时一下确保焦点拉回并键盘弹起后插入，避免光标错位
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mepToolbar.action('\n$ref\n', '');
      widget.onChanged?.call(_controller.text);
    });
  }

  // 附件链接点击处理（非图片链接）
  Future<void> _handleAttachmentClick(
    BuildContext context,
    String text,
    String href,
  ) async {
    final resolvedPath = await _attachmentService.resolvePath(href);
    final file = File(resolvedPath);
    final isExist = await file.exists();
    final fileSize = isExist ? await file.length() : 0;
    final sizeKb = (fileSize / 1024).toStringAsFixed(1);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(text.isNotEmpty ? text : '附件文件'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('路径: $resolvedPath', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Text('状态: ${isExist ? "已下载本地 ($sizeKb KB)" : "已丢失或不可访问"}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 空内容或正处于编辑态时，显示编辑器
    final showEditor = _isEditing || MarkdownUtils.isEffectivelyEmpty(widget.value);

    if (showEditor) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: MarkdownField(
              controller: _controller,
              focusNode: _focusNode,
              minLines: 3,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: widget.hintText,
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: widget.onChanged,
              onTap: () {
                if (!_isEditing) {
                  setState(() {
                    _isEditing = true;
                  });
                }
              },
            ),
          ),
          // 自研紧凑的 Markdown 工具栏
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                _buildToolbarButton(
                  icon: Icons.format_bold,
                  tooltip: '加粗',
                  onPressed: () => _mepToolbar.action('**', '**'),
                ),
                _buildToolbarButton(
                  icon: Icons.format_italic,
                  tooltip: '斜体',
                  onPressed: () => _mepToolbar.action('_', '_'),
                ),
                _buildToolbarButton(
                  icon: Icons.format_strikethrough,
                  tooltip: '中划线',
                  onPressed: () => _mepToolbar.action('~~', '~~'),
                ),
                _buildToolbarButton(
                  icon: Icons.format_list_bulleted,
                  tooltip: '列表',
                  onPressed: () => _mepToolbar.action('\n- ', ''),
                ),
                _buildToolbarButton(
                  icon: Icons.add_task,
                  tooltip: '任务列表',
                  onPressed: () => _mepToolbar.action('\n- [ ] ', ''),
                ),
                const VerticalDivider(width: 8, thickness: 1),
                _buildToolbarButton(
                  icon: Icons.image,
                  tooltip: '插入图片',
                  onPressed: () => _showImagePickerSourceDialog(context),
                ),
                _buildToolbarButton(
                  icon: Icons.insert_drive_file,
                  tooltip: '插入文件',
                  onPressed: () => _pickFile(context),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.orange),
                  tooltip: '保存',
                  onPressed: _commit,
                ),
              ],
            ),
          ),
        ],
      );
    }

    // 只读展示态
    return InkWell(
      onTap: () {
        setState(() {
          _isEditing = true;
        });
        // 延时请求焦点，确保 widget tree 渲染出 MarkdownField 之后定位光标
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _focusNode.requestFocus();
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
          ),
        ),
        child: MarkdownBody(
          data: widget.value,
          selectable: false,
          imageBuilder: (uri, title, alt) {
            final ref = uri.toString();
            return FutureBuilder<String>(
              future: _attachmentService.resolvePath(ref),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return _buildFileLostWidget(alt ?? '图片已丢失');
                }
                final path = snapshot.data!;
                final file = File(path);
                if (!file.existsSync()) {
                  return _buildFileLostWidget(alt ?? '图片已丢失');
                }
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      file,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildFileLostWidget('加载图片失败'),
                    ),
                  ),
                );
              },
            );
          },
          onTapLink: (text, href, title) {
            if (href != null && href.startsWith(MarkdownUtils.attachmentScheme)) {
              _handleAttachmentClick(context, text, href);
            }
          },
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(fontSize: 14, color: Colors.black87),
            listBullet: const TextStyle(fontSize: 14, color: Colors.black87),
            code: TextStyle(
              fontSize: 12,
              backgroundColor: Colors.grey[100],
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        icon: Icon(icon, size: 20, color: Colors.black54),
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildFileLostWidget(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.red[100]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image, size: 16, color: Colors.red),
          const SizedBox(width: 6),
          Text(
            message,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
