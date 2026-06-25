/// 任务备注 Markdown 相关工具函数。
///
/// 任务 description 字段以 Markdown 文本存储，附件（图片/文件）通过
/// 虚拟路径 `attachments://<taskId>/<fileName>` 引用，渲染端由
/// [AttachmentService] 解析回沙盒绝对路径。
///
/// 本类提供：
/// - [stripMarkdown]：剥离 Markdown 标记，返回接近纯文本的结果，
///   供通知栏等无法渲染 Markdown 的场景兜底展示。
/// - [buildImageRef] / [buildFileRef]：生成 Markdown 引用片段。
/// - [extractAttachmentRefs]：从 Markdown 中抽出所有附件引用。
class MarkdownUtils {
  MarkdownUtils._();

  /// 附件虚拟路径协议前缀。
  static const String attachmentScheme = 'attachments://';

  /// 生成图片引用 Markdown：`![alt](attachments://<taskId>/<fileName>)`
  static String buildImageRef(int taskId, String fileName, {String? alt}) {
    final altText = (alt == null || alt.trim().isEmpty) ? '' : alt.trim();
    return '![$altText](${_ref(taskId, fileName)})';
  }

  /// 生成文件引用 Markdown：`[displayName](attachments://<taskId>/<fileName>)`
  static String buildFileRef(
    int taskId,
    String fileName, {
    String? displayName,
  }) {
    final shownName = (displayName == null || displayName.trim().isEmpty)
        ? fileName
        : displayName.trim();
    return '[$shownName](${_ref(taskId, fileName)})';
  }

  /// 从 Markdown 中抽取所有附件虚拟路径引用（去重后按出现顺序）。
  ///
  /// 用于孤儿扫描、附件总量统计等场景。返回的元素形如
  /// `attachments://<taskId>/<fileName>`。
  static List<String> extractAttachmentRefs(String markdown) {
    if (markdown.isEmpty) return const [];

    // 匹配 ![alt](url) 和 [text](url) 中的 url 部分。
    final linkRegex = RegExp(r'!?\[[^\]]*\]\(([^)]+)\)');
    final refs = <String>[];
    for (final match in linkRegex.allMatches(markdown)) {
      final url = match.group(1)?.trim() ?? '';
      if (url.startsWith(attachmentScheme)) {
        refs.add(url);
      }
    }
    return refs;
  }

  /// 判断某段 Markdown 文本是否"看起来是空的"——空白或仅由标记/附件组成。
  ///
  /// 用于详情页决定显示只读卡还是直接进编辑态。
  static bool isEffectivelyEmpty(String markdown) {
    return stripMarkdown(markdown).trim().isEmpty &&
        extractAttachmentRefs(markdown).isEmpty;
  }

  /// 轻量剥离 Markdown 标记，返回接近纯文本的结果。
  ///
  /// 仅做通知栏兜底展示用，不做完整 AST 解析。处理顺序很重要：
  /// 先剥离链接/图片（保留可读文字），再剥离行内/块级标记。
  static String stripMarkdown(String markdown) {
    if (markdown.isEmpty) return '';

    var text = markdown;

    // 1. 图片 ![alt](url) -> 丢弃（图片本身无可读文本，alt 通常为空）
    text = text.replaceAll(RegExp(r'!\[[^\]]*\]\([^)]*\)'), '');

    // 2. 普通链接 [text](url) -> 保留 text，丢弃 url
    text = text.replaceAllMapped(
      RegExp(r'\[([^\]]*)\]\([^)]*\)'),
      (m) => m.group(1) ?? '',
    );

    // 3. 代码块 ```...```
    text = text.replaceAll(RegExp(r'```[^\n]*\n?'), '');
    // 4. 行内代码 `code`
    text = text.replaceAllMapped(RegExp('`([^`]*)`'), (m) => m.group(1) ?? '');

    // 5. 引用块前导 >
    text = text.replaceAll(RegExp(r'^\s{0,3}>\s?', multiLine: true), '');

    // 6. ATX 标题前导 #
    text = text.replaceAll(RegExp(r'^\s{0,3}#{1,6}\s?', multiLine: true), '');

    // 7. 强调：**bold** / __bold__ / *italic* / _italic_ / ~~strike~~
    text = text
        .replaceAllMapped(
          RegExp(r'\*\*([^*]+)\*\*'),
          (m) => m.group(1) ?? '',
        )
        .replaceAllMapped(
          RegExp('__([^_]+)__'),
          (m) => m.group(1) ?? '',
        )
        .replaceAllMapped(
          RegExp(r'\*([^*]+)\*'),
          (m) => m.group(1) ?? '',
        )
        .replaceAllMapped(
          RegExp('_([^_]+)_'),
          (m) => m.group(1) ?? '',
        )
        .replaceAllMapped(
          RegExp('~~([^~]+)~~'),
          (m) => m.group(1) ?? '',
        );

    // 8. 列表标记 - / * / + / 1.
    text = text.replaceAll(
      RegExp(r'^\s{0,3}[-*+]\s+', multiLine: true),
      '',
    );
    text = text.replaceAll(
      RegExp(r'^\s{0,3}\d+\.\s+', multiLine: true),
      '',
    );

    // 9. 水平分割线
    text = text.replaceAll(
      RegExp(r'^\s{0,3}([-*_])\1{2,}\s*$', multiLine: true),
      '',
    );

    return text;
  }

  static String _ref(int taskId, String fileName) =>
      '$attachmentScheme$taskId/$fileName';
}
