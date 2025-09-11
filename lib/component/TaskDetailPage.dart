import 'package:flutter/material.dart';
import 'package:my_dida/model/entity/Task.dart';
import 'package:provider/provider.dart';
import 'package:my_dida/provider/TaskProvider.dart';

/// 任务详情 BottomSheet（由 TaskCard 的 onTap 触发）
class TaskDetailPage extends StatefulWidget {
  final int taskId;
  final ScrollController? scrollController;

  const TaskDetailPage(this.taskId, {super.key, this.scrollController});

  @override
  State<StatefulWidget> createState() {
    return _TaskDetailPageState();
  }
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  late TaskProvider _taskProvider;

  @override
  void initState() {
    super.initState();
    _taskProvider = Provider.of<TaskProvider>(context, listen: false);
  }

  Future<String?> _editTextDialog(
    BuildContext context, {
    String title = '编辑',
    String initial = '',
  }) async {
    final controller = TextEditingController(text: initial);
    return await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: TextField(controller: controller, autofocus: true),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  //TODO：在时间的左侧添加一个退出按钮（图标：左箭头），拖过调用栈中的数量切换按钮的样式与功能（参考_buildSubTaskSection上的TODO）
  Widget _buildHeader(Task task) {
    final DateTime now = DateTime.now();
    final String dateText = "今天, ${now.month}月${now.day}日";
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.event_note, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                dateText,
                style: const TextStyle(color: Colors.orange, fontSize: 14),
              ),
            ],
          ),
          //TODO： 从 BelongingBoxProvider 中获取所有收集箱，并显示在 dropdown 中
          DropdownButton<int?>(
            value: task.belongingBoxId,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.orange),
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem<int?>(value: 1, child: Text('收集箱 1')),
              DropdownMenuItem<int?>(value: 2, child: Text('收集箱 2')),
              DropdownMenuItem<int?>(value: 3, child: Text('收集箱 3')),
            ],
            onChanged: (v) async {
              await _taskProvider.updateBelongingBox(task, v);
            },
          ),
        ],
      ),
    );
  }

  //TODO: 原地修改Title，不需要弹出Dialog
  Widget _buildTitle(Task task) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final String? text = await _editTextDialog(
                  context,
                  title: '编辑标题',
                  initial: task.name,
                );
                if (text != null && text.isNotEmpty) {
                  await _taskProvider.updateTitle(task, text);
                }
              },
              child: Text(
                task.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.orange),
            onPressed: () async {
              final String? text = await _editTextDialog(
                context,
                title: '编辑标题',
                initial: task.name,
              );
              if (text != null && text.isNotEmpty) {
                await _taskProvider.updateTitle(task, text);
              }
            },
          ),
        ],
      ),
    );
  }

  //TODO: 原地修改备注，不需要弹出Dialog
  Widget _buildDescription(Task task) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final String? text = await _editTextDialog(
                  context,
                  title: task.description.isEmpty ? '添加备注' : '编辑备注',
                  initial: task.description,
                );
                if (text != null) {
                  await _taskProvider.updateDescription(task, text);
                }
              },
              child: Text(
                task.description.isEmpty ? '添加备注...' : task.description,
                style: TextStyle(
                  fontSize: 14,
                  color: task.description.isEmpty
                      ? Colors.black26
                      : Colors.black87,
                ),
              ),
            ),
          ),
          if (task.description.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.black38),
              onPressed: () async {
                await _taskProvider.updateDescription(task, '');
              },
            ),
        ],
      ),
    );
  }

  //TODO： 添加删除按钮，删除按钮位于检查点右侧，图标为 delete_outline
  Widget _buildCheckpoints(Task task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (task.checkpoints.isEmpty)
          const SizedBox.shrink(),

        // 含义：遍历任务的检查点，并显示在列表中（未完成在前，完成在后，完成项半透明）
        for (final entry in ([
          ...task.checkpoints.where((e) => !e.isDone),
          ...task.checkpoints.where((e) => e.isDone),
        ]).asMap().entries)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              leading: Checkbox(
                value: entry.value.isDone,
                onChanged: (v) {
                  if (v == null) return;
                  _taskProvider.toggleCheckpoint(task, entry.key, v);
                },
              ),
              title: GestureDetector(
                onTap: () async {
                  final String? text = await _editTextDialog(
                    context,
                    title: '编辑检查点',
                    initial: entry.value.name,
                  );
                  if (text != null && text.isNotEmpty) {
                    await _taskProvider.renameCheckpoint(task, entry.key, text);
                  }
                },
                child: Text(
                  entry.value.name,
                  style: TextStyle(
                    color: entry.value.isDone ? Colors.black38 : null,
                  ),
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.black26),
                onPressed: () async {
                  await _taskProvider.removeCheckpoint(task, entry.key);
                },
              ),
            ),
          ),
      ],
    );
  }

  // 用于显示任务的子任务
  //TODO：子任务可以点击进入新的TaskDetailPage，跳转后Header的左上角由退出按钮（图标：左箭头），变为返回按钮（图标： ×）
  Widget _buildSubTaskSection(Task task) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFF2E8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              FutureBuilder<List<Task>>(
                future: _taskProvider.getTasksByIds(task.subTaskIds),
                builder: (context, snapshot) {
                  final List<Task> subs = snapshot.data ?? [];
                  if (subs.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    children: [
                      for (final st in subs)
                        ListTile(
                          leading: Checkbox(
                            value: st.isDone,
                            onChanged: (v) async {
                              if (v == null) return;
                              await _taskProvider.updateTaskIsDone(st, v);
                            },
                          ),
                          title: Text(st.name),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await _taskProvider.deleteSubTask(task, st.id);
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<Task?>(
        stream: _taskProvider.watchTaskById(widget.taskId),
        builder: (context, snapshot) {
          final Task? task = snapshot.data;
          if (snapshot.connectionState == ConnectionState.waiting ||
              task == null) {
            return const SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: widget.scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _buildHeader(task),
                      const SizedBox(height: 6),
                      _buildTitle(task),
                      const SizedBox(height: 8),
                      _buildDescription(task),
                      _buildCheckpoints(task), 
                      const SizedBox(height: 10),
                      _buildSubTaskSection(task),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),

              // 这是底部按钮栏
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
                ),
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        await _taskProvider.addCheckpoint(task);
                      },
                      icon: const Icon(Icons.checklist, color: Colors.orange),
                      label: const Text(
                        '新检查点',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () async {
                        await _taskProvider.createSubTask(task);
                      },
                      icon: const Icon(
                        Icons.subdirectory_arrow_right,
                        color: Colors.orange,
                      ),
                      label: const Text(
                        '新子任务',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
