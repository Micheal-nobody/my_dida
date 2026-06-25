import 'package:flutter_test/flutter_test.dart';
import 'package:my_dida/core/utils/markdown_utils.dart';

void main() {
  group('MarkdownUtils Tests', () {
    test('buildImageRef should output standard markdown format', () {
      final ref = MarkdownUtils.buildImageRef(123, 'pic.png');
      expect(ref, '![](attachments://123/pic.png)');

      final refWithAlt = MarkdownUtils.buildImageRef(123, 'pic.png', alt: '风景');
      expect(refWithAlt, '![风景](attachments://123/pic.png)');
    });

    test('buildFileRef should output standard markdown link format', () {
      final ref = MarkdownUtils.buildFileRef(123, 'doc.pdf');
      expect(ref, '[doc.pdf](attachments://123/doc.pdf)');

      final refWithTitle = MarkdownUtils.buildFileRef(
        123,
        'doc.pdf',
        displayName: '我的文档',
      );
      expect(refWithTitle, '[我的文档](attachments://123/doc.pdf)');
    });

    test('extractAttachmentRefs should extract correct virtual paths', () {
      const markdown = '''
# 任务备注
请参考图片：![图1](attachments://456/image_1.jpg) 和文件 [文档](attachments://456/spec.pdf)
外部链接不应被提取 [百度](https://baidu.com)
以及没有 title 的图片：![](attachments://456/no_title.png)
''';
      final refs = MarkdownUtils.extractAttachmentRefs(markdown);
      expect(refs, [
        'attachments://456/image_1.jpg',
        'attachments://456/spec.pdf',
        'attachments://456/no_title.png',
      ]);
    });

    test(
      'isEffectivelyEmpty should check content and attachments correctly',
      () {
        expect(MarkdownUtils.isEffectivelyEmpty(''), isTrue);
        expect(MarkdownUtils.isEffectivelyEmpty('   '), isTrue);
        expect(MarkdownUtils.isEffectivelyEmpty('\n\n'), isTrue);
        expect(MarkdownUtils.isEffectivelyEmpty('### '), isTrue);
        expect(MarkdownUtils.isEffectivelyEmpty('- '), isTrue);

        expect(MarkdownUtils.isEffectivelyEmpty('有内容'), isFalse);
        expect(
          MarkdownUtils.isEffectivelyEmpty('![](attachments://1/a.png)'),
          isFalse,
        );
        expect(
          MarkdownUtils.isEffectivelyEmpty('[文件](attachments://1/b.txt)'),
          isFalse,
        );
      },
    );

    test('stripMarkdown should clean headers, links, and bold/italic markup', () {
      expect(MarkdownUtils.stripMarkdown(''), '');
      expect(MarkdownUtils.stripMarkdown('### 标题内容'), '标题内容');
      expect(MarkdownUtils.stripMarkdown('**粗体** 和 *斜体*'), '粗体 和 斜体');
      expect(MarkdownUtils.stripMarkdown('~~删除线~~ 和 `行内代码`'), '删除线 和 行内代码');
      expect(MarkdownUtils.stripMarkdown('> 这是一个引用句'), '这是一个引用句');
      expect(MarkdownUtils.stripMarkdown('- 列表项 1\n- 列表项 2'), '列表项 1\n列表项 2');
      expect(MarkdownUtils.stripMarkdown('1. 步骤一\n2. 步骤二'), '步骤一\n步骤二');

      // 链接与图片混合
      const mixed =
          '查看文档 [我的文档](attachments://123/doc.pdf) 还有图片 ![图](attachments://123/img.png)';
      expect(MarkdownUtils.stripMarkdown(mixed).trim(), '查看文档 我的文档 还有图片');
    });
  });
}
